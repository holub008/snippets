import pandas as pd
import requests
from sklearn.feature_extraction.text import CountVectorizer
import nltk.stem
from nltk.corpus import stopwords
import lxml.etree
import lxml.builder
import binascii
import os
import traceback

data = pd.read_excel('./Students Excel (Qualitative).xlsx')
stemmer = nltk.stem.SnowballStemmer('english')


class StemmedCountVectorizer(CountVectorizer):

    def build_analyzer(self):
        analyzer = super(StemmedCountVectorizer, self).build_analyzer()
        return lambda doc: ([stemmer.stem(w) for w in analyzer(doc)])


for n in [1, 2, 3, 4]:
    writer = pd.ExcelWriter(f'./outputs/response_{n}-grams.xlsx', engine='xlsxwriter')
    for col in data.columns:
        vectorizer = StemmedCountVectorizer(ngram_range=[n, n], min_df=.01, analyzer="word", stop_words=stopwords.words('english'))
        analyzable_text = data[~pd.isnull(data[col])][col]
        try:
            freqs = vectorizer.fit_transform(analyzable_text).todense().sum(axis=0) / len(analyzable_text) * 100
        except: # general, to catch no words remaining after min_df pruning
            continue
        features = vectorizer.get_feature_names()

        freq_df = pd.DataFrame({
            'phrase': features,
            'frequency (percent of responses)': freqs.tolist()[0]
        }).sort_values('frequency (percent of responses)', ascending=False).head(250)
        freq_df.to_excel(writer, sheet_name=col[0:31], index=False)

    writer.save()


def _encode_multipart_formdata(fields):
    boundary = binascii.hexlify(os.urandom(16)).decode('ascii')

    body = (
        "".join("--%s\r\n"
                "Content-Disposition: form-data; name=\"%s\"\r\n"
                "\r\n"
                "%s\r\n" % (boundary, field, value)
                for field, value in fields.items()) +
        "--%s--\r\n" % boundary
    )

    content_type = "multipart/form-data; boundary=%s" % boundary

    return body, content_type


def _post_carrot_clustering(doc_xml):
    # this is a hardcode because I am hoping to quickly move lingo clustering to a python package
    carrot_host = 'localhost'
    carrot_port = 8080
    query = 'dcs/rest'
    url = "http://%s:%s/%s" % (carrot_host, carrot_port, query)

    fields = {
        'dcs.c2stream': doc_xml,
        'dcs.algorithm': 'lingo',
        'dcs.output.format': 'JSON',
        'dcs.clusters.only': True
    }
    body, content_type = _encode_multipart_formdata(fields)

    try:
        # note, carrot's jetty server barfs about form size being too large for even modest forms sizes
        # (with application/form content type), so we use the old-school multipart/form-data type
        response = requests.post(url, data=body, headers={'Content-type': content_type},
                             timeout=15)
    except:
        print(traceback.format_exc())
        return None

    if not response.ok:
        print(f'Carrot request failed with code: {response.status_code}')
        print(response.content)
        return None

    return response.json()


def _topic_cluster(documents):
    builder = lxml.builder.ElementMaker()
    # yes, these are as magical as they look
    # there's no secret configuration happening, the builder class is creating these attrs on the fly
    search_result = builder.searchresult
    title = builder.title
    document = builder.document
    snippet = builder.snippet

    xml_documents = [document(
        title(''),
        snippet(d)
    ) for d in documents]

    sr = search_result(
        *xml_documents
    )

    stream = lxml.etree.tostring(sr, pretty_print=False).decode('ascii')
    carrot_clustering = _post_carrot_clustering(stream)

    if not carrot_clustering:
        return [], []

    clusters = []
    for c in carrot_clustering['clusters']:
        if not c['phrases'][0] == 'Other Topics':  # for lingo, length == 1
            clusters.append({
               'topic': c['phrases'][0],
               'study_ids': [int(d) for d in c['documents']]
            })

    return clusters


# must have dcs running on localhost:8080
writer = pd.ExcelWriter(f'./outputs/response_topic_clusters.xlsx', engine='xlsxwriter')
for col in data.columns:
    analyzable_text = data[~pd.isnull(data[col])][col].tolist()
    clusters = [c['topic'] for c in _topic_cluster(analyzable_text)]
    df = pd.DataFrame({
        'topic': clusters
    })
    df.to_excel(writer, sheet_name=col[0:31], index=False)

writer.save()



import pandas as pd
from sklearn.feature_extraction.text import CountVectorizer
import nltk.stem
from nltk.corpus import stopwords

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

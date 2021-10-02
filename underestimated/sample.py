import nbib
from random import sample


# the details of a sampling strategy can be ironed out later
# e.g. we may wish to do stratified sampling on keyword underestimate/overestimate/understate/overstate
# for now we just perform a simple random sample
def pmid_sample(data, n=1500):
    pmids = [ue['pubmed_id'] for ue in data]
    return sample(pmids, min(n, len(data)))


def pubmed_format_query(pmids):
    return ' or '.join('%s[pmid]' % p for p in pmids)


def contains_interesting_phrase(abstract):
    abstract_lower = abstract.lower()
    return 'cannot be overestimated' in abstract_lower or 'cannot be underestimated' in abstract_lower or\
           'cannot be overstated' in abstract_lower or 'cannot be understated' in abstract_lower


all_records = nbib.read_file('./data/pubmed-cannotandu-set.nbib')
# since our pubmed strategy:
# cannot and (underestimated or overestimated or understated or overstated)
# is unable to do exact phrase searching with the stop word cannot, we cast a wide net and then filter it down
# programmatically with case insensitive matching
filtered_records = [r for r in all_records if 'abstract' in r and contains_interesting_phrase(r['abstract'])]
print(pubmed_format_query(pmid_sample(filtered_records)))
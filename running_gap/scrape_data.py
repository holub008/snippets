import re
from datetime import timedelta, datetime

import pandas as pd
import requests
from bs4 import BeautifulSoup

def parse_time_millis(time_unparsed,
                      time_format='%S.%f',
                      time_format_fallback='%M:%S.%f',
                      time_format_fallback2 = '%H:%M:%S.%f',
		      time_format_fallback3 = '%H:%M:%S'):
    dt = None
    try:
        dt = datetime.strptime(time_unparsed, time_format)
    except:
        try:
            dt = datetime.strptime(time_unparsed, time_format_fallback)
        except:
            try:
                dt = datetime.strptime(time_unparsed, time_format_fallback2)
            except:
		try:
                    dt = datetime.strptime(time_unparsed, time_format_fallback3)
		except:
                    return None
    delta = timedelta(hours=dt.hour, minutes=dt.minute, seconds=dt.second)
    return delta.total_seconds() * 1000


resp = requests.get('https://en.wikipedia.org/wiki/List_of_world_records_in_athletics')
soup = BeautifulSoup(resp.text, 'lxml')

record_tables = soup.find_all('table', {'class': 'wikitable sortable plainrowheaders'})

men_table_raw = record_tables[0]
women_table_raw = record_tables[1]

men_table = pd.read_html(str(men_table_raw))[0]
women_table = pd.read_html(str(women_table_raw))[0]

men_table['duration'] = [parse_time_millis(t) for t in men_table['Perf.']]
women_table['duration'] = [parse_time_millis(t) for t in women_table['Perf.']]

me = men_table[~pd.isnull(men_table['duration'])]
we = women_table[~pd.isnull(women_table['duration'])]
me['gender'] = 'male'
we['gender'] = 'female'

pd.concat([me, we]).to_csv('./records.csv')

import pandas as pd
import requests
from bs4 import BeautifulSoup

list_url = """http://aptaapps.apta.org/ptcas/observationhours.aspx"""
# too lazy to scrape
icon_to_requirement_type = {
    'apta/images/refs/ref1.gif': 'PT hours are required - a licensed PT must verify hours w/ signed form uploaded or online via PTCAS',
    'apta/images/refs/ref2.gif': 'PT hours are required - no verification by a physical therapist',
    'apta/images/refs/refpkt2.gif': 'PT hours are not required but are highly recommended ',
    'apta/images/refs/ref3.gif': 'PT hours are not required but are considered',
    'apta/images/refs/ref4.gif': 'PT hours are not required or considered',
    'apta/images/refs/varies.png': 'Other'
}

res = requests.get(list_url)
soup = BeautifulSoup(res.content, 'lxml')
program_table = soup.find('table', {'id': "ContentPlaceHolder1_gvPTO"})
program_rows = program_table.find_all('tr')

# doesn't quite work, because it drops requirement info
# df = pd.read_html(str(program_table))[0]


def parse_program(row):
    program_data = row.find_all('td')
    program_name = program_data[1].contents[0]
    minimum_hours = program_data[3].contents[0]
    recommended_hours = program_data[4].contents[0]
    requirement = icon_to_requirement_type[program_data[2].find('img')['src']]

    return program_name, minimum_hours, recommended_hours, requirement

parsed_programs = [parse_program(r) for r in program_rows[2:]]
df = pd.DataFrame(parsed_programs, columns=['program_name', 'minimum_hours', 'recommended_hours', 'requirement_type'])
df.to_csv('/Users/kholub/ptcas_obs_hours.csv')

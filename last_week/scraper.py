import requests
from bs4 import BeautifulSoup

BASE_PAGE = """https://www.yousubtitles.com/LastWeekTonight-cd-1453/%s"""
# yousubtitles implements access "control" via UA, so we spoof one
HEADERS = {'User-Agent': 'curl/7.54.0'}

def get_all_video_pages():
    resp = requests.get(BASE_PAGE % ('', ), headers=HEADERS)
    soup = BeautifulSoup(resp.content, 'lxml')
    title_pages = [div.find('a')['href'] for div in soup.find_all('div', {'class': 'title'})]
    all_title_pages = title_pages
    page = 1

    while len(title_pages) > 0:
        page += 1
        resp = requests.get(BASE_PAGE)
        title_pages = [div.find('a')['href'] for div in soup.find_all('div', {'class': 'title'})]
        all_title_pages += title_pages

    return all_title_pages

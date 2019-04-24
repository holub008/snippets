import time
from collections import Counter

import requests
from bs4 import BeautifulSoup
import nltk

HOST = """https://www.yousubtitles.com"""
BASE_PAGE = """https://www.yousubtitles.com/LastWeekTonight-cd-1453/%s"""
# yousubtitles implements access "control" via UA, so we spoof one
HEADERS = {'User-Agent': 'curl/7.54.0'}


def get_all_title_pages():
    resp = requests.get(BASE_PAGE % ('', ), headers=HEADERS)
    soup = BeautifulSoup(resp.content, 'lxml')
    title_pages = [div.find('a')['href'] for div in soup.find_all('div', {'class': 'title'})]
    all_title_pages = title_pages
    page = 1

    while len(title_pages) > 0:
        page += 1
        resp = requests.get(BASE_PAGE % ('page' + str(page), ), headers=HEADERS)
        soup = BeautifulSoup(resp.content, 'lxml')
        title_pages = [div.find('a')['href'] for div in soup.find_all('div', {'class': 'title'})]
        all_title_pages += title_pages

    return all_title_pages


def get_text_for_title(url):
    resp = requests.get(url, headers=HEADERS)
    soup = BeautifulSoup(resp.content, 'lxml')
    download_a = soup.find('a', {'id': 'downloadtext'})

    if not download_a:
        return None

    download_link = HOST + download_a['href']

    dl_resp = requests.get(download_link, headers=HEADERS)

    return dl_resp.text


def get_all_texts():
    title_page_urls = get_all_title_pages()
    all_texts = []

    for url in title_page_urls:
        text = get_text_for_title(url)
        if text:
            all_texts.append(text)
        time.sleep(1)

    return all_texts


if __name__ == "__main__":
    all_transcripts = get_all_texts()

    with open('./transcripts.txt', 'w') as f:
        f.writelines(all_transcripts)

    corpus = '\n'.join(all_transcripts)
    words = nltk.word_tokenize(corpus)

    bigrams = Counter(list(nltk.ngrams(words, 2)))
    trigrams = Counter(list(nltk.ngrams(words, 3)))

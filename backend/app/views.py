from audioop import add
from operator import le
from telnetlib import STATUS
from unicodedata import category
from django.shortcuts import render
from django.http import JsonResponse, HttpResponse 
from django.db import connection
from django.views.decorators.csrf import csrf_exempt

import json
import uuid
import geocoder

import nltk
nltk.download('punkt')
nltk.download('stopwords')

from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords
from nltk.stem import SnowballStemmer

from datetime import datetime
# Create your views here.


@csrf_exempt
def events_detail(request, slug):
    if request.method == 'GET':
        cursor = connection.cursor()
        cursor.execute(
            '''SELECT event_id, title, address, lat, lon, start_time, end_time, description, categories FROM events WHERE event_id = %s;''', [slug]
        )

        events = cursor.fetchall()
        if not events:
            return HttpResponse(status=404)

        event_data = list(events[0])

        if event_data[8]:
            event_data[8] = event_data[8].split('&')
        else:
            event_data[8] = []

        return JsonResponse({'event': event_data})

    elif request.method == 'PUT':
        cursor = connection.cursor()
        cursor.execute(
            '''SELECT event_id FROM events WHERE event_id = %s;''', [slug]
        )

        events = cursor.fetchall()
        if not events:
            return HttpResponse(status=404)

        json_data = json.loads(request.body)

        title = json_data['title']
        description = json_data['description']
        address = json_data['address']

        g = geocoder.osm(address)
        if not g.ok:
            return HttpResponse(status=400)

        lat = g.lat
        lon = g.lng

        start_time = datetime.fromtimestamp(int(json_data['start_time']))
        end_time = datetime.fromtimestamp(int(json_data['end_time']))

        categories = json_data['categories']
        if categories:
            categories_str = '&'.join(categories)

        cursor = connection.cursor()
        cursor.execute('''UPDATE events SET title = %s, description = %s, address = %s, lat = %s, lon = %s, start_time = %s, end_time = %s, categories = %s WHERE event_id = %s;''', [title, description, address, lat, lon, start_time, end_time, categories_str, slug])

        return HttpResponse(status=201)

    elif request.method == 'DELETE':
        cursor = connection.cursor()
        cursor.execute(
            '''SELECT event_id FROM events WHERE event_id = %s;''', [slug]
        )

        events = cursor.fetchall()
        if not events:
            return HttpResponse(status=404)

        cursor.execute(
            '''DELETE FROM events WHERE event_id=%s;''', [slug]    
        )
        return HttpResponse(status=201)

    else:
        return HttpResponse(status=404)



# TODO: remove csrf exempt decorator if we can figure out how
@csrf_exempt
def events(request):
    if request.method == 'POST':
        json_data = json.loads(request.body)

        event_id = str(uuid.uuid4().int)

        user_id = json_data['user_id']
        title = json_data['title']
        description = json_data['description']
        address = json_data['address']

        g = geocoder.osm(address)
        if not g.ok:
            return HttpResponse(status=400)

        lat = g.lat
        lon = g.lng

        start_time = datetime.fromtimestamp(int(json_data['start_time']))
        end_time = datetime.fromtimestamp(int(json_data['end_time']))

        categories = json_data['categories']
        if categories:
            categories_str = '&'.join(categories)

        cursor = connection.cursor()
        cursor.execute('INSERT INTO events '
            '(event_id, user_id, title, description, address, lat, lon, start_time, end_time, categories) '
            'VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s);',
            (event_id, user_id, title, description, address, lat, lon, start_time, end_time, categories_str))

        return HttpResponse(status=201)

    elif request.method == 'GET':
        # Get nearby events
        start_lat = float(request.GET.get('lat'))
        start_lon = float(request.GET.get('lon'))
        results = int(request.GET.get('results'))

        cursor = connection.cursor()
        cursor.execute('SELECT x.event_id, x.title, x.address, x.lat, x.lon, x.start_time, x.end_time, x.description FROM'
                       '('
                         'SELECT event_id, title, address, lat, lon, start_time, end_time, description, '
                           'SQRT('
                             'POW(69.1 * (lat - %s), 2) + '
                             'POW(69.1 * (%s - lon) * COS(lat / 57.3), 2)'
                           ') '
                           'AS distance '
                           'FROM events '
                       ') AS x '
                       'WHERE x.distance < 10000 '
                       'ORDER BY x.distance LIMIT %s;',
                       (start_lat, start_lon, results))

        nearby_events = cursor.fetchall()

        response = {}
        response['events'] = nearby_events
        return JsonResponse(response)

    else:
        return HttpResponse(status=404)


def score_lists(query_words: list, last_query: str, event_str: str):
    stemmer = SnowballStemmer('english')
    event_words = [stemmer.stem(word) for word in word_tokenize(event_str) if not word in stopwords.words()]
    event_len = len(query_words) + len(event_words)

    score = 0.0

    for event_word in event_words:
        for query_word in query_words:
            if event_word == query_word:
                score += 1.0 / event_len
        
        if event_word.startswith(last_query):
            score += 1.0 / (event_len)

    return score


# TODO: remove csrf exempt decorator if we can figure out how
@csrf_exempt
def search(request):
    if request.method == 'GET':
        # Get events based on location and search query
        start_lat = float(request.GET.get('lat'))
        start_lon = float(request.GET.get('lon'))
        query = request.GET.get('q')

        cursor = connection.cursor()
        cursor.execute('SELECT x.event_id, x.distance, x.title, x.description, x.user_id FROM'
                       '('
                            'SELECT event_id, user_id, title, lat, lon, start_time, end_time, description, '
                            'SQRT('
                                'POW(69.1 * (lat - %s), 2) + POW(69.1 * (%s - lon) * COS(lat / 57.3), 2)'
                            ') AS distance '
                            'FROM events '
                       ') AS x '
                       'WHERE x.distance < 500 AND x.end_time >= now();',
                       (start_lat, start_lon))

        query_words = word_tokenize(query)
        last_query = query_words.pop()

        stemmer = SnowballStemmer('english')
        query_words = [stemmer.stem(word) for word in query_words if not word in stopwords.words()]

        nearby_events = cursor.fetchall()
        scores = []

        for event in nearby_events:
            distance = event[1]
            title = event[2]
            description = event[3]
            user_id = event[4]

            score = 0.0

            score += score_lists(query_words, last_query, title)
            score += 0.75 * score_lists(query_words, last_query, description)

            score += 1 / (2 + 2*distance)

            if user_id in query:
                score += 1

            scores.append(score)

        response = {}
        response['events'] = nearby_events
        return JsonResponse(response)

    else:
        return HttpResponse(status=404)

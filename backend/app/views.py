from audioop import add
from operator import le
from telnetlib import STATUS
from unicodedata import category
from django.shortcuts import render
from django.http import JsonResponse, HttpResponse 
from django.db import connection
from django.views.decorators.csrf import csrf_exempt

from math import radians, cos, sin, asin, sqrt
import json
import uuid
import geocoder

import nltk
nltk.download('punkt')
nltk.download('stopwords')

from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords

from datetime import datetime
# Create your views here.
from django.contrib.auth.models import User
from django.contrib.auth import authenticate, login, logout

@csrf_exempt
def login_view(request):
    if request.method == 'POST':
        json_data = json.loads(request.body)
        if 'username' not in json_data or 'password' not in json_data:
            return HttpResponse(status=400)

        username = json_data['username']
        password = json_data['password']
        user = authenticate(request, username=username, password=password)
        if user is not None:
            login(request, user)
            return HttpResponse(status=200)
        else:
            return HttpResponse(status=404)
    else:
        return HttpResponse(status=404)

@csrf_exempt
def logout_view(request):
    if request.method == 'POST':
        logout(request)
        return HttpResponse(status=200)
    else:
        return HttpResponse(status=404)

@csrf_exempt
def register(request):
    if request.method == 'POST':
        json_data = json.loads(request.body)

        if 'username' not in json_data or 'password' not in json_data or 'email' not in json_data:
            return HttpResponse(status=400)

        username = json_data['username']
        password = json_data['password']
        email = json_data['email']
        user = User.objects.create_user(username, email, password)
        user.save()
        user = authenticate(request, username=username, password=password)
        if user is not None:
            login(request, user)
        return HttpResponse(status=201)
    else:
        return HttpResponse(status=404)

@csrf_exempt
def check_auth(request):
    if request.method == 'GET':
        logged_in = False
        if request.user.is_authenticated:
            logged_in = True
        return JsonResponse({'logged_in': logged_in})
    return HttpResponse(status=404)

@csrf_exempt
def events_detail(request, slug):
    if request.method == 'GET':
        cursor = connection.cursor()
        cursor.execute(
            '''SELECT event_id, title, address, lat, lon, start_time, end_time, description, categories, user_id FROM events WHERE event_id = %s;''', [slug]
        )

        events = cursor.fetchall()
        if not events:
            return HttpResponse(status=404)

        event_data = list(events[0])
        is_owner = False
        if request.user.is_authenticated:
            created_by = event_data[9]
            if created_by == request.user.username:
                is_owner = True


        if not event_data[8]:
            event_data[8] = ''

        if 'lat' not in request.GET or 'lon' not in request.GET:
            return HttpResponse(400)

        user_lat = float(request.GET.get('lat'))

        user_lon_str = request.GET.get('lon')
        if user_lon_str[-1] == '/':
            user_lon_str = user_lon_str[:-1]
        user_lon = float(user_lon_str)

        event_lat = event_data[3]
        event_lon = event_data[4]

        # formula for distance drawn from GeeksForGeeks:
        # https://www.geeksforgeeks.org/program-distance-two-points-earth/#:~:text=For%20this%20divide%20the%20values,is%20the%20radius%20of%20Earth.

        # The math module contains a function named
        # radians which converts from degrees to radians.
        user_lon = radians(user_lon)
        event_lon = radians(event_lon)
        user_lat = radians(user_lat)
        event_lat = radians(event_lat)
        
        # Haversine formula
        dlon = event_lon - user_lon
        dlat = event_lat - user_lat
        a = sin(dlat / 2)**2 + cos(user_lat) * cos(event_lat) * sin(dlon / 2)**2
    
        c = 2 * asin(sqrt(a))
        
        # Radius of earth in kilometers. Use 3956 for miles
        r = 3956
        
        # calculate the result
        dist = c * r
        event_data.append(round(dist, 1))

        return JsonResponse({'event': event_data, 'is_owner': is_owner})

    elif request.method == 'PUT':
        if not request.user.is_authenticated:
            return HttpResponse(status=401)
        cursor = connection.cursor()
        cursor.execute(
            '''SELECT event_id FROM events WHERE event_id = %s;''', [slug]
        )

        events = cursor.fetchall()
        if not events:
            return HttpResponse(status=404)

        json_data = json.loads(request.body)

        if 'title' not in json_data or 'description' not in json_data or 'address' not in json_data:
            return HttpResponse(status=400)

        title = json_data['title']
        description = json_data['description']
        address = json_data['address']

        g = geocoder.osm(address)
        if not g.ok:
            return HttpResponse(status=400)

        lat = g.lat
        lon = g.lng

        if 'start_time' not in json_data or 'end_time' not in json_data:
            return HttpResponse(status=400)

        start_time = datetime.fromtimestamp(int(json_data['start_time']))
        end_time = datetime.fromtimestamp(int(json_data['end_time']))

        if 'categories' in json_data:
            categories = json_data['categories']
        else:
            categories = ''

        cursor = connection.cursor()
        cursor.execute('''UPDATE events SET title = %s, description = %s, address = %s, lat = %s, lon = %s, start_time = %s, end_time = %s, categories = %s WHERE event_id = %s;''', [title, description, address, lat, lon, start_time, end_time, categories, slug])

        return HttpResponse(status=201)

    elif request.method == 'DELETE':
        if not request.user.is_authenticated:
            return HttpResponse(status=401)

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
        if not request.user.is_authenticated:
            return HttpResponse(status=401)
        
        user_id = request.user.username
        event_id = str(uuid.uuid4().int)

        json_data = json.loads(request.body)
        
        if 'title' not in json_data or 'description' not in json_data or 'address' not in json_data:
            return HttpResponse(status=400)

        title = json_data['title']
        description = json_data['description']
        address = json_data['address']

        g = geocoder.osm(address)
        if not g.ok:
            return HttpResponse(status=400)

        lat = g.lat
        lon = g.lng

        if 'start_time' not in json_data or 'end_time' not in json_data:
            return HttpResponse(status=400)

        start_time = datetime.fromtimestamp(int(json_data['start_time']))
        end_time = datetime.fromtimestamp(int(json_data['end_time']))

        if 'categories' in json_data:
            categories = json_data['categories']
        else:
            categories = ''

        cursor = connection.cursor()
        cursor.execute('INSERT INTO events '
            '(event_id, user_id, title, description, address, lat, lon, start_time, end_time, categories) '
            'VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s);',
            (event_id, user_id, title, description, address, lat, lon, start_time, end_time, categories))

        return HttpResponse(status=201)

    elif request.method == 'GET':

        if 'lat' not in request.GET or 'lon' not in request.GET or 'results' not in request.GET:
            return HttpResponse(400)

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
    event_words = [word for word in word_tokenize(event_str.lower()) if not word in stopwords.words()]
    event_len = len(event_words)

    score = 0.0

    for event_word in event_words:
        for query_word in query_words:
            if event_word == query_word:
                score += 1.0 / event_len
        
        if event_word.startswith(last_query):
            score += 1.0 / event_len

    return score


# TODO: remove csrf exempt decorator if we can figure out how
@csrf_exempt
def search(request):
    if request.method == 'GET':

        if 'lat' not in request.GET or 'lon' not in request.GET or 'q' not in request.GET:
            return HttpResponse(400)

        # Get events based on location and search query
        start_lat = float(request.GET.get('lat'))
        start_lon = float(request.GET.get('lon'))
        query = request.GET.get('q').lower()

        if query[-1] == '/':
            query = query[:-1]

        if 'category' in request.GET:
            desired_category = str(request.GET.get('category'))
        elif 'categories' in request.GET:
            desired_category = str(request.GET.get('categories'))
        else:
            desired_category = None

        if desired_category and desired_category[-1] == '/':
            desired_category = desired_category[:-1]

        cursor = connection.cursor()
        cursor.execute('SELECT x.event_id, x.distance, x.title, x.description, x.user_id, x.categories, x.lat, x.lon FROM'
                       '('
                            'SELECT event_id, user_id, title, lat, lon, start_time, end_time, description, categories, '
                            'SQRT('
                                'POW(69.1 * (lat - %s), 2) + POW(69.1 * (%s - lon) * COS(lat / 57.3), 2)'
                            ') AS distance '
                            'FROM events '
                       ') AS x '
                       'WHERE x.distance < 500 AND x.end_time >= now();',
                       (start_lat, start_lon))

        query_words = word_tokenize(query)
        last_query = query_words.pop()

        query_words = [word for word in query_words if not word in stopwords.words()]

        nearby_events = cursor.fetchall()
        scores = []
        short_events = []

        for event in nearby_events:
            if desired_category:
                category = event[5]
                if category != desired_category:
                    continue

            event_id = event[0]
            distance = event[1]
            title = event[2]
            description = event[3]
            user_id = event[4]
            lat = event[6]
            lon = event[7]

            score = 0.0

            score += score_lists(query_words, last_query, title)
            score += 0.75 * score_lists(query_words, last_query, description)

            score += 1 / (4 + distance)

            if user_id in query:
                score += 1

            scores.append(score)
            short_events.append({'event_id': event_id, 'title': title, 'lat': lat, 'lon': lon})

        sorted_events = [event for _, event in sorted(zip(scores, short_events), key=lambda pair: pair[0], reverse=True)]
        return JsonResponse({'event_names': sorted_events[:10]})

    else:
        return HttpResponse(status=404)

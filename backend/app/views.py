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

from datetime import datetime
# Create your views here.


@csrf_exempt
def events_detail(request, slug):
    if request.method == 'GET':
        cursor = connection.cursor()
        cursor.execute(
            '''SELECT event_id, user_id, title, description, address, lat, lon, start_time, end_time, categories FROM events WHERE event_id = %s;''', [slug]
        )

        events = cursor.fetchall()
        if not events:
            return HttpResponse(status=404)

        event_data = list(events[0])

        if event_data[9]:
            event_data[9] = event_data[9].split('&')
        else:
            event_data[9] = []

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

        return HttpResponse(status=200)

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
        return HttpResponse(status=200)

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

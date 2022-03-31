from audioop import add
from operator import le
from telnetlib import STATUS
from django.shortcuts import render
from django.http import JsonResponse, HttpResponse 
from django.db import connection
from django.views.decorators.csrf import csrf_exempt

import json
import uuid
import geocoder

from datetime import datetime
# Create your views here.

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

        cursor = connection.cursor()
        cursor.execute('INSERT INTO events '
            '(event_id, user_id, title, description, address, lat, lon, start_time, end_time) VALUES '
            '(%s, %s, %s, %s, %s, %s, %s, %s, %s);', (event_id, user_id, title, description, address, lat, lon, start_time, end_time))

        return HttpResponse(status=201)

    elif request.method == 'GET':
        # Get nearby events
        start_lat = float(request.GET.get('lat'))
        start_lon = float(request.GET.get('lon'))
        results = int(request.GET.get('results'))

        cursor = connection.cursor()
        cursor.execute('SELECT x.event_id, x.title, x.address, x.lat, x.lon, x.start_time, x.start_time, x.description FROM'
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

        # columns = [col[0] for col in cursor.description]
        # nearby_events = [ dict(zip(columns, row)) for row in cursor.fetchall() ]
        nearby_events = cursor.fetchall()

        response = {}
        response['events'] = nearby_events
        return JsonResponse(response)

    elif request.method == 'PUT':
        json_data = json.loads(request.body)

        query = 'UPDATE events SET'

        if 'title' in json_data:
            query += f' title = {json_data["title"]}'

        if 'description' in json_data:
            query += f' description = {json_data["description"]}'

        if 'address' in json_data:
            query += f' address = {json_data["address"]}'

            g = geocoder.osm(address)
            if not g.ok:
                return HttpResponse(status=400)

            lat = g.lat
            lon = g.lng

            query += f' lat = {lat}'
            query += f' lon = {lon}'

        if 'start_time' in json_data:
            query += f' start_time = {datetime.fromtimestamp(int(json_data["start_time"]))}'

        if 'end_time' in json_data:
            query += f' end_time = {datetime.fromtimestamp(int(json_data["end_time"]))}'

        event_id = json_data['event_id']
        query += f' WHERE event_id = {event_id};'

        cursor = connection.cursor()
        cursor.execute(query)

        return HttpResponse(status=201)
    
    elif request.method == 'DELETE':
        json_data = json.load(request.body)

        cursor = connection.cursor()
        cursor.execute('DELETE FROM events WHERE event_id = %s;', (json_data['event_id']))

        return HttpResponse(status=201)

    else:
        return HttpResponse(status=404)

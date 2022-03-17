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
        cursor.execute('SELECT x.event_id, title, x.lat, x.lon FROM'
                       '('
                         'SELECT event_id, title, lat, lon, '
                           'SQRT('
                             'POW(69.1 * (lat - %s), 2) + '
                             'POW(69.1 * (%s - lon) * COS(lat / 57.3), 2)'
                           ') '
                           'AS distance '
                           'FROM events '
                       ') AS x '
                       'WHERE x.distance < 25 '
                       'ORDER BY x.distance LIMIT %s;',
                       (start_lat, start_lon, results))

        columns = [col[0] for col in cursor.description]
        nearby_events = [ dict(zip(columns, row)) for row in cursor.fetchall() ]
        # nearby_events = cursor.fetchall()

        response = {}
        response['events'] = nearby_events
        return JsonResponse(response)

    else:
        return HttpResponse(status=404)

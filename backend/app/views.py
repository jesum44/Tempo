from audioop import add
from operator import le
from telnetlib import STATUS
from django.shortcuts import render
from django.http import JsonResponse, HttpResponse 
from django.db import connection
from django.views.decorators.csrf import csrf_exempt

import json

from datetime import datetime
# Create your views here.

# TODO: remove csrf exempt decorator if we can figure out how
@csrf_exempt
def events(request):
    if request.method == 'POST':
        json_data = json.loads(request.body)

        # TODO: event id
        event_id = None

        user_id = json['user_id']
        title = json['title']
        description = json['description']
        address = json['address']

        # TODO: lat/lon query
        lat = None
        lon = None

        start_time = datetime.fromtimestamp(json['start_time'])
        end_time = datetime.fromtimestamp(json['end_time'])

        cursor = connection.cursor()
        cursor.execute('INSERT INTO events'
            '(event_id, user_id, title, description, address, lat, lon, start_time, end_time) VALUES'
            '(%s, %s, %s, %s, %s, %s, %s, %s, %s);', (event_id, user_id, title, description, address, lat, lon, start_time, end_time))

        return JsonResponse({})

    elif request.method == 'GET':
        pass
    else:
        return HttpResponse(status=404)

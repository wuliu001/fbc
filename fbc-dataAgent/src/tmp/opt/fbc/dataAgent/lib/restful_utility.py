# -*- coding: utf8 -*-

import urllib2
import json

g_retry_cnt = 100

# ==== http utils ====
def http_handles(url, method, body = None, header = None):
    try:
        if method == 'GET':
            request = urllib2.Request(url)
        elif method == 'POST':
            request = urllib2.Request(url, body)
        elif method == 'PUT':
            request = urllib2.Request(url, body)
            request.get_method = lambda: 'PUT'
        elif method == 'DELETE':
            request = urllib2.Request(url, body)
            request.get_method = lambda: 'DELETE'

        if header:
            headerlists = header.split(';')
            for headerlist in headerlists:
                headerlist = header.split(':')
                key = headerlist[0]
                val = headerlist[1]
                request.add_header(key, val)

        connection = urllib2.urlopen(request)
        content = connection.read()
        http_return_code = connection.getcode()
        connection.close()
        
        return http_return_code, content

    except Exception, e:
        try:
            return e.code, e.read()
        except Exception, e:
            return -1, "No Server"

def http_json_handles(url, method, body = None, header = None):
    http_return_code, response = http_handles(url, method, body, header)

    if None == response:
        return http_return_code, None, None

    try:
        jsonObj = json.loads(response)
        api_return_code = jsonObj['ops']['code']
        return http_return_code, jsonObj, api_return_code
    except:
        return http_return_code, response, None

# ==== common lib ====
def restful_runner(url, method, header = None, body = None):
    attempts = 0
    while attempts <= g_retry_cnt:
        if method == 'GET' or method == 'POST' or method == 'PUT' or method == 'DELETE':
            http_return_code, return_json, api_return_code = http_json_handles(url, method, body, header)
        else:
            return -1, -1, json.loads('{"error_msg":"invaild method input"}')
        
        if http_return_code == 200 and api_return_code != 400:
            break
        else:
            attempts = attempts + 1
            if attempts > g_retry_cnt:
               break

    return http_return_code, api_return_code, return_json
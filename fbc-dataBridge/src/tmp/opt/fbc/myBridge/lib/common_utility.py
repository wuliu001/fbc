#!/usr/bin/env python

import sys
import os
import datetime
import urllib2
import json
import time
import fcntl

is_debug = 0

# ==== log ====
def log_base(type, msg):
    log_info = u'%(time)s UTC [%(type)s][%(pid)d] %(msg)s \n' % { 'time' : datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S'), 'type' : type, 'pid' : os.getpid(), 'msg' : msg }
    print log_info

def log_d(msg):
    if is_debug == 1:
        log_base('D', msg)

def log_i(msg):
    log_base('I', msg)

def log_e(msg):
    log_base('E', msg)

# ==== http utils ====
def http_get(url, header):
    try:
        if header is None:
            log_d('HTTP GET: %s' % url)
            connection = urllib2.urlopen(url)
            content = connection.read()
            return_code = connection.getcode()
            connection.close()
            log_d('HTTP response: %s' % content)
            return return_code, content
        else:
            log_d('HTTP GET: %s with header: %s' % (url, header))
            request = urllib2.Request(url)
            
            headerlists=header.split(';')
            for headerlist in headerlists:
                headerlist=header.split(':')
                key = headerlist[0]
                val = headerlist[1]
                request.add_header(key, val)
            
            connection = urllib2.urlopen(request)
            content = connection.read()
            return_code = connection.getcode()
            connection.close()
            log_d('HTTP response: %s' % content)
            return return_code, content
    except Exception, e:
        log_e('http_get() error: %s' % e)
        try:
            return e.code, e.read()
        except Exception, e:
            return -1, "No Server"

def http_post(url, body, header):
    try:
        if header is None:
            log_d('HTTP POST: %s, body: %s' % (url, body))
            request = urllib2.Request(url, body)
            connection = urllib2.urlopen(request)
            content = connection.read()
            return_code = connection.getcode()
            connection.close()
            log_d('HTTP response: %s' % content)
            return return_code, content
        else:
            log_d('HTTP POST: %s with header: %s' % (url, header))
            request = urllib2.Request(url, body)

            headerlists=header.split(';')
            for headerlist in headerlists:
                headerlist=header.split(':')
                key = headerlist[0]
                val = headerlist[1]
                request.add_header(key, val)

            connection = urllib2.urlopen(request)
            content = connection.read()
            return_code = connection.getcode()
            connection.close()
            log_d('HTTP response: %s' % content)
            return return_code, content
    except Exception, e:
        log_e('http_post() error: %s' % e)
        try:
            return e.code, e.read()
        except Exception, e:
            return -1, "No Server"

def http_put(url, body, header):
    try:
        #print body
        if header is None:
            log_d('HTTP PUT: %s, body: %s' % (url, body))
            request = urllib2.Request(url, body)
            request.get_method = lambda: 'PUT'
            connection = urllib2.urlopen(request)
            content = connection.read()
            return_code = connection.getcode()
            connection.close()
            log_d('HTTP response: %s' % content)
            return return_code, content
        else:
            log_d('HTTP PUT: %s with header: %s' % (url, header))
            request = urllib2.Request(url, body)
            request.get_method = lambda: 'PUT'

            headerlists=header.split(';')
            for headerlist in headerlists:
                headerlist=header.split(':')
                key = headerlist[0]
                val = headerlist[1]
                request.add_header(key, val)

            connection = urllib2.urlopen(request)
            content = connection.read()
            return_code = connection.getcode()
            connection.close()
            log_d('HTTP response: %s' % content)
            return return_code, content
    except Exception, e:
        log_e('http_put() error: %s' % e)
        try:
            return e.code, e.read()
        except Exception, e:
            return -1, "No Server"

def http_delete(url, body, header):
    try:
        if header is None:
            log_d('HTTP DELETE: %s' % (url))
            request = urllib2.Request(url, body)
            request.get_method = lambda: 'DELETE'
            connection = urllib2.urlopen(request)
            content = connection.read()
            return_code = connection.getcode()
            connection.close()
            log_d('HTTP response: %s' % content)
            return return_code, content
        else:
            log_d('HTTP DELETE: %s with header: %s' % (url, header))
            request = urllib2.Request(url, body)
            request.get_method = lambda: 'DELETE'

            headerlists=header.split(';')
            for headerlist in headerlists:
                headerlist=header.split(':')
                key = headerlist[0]
                val = headerlist[1]
                request.add_header(key, val)

            connection = urllib2.urlopen(request)
            content = connection.read()
            return_code = connection.getcode()
            connection.close()
            log_d('HTTP response: %s' % content)
            return return_code, content
    except Exception, e:
        log_e('http_delete() error: %s' % e)
        try:
            return e.code, e.read()
        except Exception, e:
            return -1, "No Server"

def http_get_json(url, header=None):
    return_code, response = http_get(url, header)

    if None == response:
        return return_code, None

    try:    
        jsonObj = json.loads(response)
        return return_code, jsonObj
    except:
        log_e('Parse json error: ' + response)
        return return_code, response

def http_post_json(url, body, header=None):
    return_code, response = http_post(url, body, header)

    if None == response:
        return return_code, None

    try:    
        jsonObj = json.loads(response)
        return return_code, jsonObj
    except:
        log_e('Parse json error: ' + response)
        return return_code, response

def http_put_json(url, body, header=None):
    return_code, response = http_put(url, body, header)

    if None == response:
        return return_code, None

    try:    
        jsonObj = json.loads(response)
        return return_code, jsonObj
    except:
        log_e('Parse json error: ' + response)
        return return_code, response

def http_delete_json(url, header=None):
    return_code, response = http_delete(url, None, header)

    if None == response:
        return return_code, None

    try:    
        jsonObj = json.loads(response)
        return return_code, jsonObj
    except:
        log_e('Parse json error: ' + response)
        return return_code, response

# ==== common lib ====
def restful_runner(url, method, header = None, body = None):
    if method == 'GET':
        return_code, return_json = http_get_json(url, header)
    elif method == 'POST':
        return_code, return_json = http_post_json(url, body, header)
    elif method == 'PUT':
        return_code, return_json = http_put_json(url, body, header)
    elif method == 'DELETE':
        return_code, return_json = http_delete_json(url, header)
    else:
        return_code = -1
        return_json = json.loads('{"error_msg":"invaild method input"}')

    return return_code, return_json

# ==== misc utils ====
def do_exit(msg='', code=0):
    
    if 0 == code:
        if msg:
            log_i(msg)
    else:
        log_e(msg)
    
    sys.exit(code)

# ==== pid file utils ====
def pid_create(g_pid_file_path, pid_name):
    try:
        pid_file_name = g_pid_file_path + '/' + pid_name + '.pid'
        pid_file_object = open(pid_file_name, 'w')
        pid_file_object.close()
        return True
    except IOError:
        return False

def pid_check(g_pid_file_path, pid_name):
    pid_file_name = g_pid_file_path + '/' + pid_name + '.pid'
    current_timestamp = int(time.time()*1000000)
    
    try:
        pid_file_object = open(pid_file_name, 'r+')
        fcntl.flock(pid_file_object, fcntl.LOCK_EX)
        pid_context = pid_file_object.read()
        if pid_context.isdigit():
            if (int(pid_context) + 120000000) >= current_timestamp:
                pid_file_object.close()
                return False
        pid_file_object.seek(0)
        pid_file_object.truncate(0)
        pid_file_object.write(str(current_timestamp))
        pid_file_object.close()
        return True
    except IOError:
        return False

def pid_remove(g_pid_file_path, pid_name):
    is_success = pid_create(g_pid_file_path, pid_name)
    retry_cnt = 0
    while (not is_success) and (retry_cnt < 100):
        is_success = pid_create(g_pid_file_path, pid_name)
        time.sleep(0.1)
        retry_cnt = retry_cnt + 1

# ==== list to str utils ====
def list_to_str(p_list):
    return str(list(set(p_list))).replace('[','').replace(']','').replace(' ','').replace("'","").strip(',')

def set_to_str(p_list):
    return str(list(p_list)).replace('[', '').replace(']', '').replace(' ', '').replace("'", "").replace("u", "").strip(',')


#!/usr/bin/env python
import threading
from datetime import datetime
import urllib2
import sys
import json

global http_error_cnt
global api_error_cnt
http_error_cnt = 0
api_error_cnt = 0

def http_get(url,thread_no):
    global http_error_cnt
    global api_error_cnt
    try:
        thread_begin_time = datetime.now()
        print 'Thread-[%d]-[%s], HTTP GET: %s' % (thread_no,str(thread_begin_time),url)
        connection = urllib2.urlopen(url)
        content = connection.read()
        return_code = connection.getcode()
        connection.close()

        Json_dataSet = json.loads(content)
        api_return_code = Json_dataSet['ops']['code']

        if return_code != 200:
            http_error_cnt += 1

        if api_return_code != 200:
            api_error_cnt += 1

        thread_end_time = datetime.now()
        during_time = str(thread_end_time - thread_begin_time)
        print 'Thread-[%d]-[%s], HTTP response code: %d, API code: %d, during time: %s' % (thread_no,str(thread_end_time),return_code,api_return_code,during_time)
    except Exception,e:
        api_error_cnt += 1
        print 'http_get() thread-[%d] error: %s' % (thread_no,e)

def build_connect(url, call_count):
    thread_list = range(call_count)

    threadpool = []
    try:
        for i in thread_list:
            th = threading.Thread(target=http_get, args=(url, i))
            threadpool.append(th)

        for th in threadpool:
            th.start()

        for th in threadpool:
            threading.Thread.join(th)
    except Exception, e:
        print 'build_connect error: %s' % e

def main():
    api_call_begin_time = datetime.now()
    print 'Http get starting at:', str(api_call_begin_time)
    print '========================================================='

    paras_count = len(sys.argv)
    if paras_count < 3:
        print "Error: please input enough parameters. example: python dataService_get_test.py [url] [concurrent_call count]"
        exit()

    url = sys.argv[1]
    call_count = int(sys.argv[2])
    thread_list = range(call_count)

    threadpool = []
    try:
        for i in thread_list:
            th = threading.Thread(target=http_get, args=(url, i))
            threadpool.append(th)

        for th in threadpool:
            th.start()

        for th in threadpool:
            threading.Thread.join(th)

        api_call_end_time = datetime.now()
        api_call_during_time = str(api_call_end_time - api_call_begin_time)
        print '========================================================='
        print 'all threads Done at:', str(api_call_end_time)
        print 'all threads time cost:', api_call_during_time
        print 'dataService GET API test result: total(%d), success(%d), fail(%d)' % (call_count,call_count - api_error_cnt,api_error_cnt)

    except Exception, e:
        print 'main() error: %s' % e


if '__main__' == __name__:
    print 'begin threadings...'
    main()


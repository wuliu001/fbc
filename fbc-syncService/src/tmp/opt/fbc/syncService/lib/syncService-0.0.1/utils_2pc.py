#!/usr/bin/env python
# -*- coding: utf8 -*-

import logging
import sys
import urllib2
import json
import uuid

global g_logger
global g_retry_cnt


logLevel = {'D':'DEBUG','I':'INFO','W':'WARNING','E':'ERROR'}

def doLogInit(log_level, log_file):
    global g_logger
    try:
        level = logLevel[log_level]
        level = eval('logging.' + level)
        logger = logging.getLogger('syncService')
        formatter = logging.Formatter('%(asctime)s [line:%(lineno)d] %(levelname)s: %(message)s')
        file_handler = logging.FileHandler(log_file)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

        logger.setLevel(level)
        g_logger = logger
    except Exception, e:
        print '[doLogInit] init log object fail: %s' % e
        doExit(1)


def logD(msg):
    global g_logger
    g_logger.debug(msg)


def logI(msg):
    global g_logger
    g_logger.info(msg)


def logW(msg):
    global g_logger
    g_logger.warning(msg)


def logE(msg):
    global g_logger
    g_logger.error(msg)


def doExit(code=0):
    sys.exit(code)

def setHttpRequest_retryCnt(retry_cnt):
    global g_retry_cnt
    g_retry_cnt = retry_cnt


def get_endpoint():
    try:
        node = uuid.getnode()
        mac = uuid.UUID(int=node).hex[-12:]
        mac_address = ":".join([mac[e:e + 2] for e in range(0, 11, 2)])
        return mac_address
    except Exception, e:
        logE('[get_mac_address] get syncService mac address as endpoint_id fail: %s' % e)
        doExit(1)


def utils_concat(ssep='',*args):
    ll=[]
    for value in args:
        ll.append(str(value))
    ss = ssep.join(ll)
    return ss


def http_handler(http_method,http_url,http_body):
    global g_retry_cnt
    retry_idx = 0
    http_return_code = 0
    api_return_code = 0
    api_return_str = ''

    try:
        if http_method == 'GET':
            req = urllib2.Request(http_url)
        elif http_method == 'POST':
            req = urllib2.Request(http_url, http_body)
        elif http_method == 'PUT':
            req = urllib2.Request(http_url, http_body)
            req.get_method = lambda: 'PUT'
        elif http_method == 'DELETE':
            req = urllib2.Request(http_url, http_body)
            req.get_method = lambda: 'DELETE'

        while retry_idx <= g_retry_cnt:
            if retry_idx > 0:
                logD('[http_handler] retry call api [%d]rd...' % retry_idx)

            try:
                response = urllib2.urlopen(req)
                content = response.read()
                http_return_code = response.getcode()
                response.close()
                api_return_str = json.loads(content)
                api_return_code = api_return_str['ops']['code']
            except Exception, e:
                logE('[http_handler] call api fail, exception info: [%s]' % e)

            if http_return_code == 200 and api_return_code != 400:
                break
            elif http_return_code != 200:
                logE('[http_handler] call api fail. [url: %s, method: %s, body: %s]' % (http_url, http_method, http_body))
            else:
                logW('[http_handler] api return code is not 200. [url: %s, method: %s, body: %s]' % (http_url,http_method,http_body))

            retry_idx += 1

        return http_return_code, api_return_code, api_return_str

    except Exception, e:
        logE('[http_handler] http_handler process fail, exception info: [%s]' % e)
        return 0,0,''


def formatSqlValue(listObj, listKeySType, listKeys):
    try:
        listNum = len(listObj)

        iCntListObj = 0
        sSql = ''
        itotalKeyCnt = len(listKeys)

        while iCntListObj < listNum:
            listItemObj = listObj[iCntListObj]
            icntKeyCnt = 0
            listValues = []

            while icntKeyCnt < itotalKeyCnt:
                sValue = str(listItemObj[listKeys[icntKeyCnt]])

                if sValue == 'None':
                    sValue = 'NULL'

                isStrType = listKeySType[icntKeyCnt]
                if isStrType == True and sValue != 'NULL':
                    listValues.append(utils_concat('', "'", sValue, "'"))
                else:
                    listValues.append(sValue)

                icntKeyCnt += 1

            iCntListObj += 1

            sSqlValues = ','.join(listValues)

            if sSql != '':
                listT1 = [sSql, ',', '(', sSqlValues, ')']
            else:
                listT1 = ['(', sSqlValues, ')']
            sSql = ''.join(listT1)

        return True, sSql
    except Exception, e:
        logE('[formatSqlValue] data format to sql value fail, data: [%s], exception info: [%s]' % (listObj,e))
        return False, ''


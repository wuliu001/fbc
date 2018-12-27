#!/usr/bin/env python
# -*- coding: utf8 -*-

import sys
import getopt
import ConfigParser
import os
import utils_2pc
import json
import time

global g_log_level
global g_log_file
global g_http_retry_cnt
global g_check_retry_cnt
global g_threadnum
global g_config_file
global g_syncService_endpoint
global g_endpoint_info
global g_endpoint_len

g_endpoint_info = []
g_endpoint_len = 0
g_sync_config_url = '/msg_management/config'
g_get_unsynced_data_url = '/msg_management/data'
g_get_weight_url = '/msg_management/weight'


def usage():
    print """Usage: syncService_2pc.py [option] [optionValue]
     Options:
      -l | --loglevel        is the loglevel for record log, for example: D
                             the loglevel info is: (D:Debug, I:Info, W:Warning, E:Error)
                             this option is optional, default value is W
      -f | --logfile         is logfile to record log msg based on loglevel, for example: /var/log/fbc/server/syncService.log
                             this option is MUST
      -c | --configfile      is config file to save endpoint info, for example: /opt/fbc/syncService/endpoints.ini
                             this option is MUST
      -p | --http_retrycnt   is http request retry count when http fail, for example: 5
                             this option is optional, default value is 0
      -k | --check_retrycnt  is queue data check retry count when queue check fail, for example: 1
                             this option is optional, default value is 0
      -t | --threadnum       is threads number for multithreading, for example: 5
                             this option is optional, default value is 1
      -h | --help            is help info"""


# parse command parameter options
def parseOptions():
    global g_log_level
    global g_log_file
    global g_config_file
    global g_http_retry_cnt
    global g_check_retry_cnt
    global g_threadnum

    g_log_level = 'W'
    g_log_file = ''
    g_config_file = ''
    g_http_retry_cnt = 0
    g_check_retry_cnt = 0
    g_threadnum = 1

    try:
        options,args = getopt.getopt(sys.argv[1:],"hl:f:c:p:k:t:",["help","loglevel=","logfile=","configfile=","http_retrycnt=","check_retrycnt=","threadnum="])
    except getopt.GetoptError:
        usage()
        print '[parseOptions] parse command parameter options fail.'
        utils_2pc.doExit(1)

    # get option value
    for name,value in options:
        if name in ("-h","--help"):
            usage()
        if name in ("-l","--loglevel"):
            g_log_level = value
        if name in ("-f","--logfile"):
            g_log_file = value
        if name in ("-c","--configfile"):
            g_config_file = value
        if name in ("-p","--http_retrycnt"):
            g_http_retry_cnt = int(value)
        if name in ("-k","--check_retrycnt"):
            g_check_retry_cnt = int(value)
        if name in ("-t","--threadnum"):
            g_threadnum = int(value)

    try:
        utils_2pc.setHttpRequest_retryCnt(int(g_http_retry_cnt))
    except Exception, e:
        print '[parseOptions] set http request retry count fail: %s' % e
        utils_2pc.doExit(1)


# endpoint config file parse class, provide 3 functions to get relation data
class endpoint_config_Parser:
    try:
        def __init__(self, path):
            self.path = path
            self.cf = ConfigParser.ConfigParser()
            self.cf.read(self.path)
    except Exception, e:
        utils_2pc.logE('[endpoint_config_Parser] init endpoint_config_file object fail: %s' % e)
        utils_2pc.doExit(1)

    # get all sections
    def get_all_sections(self):
        return self.cf.sections()

    # get items
    def get_items(self, s):
        return self.cf.items(s)

    # get options
    def get_options(self, s):
        return self.cf.options(s)


# load the info from endpoint conf file to memory
def load_config(file_path):
    global g_endpoint_info
    cp = endpoint_config_Parser(file_path)
    try:
        section_list = cp.get_all_sections()
        for section in section_list:
            item = dict(cp.get_items(section))
            # add all the endpoint info data to g_endpoint_info list
            g_endpoint_info.append(item)
    except Exception, e:
        utils_2pc.logE('[load_config] load endpoint config info fail: %s' % e)
        utils_2pc.doExit(1)

    utils_2pc.logD('[load_config] load endpoint config info success.')


# sync endpoint config info to all endpoints
def sync_config_info():
    global g_syncService_endpoint

    # get syncService endpoint
    g_syncService_endpoint = utils_2pc.get_endpoint()
    utils_2pc.logD('[sync_config_info] get syncService endpoint: %s' % g_syncService_endpoint)

    listKeySType = [True, True, False, True, False]
    listKeys = ['endpoint_id','ip','port','queue_type','weight']

    utils_2pc.logD('[sync_config_info] before format to sqlValue, the endpoint_info is: %s' % g_endpoint_info)

    # convert endpoint config info to sql value
    bRet, strSql = utils_2pc.formatSqlValue(g_endpoint_info, listKeySType, listKeys)

    utils_2pc.logD('[sync_config_info] after format to sqlValue, the endpoint_info is: %s' % strSql)

    http_body = strSql

    # sync endpoint config info to all endpoints one by one
    if bRet is True:
        endpoint_list = g_endpoint_info[:]
        for endpoint in endpoint_list:
            ip = endpoint['ip']
            port = endpoint['port']
            utils_2pc.logD('[sync_config_info] sync config info [%s] to endpoint [%s].' % (strSql, ip+':'+port))
            endpoint_info = 'http://' + ip + ':' + port
            http_url = endpoint_info + g_sync_config_url + '?syncService_id=' + g_syncService_endpoint
            http_method = 'POST'

            utils_2pc.logD('[sync_config_info] http url is: %s, body is: %s' % (http_url, http_body))

            http_code, api_return_code, api_return_str = utils_2pc.http_handler(http_method,http_url,http_body)

            if http_code != 200 or api_return_code != 200:
                # if sync data to one endpoint fail, remove this endpoint from the g_endpoint_info list
                # means do not sync queue data from this endpoint
                utils_2pc.logE('[sync_config_info] sync config info to [%s] fail, http return msg: %s, remove this endpoint.' % (ip, api_return_str))
                g_endpoint_info.remove(endpoint)
            else:
                utils_2pc.logD('[sync_config_info] sync config info to [%s] success, http return msg: %s' % (ip,api_return_str))
    else:
        utils_2pc.doExit(1)


# get last synced queue id from all the same queue type dst endpoint
def get_last_synced_id(source_endpoint_info,dst_queue_type,dst_queue_step,dst_endpoint_info):
    http_method = 'GET'
    last_sync_id = None

    http_url = dst_endpoint_info + '/msg_management/' + dst_queue_type + '/last_synced_id?dst_queue_step=' + str(dst_queue_step) + \
               '&endpoint_info=' + source_endpoint_info
    utils_2pc.logD('[get_last_synced_id] http url is: %s' % http_url)
    http_code, api_return_code, api_return_str = utils_2pc.http_handler(http_method, http_url, '')

    if http_code != 200 or api_return_code != 200:
        utils_2pc.logE('[get_last_synced_id] get last synced id from [%s] fail, http return msg: %s' % (dst_endpoint_info, api_return_str))
    else:
        utils_2pc.logD('[get_last_synced_id] get last synced id from [%s] success, http return msg: %s' % (dst_endpoint_info, api_return_str))
        last_sync_id = api_return_str['data'][0]['last_synced_id']
        utils_2pc.logD('[get_last_synced_id] the last synced id get from [%s] is: %d' % (dst_endpoint_info, last_sync_id))
    
    return last_sync_id


# get all the endpoint weight info from previous endpoint
def get_endpoint_weight(endpoint_info):
    http_method = 'GET'
    weight_info = ''

    http_url = endpoint_info + g_get_weight_url + '?syncService_id=' + g_syncService_endpoint
    utils_2pc.logD('[get_endpoint_weight] http url is: %s' % http_url)

    http_code, api_return_code, api_return_str = utils_2pc.http_handler(http_method, http_url, '')
    if http_code != 200 or api_return_code != 200:
        utils_2pc.logE('[get_endpoint_weight] get endpoint weight info from [%s] fail, http return msg: %s' % (endpoint_info,api_return_str))
    else:
        utils_2pc.logD('[get_endpoint_weight] get endpoint weight info from [%s] success, http return msg: %s' % (endpoint_info,api_return_str))
        try:
            weight_info = api_return_str["data"][0]["cur_weight_after_selected"]
        except Exception, e:
            utils_2pc.logE('[get_endpoint_weight] extract weight info fail, exception info is: [%s]' % e)
            return ''

    return weight_info


# get unsynced queue data from one endpoint
def get_unsynced_queue_info(endpoint_info,syncservice_id,last_receive_info,weight_info):
    http_method = 'GET'
    api_return_dataSet = ''

    http_url = endpoint_info + g_get_unsynced_data_url + '?syncService_id=' + syncservice_id
    if last_receive_info != '':
        http_url = http_url + '&last_receive_info=' + last_receive_info
    http_url = http_url + '&cur_weight_after_selected=' + weight_info

    utils_2pc.logD('[get_unsynced_queue_info] http url is: %s' % http_url)

    http_code, api_return_code, api_return_str = utils_2pc.http_handler(http_method, http_url, '')

    if http_code != 200 or api_return_code != 200:
        utils_2pc.logE('[get_unsynced_queue_info] get unsynced queue data from [%s] fail, http return msg: %s' % (endpoint_info,api_return_str))
    else:
        utils_2pc.logD('[get_unsynced_queue_info] get unsynced queue data from [%s] success, http return msg: %s' % (endpoint_info,api_return_str))
        api_return_dataSet = api_return_str['data']

    return http_code, api_return_code, api_return_dataSet


# insert queue message data (double queue)
def insert_queue_data(dst_http_uri,dst_endpoint_info, http_method, dst_queue_step, body, double_side):
    if double_side is 1:
        http_url = dst_http_uri + '?dst_endpoint_info=' + ('' if dst_endpoint_info is None else dst_endpoint_info) + \
               '&dst_queue_step=' + ('' if dst_queue_step is None else str(dst_queue_step))
    else:
        http_url = dst_http_uri

    utils_2pc.logD('[insert_queue_data] http url is: %s, body is: %s' % (http_url,body))

    http_code, api_return_code, api_return_str = utils_2pc.http_handler(http_method, http_url, body)

    if http_code != 200 or api_return_code != 200:
        utils_2pc.logE('[insert_queue_data] insert queue message data fail, http return msg: %s' % api_return_str)
    else:
        utils_2pc.logD('[insert_queue_data] insert queue message data success, http return msg: %s' % api_return_str)

    return http_code, api_return_code, api_return_str


# update queue status after sync data
def update_queue_status(endpoint_info,source_queue_type,dst_queue_type,dst_endpoint_info,body):
    http_method = 'PUT'
    http_url = endpoint_info + '/msg_management/' + source_queue_type + '/data?dst_queue_type=' + \
               ('' if dst_queue_type is None else dst_queue_type) + \
               '&dst_endpoint_info=' + ('' if dst_endpoint_info is None else dst_endpoint_info)

    utils_2pc.logD('[update_queue_status] http url is: %s, body is: %s' % (http_url, body))

    http_code, api_return_code, api_return_str = utils_2pc.http_handler(http_method, http_url, body)

    if http_code != 200 or api_return_code != 200:
        utils_2pc.logE('[update_queue_status] update queue status in [%s] fail, http return msg: %s' % (endpoint_info, api_return_str))
    else:
        utils_2pc.logD('[update_queue_status] update queue status in [%s] success, http return msg: %s' % (endpoint_info, api_return_str))

    return http_code, api_return_code


# check queue data is valid or not
def check_queue_valid(msgs,current_queue_id_list):
    # get queue id list from queue data
    try:
        msg_tuple = eval(msgs + ',')
        queue_id_list = ','.join([str(msg_tuple[x][0]) for x in range(len(msg_tuple))])

        utils_2pc.logD('[check_queue_valid] current_queue_id_list is: %s, queue_id_list in msgs is: %s' % (current_queue_id_list, queue_id_list))

        if current_queue_id_list == queue_id_list:
            return True
        else:
            return False
    except Exception, e:
        utils_2pc.logE('[check_queue_valid] check queue valid fail, exception info is: [%s], queue_info is: [%s]' % (e,queue_info))
        return False


# sync queue data from one endpoint to another endpoint
def sync_queue(endpoint,weight_info):
    # source endpoint ip, port, endpint_id
    ip = endpoint['ip']
    port = endpoint['port']
    endpoint_info = 'http://' + ip + ':' + port

    # get unsynced queue data from endpoint
    http_code, api_return_code, api_return_dataSet = get_unsynced_queue_info(endpoint_info,g_syncService_endpoint,'',weight_info)
    if http_code == 200 and api_return_code == 200:
        utils_2pc.logD('[sync_queue] get unsynced queue data from endpoint [%s] success.' % ip)

        # handle queue data sync one by one
        for queue_info in api_return_dataSet:
            err_flag = 0
            queue_body = ''
            check_retry_idx = 0
            last_receive_info = ''
            queue_list_chk = True
            last_queue_id_chk = True

            while check_retry_idx <= g_check_retry_cnt:
                # get unsynced queue data from endpoint when check queue list or last synced id fail
                if check_retry_idx > 0 or queue_list_chk == False or last_queue_id_chk == False:
                    utils_2pc.logD('[sync_queue] retry check queue data valid [%d]rd...' % check_retry_idx)
                    http_code, api_return_code, api_return_dataSet = get_unsynced_queue_info(endpoint_info, g_syncService_endpoint, last_receive_info, weight_info)
                    if http_code == 200 and api_return_code == 200:
                        utils_2pc.logD('[sync_queue] get unsynced queue data with last_receive_info [%s] from endpoint [%s] success.' % (last_receive_info, ip))
                        queue_info = api_return_dataSet[0]
                    else:
                        utils_2pc.logE('[sync_queue] get unsynced queue data with last_receive_info [%s] from endpoint [%s] fail.' % (last_receive_info, ip))
                        err_flag = 1
                        break

                # extract values from queue_info
                utils_2pc.logD('[sync_queue] extract values from queue_info: [%s]' % queue_info)
                try:
                    queue_http_uri = queue_info['uri']
                    http_method = queue_info['method']
                    http_body = queue_info['msgs']
                    current_queue_id_list = queue_info['current_check_list']
                    last_synced_id = queue_info['last_synced_id']
                    double_side = queue_info['double_side']
                    source_queue_type = queue_info['source_queue_type']
                    dst_queue_type = queue_info['dst_queue_type']
                    dst_queue_step = queue_info['dst_queue_step']
                    dst_endpoint_info = queue_info['dst_endpoint_info']
                except Exception, e:
                    utils_2pc.logE('[sync_queue] extract values from queue_info fail, exception info: [%s], queue_info: [%s], skip sync this queue data.' % (e,queue_info))
                    err_flag = 1
                    break
                
                # last_receive_info data
                last_receive_info = '(' + str(last_synced_id) + ',"' + source_queue_type + '","' + dst_endpoint_info + '","' + dst_queue_type + '")'

                # check queue data valid
                queue_list_chk = check_queue_valid(http_body,current_queue_id_list)
                if queue_list_chk is True:
                    utils_2pc.logD('[sync_queue] check queue data valid success, queue_info: [%s].' % queue_info)
                    if last_queue_id_chk is True:
                        check_retry_idx = 0
                else:
                    utils_2pc.logE('[sync_queue] check queue data valid fail, queue_info: [%s].' % queue_info)
                    if last_queue_id_chk is False:
                        check_retry_idx = 0
                        last_queue_id_chk = True
                    else:
                        check_retry_idx += 1
                    continue

                # handle single queue situation
                if double_side is 0:
                    utils_2pc.logD('[sync_queue] single side queue, queue_info is: [%s]' % queue_info)
                    queue_id_map = {}
                    body_list = []
                    msgs = eval(http_body + ',')
                    for msg_info in msgs:
                        queue_id = str(msg_info[0])
                        msg = msg_info[1]
                        q_info = msg.split('|$|')
                        real_id = q_info[0]
                        if real_id in queue_id_map:
                            queue_id_map[real_id] = queue_id_map[real_id] + ',' + queue_id
                        else:
                            queue_id_map[real_id] = queue_id
                        q_info_format = ['"' + q_info[x] + '"' for x in range(1,len(q_info))]
                        q_value = '(' + real_id + ',' + ','.join(q_info_format) + ')'
                        body_list.append(q_value)

                    http_body = ','.join(body_list)
                    break
                else:
                    utils_2pc.logD('[sync_queue] double side queue, queue_info is: [%s]' % queue_info)
                    # get last synced queue id from destination endpoint to check if last synced id is valid
                    dst_last_synced_id = get_last_synced_id(endpoint_info, dst_queue_type, dst_queue_step, dst_endpoint_info)
                    if dst_last_synced_id is not None and last_synced_id <= dst_last_synced_id:
                        utils_2pc.logD('[sync_queue] compare last synced queue id success, source last synced id: %d, destination last sync id: %s' % (last_synced_id, dst_last_synced_id))
                        last_queue_id_chk = True
                        break
                    else:
                        utils_2pc.logE('[sync_queue] compare last synced queue id fail, source last synced id: %d, destination last sync id: %s' % (last_synced_id, dst_last_synced_id))
                        last_queue_id_chk = False
                        check_retry_idx += 1
                        continue

            # confirm the check result, if check result is false, stop current loop, begin next loop
            if queue_list_chk is False or last_queue_id_chk is False:
                utils_2pc.logE('[sync_queue] queue info check fail, queue_info is: [%s]' % queue_info)
                continue
            
            # stop current loop, begin next loop
            if err_flag == 1:
                continue

            # post queue data to destination endpoint
            dst_http_uri = dst_endpoint_info + queue_http_uri
            http_code, api_return_code, api_return_dataSet = insert_queue_data(dst_http_uri, endpoint_info, http_method, dst_queue_step, http_body, double_side)

            if http_code == 200 and api_return_code == 200:
                utils_2pc.logD('[sync_queue] insert queue list [%s] to [%s] success.' % (current_queue_id_list, dst_endpoint_info))

                if double_side is 0:
                    if len(api_return_dataSet['data']) == 1:
                        success_handled_tids = api_return_dataSet['data'][0]['success_handled_tids'].split(',')
                        fail_handled_tids = api_return_dataSet['data'][0]['fail_handled_tids'].split(',')
                    else:
                        success_handled_tids = api_return_dataSet['moreResults'][0][0]['success_handled_tids'].split(',')
                        fail_handled_tids = api_return_dataSet['moreResults'][0][0]['fail_handled_tids'].split(',')

                    success_queue_ids_list = [] if success_handled_tids == [''] else [queue_id_map[rid] for rid in success_handled_tids]
                    fail_queue_ids_list = [] if fail_handled_tids == [''] else [queue_id_map[rid] for rid in fail_handled_tids]
                else:
                    success_queue_ids_list = current_queue_id_list.split(',')
 
                if len(success_queue_ids_list):
                    queue_success_body = ',0),('.join(success_queue_ids_list)
                    queue_success_body = '(' + queue_success_body + ',0)'
                    queue_body = queue_success_body

                if len(fail_queue_ids_list):
                    queue_fail_body = ',1),('.join(fail_queue_ids_list)
                    queue_fail_body = '(' + queue_fail_body + ',1)'
                    queue_body = queue_body + ',' + queue_fail_body

                # queue_body format: (queue_id,status),(queue_id,status),(queue_id,status)
                # queue_body example: (1,0),(2,0),(3,0),(4,1),(5,1)
                # status in queue_body: 0 is success, 1 is fail
                # update queue id (current_queue_id_list) status
                http_code, api_return_code = update_queue_status(endpoint_info, source_queue_type, dst_queue_type, dst_endpoint_info, queue_body)

                if http_code == 200 and api_return_code == 200:
                    utils_2pc.logD('[sync_queue] update queue list [%s] status to [%s] success.' % (current_queue_id_list, ip))
                else:
                    utils_2pc.logE('[sync_queue] update queue list [%s] status to [%s] fail.' % (current_queue_id_list, ip))

            else:
                utils_2pc.logE('[sync_queue] insert queue list [%s] to [%s] fail, skip sync this queue data.' % (current_queue_id_list,dst_endpoint_info))

    else:
        utils_2pc.logE('[sync_queue] sync queue data from endpoint [%s] fail, skip sync this endpoint data.' % ip)


def main():
    global g_endpoint_len
    weight_info = ''

    reload(sys)
    sys.setdefaultencoding('utf8')

    # parse command parameter options
    parseOptions()

    # init log handler
    utils_2pc.doLogInit(g_log_level, g_log_file)

    # load endpoint config info from config file
    utils_2pc.logI('[load_config] config file: %s' % g_config_file)
    if os.path.exists(g_config_file):
        load_config(g_config_file)
    else:
        utils_2pc.logE('[load_config] config file [%s] not exists.' % g_config_file)
        utils_2pc.doExit(1)

    # sync endpoint config info to all the endpoint in config file
    utils_2pc.logI('[sync_config_info]')
    sync_config_info()

    # handle endpoint one by one
    g_endpoint_len = len(g_endpoint_info)
    if g_endpoint_len == 0:
        utils_2pc.logW('[handle endpoint] there is no endpoint to handle.')
    else:
        while True:
            for i,endpoint in enumerate(g_endpoint_info):
                utils_2pc.logI('[handle endpoint] endpoint info: %s' % endpoint)

                # get endpoint weight info from previous endpoint
                idx = 0
                previous_idx = i
                while idx < g_endpoint_len:
                    previous_ip = g_endpoint_info[previous_idx - 1]['ip']
                    previous_port = g_endpoint_info[previous_idx - 1]['port']
                    previous_endpoint_info = 'http://' + previous_ip + ':' + previous_port

                    weight_info = get_endpoint_weight(previous_endpoint_info)
                    if weight_info != '':
                        break
                    else:
                        previous_idx -= 1

                    idx += 1

                if weight_info != '':
                    sync_queue(endpoint,weight_info)
                else:
                    break
            
            # sleep 5 seconds then do next round
            time.sleep(5)


if '__main__' == __name__:
    main()
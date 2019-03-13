#!/usr/bin/env python
# -*- coding: utf8 -*-


import sys
import getopt
import ConfigParser
import os
import utils_2pc
import json
import time
import re

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
            check_retry_idx = 1

            ip = endpoint['ip']
            port = endpoint['port']
            utils_2pc.logD('[sync_config_info] sync config info [%s] to endpoint [%s].' % (strSql, ip+':'+port))
            endpoint_info = 'http://' + ip + ':' + port
            http_url = endpoint_info + g_sync_config_url + '?syncService_id=' + g_syncService_endpoint
            http_method = 'POST'
            utils_2pc.logI('[get_last_synced_id] http url is: %s,method: %s' % (http_url,http_method))
            utils_2pc.logD('[sync_config_info] body is: %s' % ( http_body))

            while check_retry_idx <= g_check_retry_cnt:
                check_retry_idx = check_retry_idx + 1

                http_code, api_return_code, api_return_str = utils_2pc.http_handler(http_method,http_url,http_body)
                if http_code != 200 or api_return_code != 200:
                    utils_2pc.logE('[sync_config_info] sync config info to [%s] fail, http return msg: %s,check_retry_idx:%s.' % (ip, api_return_str,check_retry_idx))
                    time.sleep(5)
                else:
                    utils_2pc.logD('[sync_config_info] sync config info to [%s] success, http return msg: %s' % (ip,api_return_str))
                    break

            #if sync the config error ,then remove the endpoint
            if check_retry_idx > g_check_retry_cnt:
                utils_2pc.logE('[sync_config_info] sync config info to [%s] ver the maximum number of cycles,so remove the endpoint.' % (ip))
                g_endpoint_info.remove(endpoint)

    else:
        utils_2pc.doExit(1)


# get last synced queue id from all the same queue type dst endpoint
def get_last_synced_id(source_endpoint_info,dst_queue_type,dst_queue_step,dst_endpoint_info):
    try:
        http_method = 'GET'
        last_sync_id = None

        http_url = dst_endpoint_info + '/msg_management/' + dst_queue_type + '/last_synced_id?dst_queue_step=' + str(dst_queue_step) + '&endpoint_info=' + source_endpoint_info
        utils_2pc.logI('[get_last_synced_id] http url is: %s,method: %s' % (http_url,http_method))

        http_code, api_return_code, api_return_str = utils_2pc.http_handler(http_method, http_url, '')
        if http_code != 200 or api_return_code != 200:
            utils_2pc.logE('[get_last_synced_id] get last synced id from fail,api_return_code: %s,http_code : %s, http return msg: %s' % (http_code, api_return_code, api_return_str))
        else:
            utils_2pc.logD('[get_last_synced_id] get last synced id from success,api_return_code: %s,http_code : %s, http return msg: %s' % (http_code, api_return_code, api_return_str))
            last_sync_id = api_return_str['data'][0]['last_synced_id']
        
        return last_sync_id
    except Exception, e:
        utils_2pc.logE('[get_last_synced_id] get last synced queue fail,exception msg: %s' % (e))
        return None


# get all the endpoint weight info from previous endpoint
def get_endpoint_weight(endpoint_info):
    http_method = 'GET'
    weight_info = ''

    http_url = endpoint_info + g_get_weight_url + '?syncService_id=' + g_syncService_endpoint
    utils_2pc.logI('[get_endpoint_weight] http url is: %s,method: %s' % (http_url,http_method))

    http_code, api_return_code, api_return_str = utils_2pc.http_handler(http_method, http_url, '')
    if http_code != 200 or api_return_code != 200:
        utils_2pc.logE('[get_endpoint_weight] get endpoint weight info from [%s] fail, http return msg: %s' % (endpoint_info,api_return_str))
    else:
        utils_2pc.logD('[get_endpoint_weight] get endpoint weight info from [%s] success, http return msg: %s' % (endpoint_info,api_return_str))
        try:
            weight_info = api_return_str["data"][0]["cur_weight_after_selected"]
        except Exception, e:
            utils_2pc.logE('[get_endpoint_weight] extract weight info fail, exception info is: [%s],endpoint_info is: %s' % (e,endpoint_info))
            return ''

    return weight_info


# get unsynced queue data from one endpoint
def get_unsynced_queue_info(endpoint_info,syncservice_id,last_receive_info,weight_info):
    try:
        http_method = 'GET'
        api_return_dataSet = ''

        http_url = endpoint_info + g_get_unsynced_data_url + '?syncService_id=' + syncservice_id
        utils_2pc.logI('[get_unsynced_queue_info] http url is: %s,method: %s' % (http_url,http_method))

        if last_receive_info != '' or last_receive_info != None:
            http_url = http_url + '&last_receive_info=' + last_receive_info
        http_url = http_url + '&cur_weight_after_selected=' + weight_info

        utils_2pc.logI('[get_unsynced_queue_info] http url is: %s,method: %s' % (http_url,http_method))

        http_code, api_return_code, api_return_str = utils_2pc.http_handler(http_method, http_url, '')
        if http_code != 200 or api_return_code != 200:
            utils_2pc.logE('[get_unsynced_queue_info] get unsynced queue data from [%s] fail,syncservice_id : %s, http return msg: %s,last_receive_info: %s,weight_info : %s' % (endpoint_info,syncservice_id,api_return_str,last_receive_info,weight_info))
        else:
            utils_2pc.logD('[get_unsynced_queue_info] get unsynced queue data from [%s] success,syncservice_id : %s, last_receive_info: %s,weight_info : %s' % (endpoint_info,syncservice_id,last_receive_info,weight_info))
            utils_2pc.logD('[get_unsynced_queue_info] http return msg is: %s' % api_return_str)
            api_return_dataSet = api_return_str['data']

        return http_code, api_return_code, api_return_dataSet

    except Exception, e:
        utils_2pc.logE('[get_unsynced_queue_info] get unsynced queue data fail: %s,endpoint_info: %s,syncservice_id : %s,last_receive_info: %s,weight_info : %s' % (e,endpoint_info,syncservice_id,last_receive_info,weight_info))
        return 200,400,e        

# insert queue message data (double queue)
def insert_queue_data(dst_http_uri,dst_endpoint_info, http_method, dst_queue_step, body, double_side):
    try:
        if double_side is 1:
            http_url = dst_http_uri + 'dst_endpoint_info=' + ('' if dst_endpoint_info is None else dst_endpoint_info) + '&dst_queue_step=' + ('' if dst_queue_step is None else str(dst_queue_step))
        else:
            http_url = dst_http_uri
        utils_2pc.logI('[insert_queue_data] http url is: %s,method: %s' % (http_url,http_method))
        utils_2pc.logD('[insert_queue_data] body is: %s' % (body))

        http_code, api_return_code, api_return_str = utils_2pc.http_handler(http_method, http_url, body)
        if http_code != 200 or api_return_code != 200:
            utils_2pc.logE('[insert_queue_data] insert queue message data fail,error msg: %s,dst_http_uri: %s,dst_endpoint_info: %s,http_method: %s,dst_queue_step: %s,double_side: %s' % (api_return_str,dst_http_uri,dst_endpoint_info, http_method, dst_queue_step, double_side))
        else:
            utils_2pc.logD('[insert_queue_data] insert queue message data success, http return msg: %s' % api_return_str)

        return http_code, api_return_code, api_return_str
    except Exception, e:
        utils_2pc.logE('[insert_queue_data] insert_queue_data unexpected fail: %s,dst_http_uri: %s,dst_endpoint_info: %s,http_method: %s,dst_queue_step: %s,double_side: %s' % (e,dst_http_uri,dst_endpoint_info, http_method, dst_queue_step, double_side))
        return 200,400,None

# update queue status after sync data
def update_queue_status(endpoint_info,source_queue_type,dst_queue_type,dst_endpoint_info,body):
    try:
        http_method = 'PUT'
        http_url = endpoint_info + '/msg_management/' + source_queue_type + '/data?dst_queue_type=' + ('' if dst_queue_type is None else dst_queue_type) + '&dst_endpoint_info=' + ('' if dst_endpoint_info is None else dst_endpoint_info)
        utils_2pc.logI('[update_queue_status] http url is: %s,method: %s' % (http_url,http_method))

        http_code, api_return_code, api_return_str = utils_2pc.http_handler(http_method, http_url, body)
        if http_code != 200 or api_return_code != 200:
            utils_2pc.logE('[update_queue_status] update queue status fail,endpoint_info: %s,source_queue_type: %s,dst_queue_type: %s,dst_endpoint_info: %s, http return msg: %s' % (endpoint_info,source_queue_type,dst_queue_type,dst_endpoint_info, api_return_str))
        else:
            utils_2pc.logD('[update_queue_status] update queue status success,endpoint_info: %s,source_queue_type: %s,dst_queue_type: %s,dst_endpoint_info: %s, http return msg: %s' % (endpoint_info,source_queue_type,dst_queue_type,dst_endpoint_info, api_return_str))

        return http_code, api_return_code
    except Exception, e:
        utils_2pc.logE('[update_queue_status] update_queue_status unexpected fail: %s,endpoint_info: %s,source_queue_type: %s,dst_queue_type: %s,dst_endpoint_info: %s' % (e,endpoint_info,source_queue_type,dst_queue_type,dst_endpoint_info))
        return 200,None

# check current_queue_ids is valid or not
def check_current_queue_ids_valid(msgs,current_queue_ids):
    # get queue id list from queue data
    try:
        msg_tuple = eval(msgs + ',')
        queue_ids = ','.join([str(msg_tuple[x][0]) for x in range(len(msg_tuple))])

        utils_2pc.logD('[check_current_queue_ids_valid] current_queue_ids is: %s, queue_ids in msgs is: %s' % (current_queue_ids, queue_ids))

        if current_queue_ids == queue_ids:
            return True
        else:
            return False
    except Exception, e:
        utils_2pc.logE('[check_current_queue_ids_valid] check queue valid fail, exception info is: %s,current_queue_ids: %s,msgs: %s' % (e,current_queue_ids,msgs))
        return False


# handle detail queue_info 
def handle_queue_detail(endpoint_info,queue_info):
    try:
        queue_body = ''
        last_receive_info = ''
        queue_ids_chk = True
        
        # extract values from queue_info
        utils_2pc.logD('[handle_queue_detail] extract values from queue_info: [%s]' % queue_info)
        queue_http_uri = queue_info['uri']
        http_method = queue_info['method']
        http_body = queue_info['msgs']
        current_queue_ids = str(queue_info['current_check_list'])
        last_synced_id = queue_info['last_sync_queue_id']
        double_side = queue_info['double_side']
        source_queue_type = queue_info['source_queue_type']
        dst_queue_type = queue_info['dst_queue_type']
        dst_queue_step = queue_info['dst_queue_step']
        dst_endpoint_info = queue_info['dst_endpoint_info']

        # check current_queue_ids data valid
        queue_ids_chk = check_current_queue_ids_valid(http_body,current_queue_ids)
        if queue_ids_chk is False:
            utils_2pc.logE('[handle_queue_detail] check queue data detail fail, http_body: %s,current_queue_ids: %s.' % (http_body,current_queue_ids))
            last_receive_info = '(' + str(last_synced_id) + ',"' + source_queue_type + '","' + dst_endpoint_info + '","' + dst_queue_type + '")'
            return 651,'fail to check the current_queue_ids',''
        
        # handle double side queue last_handle_queue_detail_id
        if double_side == 1:
            utils_2pc.logD('[handle_queue_detail] double side queue, queue_info is: [%s]' % queue_info)
            # get last synced queue id from destination endpoint to check if last synced id is valid
            dst_last_synced_id = get_last_synced_id(endpoint_info, dst_queue_type, dst_queue_step, dst_endpoint_info)
            if dst_last_synced_id is None:
                utils_2pc.logE('[handle_queue_detail] get last synced queue id fail, source last synced id: %d, destination last sync id: %s' % (last_synced_id, dst_last_synced_id))
                return 652,'fail to get last synced queue id',''     
            elif last_synced_id > dst_last_synced_id:
                utils_2pc.logE('[handle_queue_detail] compare last synced queue id fail, source last synced id: %d, destination last sync id: %s' % (last_synced_id, dst_last_synced_id))
                last_receive_info = '(' + str(dst_last_synced_id) + ',"' + source_queue_type + '","' + dst_endpoint_info + '","' + dst_queue_type + '")'
                return 653,'fail to check last sync queue id',last_receive_info

        #handle one side body
        if double_side == 0:
            tuple_body = eval(http_body+',')
            http_body = ','.join([str(tuple_body[x][2]) for x in range(len(tuple_body))])
        
        # post queue data to destination endpoint
        dst_http_uri = dst_endpoint_info + queue_http_uri
        http_code, api_return_code, api_return_dataSet = insert_queue_data(dst_http_uri, endpoint_info, http_method, dst_queue_step, http_body, double_side)

        #get the success or fail queues in api_return_dataSet&current_queue_ids
        if http_code == 200 and api_return_code == 200:
            if re.search('success_handled_ids', str(api_return_dataSet['data'])) is not None:
                success_handled_list = api_return_dataSet['data'][0]['success_handled_ids'].split(',')
                fail_handled_list = api_return_dataSet['data'][0]['fail_handled_ids'].split(',')
                utils_2pc.logD('[handle_queue_detail] success_queues_ids: %s ,fail_queue_ids: %s.' % (success_handled_list,fail_handled_list))  
            elif re.search('success_handled_ids', str(api_return_dataSet['moreResults'])) is not None:    
                success_handled_list = api_return_dataSet['moreResults'][0][0]['success_handled_ids'].split(',')
                fail_handled_list = api_return_dataSet['moreResults'][0][0]['fail_handled_ids'].split(',')
                utils_2pc.logD('[handle_queue_detail] success_queues_ids: %s ,fail_queue_ids: %s.' % (success_handled_list,fail_handled_list))  
            else:
                success_handled_list = current_queue_ids.split(',')
                fail_handled_list = []
                utils_2pc.logD('[handle_queue_detail] success_queues_ids: %s ,fail_queue_ids: %s.' % (success_handled_list,fail_handled_list))  
        else:      
            success_handled_list = []
            fail_handled_list = current_queue_ids.split(',')
            utils_2pc.logE('[handle_queue_detail] success_queues_ids: %s ,fail_queue_ids: %s,http_msg: %s,http_code: %s.' % (success_handled_list,fail_handled_list,api_return_dataSet,http_code))  
            utils_2pc.logE('[handle_queue_detail] body detail: %s.' % (http_body))  
        
        if len(success_handled_list):
            queue_success_body = ',0),('.join(success_handled_list)
            queue_success_body = '(' + queue_success_body + ',0)'
            queue_body = queue_success_body
        if len(fail_handled_list):
            queue_fail_body = ',1),('.join(fail_handled_list)
            queue_fail_body = '(' + queue_fail_body + ',1)'
            queue_body = queue_body + ',' + queue_fail_body

        queue_body =  queue_body.strip(',')

        # update queue status
        # queue_body format: (queue_id,status),(queue_id,status),(queue_id,status)
        # queue_body example: (1,0),(2,0),(3,0),(4,1),(5,1)
        # status in queue_body: 0 is success, 1 is fail
        http_code, api_return_code = update_queue_status(endpoint_info, source_queue_type, dst_queue_type, dst_endpoint_info, queue_body)
        if http_code == 200 and api_return_code == 200:
            utils_2pc.logD('[handle_queue_detail] update queue list [%s] status to [%s] success.' % (current_queue_ids, endpoint_info))
        else:
            utils_2pc.logE('[handle_queue_detail] update queue info,endpoint_info: %s,source_queue_type: %s,dst_queue_type: %s,dst_endpoint_info: %s,queue_body: %s.' % (endpoint_info, source_queue_type, dst_queue_type, dst_endpoint_info, queue_body))
    
        return 200,'OK',last_receive_info

    except Exception, e:
        return 400,e,''


# sync queue data from one endpoint to another endpoint
def sync_queue(endpoint,weight_info):
    # source endpoint ip, port, endpint_id
    ip = endpoint['ip']
    port = endpoint['port']
    endpoint_info = 'http://' + ip + ':' + port
    final_last_receive_info = ''
    check_retry_idx = 0

    # get unsynced queue data from endpoint,last_receive_info is null
    utils_2pc.logI('[sync_queue] begin get unsynced queue. endpoint_info: %s, g_syncService_endpoint: %s,weight_info: %s.' % (endpoint_info,g_syncService_endpoint,weight_info))
    http_code, api_return_code, api_return_dataSet = get_unsynced_queue_info(endpoint_info,g_syncService_endpoint,'',weight_info) 
    if http_code == 200 and api_return_code == 200:
        utils_2pc.logD('[sync_queue] get unsynced queue data success. http_code: %s, api_return_code: %s,api_return_dataSet: %s.' % (http_code, api_return_code, api_return_dataSet))
        for queue_info in api_return_dataSet:
            utils_2pc.logI('[sync_queue] begin handle  queue details.')
            code ,msg,last_receive_info = handle_queue_detail(endpoint_info,queue_info)
            if code == 200:
                utils_2pc.logD('[sync_queue] handle queue detail success. code: %s, msg: %s,last_receive_info: %s,queue_info: %s.' % (code ,msg,last_receive_info,queue_info))
            else:
                utils_2pc.logE('[sync_queue] handle queue detail fail.code: %s, msg: %s,last_receive_info: %s.' % (code ,msg,last_receive_info))
                utils_2pc.logD('[sync_queue] handle queue detail fail.queue_info: %s.' % (queue_info))

            if last_receive_info is not None and last_receive_info != '':
                utils_2pc.logD('[sync_queue] handle last_receive_info. last_receive_info: %s.' % (last_receive_info))
                final_last_receive_info = last_receive_info + ',' + final_last_receive_info

        #get last_receive_info data 
        while check_retry_idx <= g_check_retry_cnt and final_last_receive_info != '': 
            final_last_receive_info = final_last_receive_info.strip(',')
            check_retry_idx = check_retry_idx + 1        
            utils_2pc.logI('[sync_queue] begin get unsynced queue with final_last_receive_info. endpoint_info: %s, g_syncService_endpoint: %s,weight_info: %s,final_last_receive_info: %s.' % (endpoint_info,g_syncService_endpoint,weight_info,final_last_receive_info))
            http_code, api_return_code, api_return_dataSet = get_unsynced_queue_info(endpoint_info,g_syncService_endpoint,final_last_receive_info,weight_info)      
            final_last_receive_info = ''
            if http_code == 200 and api_return_code == 200:
                utils_2pc.logD('[sync_queue] get unsynced queue data success. http_code: %s, api_return_code: %s,api_return_dataSet: %s.' % (http_code, api_return_code, api_return_dataSet))
                for queue_info in api_return_dataSet:
                    utils_2pc.logI('[sync_queue] begin handle queue details with final_last_receive_info.')
                    code ,msg,last_receive_info = handle_queue_detail(endpoint_info,queue_info)
                    if code == 200: 
                        utils_2pc.logD('[sync_queue] handle queue detail success. code: %s, msg: %s,last_receive_info: %s,queue_info: %s.' % (code ,msg,last_receive_info,queue_info))
                    else:
                        utils_2pc.logE('[sync_queue] handle queue detail fail.code: %s, msg: %s,last_receive_info: %s,check_retry_idx: %s.' % (code ,msg,last_receive_info,check_retry_idx))
                        utils_2pc.logD('[sync_queue] handle queue detail fail.queue_info: %s.' % (queue_info)) 
                    if last_receive_info is not None and last_receive_info != '':
                        utils_2pc.logD('[sync_queue] handle last_receive_info. last_receive_info: %s.' % (last_receive_info))
                        final_last_receive_info = last_receive_info + ',' + final_last_receive_info    
            else:
                utils_2pc.logE('[sync_queue] get unsynced queue data fail with final_last_receive_info.http_code: %s,api_return_code: %s,api_return_dataSet: %s.' % (http_code, api_return_code, api_return_dataSet)) 
    else:
        utils_2pc.logE('[sync_queue] get unsynced queue data fail. http_code: %s,api_return_code: %s,api_return_dataSet: %s.' % (http_code, api_return_code, api_return_dataSet))


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
                        sync_queue(endpoint,weight_info)
                        break
                    else:
                        previous_idx -= 1

                    idx += 1
                '''
                if weight_info != '':
                    sync_queue(endpoint,weight_info)
                else:
                    break
                '''    
            
            # sleep 5 seconds then do next round
            time.sleep(5)


if '__main__' == __name__:
    main()
#!/usr/bin/env python
# -*- coding: utf8 -*-

import restful_utility

import sys
import getopt
import ConfigParser
import os
import utils_packing
import json
import time
import re

def usage():
    print """Usage: packingService.py [option] [optionValue]
     Options:
      -l | --loglevel          is the loglevel for record log, for example: D
                               the loglevel info is: (D:Debug, I:Info, W:Warning, E:Error)
                               this option is optional, default value is W
      -p | --http_retrycnt     is http request retry count when http fail, for example: 5
                               this option is optional, default value is 0
      -k | --check_retrycnt    is queue data check retry count when queue check fail, for example: 1
                               this option is optional, default value is 0
      -t | --threadnum         is threads number for multithreading, for example: 5
                               this option is optional, default value is 1
      -f | --logfile           is logfile to record log msg based on loglevel, for example: /var/log/fbc/server/packingService.log
                               this option is MUST
      -c | --center_dns        is centerdb dns, for example: http://127.0.0.1:8080
                               this option is MUST
      -i | --packing_time_diff is the packing pending time   , for example: 10                    
      -h | --help              is help info"""

# parse command parameter options
def parseOptions():
    global g_log_level
    global g_log_file
    global g_http_retry_cnt
    global g_threadnum
    global g_packing_time_diff
    global g_center_dns

    g_log_level = 'W'
    g_log_file = ''
    g_http_retry_cnt = 0
    g_threadnum = 1
    g_packing_time_diff = 0
    g_center_dns = ''

    try:
        options,args = getopt.getopt(sys.argv[1:],"hl:f:c:p:t:i:",["help","packing_loglevel=","packing_logfile=","center_dns=","packing_http_retrycnt=","packing_threadnum=","packing_time_diff="])
    except getopt.GetoptError:
        usage()
        print '[parseOptions] parse command parameter options fail.'
        utils_2pc.doExit(1)

    # get option value
    for name,value in options:
        if name in ("-h","--help"):
            usage()
        if name in ("-l","--packing_loglevel"):
            g_log_level = value
        if name in ("-f","--packing_logfile"):
            g_log_file = value
        if name in ("-c","--center_dns"):
            g_center_dns = value
        if name in ("-p","--packing_http_retrycnt"):
            g_http_retry_cnt = int(value)
        if name in ("-t","--packing_threadnum"):
            g_threadnum = int(value)
        if name in ("-i","--packing_time_diff"):
            g_packing_time_diff = int(value)
    try:
        utils_packing.setHttpRequest_retryCnt(int(g_http_retry_cnt))
    except Exception, e:
        print '[parseOptions] set http request retry count fail: %s' % e
        utils_packing.doExit(1)

def sync_tx_cache_data(users_data,packingnode_ip):
    try:
        for user_info in users_data:
            accountAddress = user_info["accountAddress"]
            register_ip_address = user_info["register_ip_address"]
            
            # get accountAddress's current nonce from packing_node
            server_url = packingnode_ip + '/stateNonce?accountAddress=' + accountAddress
            utils_packing.logD('[sync_tx_cache_data] deal with url:%s'% (server_url))
            http_code, api_return_code, return_msg = restful_utility.restful_runner(server_url, 'GET', None, '')
            if http_code != 200 or api_return_code != 200:
                utils_packing.logE('[sync_tx_cache_data] fail to deal with url:%s'% (accountAddress,server_url))
                return api_return_code,return_msg
            current_account_nonce = int(return_msg["data"][0]["current_user_nonce"])
            utils_packing.logD('[sync_tx_cache_data] deal with url:%s,current_user_nonce:%s'% (server_url,current_account_nonce))

            # get user node tx_cache data
            server_url = 'http://'+register_ip_address + '/pendingTX/' + accountAddress + '?current_account_nonce=' + str(current_account_nonce) + '&time_diff=' + str(g_packing_time_diff)
            http_code, api_return_code, return_msg = restful_utility.restful_runner(server_url, 'GET', None, '')
            if http_code != 200 or api_return_code != 200:
                utils_packing.logE('[sync_tx_cache_data] fail to get tx_cache detail. url:%s'% (server_url))
                return api_return_code,return_msg

            # POST tx detail data to packing node tx_cache
            server_url = packingnode_ip + '/pendingTX/0'
            body = json.dumps(return_msg["data"][0])
            newaddStateObject = return_msg["data"][0]["newaddStateObject"]
            utils_packing.logD('[sync_tx_cache_data] send data to packing node.url:%s,body:%s'% (server_url,body))
            http_code, api_return_code, return_msg = restful_utility.restful_runner(server_url, 'POST', None, body)
            if http_code != 200 or api_return_code != 200:
                utils_packing.logE('[sync_tx_cache_data] fail to  send data to packing node.url:%s,body:%s'% (server_url,body))
                return api_return_code,return_msg

            #DELETE tx detail
            if packingnode_ip != 'http://'+register_ip_address:
                server_url = 'http://'+register_ip_address + '/pendingTX/' + accountAddress + '?current_account_nonce=' + str(current_account_nonce)
                http_code, api_return_code, return_msg = restful_utility.restful_runner(server_url, 'PUT', None, newaddStateObject)
                if http_code != 200 or api_return_code != 200:
                    utils_packing.logE('[sync_tx_cache_data] fail to delete tx_cache detail. url:%s'% (server_url))
                    return api_return_code,return_msg
        return 200,'OK'    
            
    except Exception, e:
        utils_packing.logE('[sync_tx_cache_data] sync tx_cache data fail.e:%s' % (e))
        return 400,e


def sync_blockcache_tx_cache_data(packingnode_ip):  
    try:
        #get to be packing datas for tx_cache   
        server_url = packingnode_ip + '/packing'
        http_code, api_return_code, return_msg = restful_utility.restful_runner(server_url, 'GET', None, '')
        utils_packing.logD('[sync_blockcache_tx_cache_data] get blockchain.url:%s'% (server_url))
        if http_code != 200 or api_return_code != 200: 
            utils_packing.logE('[sync_blockcache_tx_cache_data] fail to get data from  node.server_url:%s'% (server_url))
            return api_return_code,return_msg  

        #POST to be packing datas for tx_cache
        body = json.dumps(return_msg["data"][0])
        utils_packing.logD('[sync_blockcache_tx_cache_data] sync blockchain.url:%s,body:%s'% (server_url,body))
        http_code, api_return_code, return_msg = restful_utility.restful_runner(server_url, 'POST', None, body)
        if http_code != 200 or api_return_code != 200: 
            utils_packing.logE('[sync_blockcache_tx_cache_data] fail to post data from  node.server_url:%s,body:%s'% (server_url,body))
            return api_return_code,return_msg 

        #delete to be packing datas for tx_cache
        utils_packing.logD('[sync_blockcache_tx_cache_data] delete blockchain.url:%s'% (server_url))    
        http_code, api_return_code, return_msg = restful_utility.restful_runner(server_url, 'DELETE', None, '')
        if http_code != 200 or api_return_code != 200: 
            utils_packing.logE('[sync_blockcache_tx_cache_data] fail to delete data from  node.server_url:%s'% (server_url))
            return api_return_code,return_msg            
            
        return 200,'OK'
    except Exception, e:
        utils_packing.logE('[sync_blockcache_tx_cache_data] sync cache chain data fail.e:%s' % (e))
        return 400,e

def sync_cache_chain_data(users_data,packingnode_ip):  
    try:
        user_ip_set = set()
        all_ip_list = [packingnode_ip]
        for user_info in users_data:
            user_ip_set.add('http://'+str(user_info["register_ip_address"]))
        all_ip_list.extend(list(user_ip_set))  #to keep packing_node the first
        ##sync cacha_chain data
        for ip_detail in all_ip_list:
            #get blockcache_data
            server_url = ip_detail + '/blockchain'
            utils_packing.logD('[sync_cache_chain_data] deal with url:%s'% (server_url))
            http_code, api_return_code, return_msg = restful_utility.restful_runner(server_url, 'GET', None, '')
            if http_code != 200 or api_return_code != 200:
                utils_packing.logE('[sync_cache_chain_data] fail to get data from  node.url:%s'% (server_url))
                return api_return_code,return_msg
            
            #post blockcache_data to blockchain
            body = json.dumps(return_msg["data"][0])
            utils_packing.logD('[sync_cache_chain_data] deal with body:%s'% (body))
            http_code, api_return_code, return_msg = restful_utility.restful_runner(server_url, 'POST', None, body)
            if http_code != 200 or api_return_code != 200:
                utils_packing.logE('[sync_cache_chain_data] fail to post data to  node.url:%s,body:%s'% (server_url,body))
                return api_return_code,return_msg
            
            #delete blockcache data
            http_code, api_return_code, return_msg = restful_utility.restful_runner(server_url, 'DELETE', None, '')
            if http_code != 200 or api_return_code != 200: 
                utils_packing.logE('[sync_cache_chain_data] fail to delete data from  node.server_url:%s'% (server_url))
                return api_return_code,return_msg     

        return 200,'OK'
    except Exception, e:
        utils_packing.logE('[sync_cache_chain_data] sync cache chain data fail.e:%s' % (e))
        return 400,e      

def main():
    packingnode_ip = 'http://127.0.0.1:8080'

    # parse command parameter options
    parseOptions() 

    # init log handler
    utils_packing.doLogInit(g_log_level, g_log_file)
    
    # begin process
    while True:
        ############## get all the accountAddress & register_ip_address from centerdb###############
        server_url = g_center_dns + '/users/0'
        utils_packing.logI('[main] begin to get data from centerdb.centerdb url: %s'% (server_url)) 
        http_code, api_return_code, return_msg = restful_utility.restful_runner(server_url, 'GET', None, '')
        utils_packing.logI('[main] end to get data from centerdb.')
        if http_code == 200 and api_return_code == 200:
            utils_packing.logD('[main] success to get user detail from centerdb:%s,http_code:%s,api_return_code:%s,return_msg:%s'% (g_center_dns,http_code, api_return_code, return_msg))
            user_datas = return_msg["data"]
            ########################sync user node data to packing_node.tx_cache one by one ##########################################
            utils_packing.logI('[main] begin to sync user node data to packing_node.tx_cache one by one.')
            code, msg = sync_tx_cache_data(user_datas,packingnode_ip)
            utils_packing.logI('[main] end to sync user node data to packing_node.tx_cache one by one.')
            if code == 200:
                utils_packing.logD('[main] success to sync user node data to packing_node.tx_cache.packing_node:%s,user_detail:%s,code:%s,msg:%s'% (packingnode_ip,user_datas,code,msg))
                ########################sync all packing_node.tx_cache data to packing_node.block_cache############################
                utils_packing.logI('[main] begin to sync all packing_node.tx_cache data to packing_node.block_cache.')
                code ,msg = sync_blockcache_tx_cache_data(packingnode_ip)
                utils_packing.logI('[main] end to sync all packing_node.tx_cache data to packing_node.block_cache.')
                if code == 200 :
                    utils_packing.logD('[main] success to sync all packing_node.tx_cache data to packing_node.block_cache.packing_node: %s,code:%s,msg:%s'% (packingnode_ip,code,msg))
                    #########sync all packing_node.block_cache data to packing_node.blockchain and user_node.block_cache data to user_node.blockchain#####
                    utils_packing.logI('[main] begin to sync all packing_node.block_cache data to packing_node.blockchain and user_node.block_cache data to user_node.blockchain.')
                    code, msg = sync_cache_chain_data(user_datas,packingnode_ip)
                    utils_packing.logI('[main] end to sync all packing_node.block_cache data to packing_node.blockchain and user_node.block_cache data to user_node.blockchain.')
                    if code == 200:
                        utils_packing.logD('[main] success to sync packing_node&user_node data to blockchain. packing_node: %s,user_detail:%s,code:%s,msg:%s'% (packingnode_ip,user_datas,code,msg))
                    else:
                        utils_packing.logE('[main] fail to sync packing_node&user_node data to blockchain. packing_node: %s,user_detail:%s,code:%s,msg:%s'% (packingnode_ip,user_datas,code,msg))  
                else:
                    utils_packing.logE('[main] fail to sync all packing_node.tx_cache data to packing_node.block_cache.packing_node: %s,code:%s,msg:%s'% (packingnode_ip,code,msg))    
            else:    
                utils_packing.logE('[main] fail to sync user node data to packing_node.tx_cache.packing_node:%s,user_detail:%s,code:%s,msg:%s'% (packingnode_ip,user_datas,code,msg))    
        else:
            utils_packing.logE('[main] fail to get user detail from centerdb:%s,http_code:%s,api_return_code:%s,return_msg:%s'% (g_center_dns,http_code, api_return_code, return_msg))
                        
        # sleep 5 seconds then do next round        
        time.sleep(5)                

if '__main__' == __name__:
    main()
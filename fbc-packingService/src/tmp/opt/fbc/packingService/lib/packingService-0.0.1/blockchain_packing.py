#!/usr/bin/env python
# -*- coding: utf8 -*-

import restful_utility

import sys
import getopt
import ConfigParser
import os
import utils_2pc
import json
import time
import re

def usage():
    print """Usage: packingService_2pc.py [option] [optionValue]
     Options:
      -l | --loglevel          is the loglevel for record log, for example: D
                               the loglevel info is: (D:Debug, I:Info, W:Warning, E:Error)
                               this option is optional, default value is W
      -f | --logfile           is logfile to record log msg based on loglevel, for example: /var/log/fbc/server/packingService.log
                               this option is MUST
      -c | --center_dns        is centerdb dns, for example: http://127.0.0.1:8080
                               this option is MUST
      -p | --http_retrycnt     is http request retry count when http fail, for example: 5
                               this option is optional, default value is 0
      -k | --check_retrycnt    is queue data check retry count when queue check fail, for example: 1
                               this option is optional, default value is 0
      -t | --threadnum         is threads number for multithreading, for example: 5
                               this option is optional, default value is 1
      -i | --packing_time_diff is the packing pending time   , for example: 10                    
      -h | --help              is help info"""


def main():
    # get all the accountAddress & register_ip_address from centerdb
    # /users?
    server_url = centerdb_dns + '/users/'
    http_code, api_code, return_msg = restful_utility.restful_runner(server_url, 'GET', None, '')
    users_data = return_msg["data"]
    for user_info in users_data:
        accountAddress = user_info["accountAddress"]
        register_ip_address = user_info["register_ip_address"]

        # get accountAddress's current nonce
        # /stateNonce?accountAddress=
        server_url = register_ip_address + '/stateNonce?accountAddress=' + accountAddress
        http_code, api_code, return_msg = restful_utility.restful_runner(server_url, 'GET', None, '')
        current_nonce = return_msg["data"][0]["current_user_nonce"]

        # get tx detail data from tx_cache on user node 
        # /pendingTX/{accountAddress}?current_account_nonce=&time_diff=
        server_url = register_ip_address + '/pendingTX/' + accountAddress + '?current_account_nonce=' + current_nonce + '&time_diff=' + time_diff
        http_code, api_code, return_msg = restful_utility.restful_runner(server_url, 'GET', None, '')
        tx_data = return_msg["data"][0]

        # update accountAddress's current nonce to keystore

        # POST tx detail data to tx_cache on packing node
        # /pendingTX/{accountAddress} + body

        # POST tx relation data to blockchain_cache on packing node
        # /packing

        # POST tx relation data to blockchain on packing node
        # /blockchain + body

        # delete pendingTX
        # /pendingTX/{accountAddress}?current_account_nonce=




if '__main__' == __name__:
    main()
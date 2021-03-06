# -*- coding: utf-8 -*-

import urlparse
import hashlib  
import restful_utility
import crypto_utility
import json
import re

# check body
def bodyChecker(body, tx_key_check_dict):
    return_flag = True
    check_result = ''

    body_item_length = len(body)
    if body_item_length < 2 or body_item_length > 3:
        return_flag = False
        check_result = 'body format error'
        return return_flag, check_result

    # check tx details
    tx_detail = body[0]
    for key in tx_key_check_dict:
        if key not in tx_detail \
                or (key != 'Type' and isinstance(tx_detail[key],tx_key_check_dict[key]) is False) \
                or (key == 'Type' and tx_key_check_dict[key] != tx_detail[key]):
            return_flag = False
            check_result = 'check %s fail!' % key
            break

    return return_flag, check_result


# parse url parameters
def parse_url(query_string):
    return urlparse.parse_qs(urlparse.urlparse(query_string).query)


# get parameter value
def get_parameter(query_string_dict, key):
    return query_string_dict[key][0]


# get account basic info (public_key, balance, nonce)
def get_account_basicInfo(data_service_host,account_address):
    flag = True
    public_key = ''
    balance = 0
    nonce = 0
    return_msg = 'OK'

    server_url = data_service_host + '/statedb/' + account_address + '/basic_info'
    http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'GET', None, '')
    if http_code == 200 and api_code == 200:
        public_key = api_result["data"][0]["publicKey"]
        balance = api_result["data"][0]["balance"]
        nonce = api_result["data"][0]["nonce"]
    else:
        flag = False
        return_msg = api_result

    return flag, public_key, balance, nonce, return_msg


# get account's gasRequest (include normal account in pending handle transactions & smartcontract)
def get_account_gasRequest(data_service_host,account_address,is_smartcontract=0,is_packingnode=0):
    flag = True
    gasCost = 0
    gasDeposit = 0
    return_msg = 'OK'

    if is_smartcontract == 1:
        server_url = data_service_host + '/statedb/' + account_address + '/gas_request'
    elif is_packingnode == 1:
        server_url = data_service_host + '/packing/' + account_address + '/gas_request'
    else:
        server_url = data_service_host + '/tx_cache/' + account_address + '/gas_request'


    http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'GET', None, '')
    if http_code == 200 and api_code == 200:
        gasCost = api_result["data"][0]["gasCost"]
        gasDeposit = api_result["data"][0]["gasDeposit"]
    else:
        flag = False
        return_msg = api_result

    return flag, gasCost, gasDeposit, return_msg


# get normal account's private_key
def get_account_privateKey(data_service_host,account_address,txpasswd):
    flag = True
    private_key = ''
    return_msg = 'OK'

    server_url = data_service_host + '/users/' + account_address + '/private_key'
    http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'POST', None, txpasswd)
    if http_code == 200 and api_code == 200:
        private_key = api_result["ops"]["private_key"]
    else:
        flag = False
        return_msg = api_result

    return flag, private_key, return_msg


# get nonce from pending handle transactions
def get_pending_handle_account_maxNonce(data_service_host,account_address):
    flag = True
    max_pending_nonce = ''
    return_msg = 'OK'

    #server_url = data_service_host + '/tx_cache/' + account_address + '/nonce'
    server_url = data_service_host + '/stateNonce?accountAddress=' + account_address
    http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'GET', None, '')
    if http_code == 200 and api_code == 200:
        max_pending_nonce = api_result["data"][0]["current_user_nonce"]
    else:
        flag = False
        return_msg = api_result

    return flag, max_pending_nonce, return_msg


# ues private key generate hashSign
def get_hashsign(public_key,private_key,tx_detail):
    flag = True
    hashSign = ''
    return_message = ''

    if re.search('-----BEGIN PUBLIC KEY-----', public_key) and re.search('-----END PUBLIC KEY-----', public_key) and re.search('-----BEGIN RSA PRIVATE KEY-----', private_key) and re.search('-----END RSA PRIVATE KEY-----', private_key):
        tx_detail_md5 = crypto_utility.encrypt_md5(tx_detail)
        hashSign = crypto_utility.sign_encode(tx_detail_md5, private_key)
        if crypto_utility.sign_check(tx_detail_md5, hashSign, public_key) is False:
            flag = False
            return_message = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "public key and private key mis-match!"}}'
    else:
        flag = False
        return_message = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "public key or private key format error!"}}'

    return flag, hashSign, return_message


# check md5 signature
def check_md5_signature(public_key,hashSign,tx_detail):
    flag = True
    verify_message = ''

    if re.search('-----BEGIN PUBLIC KEY-----', public_key) and re.search('-----END PUBLIC KEY-----', public_key):
        tx_detail_md5 = crypto_utility.encrypt_md5(tx_detail)
        if crypto_utility.sign_check(tx_detail_md5, hashSign, public_key) is False:
            flag = False
            verify_message = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "md5 signature and hash not match!"}}'
    else:
        flag = False
        verify_message = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "public key format error!"}}'
    return flag, verify_message


# check body
def bodyTypeChecker(body, body_key_check_dict):
    return_flag = True
    check_result = ''
    formated_body = eval(body)    
    
    # check contents
    for key in body_key_check_dict:
        if key not in formated_body or isinstance(formated_body[key],body_key_check_dict[key]) is False:
            return_flag = False
            check_result = 'check %s fail' % key
            break

    return return_flag, check_result

def get_md5(str):
    m = hashlib.new('MD5', str)
    return m.hexdigest()




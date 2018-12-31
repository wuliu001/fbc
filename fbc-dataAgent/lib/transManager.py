# -*- coding: utf8 -*-

import urllib
import crypto_utility
import restful_utility
import json
import re


def bodyChecker(body, body_key_check_dict):
    goods_body = json.loads(body[0])
    body_list_len = len(body)
    return_flag = True
    check_result = ''

    # check body list number cnt
    if body_list_len < 2 or body_list_len > 3:
        return_flag = False
        check_result = 'body member count error'
    else:
        # check goods contents
        for key in body_key_check_dict:
            if key not in goods_body \
                    or (key != 'Type' and isinstance(goods_body[key],body_key_check_dict[key]) is False) \
                    or (key == 'Type' and body_key_check_dict[key] != goods_body[key]):
                return_flag = False
                check_result = 'check %s fail' % key
                break

    return return_flag, check_result


# execute api
def api_execution(url, method, body):
    http_code, api_code, json_obj = restful_utility.restful_runner(url, method, None, body)
    return http_code, api_code, json_obj


# verify private key
def verify_private_key(user, private_key, data_service_host, data_service_uri, goods_info):
    flag = False
    md5 = ''
    hash_code = ''
    verify_message = ''

    if re.search('-----BEGIN RSA PRIVATE KEY-----', private_key) and re.search('-----END RSA PRIVATE KEY-----', private_key):
        # get user public key
        server_url = data_service_host + data_service_uri + user
        http_code, api_code, api_result = api_execution(server_url, 'GET', None)
        if http_code != 200 or api_code != 200:
            verify_message = api_result
        else:
            api_json_result = json.loads(api_result)
            public_key = api_json_result["data"][0]["public_key"]

            cipher = crypto_utility.rsa_encode(goods_info, public_key)
            msg = crypto_utility.rsa_decode(cipher, private_key)
            if msg != goods_info:
                verify_message = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "public key and private key mis-match", "goods_batch_id": ""}}'
            else:
                md5 = crypto_utility.encrypt_md5(goods_info)
                hash_code = crypto_utility.sign_encode(md5, private_key)
                flag = True
    else:
        verify_message = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "private key format error", "goods_batch_id": ""}}'

    return flag, md5, hash_code, verify_message



# verify md5 signature
def verify_md5_signature(user, hash_code, data_service_host, data_service_uri, node_dns, goods_info):
    flag = False
    verify_message = ''

    server_url = data_service_host + data_service_uri + user
    http_code, api_code, api_result = api_execution(server_url, 'GET', None)
    if http_code != 200 or (api_code != 200 and api_code != 511):
        verify_message = api_result
        return flag, verify_message

    if api_code == 200:
        api_json_result = json.loads(api_result)
        public_key = api_json_result["data"][0]["public_key"]
        md5 = crypto_utility.encrypt_md5(goods_info)
        if crypto_utility.sign_check(md5, hash_code, public_key) is False:
            verify_message = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "md5 signature and hash not match", "goods_batch_id": ""}}'
            return flag, verify_message

    if api_code == 511:
        # get user public key
        server_url = node_dns + data_service_uri + user
        http_code, api_code, api_result = api_execution(server_url, 'GET', None)
        if http_code != 200 or api_code != 200:
            verify_message = api_result
            return flag, verify_message

        api_json_result = json.loads(api_result)
        public_key = api_json_result["data"][0]["public_key"]
        goods_info_md5 = crypto_utility.encrypt_md5(goods_info)
        if crypto_utility.sign_check(goods_info_md5, hash_code, public_key):
            # create user in current node
            server_url = data_service_host + data_service_uri + user
            http_code, api_code, api_result = api_execution(server_url, 'POST', public_key)
            if http_code != 200 or api_code != 200:
                verify_message = api_result
                return flag, verify_message

            flag = True

        else:
            verify_message = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "md5 signature and hash not match", "goods_batch_id": ""}}'
            return flag, verify_message

    return flag, verify_message



def goodsRegister(data_service_host, body):
    body_key_check_dict = {"User": str, "Type": "goodsRegister", "Varieties": str, "placeOfProduction": str, "dateOfProduction": str, \
                           "sizeRating": int, "sweetnessRating": int, "Quantity": float, "Price": float, "countryOfIssuingLocation": str, \
                           "provinceOfIssuingLocation": str, "cityOfIssuingLocation": str, "zoneOfIssuingLocation": str, \
                           "addressOfIssuingLocation": str, "request_timestemp": str}
    # body check
    check_result, check_msg = bodyChecker(body, body_key_check_dict)

    # body check success
    if check_result:
        body_list_len = len(body)
        goods_info = body[0]
        goods_info_json = json.loads(goods_info)
        user = goods_info_json['User']
        transType = goods_info_json['Type']

        # check private key
        if body_list_len == 2:
            is_create = 1
            private_key = body[1]

            flag, goods_info_md5, goods_info_hash, is_create, verify_message = verify_private_key(user, private_key, data_service_host, '/users/sync/', goods_info)
            if flag is False:
                api_result = verify_message
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        # check md5 signature
        else:
            is_create = 0
            goods_info_hash = body[1]
            node_dns = body[2]

            flag, is_create, verify_message = verify_md5_signature(user, goods_info_hash, data_service_host, '/users/sync/', node_dns, goods_info)
            if flag is False:
                api_result = verify_message
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']


        # call api
        # parameter: user, transType, goods_info_hash, is_create
        #
        server_url = data_service_host + 'xxx' + user + '?....'
        http_code, api_code, api_result = api_execution(server_url, 'POST', goods_info)
        return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

    # body check fail
    else:
        api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s", "goods_batch_id": ""}}' % check_msg
        return '200 OK', [('Content-Type','text/html')], [api_result + '\n']


def goodsPriceModify(data_service_host, body):
    pass


def goodsQuantityModify(data_service_host, body):
    pass


def goodsPurchaseRequest(data_service_host, body):
    pass


def goodsPurchaseDelete(data_service_host, body):
    pass


def goodsPurchaseModify(data_service_host, body):
    pass


def goodsLogisticsRegister(data_service_host, body):
    pass


def goodsComments(data_service_host, body):
    pass


def goodsLogisticsSalerConfirm(data_service_host, body):
    pass


def goodsLogisticsBuyerConfirm(data_service_host, body):
    pass


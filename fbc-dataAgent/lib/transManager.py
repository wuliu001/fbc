# -*- coding: utf8 -*-

import urllib
import crypto_utility
import restful_utility
import json
import re


def bodyChecker(body_list_len,goods_body):
    # check body list number cnt
    if body_list_len < 2 or body_list_len > 3:
        check_result = 'body format error'
        return False, check_result

    # check goods contents
    user = ''
    if 'User' in goods_body and isinstance(goods_body['User'],str):
        check_result = 'check User fail'
        return False, check_result, '', ''
    user = goods_body['User']

    if 'Type' in goods_body and isinstance(goods_body['Type'],str):
        check_result = 'check Type fail'
        return False, check_result, user, ''
    else:
        type = goods_body['Type']
        if type != 'goodsRegister':
            check_result = 'transaction type mis-match'
            return False, check_result, user, type

    if 'Varieties' in goods_body and isinstance(goods_body['Varieties'],str):
        check_result = 'check Varieties fail'
        return False, check_result, user, type

    if 'placeOfProduction' in goods_body and isinstance(goods_body['placeOfProduction'],str):
        check_result = 'check placeOfProduction fail'
        return False, check_result, user, type

    if 'dateOfProduction' in goods_body and isinstance(goods_body['dateOfProduction'],str):
        check_result = 'check dateOfProduction fail'
        return False, check_result, user, type

    if 'sizeRating' in goods_body and isinstance(goods_body['sizeRating'],int):
        check_result = 'check sizeRating fail'
        return False, check_result, user, type

    if 'sweetnessRating' in goods_body and isinstance(goods_body['sweetnessRating'],int):
        check_result = 'check sweetnessRating fail'
        return False, check_result, user, type

    if 'Quantity' in goods_body and isinstance(goods_body['Quantity'],float):
        check_result = 'check Quantity fail'
        return False, check_result, user, type

    if 'Price' in goods_body and isinstance(goods_body['Price'],float):
        check_result = 'check Price fail'
        return False, check_result, user, type

    if 'country' in goods_body and isinstance(goods_body['country'],str):
        check_result = 'check country fail'
        return False, check_result, user, type

    if 'province' in goods_body and isinstance(goods_body['province'],str):
        check_result = 'check province fail'
        return False, check_result, type

    if 'city' in goods_body and isinstance(goods_body['city'],str):
        check_result = 'check city fail'
        return False, check_result, user, type

    if 'zone' in goods_body and isinstance(goods_body['zone'],str):
        check_result = 'check zone fail'
        return False, check_result, user, type

    if 'address' in goods_body and isinstance(goods_body['address'],str):
        check_result = 'check address fail'
        return False, check_result, user, type

    if 'request_timestemp' in goods_body and isinstance(goods_body['request_timestemp'],str):
        check_result = 'check request_timestemp fail'
        return False, check_result, user, type

    return True, ''


# get user public key
def get_public_key(dns, uri, method, body):
    ds_url = dns + uri
    code, json_obj = restful_utility.restful_runner(ds_url, method, None, body)
    restful_result = json.dumps(json_obj)
    restful_code = restful_result["ops"]["code"]
    restful_data = restful_result["ops"]["data"]
    return restful_code, restful_data


def goodsRegister(server_url, body, method):
    body_list_len = len(body)
    goods_info = body[0]

    # body check
    check_result, check_msg, user, transType = bodyChecker(body_list_len, goods_info)
    # body check success
    if check_result:
        # check private key
        if body_list_len == 2:
            private_key = body[1]
            if re.search('-----BEGIN RSA PRIVATE KEY-----', private_key) and re.search('-----END RSA PRIVATE KEY-----', private_key):
                # get user public key
                code, data = get_public_key(server_url, '/users/sync/'+user, 'GET', None, '')
                if code != 200:
                    data = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "get public key error", "goods_batch_id": ""}}'
                    return '200 OK', [('Content-Type', 'text/html')], [data + '\n']
                public_key = data[0]["public_key"]

                cipher = crypto_utility.rsa_encode(goods_info, public_key)
                msg = crypto_utility.rsa_decode(cipher, private_key)
                if msg != goods_info:
                    data = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "public key and private key mis-match", "goods_batch_id": ""}}'
                    return '200 OK', [('Content-Type', 'text/html')], [data + '\n']

                goods_info_md5 = crypto_utility.encrypt_md5(goods_info)
                goods_info_hash = crypto_utility.sign_encode(goods_info_md5, private_key)
                is_create = 0

            else:
                data = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "private key format error", "goods_batch_id": ""}}'
                return '200 OK', [('Content-Type', 'text/html')], [data + '\n']


        # check public key
        else:
            hash_code = body[1]
            node_dns = body[2]

            # get user public key
            code, data = get_public_key(server_url, '/users/sync/' + user, 'GET', None, '')
            if code == 200:
                public_key = data[0]["public_key"]
                if crypto_utility.sign_check(goods_info, hash_code, public_key):
                    goods_info_hash = hash_code
                    is_create = 0
                else:
                    data = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "md5 signature and hash not match", "goods_batch_id": ""}}'
                    return '200 OK', [('Content-Type', 'text/html')], [data + '\n']

            elif code == 511:
                # get user public key
                code, data = get_public_key(node_dns, '/users/sync/' + user, 'GET', None, '')
                if code == 200:
                    public_key = data[0]["public_key"]
                    if crypto_utility.sign_check(goods_info, hash_code, public_key):
                        goods_info_hash = hash_code
                        is_create = 0

                        # create user in current node
                        url = server_url + '/users/sync/' + user
                        code, data = restful_utility.restful_runner(url, 'POST', None, public_key)
                        # ...

                    else:
                        data = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "md5 signature and hash not match", "goods_batch_id": ""}}'
                        return '200 OK', [('Content-Type', 'text/html')], [data + '\n']

            else:
                pass


        # call api
        # ...


    # body check fail
    else:
        data = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s", "goods_batch_id": ""}}' % check_msg
    
    return '200 OK', [('Content-Type','text/html')], [data + '\n']


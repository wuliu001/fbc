# -*- coding: utf8 -*-

import urllib
import crypto_utility
import restful_utility
import json
import re


def bodyChecker(body):
    goods_body = body[0]
    body_list_len = len(body)

    # check body list number cnt
    if body_list_len < 2 or body_list_len > 3:
        check_result = 'body format error'
        return False, check_result

    # check goods contents
    if 'User' not in goods_body or isinstance(goods_body['User'],str) is False:
        check_result = 'check User fail'
        return False, check_result

    if 'Type' not in goods_body or isinstance(goods_body['Type'],str) is False or goods_body['Type'] != 'goodsRegister':
        check_result = 'check Type fail'
        return False, check_result

    if 'Varieties' not in goods_body or isinstance(goods_body['Varieties'],str) is False:
        check_result = 'check Varieties fail'
        return False, check_result

    if 'placeOfProduction' not in goods_body or isinstance(goods_body['placeOfProduction'],str) is False:
        check_result = 'check placeOfProduction fail'
        return False, check_result

    if 'dateOfProduction' not in goods_body or isinstance(goods_body['dateOfProduction'],str) is False:
        check_result = 'check dateOfProduction fail'
        return False, check_result

    if 'sizeRating' not in goods_body or isinstance(goods_body['sizeRating'],int) is False:
        check_result = 'check sizeRating fail'
        return False, check_result

    if 'sweetnessRating' not in goods_body or isinstance(goods_body['sweetnessRating'],int) is False:
        check_result = 'check sweetnessRating fail'
        return False, check_result

    if 'Quantity' not in goods_body or isinstance(goods_body['Quantity'],float) is False:
        check_result = 'check Quantity fail'
        return False, check_result

    if 'Price' not in goods_body or isinstance(goods_body['Price'],float) is False:
        check_result = 'check Price fail'
        return False, check_result

    if 'country' not in goods_body or isinstance(goods_body['country'],str) is False:
        check_result = 'check country fail'
        return False, check_result

    if 'province' not in goods_body or isinstance(goods_body['province'],str) is False:
        check_result = 'check province fail'
        return False, check_result

    if 'city' not in goods_body or isinstance(goods_body['city'],str) is False:
        check_result = 'check city fail'
        return False, check_result

    if 'zone' not in goods_body or isinstance(goods_body['zone'],str) is False:
        check_result = 'check zone fail'
        return False, check_result

    if 'address' not in goods_body or isinstance(goods_body['address'],str) is False:
        check_result = 'check address fail'
        return False, check_result

    if 'request_timestemp' not in goods_body or isinstance(goods_body['request_timestemp'],str) is False:
        check_result = 'check request_timestemp fail'
        return False, check_result

    return True, ''


# get user public key
def api_execution(url, method, body):
    http_code, api_code, json_obj = restful_utility.restful_runner(url, method, None, body)
    return http_code, api_code, json_obj


def goodsRegister(data_service_host, body):
    # body check
    check_result, check_msg = bodyChecker(body)

    # body check success
    if check_result:
        body_list_len = len(body)
        goods_info = body[0]
        user = goods_info['User']
        transType = goods_info['Type']

        # check private key
        if body_list_len == 2:
            private_key = body[1]
            if re.search('-----BEGIN RSA PRIVATE KEY-----', private_key) and re.search('-----END RSA PRIVATE KEY-----', private_key):
                # get user public key

                server_url = data_service_host + '/users/sync/' + user
                http_code, api_code, api_result = api_execution(server_url, 'GET', None)
                if http_code != 200:
                    return str(http_code) + ' OK', [('Content-Type', 'text/html')], [api_result + '\n']
                if api_code != 200:
                    return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

                api_json_result = json.loads(api_result)
                public_key = api_json_result["data"][0]["public_key"]

                cipher = crypto_utility.rsa_encode(goods_info, public_key)
                msg = crypto_utility.rsa_decode(cipher, private_key)
                if msg != goods_info:
                    api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "public key and private key mis-match", "goods_batch_id": ""}}'
                    return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

                goods_info_md5 = crypto_utility.encrypt_md5(goods_info)
                goods_info_hash = crypto_utility.sign_encode(goods_info_md5, private_key)
                is_create = 0

            else:
                api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "private key format error", "goods_batch_id": ""}}'
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']


        # check md5 signature
        else:
            hash_code = body[1]
            node_dns = body[2]

            # get user public key
            server_url = data_service_host + '/users/sync/' + user
            http_code, api_code, api_result = api_execution(server_url, 'GET', None)
            if http_code != 200:
                return str(http_code) + ' OK', [('Content-Type', 'text/html')], [api_result + '\n']

            if api_code == 200:
                api_json_result = json.loads(api_result)
                public_key = api_json_result["data"][0]["public_key"]
                goods_info_md5 = crypto_utility.encrypt_md5(goods_info)
                if crypto_utility.sign_check(goods_info_md5, hash_code, public_key):
                    goods_info_hash = hash_code
                    is_create = 0
                else:
                    api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "md5 signature and hash not match", "goods_batch_id": ""}}'
                    return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

            elif api_code == 511:
                # get user public key
                server_url = node_dns + '/users/sync/' + user
                http_code, api_code, api_result = api_execution(server_url, 'GET', None)
                if http_code != 200:
                    return str(http_code) + ' OK', [('Content-Type', 'text/html')], [api_result + '\n']
                if api_code != 200:
                    return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

                api_json_result = json.loads(api_result)
                public_key = api_json_result["data"][0]["public_key"]
                goods_info_md5 = crypto_utility.encrypt_md5(goods_info)
                if crypto_utility.sign_check(goods_info_md5, hash_code, public_key):
                    goods_info_hash = hash_code
                    is_create = 1

                    # create user in current node
                    server_url = data_service_host + '/users/sync/' + user
                    http_code, api_code, api_result = api_execution(server_url, 'POST', public_key)
                    if http_code != 200:
                        return str(http_code) + ' OK', [('Content-Type', 'text/html')], [api_result + '\n']
                    if api_code != 200:
                        return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

                else:
                    api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "md5 signature and hash not match", "goods_batch_id": ""}}'
                    return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']
            else:
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']


        # call api
        # parameter: user, transType, goods_info_hash, is_create
        # body: goods_info
        server_url = data_service_host + 'xxx' + user + '?....'
        http_code, api_code, api_result = api_execution(server_url, 'POST', public_key)
        if http_code != 200:
            return str(http_code) + ' OK', [('Content-Type', 'text/html')], [api_result + '\n']
        else:
            return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

    # body check fail
    else:
        api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s", "goods_batch_id": ""}}' % check_msg
        return '200 OK', [('Content-Type','text/html')], [api_result + '\n']


# -*- coding: utf8 -*-

import urllib
import crypto_utility
import restful_utility
import misc_utility
import json


def goodsRegister(data_service_host, body):
    body_key_check_dict = {"User": str, "Type": "goodsRegister", "Varieties": str, "placeOfProduction": str, "dateOfProduction": str, \
                           "appearanceRating": int,"sizeRating": int, "sweetnessRating": int, "Quantity": float, "Price": float, \
                           "countryOfIssuingLocation": str, "provinceOfIssuingLocation": str, "cityOfIssuingLocation": str, \
                           "zoneOfIssuingLocation": str, "addressOfIssuingLocation": str, "request_timestemp": str}

    # body check
    check_result, check_msg, tuple_body = misc_utility.bodyChecker(body, body_key_check_dict)
    list_body = tuple_body[1]
    # body check success
    if check_result:
        body_item_len = len(list_body)
        goods_info = list_body[0]
        goods_info_str = json.dumps(goods_info)
        user = goods_info['User']
        transType = goods_info['Type']
        node_dns = ''

        # check private key
        if body_item_len == 2:
            is_create = 1
            private_key = list_body[1]

            flag, goods_info_hash, verify_message = crypto_utility.verify_private_key(user, private_key, data_service_host, '/users/sync/', goods_info_str)
            if flag is False:
                api_result = verify_message
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        # check md5 signature
        else:
            is_create = 0
            goods_info_hash = list_body[1]
            node_dns = list_body[2]

            flag, verify_message = crypto_utility.verify_md5_signature(user, goods_info_hash, data_service_host, '/users/sync/', node_dns, goods_info_str)
            if flag is False:
                api_result = verify_message
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        if 'paymentMinStage' not in goods_info:
            tuple_body[1][0]['paymentMinStage'] = 1
        if 'paymentMaxStage' not in goods_info:
            tuple_body[1][0]['paymentMaxStage'] = 1
        
        goods_info_tuple = (tuple_body[0],tuple_body[1][0])

        # call api
        server_url = data_service_host + '/goods/cache?user=' + user + '&type=' + transType + '&hashSign=' + goods_info_hash + '&is_create=' + is_create + '&node_dns=' + node_dns
        http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'POST', None, str(goods_info_tuple))
        return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

    # body check fail
    else:
        api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s", "goods_batch_id": ""}}' % check_msg
        return '200 OK', [('Content-Type','text/html')], [api_result + '\n']


def goodsPriceModify(data_service_host, query_string, body):
    body_key_check_dict = {"User": str, "Type": "goodsPriceModify", "Price": float, "request_timestemp": str, "Comments": str}

    # body check
    check_result, check_msg, tuple_body = misc_utility.bodyChecker(body, body_key_check_dict)
    list_body = tuple_body[1]
    # body check success
    if check_result:
        body_item_len = len(list_body)
        goods_info = list_body[0]
        goods_info_str = json.dumps(goods_info)
        user = goods_info['User']
        node_dns = ''

        # check private key
        if body_item_len == 2:
            is_create = 1
            private_key = list_body[1]

            flag, goods_info_hash, verify_message = crypto_utility.verify_private_key(user, private_key, data_service_host, '/users/sync/', goods_info_str)
            if flag is False:
                api_result = verify_message
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        # check md5 signature
        else:
            is_create = 0
            goods_info_hash = list_body[1]
            node_dns = list_body[2]

            flag, is_create, verify_message = crypto_utility.verify_md5_signature(user, goods_info_hash, data_service_host, '/users/sync/', node_dns, goods_info_str)
            if flag is False:
                api_result = verify_message
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        if 'paymentMinStage' not in goods_info:
            tuple_body[1][0]['paymentMinStage'] = 1
        if 'paymentMaxStage' not in goods_info:
            tuple_body[1][0]['paymentMaxStage'] = 1

        # get parameter
        query_string_dict = misc_utility.parse_url('?' + query_string)
        goods_batch_id = misc_utility.get_parameter(query_string_dict, 'goods_batch_id')

        goods_info_tuple = (tuple_body[0],tuple_body[1][0])

        # call api
        server_url = data_service_host + '/goods/cache/' + goods_batch_id + '/price?user=' + user + '&hashSign=' + goods_info_hash + '&is_create=' + is_create + '&node_dns=' + node_dns
        http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'PUT', None, str(goods_info_tuple))
        return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

    # body check fail
    else:
        api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s"}}' % check_msg
        return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']


def goodsQuantityModify(data_service_host, query_string, body):
    body_key_check_dict = {"User": str, "Type": "goodsQuantityModify", "Quantity": float, "countryOfIssuingLocation": str, \
                           "provinceOfIssuingLocation": str, "cityOfIssuingLocation": str, "zoneOfIssuingLocation": str, \
                           "addressOfIssuingLocation": str, "request_timestemp": str, "Comments": str}

    # body check
    check_result, check_msg, tuple_body = misc_utility.bodyChecker(body, body_key_check_dict)
    list_body = tuple_body[1]
    # body check success
    if check_result:
        body_item_len = len(list_body)
        goods_info = list_body[0]
        goods_info_str = json.dumps(goods_info)
        user = goods_info['User']
        node_dns = ''

        # check private key
        if body_item_len == 2:
            is_create = 1
            private_key = list_body[1]

            flag, goods_info_hash, verify_message = crypto_utility.verify_private_key(user, private_key, data_service_host, '/users/sync/', goods_info_str)
            if flag is False:
                api_result = verify_message
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        # check md5 signature
        else:
            is_create = 0
            goods_info_hash = list_body[1]
            node_dns = list_body[2]

            flag, is_create, verify_message = crypto_utility.verify_md5_signature(user, goods_info_hash, data_service_host, '/users/sync/', node_dns, goods_info_str)
            if flag is False:
                api_result = verify_message
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        # get parameter
        query_string_dict = misc_utility.parse_url('?' + query_string)
        goods_batch_id = misc_utility.get_parameter(query_string_dict, 'goods_batch_id')

        goods_info_tuple = (tuple_body[0],tuple_body[1][0])

        # call api
        server_url = data_service_host + '/goods/cache/' + goods_batch_id + '/quantity?user=' + user + '&hashSign=' + goods_info_hash + '&is_create=' + is_create + '&node_dns=' + node_dns
        http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'POST', None, str(goods_info_tuple))
        return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

    # body check fail
    else:
        api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s"}}' % check_msg
        return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']


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


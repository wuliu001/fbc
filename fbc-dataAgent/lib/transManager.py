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
        node_dns = data_service_host

        # check private key
        if body_item_len == 2:
            is_create = 1
            private_key = list_body[1]

            flag, hashSign, verify_message = crypto_utility.verify_private_key(user, private_key, data_service_host, '/users/sync/', goods_info_str)
            if flag is False:
                api_result = verify_message
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        # check md5 signature
        else:
            is_create = 0
            hashSign = list_body[1]
            node_dns = list_body[2]

            flag, verify_message = crypto_utility.verify_md5_signature(user, hashSign, data_service_host, '/users/sync/', node_dns, goods_info_str)
            if flag is False:
                api_result = verify_message
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        if 'paymentMinStage' not in goods_info:
            tuple_body[1][0]['paymentMinStage'] = 1
        if 'paymentMaxStage' not in goods_info:
            tuple_body[1][0]['paymentMaxStage'] = 1
        
        goods_info_tuple = (tuple_body[0],json.dumps(tuple_body[1][0]))

        # call api
        server_url = data_service_host + '/goods/cache?user=' + user + '&type=' + transType + '&hashSign=' + hashSign + '&is_create=' + str(is_create) + '&node_dns=' + node_dns
        http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'POST', None, str(goods_info_tuple))
        return '200 OK', [('Content-Type', 'text/html')], [json.dumps(api_result) + '\n']

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
        node_dns = data_service_host

        # check private key
        if body_item_len == 2:
            is_create = 1
            private_key = list_body[1]

            flag, hashSign, verify_message = crypto_utility.verify_private_key(user, private_key, data_service_host, '/users/sync/', goods_info_str)
            if flag is False:
                api_result = verify_message
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        # check md5 signature
        else:
            is_create = 0
            hashSign = list_body[1]
            node_dns = list_body[2]

            flag, is_create, verify_message = crypto_utility.verify_md5_signature(user, hashSign, data_service_host, '/users/sync/', node_dns, goods_info_str)
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

        goods_info_tuple = (tuple_body[0],json.dumps(tuple_body[1][0]))

        # call api
        server_url = data_service_host + '/goods/cache/' + goods_batch_id + '/price?user=' + user + '&hashSign=' + hashSign + '&is_create=' + str(is_create) + '&node_dns=' + node_dns
        http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'PUT', None, str(goods_info_tuple))
        return '200 OK', [('Content-Type', 'text/html')], [json.dumps(api_result) + '\n']

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
        node_dns = data_service_host

        # check private key
        if body_item_len == 2:
            is_create = 1
            private_key = list_body[1]

            flag, hashSign, verify_message = crypto_utility.verify_private_key(user, private_key, data_service_host, '/users/sync/', goods_info_str)
            if flag is False:
                api_result = verify_message
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        # check md5 signature
        else:
            is_create = 0
            hashSign = list_body[1]
            node_dns = list_body[2]

            flag, is_create, verify_message = crypto_utility.verify_md5_signature(user, hashSign, data_service_host, '/users/sync/', node_dns, goods_info_str)
            if flag is False:
                api_result = verify_message
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        # get parameter
        query_string_dict = misc_utility.parse_url('?' + query_string)
        goods_batch_id = misc_utility.get_parameter(query_string_dict, 'goods_batch_id')

        goods_info_tuple = (tuple_body[0],json.dumps(tuple_body[1][0]))

        # call api
        server_url = data_service_host + '/goods/cache/' + goods_batch_id + '/quantity?user=' + user + '&hashSign=' + hashSign + '&is_create=' + str(is_create) + '&node_dns=' + node_dns
        http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'POST', None, str(goods_info_tuple))
        return '200 OK', [('Content-Type', 'text/html')], [json.dumps(api_result) + '\n']

    # body check fail
    else:
        api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s"}}' % check_msg
        return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']


def goodsPurchaseRequest(data_service_host,query_string, body):
    #check parameter valid
    query_string_dict = misc_utility.parse_url('?' + query_string)
    transactions_type = misc_utility.get_parameter(query_string_dict, 'transactions_type')
    purchase_type = misc_utility.get_parameter(query_string_dict, 'purchase_type')
    if (str(transactions_type) != 'purchase') and (str(purchase_type) != 'fruit' and str(purchase_type) != 'seed'):
        api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s", "purchase_request_id": ""}}' % check_msg
        return '200 OK', [('Content-Type','text/html')], [api_result + '\n']
    
    #deal with body
    body_key_check_dict = {"User": str, "Type": "newPurchase", "Varieties": str, "placeOfProduction": str, "dateOfProduction": str, \
                           "appearanceRating": str,"sizeRating": str, "sweetnessRating": str, "Quantity": float, "Price": float, \
                           "countryOfDeliveryLocationLocation": str, "provinceOfDeliveryLocationLocation": str, "cityOfDeliveryLocationLocation": str, \
                           "zoneOfDeliveryLocationLocation": str, "addressOfDeliveryLocationLocation": str, "request_timestemp": int}

    # body check
    check_result, check_msg, tuple_body = misc_utility.bodyChecker(body, body_key_check_dict)
    list_body = tuple_body[1]
    # body check success
    if check_result:
        body_item_len = len(list_body)
        purchase_info = list_body[0]
        purchase_info_str = json.dumps(purchase_info)
        user = purchase_info['User']
        transType = purchase_info['Type']
        node_dns = data_service_host
        # check private key
        if body_item_len == 2:
            is_create = 1
            private_key = list_body[1]

            flag, hashSign, verify_message = crypto_utility.verify_private_key(user, private_key, data_service_host, '/users/sync/', purchase_info_str)
            if flag is False:
                api_result = verify_message
                api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "verify_private_key fail", "purchase_request_id": ""}}'
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        # check md5 signature
        else:
            is_create = 0
            hashSign = list_body[1]
            node_dns = list_body[2]

            flag, verify_message = crypto_utility.verify_md5_signature(user, hashSign, data_service_host, '/users/sync/', node_dns, purchase_info_str)
            if flag is False:
                api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "verify_md5_signature fail", "purchase_request_id": ""}}'
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        if 'paymentMinStage' not in purchase_info:
            tuple_body[1][0]['paymentMinStage'] = 1
        if 'paymentMaxStage' not in purchase_info:
            tuple_body[1][0]['paymentMaxStage'] = 1
        
        purchase_info_tuple = (tuple_body[0],json.dumps(tuple_body[1][0]))

        # call api
        server_url = data_service_host +'/transactions/cache/'+transactions_type+'/'+purchase_type+'?user=' + user + '&type=' + transType + '&hashSign=' + hashSign + '&is_create=' + str(is_create) + '&node_dns=' + node_dns
        http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'POST', None, str(purchase_info_tuple))
        return '200 OK', [('Content-Type', 'text/html')], [json.dumps(api_result) + '\n']

    # body check fail
    else:
        api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s", "purchase_request_id": ""}}' % check_msg
        return '200 OK', [('Content-Type','text/html')], [api_result + '\n']


def goodsPurchaseDelete(data_service_host, query_string,body):    
    #check parameter valid
    print 'query_string',query_string
    query_string_dict = misc_utility.parse_url('?' + query_string)
    #query_string_dict["request_id"] = 'qYeBQUM2g6bTFqJruy8hVO1qHu/pHUFoUJHyZ4vUMrJMwhNs7zxFN1q0QGJxksxhxfk0YqxZ7H35zfy2twmNIEEozSUy8NxqQAQ13VXdeI7umvmP+AbDZqt2TTAE4uYF+7iNoLk8IrfMrB8TVQVoBHZ2ewLrKQx0FXtUfC1mBu8='
    transactions_type = misc_utility.get_parameter(query_string_dict, 'transactions_type')
    purchase_type = misc_utility.get_parameter(query_string_dict, 'purchase_type')
    request_id = misc_utility.get_parameter(query_string_dict, 'request_id')
    user = misc_utility.get_parameter(query_string_dict, 'user')
    if (str(transactions_type) != 'purchase' and str(transactions_type) != 'sell') and (str(purchase_type) != 'fruit' and str(purchase_type) != 'seed') and (request_id == None or request_id == '') and (user == None or user == ''):
        api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s"}}' % check_msg
        return '200 OK', [('Content-Type','text/html')], [api_result + '\n']
    
    #deal with body
    body_key_check_dict = {}

    # body check
    check_result, check_msg, tuple_body = misc_utility.bodyChecker(body, body_key_check_dict)
    list_body = tuple_body[1]
    # body check success
    if check_result:
        body_item_len = len(list_body)
        purchase_info = list_body[0]
        purchase_info_str = json.dumps(purchase_info)
        node_dns = data_service_host
        # check private key
        if body_item_len == 1:
            private_key = list_body[0]

            flag, hashSign, verify_message = crypto_utility.verify_private_key(user, private_key, data_service_host, '/users/sync/', purchase_info_str)
            if flag is False:
                api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "verify_private_key fail"}}'
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        # check md5 signature
        else:
            hashSign = list_body[0]
            node_dns = list_body[1]
            flag, verify_message = crypto_utility.verify_md5_signature(user, hashSign, data_service_host, '/users/sync/', node_dns, purchase_info_str)
            if flag is False:
                api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "verify_md5_signature fail"}}'
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']
        
        purchase_info_tuple = (tuple_body[0],json.dumps(tuple_body[1][0]))

        # call api
        #request_id = 'test'
        server_url = data_service_host +'/transactions/cache/'+transactions_type+'/'+purchase_type+'?user=' + user + '&request_id=' + request_id + '&node_dns=' + node_dns
        http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'PUT', None, str(purchase_info_tuple))
        return '200 OK', [('Content-Type', 'text/html')], [json.dumps(api_result) + '\n']

    # body check fail
    else:
        api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s"}}' % check_msg
        return '200 OK', [('Content-Type','text/html')], [api_result + '\n']


def goodsPurchaseModify(data_service_host,query_string, body):
    #check parameter valid
    query_string_dict = misc_utility.parse_url('?' + query_string)
    print 'query_string_dict',query_string_dict
    #query_string_dict["old_purchase_batch"] = 'qYeBQUM2g6bTFqJruy8hVO1qHu/pHUFoUJHyZ4vUMrJMwhNs7zxFN1q0QGJxksxhxfk0YqxZ7H35zfy2twmNIEEozSUy8NxqQAQ13VXdeI7umvmP+AbDZqt2TTAE4uYF+7iNoLk8IrfMrB8TVQVoBHZ2ewLrKQx0FXtUfC1mBu8='
    transactions_type = misc_utility.get_parameter(query_string_dict, 'transactions_type')
    purchase_type = misc_utility.get_parameter(query_string_dict, 'purchase_type')
    old_purchase_batch = misc_utility.get_parameter(query_string_dict, 'old_purchase_batch')
    if (str(transactions_type) != 'purchase') and (str(purchase_type) != 'fruit' and str(purchase_type) != 'seed') and (old_purchase_batch == None or old_purchase_batch == ''):
        api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s", "new_purchase_id": ""}}' % check_msg
        return '200 OK', [('Content-Type','text/html')], [api_result + '\n']
    
    #deal with body
    body_key_check_dict = {"User": str, "Type": "newPurchase", "Varieties": str, "placeOfProduction": str, "dateOfProduction": str, \
                           "appearanceRating": str,"sizeRating": str, "sweetnessRating": str, "Quantity": float, "Price": float, \
                           "countryOfDeliveryLocationLocation": str, "provinceOfDeliveryLocationLocation": str, "cityOfDeliveryLocationLocation": str, \
                           "zoneOfDeliveryLocationLocation": str, "addressOfDeliveryLocationLocation": str, "request_timestemp": int}

    # body check
    check_result, check_msg, tuple_body = misc_utility.bodyChecker(body, body_key_check_dict)
    list_body = tuple_body[1]
    # body check success
    if check_result:
        body_item_len = len(list_body)
        purchase_info = list_body[0]
        purchase_info_str = json.dumps(purchase_info)
        user = purchase_info['User']
        transType = purchase_info['Type']
        node_dns = data_service_host

        # check private key
        if body_item_len == 2:
            is_create = 1
            private_key = list_body[1]

            flag, hashSign, verify_message = crypto_utility.verify_private_key(user, private_key, data_service_host, '/users/sync/', purchase_info_str)
            if flag is False:
                api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "verify_private_key fail", "purchase_request_id": ""}}'
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']
        else:
            api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "verify_md5_signature fail", "purchase_request_id": ""}}'
            return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        if 'paymentMinStage' not in purchase_info:
            tuple_body[1][0]['paymentMinStage'] = 1
        if 'paymentMaxStage' not in purchase_info:
            tuple_body[1][0]['paymentMaxStage'] = 1
        
        purchase_info_tuple = (tuple_body[0],json.dumps(tuple_body[1][0]))

        # call api
        #old_purchase_batch = 'test'
        server_url = data_service_host +'/transactions/cache/'+transactions_type+'/'+purchase_type+'/'+old_purchase_batch+'?user=' + user + '&type=' + transType + '&hashSign=' + hashSign + '&is_create=' + str(is_create) + '&node_dns=' + node_dns
        http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'PUT', None, str(purchase_info_tuple))
        return '200 OK', [('Content-Type', 'text/html')], [json.dumps(api_result) + '\n']

    # body check fail
    else:
        api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s", "purchase_request_id": ""}}' % check_msg
        return '200 OK', [('Content-Type','text/html')], [api_result + '\n']

def goodsLogisticsRegister(data_service_host, query_string,body):
    pass


def goodsComments(data_service_host, query_string,body):
    pass


def goodsLogisticsSalerConfirm(data_service_host,query_string, body):
    pass


def goodsLogisticsBuyerConfirm(data_service_host,query_string, body):
    pass


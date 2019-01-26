# -*- coding: utf-8 -*-

import urlparse
import hashlib  

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
            check_result = 'check %s fail' % key
            break

    return return_flag, check_result


# parse url parameters
def parse_url(query_string):
    return urlparse.parse_qs(urlparse.urlparse(query_string).query)


def get_parameter(query_string_dict, key):
    return query_string_dict[key][0]


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




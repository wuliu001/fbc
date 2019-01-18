# -*- coding: utf-8 -*-

import urlparse
import hashlib  

# check body
def bodyChecker(body, body_key_check_dict):
    return_flag = True
    check_result = ''
    tuple_body = {}
    list_body = []
    
    if body[0:1] == '(':
        body = body.replace('"[','[').replace(']"',']')
        
    formated_body = eval(body)
    if isinstance(formated_body,list):
        list_body = formated_body
        tuple_body = ('null', formated_body)
    elif isinstance(formated_body,tuple):
        list_body = formated_body[1]
        tuple_body = formated_body
    else:
        return_flag = False
        check_result = 'body format error'
        return return_flag, check_result, tuple_body

    goods_body = list_body[0]
    goods_body_list_len = len(list_body)

    # check body list number cnt
    if goods_body_list_len == 1:
        return return_flag, check_result, tuple_body
    else:
        # check goods contents
        for key in body_key_check_dict:
            if key not in goods_body \
                    or (key != 'Type' and isinstance(goods_body[key],body_key_check_dict[key]) is False) \
                    or (key == 'Type' and body_key_check_dict[key] != goods_body[key]):
                return_flag = False
                check_result = 'check %s fail' % key
                break

        return return_flag, check_result, tuple_body


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




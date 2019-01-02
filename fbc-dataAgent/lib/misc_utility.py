# -*- coding: utf-8 -*-

import urlparse

# check body
def bodyChecker(body, body_key_check_dict):
    return_flag = True
    check_result = ''
    tuple_body = {}
    list_body = []

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
    if goods_body_list_len < 2 or goods_body_list_len > 3:
        return_flag = False
        check_result = 'body member count error'
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





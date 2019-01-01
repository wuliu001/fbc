# -*- coding: utf-8 -*-

import json
import urlparse

# check body
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


# parse url parameters
def parse_url(query_string):
    return urlparse.parse_qs(urlparse.urlparse(query_string).query)


def get_parameter(query_string_dict, key):
    return query_string_dict[key][0]





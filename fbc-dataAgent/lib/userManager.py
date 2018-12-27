# -*- coding: utf8 -*-

import urllib
import crypto_utility
import restful_utility
import json

def register(server_url, body):
    crypto_utility.unify_encoding()
    public_key, private_key = crypto_utility.get_key()
    body_list = [body]
    body_list.append(public_key)
    body_list.append(private_key)
    final_body = '|$|'.join(body_list)
    ds_url = server_url + '/users/insert'
    code, json_obj = restful_utility.restful_runner(ds_url, "POST", None, final_body)
    data = json.dumps(json_obj)
    return '200 OK', [('Content-Type','text/html')], [data + '\n']

# -*- coding: utf8 -*-

import urllib
import crypto_utility
import restful_utility
import json

def register(server_url, body):
    crypto_utility.unify_encoding()
    public_key, private_key = crypto_utility.get_key()
    ds_url = server_url + '/users/insert?pubkey='+urllib.quote(str(public_key))+'&prikey='+urllib.quote(str(private_key))
    code, json_obj = restful_utility.restful_runner(ds_url, "POST", None, body)
    data = json.dumps(json_obj)
    return '200 OK', [('Content-Type','text/html')], [data + '\n']
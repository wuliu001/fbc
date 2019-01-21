# -*- coding: utf8 -*-

import urllib
import crypto_utility
import restful_utility
import misc_utility
import json


def register(server_url, body):
    api_result = {"data": [{"private_key": "[private_key]"},{"publick_key": "[publick_key]"}], "moreResults": [], "ops": {"code": "[CODE]", "message": "[MSG]"}}
    print 'server_url',server_url
    #check body 
    body_key_check_dict = {"userAccount": str, "password": str,"trans_password": str, "corporationName": str, "owner": str, "address": str, \
                           "companyRegisterDate": str,"registeredCapital": str, "annualIncome": str, "telNum": str, "email": str}
    check_flag, check_msg = misc_utility.bodyTypeChecker(body, body_key_check_dict)
    if check_flag is False:
        api_result["ops"]["code"] = 400
        api_result["ops"]["message"] = check_msg
        api_result["data"][0]["private_key"]=''
        api_result["data"][1]["publick_key"]=''
        return '200 OK', [('Content-Type', 'text/html')], json.dumps(api_result)+'\n'

    #get userid
    format_body = eval(body)
    user_str = format_body['userAccount'] + format_body['owner']+ format_body['address']
    user = misc_utility.get_md5(user_str)
    print 'user',user
    #get publick_key and private_key
    crypto_utility.unify_encoding()
    public_key, private_key = crypto_utility.get_key()
    
    #set user private key to local
    http_code, api_code, json_obj = restful_utility.restful_runner(server_url + '/users/insert?user=' + user + '&trans_password='+format_body['trans_password'], "POST", None,private_key )
    if http_code != 200 :
        api_result["ops"]["code"] = 400
        api_result["ops"]["message"] = str(json_obj)
        api_result["data"][0]["private_key"]=''
        api_result["data"][1]["publick_key"]=''
        return http_code, [('Content-Type', 'text/html')], json.dumps(api_result)+'\n'  
    elif api_code != 200:
        api_result["ops"]["code"] = 400
        api_result["ops"]["message"] = json_obj["ops"]["message"]
        api_result["data"][0]["private_key"]=''
        api_result["data"][1]["publick_key"]=''
        return '200 OK', [('Content-Type', 'text/html')], json.dumps(api_result)+'\n'    

    #set user public info to user_center
    http_code, api_code, json_obj = restful_utility.restful_runner(server_url + '/user_center/insert?user=' + user, "POST", None,body)
    if http_code != 200 :
        api_result["ops"]["code"] = 400
        api_result["ops"]["message"] = str(json_obj)
        api_result["data"][0]["private_key"]=''
        api_result["data"][1]["publick_key"]=''
        return http_code, [('Content-Type', 'text/html')], json.dumps(api_result)+'\n' 
    elif api_code != 200:
        api_result["ops"]["code"] = 400
        api_result["ops"]["message"] = json_obj["ops"]["message"]
        api_result["data"][0]["private_key"]=''
        api_result["data"][1]["publick_key"]=''
        return '200 OK', [('Content-Type', 'text/html')], json.dumps(api_result)+'\n'

    #set user public key to blockchain
    

    #return final result
    api_result["ops"]["code"] = 200
    api_result["ops"]["message"] = 'OK'
    api_result["data"][0]["private_key"]= private_key
    api_result["data"][1]["publick_key"]= public_key
    return '200 OK', [('Content-Type', 'text/html')], json.dumps(api_result)+'\n'
    
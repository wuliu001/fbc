# -*- coding: utf8 -*-

import urllib
import crypto_utility
import restful_utility
import misc_utility
import json


def register(server_url, body):
    api_result = {"data": [], "moreResults": [], "ops": {"code": "[CODE]", "message": "[MSG]"}}
    print 'server_url',server_url
    #check body 
    body_key_check_dict = {"userAccount": str, "loginPassword": str,"txPassword": str,"corporationName": str, "owner": str, "address": str, \
                           "companyRegisterDate": str,"registeredCapital": str, "annualIncome": str, "telNum": str, "email": str}
    check_flag, check_msg = misc_utility.bodyTypeChecker(body, body_key_check_dict)
    if check_flag is False:
        api_result["ops"]["code"] = 400
        api_result["ops"]["message"] = check_msg
        return '200 OK', [('Content-Type', 'text/html')], json.dumps(api_result)+'\n'

    #get publick_key and private_key
    crypto_utility.unify_encoding()
    public_key, private_key = crypto_utility.get_key()

    #get accountAddress
    accountAddress = crypto_utility.encrypt_md5(public_key)
    print 'accountAddress',accountAddress

    #set format body
    format_body = eval(body)

    #set user private key to local
    http_code, api_code, json_obj = restful_utility.restful_runner(server_url + '/users/insert?accountAddress=' + accountAddress + '&trans_password='+format_body['trans_password'], "POST", None,private_key )
    if http_code != 200 :
        api_result["ops"]["code"] = 400
        api_result["ops"]["message"] = str(json_obj)
        return http_code, [('Content-Type', 'text/html')], json.dumps(api_result)+'\n'  
    elif api_code != 200:
        api_result["ops"]["code"] = 400
        api_result["ops"]["message"] = json_obj["ops"]["message"]
        return '200 OK', [('Content-Type', 'text/html')], json.dumps(api_result)+'\n'    

    #set user public info to user_center
    http_code, api_code, json_obj = restful_utility.restful_runner(server_url + '/user_center/insert?accountAddress=' + accountAddress, "POST", None,body)
    if http_code != 200 :
        api_result["ops"]["code"] = 400
        api_result["ops"]["message"] = str(json_obj)
        return http_code, [('Content-Type', 'text/html')], json.dumps(api_result)+'\n' 
    elif api_code != 200:
        api_result["ops"]["code"] = 400
        api_result["ops"]["message"] = json_obj["ops"]["message"]
        return '200 OK', [('Content-Type', 'text/html')], json.dumps(api_result)+'\n'

    #set user info to statedb
    statebody = {"publicKey":"[publicKey]","creditRating":0,"balance":0,"smartContractPrice":0,"minSmartContractDeposit":0,"nonce":0}
    statebody["publicKey"] = public_key
    http_code, api_code, json_obj = restful_utility.restful_runner(server_url + '/statedb/insert?accountAddress=' + accountAddress, "POST", None,statebody)
    if http_code != 200 :
        api_result["ops"]["code"] = 400
        api_result["ops"]["message"] = str(json_obj)
        return http_code, [('Content-Type', 'text/html')], json.dumps(api_result)+'\n' 
    elif api_code != 200:
        api_result["ops"]["code"] = 400
        api_result["ops"]["message"] = json_obj["ops"]["message"]
        return '200 OK', [('Content-Type', 'text/html')], json.dumps(api_result)+'\n'

    #return final result
    api_result["ops"]["code"] = 200
    api_result["ops"]["message"] = 'OK'
    return '200 OK', [('Content-Type', 'text/html')], json.dumps(api_result)+'\n'
    
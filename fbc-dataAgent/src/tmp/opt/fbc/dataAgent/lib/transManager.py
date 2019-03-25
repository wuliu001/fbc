# -*- coding: utf8 -*-

import urllib
import crypto_utility
import restful_utility
import misc_utility
import json


def transaction_register(tx_type, data_service_host, query_string, body):
    if tx_type == 'vendition':
        tx_key_check_dict = {"User": str, "Recipient": str, "Type": "vendition", "Varieties": str, "placeOfProduction": str, "dateOfMature": str, \
                            "dateOfProduction": str, "appearanceRating": int,"sizeRating": int, "sweetnessRating": int, "minQuantity": float, \
                            "maxQuantity": float, "Price": float, "countryOfIssuingLocation": str, "provinceOfIssuingLocation": str, \
                            "cityOfIssuingLocation": str, "zoneOfIssuingLocation": str, "addressOfIssuingLocation": str, "dateOfReqBegin": str, \
                            "dateOfReqEnd": str, "paymentMinStage":int, "paymentMaxStage": int, "request_timestemp": str}
    elif tx_type == 'purchase':
        tx_key_check_dict = {"User": str, "Recipient": str, "Type": "purchase", "Varieties": str, "placeOfProduction": str, "dateOfMature": str, \
                            "dateOfProduction": str, "appearanceRating": int,"sizeRating": int, "sweetnessRating": int, "minQuantity": float, \
                            "maxQuantity": float, "Price": float, "countryOfDeliveryLocation": str, "provinceOfDeliveryLocation": str, \
                            "cityOfDeliveryLocation": str, "zoneOfDeliveryLocation": str, "addressOfDeliveryLocation": str, \
                            "dateOfReqEnd": str, "paymentMinStage":int, "paymentMaxStage": int, "request_timestemp": str}

    tx_detail_str = body.split('}')[0][1:]+'}'
    formated_body = eval(body)
    # body check
    check_result, check_msg = misc_utility.bodyChecker(formated_body, tx_key_check_dict)

    # body check success
    if check_result:
        body_item_length = len(formated_body)
        tx_detail = formated_body[0]
        normal_account_address = tx_detail['User']
        smart_contract_address = tx_detail['Recipient']

        # get normal account's public_key, balance, nonce
        flag, public_key, balance, original_nonce, return_msg = misc_utility.get_account_basicInfo(data_service_host,normal_account_address)
        if flag is False:
            api_result = json.dumps(return_msg)
            return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        # get smartcontract account's gasRequest
        flag, smartcontract_gasCost, smartcontract_gasDeposit, return_msg = misc_utility.get_account_gasRequest(data_service_host,smart_contract_address,1)
        if flag is False:
            api_result = json.dumps(return_msg)
            return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']
        smartcontract_gasRequest = smartcontract_gasCost + smartcontract_gasDeposit

        # get normal account's gasRequest from pending packing transactions
        flag, txcache_account_gasCost, txcache_account_gasDeposit, return_msg = misc_utility.get_account_gasRequest(data_service_host,normal_account_address)
        if flag is False:
            api_result = json.dumps(return_msg)
            return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']
        txcache_account_gasRequest = txcache_account_gasCost + txcache_account_gasDeposit

        # get normal account's gasRequest from pending blocking transactions & pending matching contract transactions
        flag, packing_account_gasCost, packing_account_gasDeposit, return_msg = misc_utility.get_account_gasRequest(data_service_host, normal_account_address,0,1)
        if flag is False:
            api_result = json.dumps(return_msg)
            return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']
        packing_account_gasRequest = packing_account_gasCost + packing_account_gasDeposit

        # check whether the account's balance is enough to start a transaction
        if (balance - txcache_account_gasRequest - packing_account_gasRequest) < smartcontract_gasRequest:
            err_msg = "account's balance is not enough to start a transaction!"
            api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s"}}' % err_msg
            return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        # get parameter
        query_string_dict = misc_utility.parse_url('?' + query_string)
        if 'is_broadcast' in query_string_dict.keys():
           is_broadcast = int(misc_utility.get_parameter(query_string_dict, 'is_broadcast'))
        else:
            is_broadcast = 0
        
        if 'txAddress' in query_string_dict.keys():
            # vendition/purchase modify
            txAddress = misc_utility.get_parameter(query_string_dict, 'txAddress')
            server_url = data_service_host + '/tx_cache/' + txAddress + '/detail'
            http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'GET', None, '')
            if http_code == 200 and api_code == 200:
                current_nonce = api_result["data"][0]["nonceForCurrentInitiator"]
                # get user's current packing nonce
                server_url = data_service_host + '/users/' + normal_account_address + '/nonce'
                http_code, api_code, return_msg = restful_utility.restful_runner(server_url, 'GET', None, '')
                if http_code == 200 and api_code == 200:
                    current_packing_nonce = api_result["data"][0]["current_packing_nonce"]
                    if current_packing_nonce > current_nonce:
                        err_msg = 'nonce check failed, cannot modify this transaction.'
                        api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s"}}' % err_msg
                        return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']
                else:
                    api_result = json.dumps(return_msg)
                    return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']
            else:
                err_msg = 'verify txAddress fail.'
                api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s"}}' % err_msg
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']
        else:
            txAddress = ''

        if body_item_length == 2 and is_broadcast == 0:
            tx_password = formated_body[1]
            # get normal account's private_key
            flag, private_key, return_msg = misc_utility.get_account_privateKey(data_service_host,normal_account_address,tx_password)
            if flag is False:
                api_result = json.dumps(return_msg)
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

            # ues private key generate hashSign
            flag, hashSign, verify_message = misc_utility.get_hashsign(public_key,private_key,tx_detail_str)
            if flag is False:
                api_result = verify_message
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

            if txAddress == '':
                # get nonce from pending handle transactions
                flag, account_current_nonce, return_msg = misc_utility.get_pending_handle_account_maxNonce(data_service_host,normal_account_address)
                if flag is False:
                    api_result = json.dumps(return_msg)
                    return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

                # generate new nonce
                nonce = account_current_nonce + 1
            else:
                nonce = 0

        elif body_item_length == 3 and is_broadcast == 1:
            hashSign = formated_body[1]
            nonce = formated_body[2]
            # check hashSign using public key
            flag, verify_message = misc_utility.check_md5_signature(public_key,hashSign,tx_detail_str)
            if flag is False:
                api_result = verify_message
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

            # get nonce from pending handle transactions
            flag, account_current_nonce, return_msg = misc_utility.get_pending_handle_account_maxNonce(data_service_host,normal_account_address)
            if flag is False:
                api_result = json.dumps(return_msg)
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

            # check nonce
            if nonce <= account_current_nonce:
                err_msg = "nonce check error! nonce in body: %d, account_current_nonce: %d" % (nonce, account_current_nonce)
                api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s"}}' % err_msg
                return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        else:
            err_msg = "is_broadcast parameter value error!"
            api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s"}}' % err_msg
            return '200 OK', [('Content-Type', 'text/html')], [api_result + '\n']

        # record into pending transaction
        server_url = data_service_host + '/tx_cache/' + normal_account_address + '/transaction' + '?type=' + tx_type + \
                     '&hashSign=' + hashSign + '&gasCost=' + str(smartcontract_gasCost) + '&gasDeposit=' + str(smartcontract_gasDeposit) + \
                     '&receiver=' + smart_contract_address + '&original_nonce=' + original_nonce + '&current_nonce=' + str(nonce) + \
                     '&is_broadcast=' + str(is_broadcast) + '&old_txAddress=' + txAddress
        http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'POST', None, tx_detail_str)
        return '200 OK', [('Content-Type', 'text/html')], [json.dumps(api_result) + '\n']

    # body check fail
    else:
        api_result = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "%s"}}' % check_msg
        return '200 OK', [('Content-Type','text/html')], [api_result + '\n']



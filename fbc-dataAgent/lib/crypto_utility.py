# -*- coding: utf-8 -*-

from Crypto import Random
from Crypto.PublicKey import RSA
from Crypto.Hash import SHA
from Crypto.Cipher import PKCS1_v1_5 as Cipher_PKCS1_v1_5
from Crypto.Signature import PKCS1_v1_5 as Signature_pkcs1_v1_5
import restful_utility
import hashlib
import base64
import sys
import json
import re

# unify the sys defult encoding
def unify_encoding():
    if sys.getdefaultencoding() != 'utf-8':
        reload(sys)
        sys.setdefaultencoding('utf-8')

# rsa generate instance
def get_key():
    rsa = RSA.generate(1024, Random.new().read)
    # master private key pair generate
    private_pem = rsa.exportKey()
    public_pem = rsa.publickey().exportKey()

    return public_pem.decode(), private_pem.decode()

# using pub key encode
def rsa_encode(message, public_key):
    rsakey = RSA.importKey(public_key)  # import pub key
    cipher = Cipher_PKCS1_v1_5.new(rsakey)  # generate object
    cipher_text = base64.b64encode(
        cipher.encrypt(message.encode(encoding="utf-8")))
    return cipher_text.decode()


# using private key decode
def rsa_decode(cipher_text, private_key):
    rsakey = RSA.importKey(private_key)  
    cipher = Cipher_PKCS1_v1_5.new(rsakey)  
    text = cipher.decrypt(base64.b64decode(cipher_text), "ERROR")
    return text.decode()

# string md5 function
def encrypt_md5(message):
    md = hashlib.md5() 
    md.update(message.encode(encoding='utf-8'))
    return md.hexdigest()

# using private key sign
def sign_encode(message, private_key):
    rsakey = RSA.importKey(private_key)
    signer = Signature_pkcs1_v1_5.new(rsakey)
    digest = SHA.new()
    digest.update(encrypt_md5(message))
    sign = signer.sign(digest)
    signature = base64.b64encode(sign)
    return signature

# using pub key check
def sign_check(message, signature, public_key):
    rsakey = RSA.importKey(public_key)
    verifier = Signature_pkcs1_v1_5.new(rsakey)
    digest = SHA.new()
    # Assumes the data is base64 encoded to begin with
    digest.update(encrypt_md5(message))
    is_verify = verifier.verify(digest, base64.b64decode(signature))
    return is_verify

# verify private key
def verify_private_key(user, private_key, data_service_host, data_service_uri, goods_info):
    flag = False
    hashSign = ''
    verify_message = ''

    if re.search('-----BEGIN RSA PRIVATE KEY-----', private_key) and re.search('-----END RSA PRIVATE KEY-----', private_key):
        # get user public key
        server_url = data_service_host + data_service_uri + user
        http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'GET', None, '')
        if http_code != 200 or api_code != 200:
            verify_message = json.dumps(api_result)
        else:
            public_key = api_result["data"][0]["public_key"]
            hashSign = sign_encode(goods_info, private_key)
            is_verify = sign_check(goods_info, hashSign, public_key)
            if is_verify:
                flag = True
            else:
                verify_message = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "public key and private key mis-match", "goods_batch_id": ""}}'
    else:
        verify_message = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "private key format error", "goods_batch_id": ""}}'

    return flag, hashSign, verify_message


# verify md5 signature
def verify_md5_signature(user, hashSign, data_service_host, data_service_uri, node_dns, goods_info):
    flag = False
    verify_message = ''

    server_url = data_service_host + data_service_uri + user
    http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'GET', None, '')
    if http_code != 200 or (api_code != 200 and api_code != 511):
        verify_message = json.dumps(api_result)
        return flag, verify_message

    if api_code == 200:
        public_key = api_result["data"][0]["public_key"]
        if sign_check(goods_info, hashSign, public_key) is False:
            verify_message = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "md5 signature and hash not match", "goods_batch_id": ""}}'
            return flag, verify_message
        else:
            flag = True

    if api_code == 511:
        # get user public key
        server_url = node_dns + data_service_uri + user
        http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'GET', None, '')
        if http_code != 200 or api_code != 200:
            verify_message = json.dumps(api_result)
            return flag, verify_message

        public_key = api_result["data"][0]["public_key"]
        if sign_check(goods_info, hashSign, public_key):
            # create user in current node
            server_url = data_service_host + data_service_uri + user
            http_code, api_code, api_result = restful_utility.restful_runner(server_url, 'POST', None, public_key)
            if http_code != 200 or api_code != 200:
                verify_message = json.dumps(api_result)
                return flag, verify_message

            flag = True

        else:
            verify_message = '{"data": [], "moreResults": [], "ops": {"code": 400, "message": "md5 signature and hash not match", "goods_batch_id": ""}}'
            return flag, verify_message

    return flag, verify_message


if __name__ == '__main__':
    unify_encoding()
    message = "Hello World"

    public_key, private_key = get_key()
    print 'public_key:'
    print public_key
    print 'private_key:'
    print private_key
    
    cipher = rsa_encode(message, public_key)
    print 'cipher:'
    print(cipher)

    msg = rsa_decode(cipher, private_key)
    print 'msg:'
    print(msg)
    
    print 'md5:'
    print encrypt_md5(message)
    
    signature = sign_encode(message, private_key)
    print 'signature:'
    print(signature)
    
    is_verify = sign_check(message, signature, public_key)
    print 'is_verify:'
    print(is_verify)

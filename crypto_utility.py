# -*- coding: utf-8 -*-

from Crypto import Random
from Crypto.PublicKey import RSA
from Crypto.Hash import SHA
from Crypto.Cipher import PKCS1_v1_5 as Cipher_PKCS1_v1_5
from Crypto.Signature import PKCS1_v1_5 as Signature_pkcs1_v1_5
import hashlib
import base64
import sys

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

'''
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
'''

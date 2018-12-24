# -*- coding: utf8 -*-

#import sys
import crypto_utility

def register(body):
    crypto_utility.unify_encoding()
    public_key, private_key = crypto_utility.get_key()
    data = str(public_key)+'\n'+str(private_key)
    return '200 OK', [('Content-Type','text/html')], [data + '\n'], 
# -*- coding: utf8 -*-

import mysql.connector.pooling
import urllib
import json
import sys
import re
import time
import datetime
import uuid

g_retry_cnt = 1000
g_chunk_threshold = 2000000
g_chunk_size = 100000

def usage():
    return """Usage: /mysql/proc?f=json&d=1&n=name&i=v1&i=v2&i=v3&o=n1&o=n2&pi=1<p> 
Arguments:<p>
-i means input args. <p>
-o means output arg names <p>
-n means the name of the procedure. Note that input args should be ahead of all output args.<p>
-pi is the index of input param (from 1) where HTTP body should be put.<p>
-f means response format (jdct).<p>
"""

# Analysis Query String
def analysis_query_string(args):
    name = re.findall("n=([^&]*)", args)
    if len(name) == 0:
        name = None
    else:
        name = name[0]

    ops = [urllib.unquote(x) for x in re.findall("&o=([^&]*)", args)]

    ips = [urllib.unquote(x) for x in re.findall("&i=([^&]*)", args)]

    bodyPos = re.findall("&pi=([^&]*)", args)
    if len(bodyPos) == 0:
        bodyPos = None
    else:
        bodyPos = int(bodyPos[0]) - 1
    
    return name, ips, ops, bodyPos

# MySQL Connection Create
def mysql_connection(host, port, user, passwd, db, ps):
    dbconfig = {
        "user":       user,  
        "password":   passwd,  
        "host":       host,  
        "port":       port,  
        "database":   db,  
        "charset":    "utf8"  
    }  
    try:
        if ps <= 32:
            mysql.connector.pooling.CNX_POOL_MAXSIZE = 32
        else:
            mysql.connector.pooling.CNX_POOL_MAXSIZE = ps
       
        cnxpool = mysql.connector.pooling.MySQLConnectionPool(pool_name = "mypool", pool_size=ps, pool_reset_session=True, **dbconfig)
        return cnxpool
    except Exception as e:
        print e
        return None

# MySQL Pooling Management
def mysql_pooling_begin(cnxpool):
    try:
        cnx = cnxpool.get_connection() 
        #cnxpool.add_connection()
        cnx.autocommit = True 
        cursor = cnx.cursor()
        return cursor, cnx
    except Exception as e:
        print e
        return None, None

def mysql_pooling_end(cur, conn):
    try:
        cur.close()  
        conn.commit()  
        conn.close()
        #time.sleep(0.1)
        return 0
    except Exception as e:
        print e
        return 1

# Run Procedure
def procedure(cur,conn, proc_name, is_chunk, bodyPos, proc_para, proc_out):
    try:
        final_result = {}

        proc_o = ["@_op_%s" % x for x in proc_out]
        if is_chunk == 0:
            proc_header = "CALL " + str(proc_name) + "(" + ",".join(["%s"] * len(proc_para) + proc_o) +")"
        else:
            proc_header = "CALL " + str(proc_name) + "(" + ",".join(["%s"] * bodyPos + ["commons.`body_chunk.get`(%s)"] + ["%s"] * (len(proc_para)-bodyPos-1) + proc_o) +")"
        #print proc_header, str(tuple(proc_para))
        rtn = []
        rtn_more = []
        cnt = 1
        for result in cur.execute(proc_header, tuple(proc_para), multi=True):
            index = list(cur.column_names)
            rtn_one = []
            if result.with_rows:
                for res_tuple in result:
                    res = list(res_tuple)
                    row = {}
                    for i in list(range(len(index))):
                        one_val = res[i]
                        one_val_type = str(type(one_val))
                        if one_val_type.find('datetime.datetime') >= 0:
                            one_val = str(one_val).replace(' ','T')
                        elif one_val_type.find('bytearray') >= 0:
                            one_val = str(one_val)
                        row[index[i]] = one_val
                    if cnt == 1:
                        rtn.append(row)
                    else:
                        rtn_one.append(row)
                if cnt != 1:
                    rtn_more.append(rtn_one)
            cnt = cnt + 1
        final_result["data"] = rtn
        final_result["moreResults"] = rtn_more
    
        row = {}
        if proc_out:
            sqlStr = "SELECT %s" % ",".join(["@_op_%s" % x for x in proc_out])
            cur.execute(sqlStr)
            ops = list(cur.fetchone())
            for i in list(range(len(proc_out))):
                row[proc_out[i]] = ops[i]
        final_result["ops"] = row
        return json.dumps(final_result), 0
    except Exception, e:
        return str(e), 1

def handle_body(cur, conn, body):
    body_len = len(body)
    if body_len <= g_chunk_threshold:
        return 0, body
    else:
        uuid_str = str(uuid.uuid1()) + '-' + str(uuid.uuid4())
        str_list = []
        loop_cnt = 0
        for body_chunk in re.findall(r'.{'+str(g_chunk_size)+'}', body.replace('\n','').replace('\r','')):
            loop_cnt = loop_cnt + 1
            str_tuple = (uuid_str, loop_cnt, body_chunk)
            stmt = "CALL commons.`body_chunk.insert`(%s, %s, %s)"
            for result in cur.execute(stmt, tuple(str_tuple), multi=True):
                tmp = ''
                # print str(result.with_rows), loop_cnt
        
        str_tuple = (uuid_str, loop_cnt+1, body[g_chunk_size*loop_cnt:])
        stmt = "CALL commons.`body_chunk.insert`(%s, %s, %s)"
        for result in cur.execute(stmt, tuple(str_tuple), multi=True):
            tmp = ''
            # print str(result.with_rows), loop_cnt+1
        #conn.commit()
        return 1, uuid_str

def del_chunk(cur, is_chunk, uuid):
    if is_chunk == 1:
        stmt = "CALL commons.`body_chunk.delete`('" + uuid + "')"
        for result in cur.execute(stmt, multi=True):
            tmp = ''
        #print 1

def main(env, dbconnect, method, query_string, host, port, user, pwd, db_n, pool_size):
    usage_info = usage()

    if dbconnect is None:
        #start_response('520 DB Connect Failed', [('Content-Type','text/html')])
        return '520 DB Connect Failed', [('Content-Type','text/html')], ['DB Connect Failed\n']

    cur, pool = mysql_pooling_begin(dbconnect)

    cur_cnt = 0
    while cur is None and cur_cnt < g_retry_cnt:
        dbconnect = mysql_connection(host, port, user, pwd, db_n, pool_size)

        dbconn_cnt = 0
        while dbconnect is None and dbconn_cnt < g_retry_cnt:
            dbconnect = mysql_connection(host, port, user, pwd, db_n, pool_size)
            dbconn_cnt = dbconn_cnt + 1
            print "Retry dbconnect number:"+str(dbconn_cnt)

        cur, pool = mysql_pooling_begin(dbconnect)
        cur_cnt = cur_cnt + 1
        print "Retry pooling begin number:"+str(cur_cnt)

    if cur_cnt >= g_retry_cnt:
        #start_response('521 Mysql Pooling Failed', [('Content-Type','text/html')])
        return '521 Mysql Pooling Failed', [('Content-Type','text/html')], ['DB Connect Failed\n']

    proc_name, proc_para, proc_out, bodyPos = analysis_query_string(query_string)
    if proc_name is None:
        #start_response('420 No Proc Name', [('Content-Type','text/html')])
        return '420 No Proc Name', [('Content-Type','text/html')], [usage_info + '\n']

    data = ''
    is_chunk = 0
    if method == 'POST' or method == 'PUT':
        body = env['wsgi.input'].read()
        if (bodyPos is not None) and len(proc_para) > bodyPos:
            is_chunk, proc_para[bodyPos] = handle_body(cur, pool, body)

    data, code = procedure( cur,pool, proc_name, is_chunk, bodyPos, proc_para, proc_out)

    proc_cnt = 0
    if code !=0 and proc_cnt < g_retry_cnt:
        dbconnect = mysql_connection(host, port, user, pwd, db_n, pool_size)
        dbconn_cnt = 0
        while dbconnect is None and dbconn_cnt < g_retry_cnt:
            dbconnect = mysql_connection(host, port, user, pwd, db_n, pool_size)
            dbconn_cnt = dbconn_cnt + 1
            print "Retry dbconnect number:"+str(dbconn_cnt)

        cur, pool = mysql_pooling_begin(dbconnect)
        
        data, code = procedure( cur,pool, proc_name, is_chunk, bodyPos, proc_para,proc_out)
        proc_cnt = proc_cnt + 1
        print "Retry run procedure number:"+str(proc_cnt)
    
    if proc_cnt >= g_retry_cnt:
        return_code = '500'
        return_msg = data
        if is_chunk == 1:
            del_chunk(cur, is_chunk, proc_para[bodyPos])
        #start_response(return_code+' '+return_msg, [('Content-Type','text/html')])
        return return_code+' '+return_msg, [('Content-Type','text/html')], [data + '\n']
    
    if is_chunk == 1:
        del_chunk(cur, is_chunk, proc_para[bodyPos])
    
    end_result = mysql_pooling_end(cur, pool)

    commit_cnt = 0
    while end_result != 0 and commit_cnt < g_retry_cnt:
        end_result = mysql_pooling_end(cur, pool)
        commit_cnt = commit_cnt + 1
        #time.sleep(0.01)
        print "Retry pooling end number:"+str(commit_cnt)

    if commit_cnt >= g_retry_cnt:
        #start_response('522 Mysql Pooling Commit Failed', [('Content-Type','text/html')])
        return '522 Mysql Pooling Commit Failed', [('Content-Type','text/html')], ['DB Connect Failed\n']

    if code == 0:
        #json_ops = json.loads(data)['ops']

        #return_code = None
        #if json_ops.has_key('code'):
        #    return_code = str(json_ops['code'])
        #if return_code is None:
        return_code = '200'

        #return_msg = None
        #if json_ops.has_key('message'):
        #    return_msg = str(json_ops['message'])
        #if return_msg is None:
        return_msg = 'OK'
    elif code == 1:
        return_code = '500'
        return_msg = data

    #start_response(return_code+' '+return_msg, [('Content-Type','text/html')])
    return return_code+' '+return_msg, [('Content-Type','text/html')], [data + '\n']
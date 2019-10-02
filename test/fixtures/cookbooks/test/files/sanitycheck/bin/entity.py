# Copyright (C) 2005-2011 Splunk Inc.  All Rights Reserved.  Version 4.0
# 

import os,time
import splunk
import splunk.entity as en
import splunk.auth as sa
import splunk.Intersplunk as si
import logging as logger

logger.basicConfig(level=logger.INFO, format='%(asctime)s %(levelname)s %(message)s',
                   filename=os.path.join(os.environ['SPLUNK_HOME'],'var','log','splunk','entity.log'),
                   filemode='a')


def entityToResult(name, entity):
    result = {}
    
    if '_raw' not in entity:
        result['_raw'] = name
    if '_time' not in  entity:
        result['_time'] = time.time()
        
    for key, val in entity.items():
        valclass = val.__class__.__name__
        if valclass == 'dict':
            val = str(val)
        result[key] = val

    return result


def usage():
    si.generateErrorResults("Usage: entity <endpoint>")
    exit(0)

def execute():
    results = []
    try:
        results,dummyresults,settings = si.getOrganizedResults()

        # default values
        args = { 'namespace':'search'}
        # get commandline args
        keywords, options = si.getKeywordsAndOptions()
        # override default args with settings from search kernel 
        args.update(settings)
        # override default args with commandline args
        args.update(options)
        
        sessionKey = args.get("sessionKey", None)
        owner      = args.get("owner", 'admin')
        namespace  = args.get("namespace", None)


        if namespace.lower() == "none":
            namespace = None

        messages = {}

        if sessionKey == None:
            # this shouldn't happen, but it's useful for testing.
            try:
                sessionKey = sa.getSessionKey('admin', 'changeme')
                si.addWarnMessage(messages,  "No session given to 'tune' command. Using default admin account and password.")
            except splunk.AuthenticationFailed, e:
                si.addErrorMessage(messages, "No session given to 'tune' command.")
                return

        if len(keywords) != 1:
            usage()
            
        # e.g., '/data/inputs/monitor'
        entity = keywords[0]
        logger.info("Entity: %s Args: %s" % (entity, args))
        
        results = [] # we don't care about incoming results
        try:
            entitys = en.getEntities(entity, sessionKey=sessionKey, owner=owner, namespace=namespace, count=-1)
            for name, entity in entitys.items():
                try:
                    myapp = entity["eai:acl"]["app"]
                    if namespace != None and myapp != namespace:
                        continue
                except:
                    continue # if no eai:acl/app, filter out
                result = entityToResult(name, entity)
                results.append(result)
        except splunk.ResourceNotFound,e2:
            pass
        si.outputResults(results, messages)
    except Exception, e:
        import traceback
        stack =  traceback.format_exc()
        logger.error(str(e) + ". Traceback: " + str(stack))
        si.generateErrorResults(str(e))
        
if __name__ == '__main__':
    execute()

# Copyright (C) 2005-2011 Splunk Inc.  All Rights Reserved.  Version 4.0

import splunk.Intersplunk as si
import splunk.searchhelp.utils as parseutils
import re

def usage():
    si.generateErrorResults("Usage: searchstats <field>")
    exit(0)

def getStats(result, search):
    commands = parseutils.getJustCommands(search, None)
    for command in commands:
        field = "%s_count" % command
        result[field] = result.get(field, 0) + 1
    for keyword in ["OR", "NOT", "AND"]:
        result['%s_count' % keyword] = search.count(" %s " % keyword)
    result['unknown_tokens'] = getUnknown(search)

g_known_keywords = set(['abs', 'abstract', 'accum', 'action', 'add', 'addinfo', 'addtime', 'addtotals', 'af', 'agg', 'allnum', 'allowempty', 'allrequired', 'and', 'annotate', 'anomalies', 'anomalousvalue', 'append', 'appendcols', 'as', 'associate', 'attr', 'attribute', 'attrn', 'audit', 'auto', 'autoregress', 'avg', 'bcc', 'bins', 'blacklist', 'blacklistthreshold', 'bottom', 'bucket', 'bucketdir', 'buffer_span', 'by', 'c', 'case', 'cb', 'cc', 'cfield', 'chart', 'chunk', 'chunksize', 'cidrmatch', 'cityblock', 'classfield', 'clean_keys', 'cluster', 'cmd', 'coalesce', 'cocur', 'col', 'collapse', 'collect', 'commands', 'concurrency', 'connected', 'consecutive', 'cont', 'context', 'contingency', 'convert', 'copyattrs', 'copyresults', 'correlate', 'cos', 'cosine', 'count', 'counterexamples', 'countfield', 'crawl', 'createinapp', 'createrss', 'cs', 'csv', 'ctime', 'current', 'd', 'day', 'days', 'daysago', 'dbinspect', 'dc', 'dd', 'debug', 'dedup', 'default', 'delete', 'delim', 'delims', 'delta', 'desc', 'descr', 'dest', 'dictionary', 'diff', 'discard', 'dispatch', 'distinct', 'ds', 'dt', 'dur', 'duration', 'earlier', 'editinfo', 'ema', 'end', 'end_time', 'enddaysago', 'endhoursago', 'endminutesago', 'endmonthsago', 'endswith', 'endtime', 'erex', 'eval', 'eventcount', 'events', 'eventstats', 'eventtype', 'eventtypetag', 'exact', 'examples', 'exp', 'extract', 'false', 'field', 'fieldname', 'fields', 'file', 'fillnull', 'filter', 'findtypes', 'first', 'floor', 'folderize', 'forceheader', 'form', 'format', 'from', 'fromfield', 'gentimes', 'global', 'graceful', 'h', 'head', 'header', 'hh', 'high', 'highest', 'highlight', 'hilite', 'host', 'hosts', 'hosttag', 'hour', 'hours', 'hoursago', 'hr', 'hrs', 'html', 'iconify', 'id', 'if', 'ifnull', 'improv', 'in', 'increment', 'index', 'inline', 'inner', 'input', 'inputcsv', 'inputlookup', 'internalinputcsv', 'intersect', 'ip', 'iplocation', 'iqr', 'isbool', 'isint', 'isnotnull', 'isnull', 'isnum', 'isstr', 'join', 'k', 'keepempty', 'keepevents', 'keepevicted', 'keeplast', 'keepsingle', 'keyset', 'kmeans', 'kvform', 'l', 'label', 'labelfield', 'labelonly', 'last', 'left', 'len', 'like', 'limit', 'link', 'list', 'ln', 'loadjob', 'local', 'localize', 'localop', 'log', 'logchange', 'lookup', 'loop', 'low', 'lower', 'lowest', 'ltrim', 'm', 'makecontinuous', 'makemv', 'map', 'mappy', 'marker', 'match', 'max', 'max_buffer_size', 'max_match', 'max_time', 'maxchars', 'maxcols', 'maxcount', 'maxevents', 'maxfolders', 'maxinputs', 'maxiters', 'maxlen', 'maxlines', 'maxopenevents', 'maxopentxn', 'maxout', 'maxpause', 'maxresolution', 'maxresults', 'maxrows', 'maxsample', 'maxsearches', 'maxspan', 'maxterms', 'maxtime', 'maxtrainers', 'maxvalues', 'md', 'mean', 'median', 'memk', 'metadata', 'min', 'mincolcover', 'minfolders', 'minrowcover', 'mins', 'minute', 'minutes', 'minutesago', 'mktime', 'mm', 'mode', 'mon', 'month', 'months', 'monthsago', 'ms', 'msg_debug', 'msg_error', 'msg_info', 'msg_warn', 'mstime', 'multikv', 'multitable', 'mv_add', 'mvappend', 'mvcombine', 'mvcount', 'mvexpand', 'mvfilter', 'mvindex', 'mvjoin', 'mvlist', 'name', 'newseriesfilter', 'ngramset', 'noheader', 'nokv', 'nomv', 'none', 'norm', 'normalize', 'nosubstitution', 'not', 'notcovered', 'notin', 'now', 'null', 'nullif', 'nullstr', 'num', 'optimize', 'or', 'otherstr', 'outer', 'outfield', 'outlier', 'output', 'outputatom', 'outputcsv', 'outputlookup', 'outputraw', 'outputrawr', 'outputtext', 'overlap', 'override', 'overwrite', 'p', 'param', 'partial', 'path', 'pathfield', 'perc', 'percentfield', 'perl', 'pi', 'position', 'pow', 'prefix', 'priority', 'private', 'pthresh', 'public', 'python', 'random', 'range', 'rangemap', 'rare', 'raw', 'rawstats', 'readlevel', 'reducepy', 'regex', 'relative_time', 'relevancy', 'reload', 'remove', 'rename', 'replace', 'reps', 'resample', 'rescan', 'reverse', 'rex', 'rm', 'rmcomma', 'rmorig', 'rmunit', 'roll', 'round', 'row', 'rtorder', 'rtrim', 's', 'sample', 'savedsearch', 'savedsplunk', 'script', 'scrub', 'search', 'searchkeys', 'searchmatch', 'searchtimespandays', 'searchtimespanhours', 'searchtimespanminutes', 'searchtimespanmonths', 'sec', 'second', 'seconds', 'secs', 'sed', 'segment', 'select', 'selfjoin', 'sendemail', 'sep', 'server', 'set', 'setfields', 'setsv', 'showargs', 'showcount', 'showlabel', 'showperc', 'sichart', 'sid', 'singlefile', 'sirare', 'sistats', 'sitimechart', 'sitop', 'size', 'sizefield', 'sleep', 'sma', 'sort', 'sortby', 'source', 'sources', 'sourcetype', 'sourcetypes', 'span', 'spawn_process', 'split', 'spool', 'sq', 'sqeuclidean', 'sqrt', 'ss', 'start', 'start_time', 'startdaysago', 'starthoursago', 'startminutesago', 'startmonthsago', 'startswith', 'starttime', 'starttimeu', 'stats', 'stdev', 'stdevp', 'str', 'strcat', 'streamedcsv', 'streamstats', 'strftime', 'strptime', 'substr', 'sum', 'summary', 'sumsq', 'supcnt', 'supfreq', 'surrounding', 'sync', 't', 'table', 'tag', 'tagcreate', 'tagdelete', 'tags', 'tagset', 'tail', 'termlist', 'terms', 'termset', 'testmode', 'text', 'tf', 'threshold', 'time', 'timeafter', 'timebefore', 'timechart', 'timeconfig', 'timeformat', 'timeout', 'to', 'tokenizer', 'tol', 'top', 'tostring', 'totalstr', 'transaction', 'transform', 'transpose', 'trendline', 'trim', 'true', 'ttl', 'type', 'typeahead', 'typelearner', 'typeof', 'typer', 'union', 'uniq', 'untable', 'upper', 'urldecode', 'us', 'uselower', 'usenull', 'useother', 'useraw', 'usetime', 'usetotal', 'usexml', 'validate', 'value', 'values', 'var', 'varp', 'where', 'window', 'with', 'wma', 'xmlkv', 'xmlunescape', 'xor', 'xpath', 'xyseries', 'yy'])

MAJOR_TOKENIZER = re.compile("[][<>(){}|!;,'\"*\n\r\s\t&?=]+")           # 'added = to prevent foo=bar as a value

def getUnknown(search):
    majortokens = set(re.split(MAJOR_TOKENIZER, search))
    return [token for token in majortokens if not token.isdigit() and token not in g_known_keywords and len(token)>1]

    
if __name__ == '__main__':
    try:
        keywords,options = si.getKeywordsAndOptions()
        results,dumb1, dumb2 = si.getOrganizedResults()
        messages = {}

        field = 'search'
        if len(keywords) == 1:
            field = keywords[0]
        elif len(keywords) > 1:
            usage()

        for result in results:
            search = result.get(field, None)
            if search != None:
                getStats(result, search)

        si.outputResults(results, messages)
    except Exception, e:
        import traceback
        stack =  traceback.format_exc()
        logger.error("%s" % e)
        logger.info("Traceback: %s" % stack)
        si.generateErrorResults("Error '%s'" % e)

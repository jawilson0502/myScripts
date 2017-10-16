#!/usr/bin/python
"""Script to parse through my website log to pull out valid visitors"""

import json
import re
import time
import urllib

import requests

#from IPython import embed

LOG_PATH = "/var/log/nginx/access.log"
OUTPUT_PATH = "/home/serenity/weblogs/%s.txt" % time.strftime("%Y%m%d")

with open(LOG_PATH, "r") as f:
    log_file = f.read()

log_file = log_file.splitlines()

logs = {}
for log in log_file:
    fields = log.split()
    if len(fields) < 11:
        continue
    if fields[0] in logs.keys():
        logs[fields[0]]['page'].append(fields[6])
    else:
        fields_dict = {}
        fields_dict['date'] = ' '.join(fields[3:5])
        fields_dict['rest'] = fields[5]
        fields_dict['page'] = [fields[6]]
        fields_dict['status_code'] = fields[8]
        fields_dict['referrer'] = fields[10]
        fields_dict['referrer'] = fields_dict['referrer'].replace('"', '')
        fields_dict['ua'] = ' '.join(fields[11:])
        fields_dict['ua'] = fields_dict['ua'].replace('"', '')

        logs[fields[0]] = fields_dict

for ip in logs.keys():
    # Look for ips that only occur once, probs a bot
    if len(logs[ip]['page']) == 1:
        logs.pop(ip)
        continue

    # Look for ips that visit the below pages
    regex = "/.*(js|css|favicon|jpg|png|fonts)"
    r = re.compile(regex)
    matches = filter(r.match, logs[ip]['page'])

    if not matches:
        logs.pop(ip)
        continue
    else:
        for match in matches:
            logs[ip]['page'].remove(match)


    # Look for bots
    regex = ".*(proxy|seo|Synapse|scan|crawler|analytics|yandex|ad|\
             preview|speed|spider|button|facebookexternalhit|baidu|bot).*"
    m1_list = [logs[ip]['referrer'], logs[ip]['ua']]
    m1_regex = re.compile(regex, re.IGNORECASE)
    m1 = filter(m1_regex.match, m1_list)

    m2 = logs[ip]['ua'] == '"-"'

    m3 = int(logs[ip]["status_code"]) >= 400
    m4_regex = re.compile("http://.*|/robots.txt")
    m4 = filter(m4_regex.match, logs[ip]['page'])
    # TODO: Add another conditional if it is not a GET or POST request
    if m1 or m2 or m3 or m4:
        logs.pop(ip)
        continue

    # Unique page visits
    logs[ip]['count'] = len(logs[ip]['page'])
    logs[ip]['page'] = set(logs[ip]['page'])

    if logs[ip]['count'] < 1:
        logs.pop(ip)
        continue

    # Get IP information
    url = 'http://ipinfo.io/%s' % ip
    r = requests.get(url)
    ipinfo = json.loads(r.text)

    if 'DigitalOcean' in ipinfo['org']:
        logs.pop(ip)
        continue
    else:
        logs[ip]['ipinfo'] = ipinfo

    # Get UA information
    encoded_ua = urllib.quote_plus(logs[ip]['ua'])
    url = 'http://useragentapi.com/api/v2/json/<api key>/%s' % encoded_ua
    r = requests.get(url)
    ua = json.loads(r.text)

    logs[ip]['ua'] = ua

with open(OUTPUT_PATH, 'w') as f:
    for ip in logs.keys():
        log = logs[ip]
        ipinfo = log['ipinfo']
        ua = log['ua']
        log['date'] = time.strptime(log['date'], '[%d/%b/%Y:%H:%M:%S +0000]')
        date = time.strftime('%b/%d/%Y', log['date'])

        f.write('-' * 20 + '\n')
        try:
            f.write('%s\nDate: %s \nCount: %d\nPages: %s\nReferrer: %s \
                     \nOrg: %s\nGeo: %s, %s %s\nUA: %s, %s\n' %
                    (ip, date, log['count'], ', '.join(log['page']),
                     log['referrer'], ipinfo['org'], str(ipinfo['city']),
                     ipinfo['region'], ipinfo['country'], ua['browser_name'],
                     ua['platform_name']))

        except:
            # Currently, any unicode will cause an except
            # TODO: Handle unicode better
            pass

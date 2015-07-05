#!/bin/bash

#Created by Jessica Wilson July 5th 2015

#pull all requests for pages not related to js/css
cat /var/log/apache2/access.log | grep -v -E 'js|css|favicon|img|fonts'  > accessedPages.txt;

#find bots out of those pages assuming that only robots visit robots.txt
cat accessedPages.txt | grep -E 'robots.txt' |grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -n | uniq >> knownBots.txt ;
cat knownBots.txt |sort -n |uniq > knownBots.txt

#filter out all known robots
cat accessedPages.txt | grep -v -f "knownbots.txt" > reducedHits.txt;

#Assume that if someone gets a 404 , they maliciously went there
cat reducedHits.txt | grep 404 > badVisits.txt;
cat badVisits.txt | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -n | uniq > badBots.txt;

#filter out all malicious visits
cat reducedHits.txt |grep -v -f "badBots.txt" | grep -o '.*HTTP' | grep -v 'OPTIONS' | grep -v -E "127.0.0.1|10.0.0" > actualHits.txt;

#pull out IP's for good visitors
cat actualHits.txt | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -n | uniq > goodVisitors.txt;

#find out where the IP's are located from good visitors
while read a;
do 
	b=$(echo `curl -s ipinfo.io/$a/city`);
	c=$(echo `curl -s ipinfo.io/$a/region`);
	d=$(echo `curl -s ipinfo.io/$a/country`);
	echo $a $b $c $d >> visitorsLoc.txt;
done < goodVisitors.txt

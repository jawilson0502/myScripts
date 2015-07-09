#!/bin/bash

#Created by Jessica Wilson July 5th 2015
#Updated by Jessica Wilson July 9th 2015


#pull out any ip's that only see a single page w/o loading css (which is a 2nd page load- assuming it is a bad bot
cat /var/log/apache2/access.log | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -n | uniq -c | sort -n > IPCounts.txt;

#make sure there is no residual file, there may not be a file, so this creates one incase there isn't to remove
touch badBots.txt;
rm badBots.txt;

while read a b;
do 
	if [ $a -eq 1 ]
		then echo $b >> badBots.txt;
	fi
done < IPCounts.txt;

#filter out all requests pertaining to js and css
cat /var/log/apache2/access.log | grep -v -E 'js|css|favicon|img|fonts'  > accessedPages.txt;

#find bots out of those pages assuming that only robots visit robots.txt
cat accessedPages.txt | grep -E 'robots.txt' |grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -n | uniq > knownBots.txt ;

#filter out all known robots
cat accessedPages.txt | grep -v -f "knownBots.txt" | grep -v -f "badBots.txt" > reducedHits.txt;

#Assume that if someone gets a 404 , they maliciously went there
cat reducedHits.txt | grep 404 > badVisits.txt;
cat badVisits.txt | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -n | uniq >> badBots.txt;

#filter out all malicious visits
cat reducedHits.txt |grep -v -f "badBots.txt" | grep -o '.*HTTP' | grep -v 'OPTIONS' | grep -v -E "127.0.0.1|10.0.0" > actualHits.txt;

#pull out IP's for good visitors
cat actualHits.txt | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -n | uniq -c | sort -n> goodVisitors.txt;

#find out where the IP's are located from good visitors
#rm an old file if it exists, creates it if it doesn't and removes it to ensure we start fresh
touch visitorsLoc.txt;
rm visitorsLoc.txt;

while read a b;
do 
	c=$(echo `curl -s ipinfo.io/$b/city`);
	d=$(echo `curl -s ipinfo.io/$b/region`);
	e=$(echo `curl -s ipinfo.io/$b/country`);
	echo $a $b $c $d $e >> visitorsLoc.txt;
done < goodVisitors.txt

#find out where the IP's are located from bad bots
#rm an old file if it exists, creates it if it doesn't and removes it to ensure we start fresh
touch badBotLoc.txt;
rm badBotLoc.txt;

while read a;
do 
	b=$(echo `curl -s ipinfo.io/$a/city`);
	c=$(echo `curl -s ipinfo.io/$a/region`);
	d=$(echo `curl -s ipinfo.io/$a/country`);
	echo $a $b $c $d >> badBotLoc.txt;
done < badBots.txt

#remove files I don't want to review afterwards
rm goodVisitors.txt;
rm accessedPages.txt;
rm actualHits.txt;
rm badVisits.txt;
rm reducedHits.txt;
rm badBots.txt;

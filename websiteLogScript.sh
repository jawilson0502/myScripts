#!/bin/bash

#Created by Jessica Wilson July 5th 2015
#Updated by Jessica Wilson July 15th 2015
#Updated by Jeff Kaminski September 21st 2015

#Declare the api key for useragentapi.com, get your from http://useragentapi.com/account/signup
apikey="<getyour own api>"

#pull out any ip's that only see a single page w/o loading css (which is a 2nd page load- assuming it is a bad bot
cat /var/log/apache2/access.log | grep -o "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -n | uniq -c | sort -n > IPCounts.txt;

#make sure there is no residual file, there may not be a file, so this creates one incase there isn't to remove
touch badBots.txt;
rm badBots.txt;

#sometimes mobile phones don't load everything, but still are legit visits, needed to filter out
while read a b;
do 
	if [ $a -eq 1 ];then 
		c=$(echo `cat /var/log/apache2/access.log | grep "$b" | grep "Mobile"`);
		if [ -z "$c" ]; then 
			echo $b >> badBots.txt;
		fi
	fi
done < IPCounts.txt;

#filter out all requests pertaining to js and css
cat /var/log/apache2/access.log | grep -v -E 'js|css|favicon|img|fonts'  > accessedPages.txt;

#find bots out of those pages assuming that only robots have 'bot' somewhere in their log record
cat accessedPages.txt | grep -E 'bot' |grep -o "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -n | uniq > knownBots.txt ;

#filter out all known robots
cat accessedPages.txt | grep -v -f "knownBots.txt" | grep -v -f "badBots.txt" > reducedHits.txt;

#Assume that if someone gets a 404 or links somehow with something that says proxy or seo, they maliciously went there
cat reducedHits.txt | grep -E '404|proxy|seo|Synapse' > badVisits.txt;
cat badVisits.txt | grep -o "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -n | uniq >> badBots.txt;

#filter out all malicious visits
cat reducedHits.txt |grep -v -f "badBots.txt" | grep -v 'OPTIONS' | grep -v -E "127.0.0.1|10.0.0" > actualHits.txt;

#pull out IP's for good visitors
cat actualHits.txt | grep -o "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -n | uniq -c | sort -n> goodVisitors.txt;

#find out where the IP's are located from good visitors, parse the json object returned from curl with jq
#rm an old file if it exists, creates it if it doesn't and removes it to ensure we start fresh
touch visitorsLoc.txt;
rm visitorsLoc.txt;

while read a b;
do 
	#The original which stored to txt, remove this
	#curl -s ipinfo.io/$b/geo > temp.txt;
	geo=$(curl -s ipinfo.io/$b/geo)
	
	#c=$(echo `cat temp.txt | jq '.city'`);
	#d=$(echo `cat temp.txt | jq '.region'`);
	#e=$(echo `cat temp.txt | jq '.country'`);
	c=$(echo $geo | jq '.city')
	d=$(echo $geo | jq '.region')
	e=$(echo $geo | jq '.country')	
	
	#set up for UA string encoding
	ua_string=$(echo `cat actualHits.txt | grep "$b" |  sed s'/.$//' | sed 's/.*"//' | head -1`);
	ua_string=$(urlencode $ua_string)
	decoded_ua_string=$(curl -s "http://useragentapi.com/api/v2/json/$apikey/$ua_string");
	#echo $decoded_ua_string
	f=$(echo $decoded_ua_string | jq '.browser_name')
	g=$(echo $decoded_ua_string | jq '.browser_version')
	h=$(echo $decoded_ua_string | jq '.platform_name')
	
	echo $a $b $c $d $e >> visitorsLoc.txt;
	echo $h $f $g >> visitorsLoc.txt;
	cat actualHits.txt | grep "$b" | grep -E -o  " /.*?\.html | / " | sort | uniq >> visitorsLoc.txt
	echo "----------------------------------" >> visitorsLoc.txt;
done < goodVisitors.txt

#replace "/" with "/landing" to indicate they came straight to my site
sed -i 's/ \/ / \/landing/' visitorsLoc.txt;

#find out where the IP's are located from bad bots, parse the json object returned from curl with jq
#rm an old file if it exists, creates it if it doesn't and removes it to ensure we start fresh
touch badBotLoc.txt;
rm badBotLoc.txt;

while read a;
do 
	curl -s ipinfo.io/$a/geo > temp.txt;

	b=$(echo `cat temp.txt | jq '.city'`);
	c=$(echo `cat temp.txt | jq '.region'`);
	d=$(echo `cat temp.txt | jq '.country'`);
	echo $a $b $c $d >> badBotLoc.txt;
done < badBots.txt

#remove files I don't want to review afterwards
rm goodVisitors.txt;
rm accessedPages.txt;
rm badVisits.txt;
rm reducedHits.txt;
rm badBots.txt;
rm temp.txt;
rm actualHits.txt;

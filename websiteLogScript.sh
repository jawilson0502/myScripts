#!/bin/bash

#Created by Jessica Wilson July 5th 2015
#Updated by Jessica Wilson August 14th, 2015


#pull out any ip's that only see a single page w/o loading css (which is a 2nd page load- assuming it is a bad bot
cat /var/log/apache2/access.log | grep -o "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -n | uniq -c | sort -n > IPCounts.txt;

#make sure there is no residual file, there may not be a file, so this creates one incase there isn't to remove
touch badBots.txt;
rm badBots.txt;

#sometimes mobile phones don't load everything, but still are legit visits, needed to filter out
while read occurrence ipAddress;
do 
	if [ $occurrence -eq 1 ];then 
		mobileString=$(echo `cat /var/log/apache2/access.log | grep "$ipAddress" | grep "Mobile"`);
		#-z means string is null, so -z $mobileString is true if $mobileString has no value
		if [ -z "$mobileString" ]; then 
			echo $ipAddress >> badBots.txt;
		fi
	fi
done < IPCounts.txt;

#filter out all requests pertaining to js and css
cat /var/log/apache2/access.log | grep -v -E 'js|css|favicon|img|fonts'  > accessedPages.txt;

#find bots out of those pages assuming that only robots have 'bot' somewhere in their log record
cat accessedPages.txt | grep -E 'bot' |grep -o "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -n | uniq > knownBots.txt ;

#filter out all known robots
cat accessedPages.txt | grep -v -f "knownBots.txt" | grep -v -f "badBots.txt" > reducedHits.txt;

#Assume that if someone gets a 404 or links somehow with something that says proxy or seo, or does a head request, they maliciously went there, after filtering 
#out anything that would have announced that it was a bot by visiting robots.txt
cat reducedHits.txt | grep -E '404|proxy|seo|Synapse|HEAD' > badVisits.txt;
cat badVisits.txt | grep -o "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -n | uniq >> badBots.txt;

#filter out anything that does not send a user agent string and assume it is malicious
while read entireString;
do
	uaString=$(echo $entireString |  sed s'/.$//' | sed 's/.*"//');
	#When a User Agent string is blank, it shows up as "-" in the log
	if [ "$uaString" == "-" ]; then
		echo $entireString | grep -o "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" >> badBots.txt;
	fi

done < reducedHits.txt;

#filter out all malicious visits and internal visits
cat reducedHits.txt |grep -v -f "badBots.txt" | grep -v 'OPTIONS' | grep -v -E "127.0.0.1|10.0.0" > actualHits.txt;

#pull out IP's for good visitors
cat actualHits.txt | grep -o "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort -n | uniq -c | sort -n> goodVisitors.txt;

#find out where the IP's are located from good visitors, parse the json object returned from curl with jq
#rm an old file if it exists, creates it if it doesn't and removes it to ensure we start fresh
touch visitorsLoc.txt;
rm visitorsLoc.txt;

while read occurrence ipAddress;
do 
	#Perform a curl, grabbing all geo location information, then parse the JSON to pull out the information I want
	curl -s ipinfo.io/$ipAddress/geo > temp.txt;
	
	city=$(echo `cat temp.txt | jq '.city'`);
	region=$(echo `cat temp.txt | jq '.region'`);
	country=$(echo `cat temp.txt| jq '.country'`);
	
	#set up for UA string encoding
	#f=$(echo `cat actualHits.txt | grep "$b" |  sed s'/.$//' | sed 's/.*"//' | head -1`);
	
	#Set up the style of the report, first showing all the information on the IP
	echo $occurrence $ipAddress $city $region $country >> visitorsLoc.txt;
	#Next, pull out which pages they visited from my site
	cat actualHits.txt | grep "$ipAddress" | grep -E -o  " /.*?\.html | / | /.*?\.php" | sort | uniq >> visitorsLoc.txt
	echo "----------------------------------" >> visitorsLoc.txt;
done < goodVisitors.txt

#replace "/" with "/landing" to indicate they came straight to my site
sed -i 's/ \/ / \/landing/' visitorsLoc.txt;

#find out where the IP's are located from bad bots, parse the json object returned from curl with jq
#rm an old file if it exists, creates it if it doesn't and removes it to ensure we start fresh
touch badBotLoc.txt;
rm badBotLoc.txt;

while read ipAddress;
do 
	#Curl all geo location information as before with the good visitor's IP, process for a report
	curl -s ipinfo.io/$ipAddress/geo > temp.txt;

	city=$(echo `cat temp.txt | jq '.city'`);
	region=$(echo `cat temp.txt | jq '.region'`);
	country=$(echo `cat temp.txt | jq '.country'`);
	echo $ipAddress $city $region $country >> badBotLoc.txt;
done < badBots.txt

#remove files I don't want to review afterwards
rm goodVisitors.txt;
rm accessedPages.txt;
rm badVisits.txt;
rm reducedHits.txt;
rm badBots.txt;
rm temp.txt;
rm actualHits.txt;

#!/bin/bash

#Created by Jessica Wilson April 24th, 2015

#Pull current date for file name
DATE=$(date +%Y_%m_%d);

#Pull all IP's for failed login attempts
cat /var/log/auth.log.1 | grep -i "failed\|failure" | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" > /home/pi/linux_project/ip_$DATE.txt;

#below sorts unique IPs by amount of occurences
cat /home/pi/linux_project/ip_$DATE.txt | sort -n | uniq -c | sort -n > /home/pi/linux_project/ip_sorted_$DATE.txt ;

#Take each unique IP and assign a country code
while read a b;
do
	c=$(echo `curl -s ipinfo.io/$b/country`);
	echo $a $b $c >> /home/pi/linux_project/ip_country_$DATE.txt;
done < /home/pi/linux_project/ip_sorted_$DATE.txt

#Sort by  County

#how many ips are in the original ip pull
attempts=$(echo `cat /home/pi/linux_project/ip_$DATE.txt | wc -l`);

#declare current country variables for adding up big data
declare -i china_tries=0;
declare -i japan_tries=0;
declare -i hongkong_tries=0;
declare -i taiwan_tries=0;
declare -i us_tries=0;
declare -i bosnia_tries=0;
declare -i russia_tries=0;
declare -i mexico_tries=0;
declare -i other_tries=0;

#while loop running through txt sorted by attempts and Country Code
while read a b c;
 do
	if [ "$c" = "CN" ]
		then china_tries=$china_tries+$a;
		elif [ "$c" = "JP" ]
			then japan_tries=$japan_tries+$a;
		elif [ "$c" = "HK" ]
			then hongkong_tries=$hongkong_trie+$a;
		elif [ "$c" = "TW" ]
			then taiwan_tries=$taiwan_tries+$a;
		elif [ "$c" = "US" ]
			then us_tries=$us_tries+$a;
		elif [ "$c" = "BA" ]
			then bosnia_tries=$bosnia_tries+$a;
		elif [ "$c" = "RU" ]
			then russia_tries=$russia_tries+$a;
		elif [ "$c" =  "MX" ]
			then mexico_tries=$mexico_tries+$a;
	#throw it to "other" if I do not have the country currently. Try to add countries every week or so
		else
			other_tries=$other_tries+$a;
	fi
done < /home/pi/linux_project/ip_country_$DATE.txt;

#Create a new file with all the information laid out, with countries only with attempts shown
echo "Number of tries by country:" >> /home/pi/linux_project/attemptsbycountry_$DATE.txt;
if [ $china_tries -gt 0 ]
	then echo "China: $china_tries" >> /home/pi/linux_project/attemptsbycountry_$DATE.txt;
fi
if [ $russia_tries -gt 0 ]
	then echo "Russia: $russia_tries" >> /home/pi/linux_project/attemptsbycountry_$DATE.txt;
fi
if [ $hongkong_tries -gt  0 ]
	then echo "Hong Kong: $hongkong_tries" >> /home/pi/linux_project/attemptsbycountry_$DATE.txt;
fi
if [ $japan_tries -gt 0 ]
	then echo "Japan:$japan_tries" >> /home/pi/linux_project/attemptsbycountry_$DATE.txt;
fi
if [ $us_tries -gt 0 ]
	then echo "United States:$us_tries" >> /home/pi/linux_project/attemptsbycountry_$DATE.txt;
fi
if [ $taiwan_tries -gt 0 ]
	then echo "Taiwan: $taiwan_tries" >> /home/pi/linux_project/attemptsbycountry_$DATE.txt;
fi
if [ $bosnia_tries -gt 0 ]
	then echo "Bosnia: $bosnia_tries" >> /home/pi/linux_project/attemptsbycountry_$DATE.txt;
fi
if [ $mexico_tries -gt 0 ]
	then echo "Mexico: $mexico_tries" >> /home/pi/linux_project/attemptsbycountry_$DATE.txt;
fi
if [ $other_tries -gt 0 ]
	then echo "Other Countries: $other_tries" >> /home/pi/linux_project/attemptsbycountry_$DATE.txt;
fi

#condense all revelant information into one easy to read report
#break line
echo "*************************" >> /home/pi/linux_project/report_$DATE.txt;
echo "Here is a the break down of intrusions on: $DATE" >> /home/pi/linux_project/report_$DATE.txt;
#break line
echo "*************************" >> /home/pi/linux_project/report_$DATE.txt;
echo "Total Number of Attempts: $attempts" >> /home/pi/linux_project/report_$DATE.txt;
#pull in the attempts per country
echo `cat /home/pi/linux_project/attemptsbycountry_$DATE.txt >> /home/pi/linux_project/report_$DATE.txt`;
#break line
echo "*************************" >> /home/pi/linux_project/report_$DATE.txt;
echo "Attempts broken down by IP address:" >> /home/pi/linux_project/report_$DATE.txt;
echo `cat /home/pi/linux_project/ip_country_$DATE.txt >> /home/pi/linux_project/report_$DATE.txt`;
#break line
echo "*************************" >> /home/pi/linux_project/report_$DATE.txt;
#end of reporting

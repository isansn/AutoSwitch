#!/bin/bash
source "conf.all.conf"

ex=0
package=$(dpkg -s curl | grep Status)
[ -z "$package" ] && echo -e "\e[1;31mNot find package curl.	Please install curl.\e[0m" && ex=1
package=$(dpkg -s jq | grep Status)
[ -z "$package" ] && echo -e "\e[1;31mNot find package jq.	Please install jq.\e[0m" && ex=1
package=$(dpkg -s bc | grep Status)
[ -z "$package" ] && echo -e "\e[1;31mNot find package bc.	Please install bc.\e[0m" && ex=1
package=$(dpkg -s screen | grep Status)
[ -z "$package" ] && echo -e "\e[1;31mNot find package screen.	Please install screen.\e[0m" && ex=1


[ $ex -eq 1 ] && exit


nice=`curl -k -s $niceUrl`
echo $nice > $NICE_FILE

for n in $@
do
	[ "$n" = "-h" ] && echo "Use:	run.sh start [all]" && echo " or:	run.sh stop" && echo "start		start only config.conf" && echo "start all	start other config.RIG_NAME.conf without config.conf"
	[ "$n" = "start" ] && start="1"
	[ "$n" = "stop" ] && stop="1"
	[ "$n" = "all" ] && all="1"
done

function stop {
	if [ -f $PIDS_FILE ]
	then
		for i in $(cat $PIDS_FILE); do
			kill -9 $i >/dev/null 2>/dev/null
		done
		echo "" > $PIDS_FILE
	fi
}

[ ! -z "$stop" ] && stop && exit

if [ ! -z "$start" ]
then
	stop
	if [ ! -z "$all" ]
	then
		for i in $(ls config.*.conf); do
			arr=($(echo $i | tr "." "\n"))
			screen -dmS auto-${arr[1]} ./auto.sh -fc $i
		done
	else
		screen -dmS auto ./auto.sh -fc config.conf
	fi
fi

echo $$ >> $PIDS_FILE 

while true
do
	nice=`curl -k -s $niceUrl`
	echo $nice > $NICE_FILE
	sleep $INTERVAL
done

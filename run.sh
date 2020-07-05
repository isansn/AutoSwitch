#!/bin/bash
source "conf.all.conf"

nice=$(wget -q -O - https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info)
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
			echo "" > $PIDS_FILE
		done
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
	nice=$(wget -q -O - https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info)
	echo $nice > $NICE_FILE
	sleep $INTERVAL
done

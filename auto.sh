#!/bin/bash
source "$HOME/AutoSwitch/conf.all.conf"
echo "" > $LOG_FILE
echo $$ >> $PIDS_FILE 
[ "$1" = "-fc" ] && source "$2"
[ -z "$TOKEN" ] && echo "Can't find token." >> $LOG_FILE && echo "Can't find token. Please edit config file." && exit

function print {
response=`curl -s -w "\n%{http_code}" \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer $TOKEN" \
         -X POST \
	 -d "{\"worker_ids\": [$RIG_ID], \"data\": {\"command\": \"exec\", \"data\": {\"cmd\": \"echo $MESSAGE\"} } }" \
         "$baseUrl/farms/$FARM_ID/workers/command"`
[ $? -ne 0 ] && (>&2 echo 'Curl error')
statusCode=`echo "$response" | tail -1`
response=`echo "$response" | sed '$d'`
[[ $statusCode -lt 200 || $statusCode -ge 300 ]] && echo "Error in message $response" >> $LOG_FILE && echo "Error in fs apply" && echo "$response" | jq 1>&2

}

function fs_apply {
response=`curl -s -w "\n%{http_code}" \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer $TOKEN" \
         -X PATCH \
         -d "{\"fs_id\": $top_id}" \
         "$baseUrl/farms/$FARM_ID/workers/$RIG_ID"`
[ $? -ne 0 ] && (>&2 echo 'Curl error')
statusCode=`echo "$response" | tail -1`
response=`echo "$response" | sed '$d'`
[[ $statusCode -lt 200 || $statusCode -ge 300 ]] && echo "Error in fs apply $response" >> $LOG_FILE && echo "Error in fs apply" && echo "$response" | jq 1>&2
}

response=`curl -s -w "\n%{http_code}" \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer $TOKEN" \
         "$baseUrl/farms/$FARM_ID/fs"`
[ $? -ne 0 ] && (>&2 echo 'Curl error')
statusCode=`echo "$response" | tail -1`
response=`echo "$response" | sed '$d'`
[[ $statusCode -lt 200 || $statusCode -ge 300 ]] && echo "Error in get FS $response" >> $LOG_FILE  && echo "Error in get FS" && echo "$response" | jq 1>&2
FS=$response

tmp=""
i=0
a=0
cnt=0
while [ ! "$tmp" == "null" ]
do
	algo=$(echo "$FACTORSHASH" | jq .[$i][0] | tr -d \")
	tmp=$algo
	if [ ! "$tmp" == "null" ]
	then
		factors=$(echo "$FACTORSHASH" | jq .[$i][1])
		hash=$(echo "$FACTORSHASH" | jq .[$i][2])
		fsname=$(echo "$FACTORSHASH" | jq .[$i][3] | tr -d \")
		if (( $(echo "$hash > 0" |bc -l) ))
		then
			n=0
			tmp0=""
			t=$a
			[ ! "$fsname" == "null" ] && val=$fsname
			[ "$fsname" == "null" ] && val="Autoswitch $algo"
			echo "FS in conf: $fsname - $val" >> $LOG_FILE
			while [ ! "$tmp0" == "null" ]
			do
				tmp0=$(echo "$FS" | jq .data[$n].id | tr -d \")
				name=$(echo "$FS" | jq .data[$n].name | tr -d \")
				echo "FS in hive: $name; in conf $val" >> $LOG_FILE
				if [ "$val" == "$name" ]
				then
					FS_ALGO[$a]=$algo
					FS_ID[$a]=$(echo "$FS" | jq .data[$n].id)
					FS_FACTORS[$a]=$(echo "$FACTORSHASH" | jq .[$i][1])
					FS_HASH[$a]=$(echo "$FACTORSHASH" | jq .[$i][2])
					FS_NAME[$a]=$val
					printf "\e[1;33m%-30s %-20s %s\n\e[0m" "Algo: ${FS_ALGO[$a]}," "Factors: ${FS_FACTORS[$a]}," "Hash: ${FS_HASH[$a]}"
					((a++))
					((n++))
					echo "FIND FS $val in Hive" >> $LOG_FILE
					break
				fi
				((n++))
			done
			[ $t -eq $a ] && echo "NOT FIND $val in Hive" >> $LOG_FILE
			[ $t -eq $a ] && printf "\e[1;31m%-30s %-20s %s\n\e[0m" "Algo: $algo," "Factors: $factors," "Hash: $hash"
		else
			printf "\e[1;30m%-30s %-20s %s\n\e[0m" "Algo: $algo," "Factors: $factors," "Hash: $hash"
		fi
	((i++))
	fi
done

best=""

TIME=$(stat --format="%Y" $NICE_FILE)
while true
do
	while [ "$TIME" -eq $(stat --format="%Y" $NICE_FILE) ]
	do 
		sleep 1
	done
	TIME=$(stat --format="%Y" $NICE_FILE)
	
	title=""
	unset AUTOFS
	
	nice=$(cat $NICE_FILE)

	i=0
	max=0
	maxi=0
	while [ ! "$title" == "null" ]
	do
		title=$(echo $nice | jq .miningAlgorithms[$i].title | tr -d \")
		paying=$(echo $nice | jq .miningAlgorithms[$i].paying | tr -d \")
		if [ ! "$title" == "null" ]
		then
			for (( x = 0; x < ${#FS_ALGO[*]}; x++ ))
			do
				if [ "${FS_ALGO[$x]}" = "$title" ]
				then
					profit=$(echo "${FS_FACTORS[$x]} ${FS_HASH[$x]} $paying" | awk '{printf "%.8f", $1 * $2 * $3}')
					AUTOFS[${#AUTOFS[*]}]="[\"${FS_ALGO[$x]}\",${FS_ID[$x]},$profit,\"${FS_NAME[$x]}\"]"
				fi
			done
			((i++))
		fi
	done
	for (( y = 0; y < ${#AUTOFS[*]}-1; y++ ))
	do
		max=0
		maxi=0
		for (( x = 0+$y; x < ${#AUTOFS[*]}; x++ ))
		do
			profit=$(echo "${AUTOFS[$x]}" | jq .[2])
			if (( $(echo "$profit $max" | awk '{printf($1>$2)}') )); then
				max=$profit
				maxi=$x
			fi
		done
		temp=${AUTOFS[$y]}
		AUTOFS[$y]=${AUTOFS[$maxi]}
		AUTOFS[$maxi]=$temp
	done
	if [ -z "$best" ]; then
		best=${AUTOFS[0]}
		top_algo=$(echo "${AUTOFS[0]}" | jq .[0])
		top_id=$(echo "${AUTOFS[0]}" | jq .[1])
		top_profit=$(echo "${AUTOFS[0]}" | jq .[2])
		top_name=$(echo "${AUTOFS[0]}" | jq .[3])
		fs_apply
		MESSAGE="Autoswitch: Switch to $(echo $top_name | tr -d \") Profit=$top_profit BTC/day "
		print
	fi
	cur_algo=$(echo "$best" | jq .[0])
	cur_profit=$(echo "$best" | jq .[2])
	for (( x = 0; x < ${#AUTOFS[*]}; x++ ))
	do
		algo=$(echo "${AUTOFS[$x]}" | jq .[0])
		if [ "$algo" == "$cur_algo" ];then
			profit=$(echo "${AUTOFS[$x]}" | jq .[2])
			(( $(echo "$profit != $cur_profit" |bc -l) )) && best=${AUTOFS[$x]}
		fi
	done

	top_algo=$(echo "${AUTOFS[0]}" | jq .[0])
	top_id=$(echo "${AUTOFS[0]}" | jq .[1])
	cur_algo=$(echo "$best" | jq .[0])
	cur_profit=$(echo "$best" | jq .[2])
	top_profit=$(echo "${AUTOFS[0]}" | jq .[2])
	top_name=$(echo "${AUTOFS[0]}" | jq .[3])
	if [ ! "$top_algo" == "$cur_algo" ]; then
		d=$(echo "$top_profit $cur_profit" | awk '{printf "%.3f", $1 * 100 / $2 -100}')
		if (( $(echo "$d > $MIN_DIFF" |bc -l) ))
		then
			[ ! "$callalgo" == "$top_algo" ] && callalgo=$top_algo && cnt=0
			
			((cnt++))
			if [ $cnt -ge $CALC_COUNT ]
			then
				best=${AUTOFS[0]}
				echo "Switch to $top_algo"
				fs_apply
				MESSAGE="Autoswitch: Switch to $(echo $top_name | tr -d \") Profit=$top_profit BTC/day "
				print
			fi
		else
			callalgo="" 
			cnt=0
		fi
	else
		d=0
		callalgo="" 
		cnt=0
	fi

	if [ "$top_algo" == "$cur_algo" ]; then
		dfrof=$(echo "${AUTOFS[1]}" | jq .[2])
		d=$(echo "$cur_profit $dfrof" | awk '{printf "%.3f", ($1 * 100 / $2 - 100)*-1}')
	fi

	printf "Cur algo: %-16s Cur profit: %s BTC Cnt: %s\n" "$cur_algo" "$cur_profit" "$cnt"
	printf "Top algo: %-16s Top profit: %s BTC Diff: %s\n" "$top_algo" "$top_profit" "$d%"
	printf "%-15s %-10s %-15s %-10s\n" "Algo" "Profit" "Algo" "Profit"
	for (( x = 0; x < ${#AUTOFS[*]}; x++ ))
	do
		al1=$(echo "${AUTOFS[$x]}" | jq .[0] | tr -d \")
		pr1=$(echo "${AUTOFS[$x]}" | jq .[2] | tr -d \")
		((x++))
		al2=$(echo "${AUTOFS[$x]}" | jq .[0] | tr -d \")
		pr2=$(echo "${AUTOFS[$x]}" | jq .[2] | tr -d \")
		printf "%-15s %-10s %-15s %-10s\n" "$al1" "$pr1" "$al2" "$pr2"
	done
	echo ""
done


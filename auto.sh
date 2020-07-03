#!/bin/bash
source "$HOME/Autoswitch/config.conf"
baseUrl='https://api2.hiveos.farm/api/v2'
niceUrl='https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info'

function print {
response=`curl -s -w "\n%{http_code}" \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer $TOKEN" \
         -X POST \
	 -d "{\"worker_ids\": [$RIG_ID], \"data\": {\"command\": \"exec\", \"data\": {\"cmd\": \"echo $MESSAGE\"} } }" \
         "$baseUrl/farms/$FARM_ID/workers/command"`
[ $? -ne 0 ] && (>&2 echo 'Curl error') #&& exit 1
statusCode=`echo "$response" | tail -1`
response=`echo "$response" | sed '$d'`
[[ $statusCode -lt 200 || $statusCode -ge 300 ]] && { echo "$response" | jq 1>&2; } #&& exit 1

#echo "$response"
}

function fs_apply {
response=`curl -s -w "\n%{http_code}" \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer $TOKEN" \
         -X PATCH \
         -d "{\"fs_id\": $top_id}" \
         "$baseUrl/farms/$FARM_ID/workers/$RIG_ID"`
[ $? -ne 0 ] && (>&2 echo 'Curl error') #&& exit 1
statusCode=`echo "$response" | tail -1`
response=`echo "$response" | sed '$d'`
[[ $statusCode -lt 200 || $statusCode -ge 300 ]] && { echo "$response" | jq 1>&2; } #&& exit 1
#echo "$response"
}

response=`curl -s -w "\n%{http_code}" \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer $TOKEN" \
         "$baseUrl/farms/$FARM_ID/fs"`
FS=$(echo "$response" | sed '$d')



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
		if (( $(echo "$hash > 0" |bc -l) ))
		then
			val="Autoswitch $algo"

			n=0
			tmp0=""
			t=$a
			while [ ! "$tmp0" == "null" ]
			do
				tmp0=$(echo "$FS" | jq .data[$n].name | tr -d \")
				if [ "$val" = "$tmp0" ]
				then
					FS_ALGO[$a]=$algo
					FS_ID[$a]=$(echo "$FS" | jq .data[$n].id)
					FS_FACTORS[$a]=$(echo "$FACTORSHASH" | jq .[$i][1])
					FS_HASH[$a]=$(echo "$FACTORSHASH" | jq .[$i][2])
					printf "\e[1;33m%-30s %-20s %s\n\e[0m" "Algo: ${FS_ALGO[$a]}," "Factors: ${FS_FACTORS[$a]}," "Hash: ${FS_HASH[$a]}"
					((a++))
				fi
				((n++))
			done
			[ $t -eq $a ] && printf "\e[1;31m%-30s %-20s %s\n\e[0m" "Algo: $algo," "Factors: $factors," "Hash: $hash"
		else
			printf "\e[1;30m%-30s %-20s %s\n\e[0m" "Algo: $algo," "Factors: $factors," "Hash: $hash"
		fi
	((i++))
	fi
done

best=""

while true
do
	title=""
	unset AUTOFS
	nice=$(wget -q -O - https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info)

	i=0
	#echo $nice | jq .
	#echo $nice | jq .miningAlgorithms[$i].title
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
				#echo "${#AUTOFS[*]}"
				if [ "${FS_ALGO[$x]}" = "$title" ]
				then
					#profit=$(echo "${FS_FACTORS[$x]}*${FS_HASH[$x]}*$paying" |bc -l)
					profit=$(echo "${FS_FACTORS[$x]} ${FS_HASH[$x]} $paying" | awk '{printf "%.8f", $1 * $2 * $3}')
		
					#echo "profit $profit paying $paying factors ${FS_FACTORS[$x]}"
					#if (( $(echo "$hash > 0" |bc -l) ))
					AUTOFS[${#AUTOFS[*]}]="[\"${FS_ALGO[$x]}\",${FS_ID[$x]},$profit]"
					#echo ${AUTOFS[((${#AUTOFS[*]}-1))]} | jq .
					#AUTOFS[]=${FS_ID[$x]}
					#AUTOFS[]=${FS_FACTORS[$x]}
					#AUTOFS[]=${FS_HASH[$x]}
					#echo "${AUTOFS[0]} ${AUTOFS[1]} ${AUTOFS[2]} ${AUTOFS[3]}"
				fi
			done

			((i++))
		fi
	done
	#echo "|START $max $maxi ${AUTOFS[0]} ${AUTOFS[1]} ${AUTOFS[2]} ${AUTOFS[3]}"
	#temp=${AUTOFS[0]}
	#AUTOFS[0]=${AUTOFS[$maxi]}
	#AUTOFS[$maxi]=$temp	
#echo "|||START ${AUTOFS[0]} ${AUTOFS[1]} ${AUTOFS[2]} ${AUTOFS[3]} ${AUTOFS[4]} ${AUTOFS[5]} ${AUTOFS[6]}"
	for (( y = 0; y < ${#AUTOFS[*]}-1; y++ ))
	do
	#echo "y $y"
		max=0
		maxi=0
		for (( x = 0+$y; x < ${#AUTOFS[*]}; x++ ))
		do
		
		#echo "x $x"
			profit=$(echo "${AUTOFS[$x]}" | jq .[2])
			#echo $profit $max
			if (( $(echo "$profit $max" | awk '{printf($1>$2)}') )); then
				max=$profit
				maxi=$x
				#echo "MAX $max ind $maxi"
			fi
		done
		temp=${AUTOFS[$y]}
		AUTOFS[$y]=${AUTOFS[$maxi]}
		AUTOFS[$maxi]=$temp
		#echo "|||y $y maxi $maxi ${AUTOFS[0]} ${AUTOFS[1]} ${AUTOFS[2]} ${AUTOFS[3]}"
	done
#echo "|||AFTER ${AUTOFS[0]} ${AUTOFS[1]} ${AUTOFS[2]} ${AUTOFS[3]} ${AUTOFS[4]} ${AUTOFS[5]} ${AUTOFS[6]}"
	if [ -z "$best" ]; then
		best=${AUTOFS[0]}
		top_algo=$(echo "${AUTOFS[0]}" | jq .[0])
		top_id=$(echo "${AUTOFS[0]}" | jq .[1])
		top_profit=$(echo "${AUTOFS[0]}" | jq .[2])
		fs_apply
		MESSAGE="Autoswitch: Switch to $(echo $top_algo | tr -d \") Profit=$top_profit BTC/day "
		print
	fi
	cur_algo=$(echo "$best" | jq .[0])
	cur_profit=$(echo "$best" | jq .[2])
	for (( x = 0; x < ${#AUTOFS[*]}; x++ ))
	do
		algo=$(echo "${AUTOFS[$x]}" | jq .[0])
		if [ "$algo" == "$cur_algo" ];then
			profit=$(echo "${AUTOFS[$x]}" | jq .[2])
			(( $(echo "$profit != $cur_profit" |bc -l) )) && best=${AUTOFS[$x]} #&& echo "RUN $profit $cur_profit"
		fi
	done

	top_algo=$(echo "${AUTOFS[0]}" | jq .[0])
	top_id=$(echo "${AUTOFS[0]}" | jq .[1])
	cur_algo=$(echo "$best" | jq .[0])
	cur_profit=$(echo "$best" | jq .[2])
	top_profit=$(echo "${AUTOFS[0]}" | jq .[2])
	if [ ! "$top_algo" == "$cur_algo" ]; then
		#echo "top_profit $top_profit cur_profit $cur_profit"
		#d=$(echo "$top_profit*100/$cur_profit - 100" |bc -l)
		d=$(echo "$top_profit $cur_profit" | awk '{printf "%.3f", $1 * 100 / $2 -100}')
		#echo "$d%"
		if (( $(echo "$d > $MIN_DIFF" |bc -l) ))
		then
			[ ! "$callalgo" == "$top_algo" ] && callalgo=$top_algo && cnt=0
			
			((cnt++))
			if [ $cnt -ge $CALC_COUNT ]
			then
				best=${AUTOFS[0]}
				echo "Switch to $top_algo"
				fs_apply
				MESSAGE="Autoswitch: Switch to $(echo $top_algo | tr -d \") Profit=$top_profit BTC/day "
				print
			fi
			#echo "CALC_COUNT $cnt"
		else
			callalgo="" 
			cnt=0
		fi
	else
		d=0
		callalgo="" 
		cnt=0
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
	#echo "||| Best: ${AUTOFS[0]} ${AUTOFS[1]} ${AUTOFS[2]} ${AUTOFS[3]} ${AUTOFS[4]} ${AUTOFS[5]} ${AUTOFS[6]} ${AUTOFS[7]} ${AUTOFS[8]} ${AUTOFS[9]} ${AUTOFS[10]} ${AUTOFS[11]} "
	echo ""
	sleep $INTERVAL
done




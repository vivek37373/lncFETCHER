#!/bin/bash

var=""
while IFS=$'\t' read -r -a line; do
	if [[ ${line[2]} == "transcript" ]]; then
    	if [[ "${line[@]}" =~ class_code\ \"[xu]\" ]]; then
        	var="+"
        	printf "%s\n" "${line[@]}"
    	else
        	var="-"
    	fi
	elif [[ ${line[2]} == "exon" ]]; then
    	if [[ $var == "+" ]]; then
        	printf "%s\n" "${line[@]}"
    	fi
	fi
done < atha_merged_compared.gtf > unknown_and_antisense_ids.gtf

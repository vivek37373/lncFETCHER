#!/bin/bash

# Define input and output file paths
input_file="atha_unknown_and_antisense_transcripts_renamed.fasta"
output_file="atha_unknown_and_antisense_transcripts_renamed_longer200.fasta"

header=""
sequence=""

while IFS= read -r line; do
	if [[ $line =~ ^\> ]]; then
    	if [ ${#sequence} -gt 200 ]; then
        	printf "%s\n%s\n" "$header" "$sequence"
    	fi
    	header="$line"
    	sequence=""
	else
    	sequence+="$line"
	fi
done < "$input_file" > "$output_file"

if [ ${#sequence} -gt 200 ]; then
	printf "%s\n%s\n" "$header" "$sequence" >> "$output_file"
fi

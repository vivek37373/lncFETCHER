#!/bin/bash

# Input files
gtf_file="$1"
non_coding_list="$2"
output_saf="$4"
output_bed="$5"
original_gff="$6"

id_table=()

non_coding_ids=()
while IFS= read -r line || [ -n "$line" ]; do
    line_split=($line)
    mstrg="${line_split[0]}"
    non_coding_ids["$mstrg"]=$line
done < "$non_coding_list"

while IFS= read -r line || [ -n "$line" ]; do
    if [[ $line == \#* ]]; then
        continue
    fi
    IFS=$'\t' read -r -a fields <<<"$line"
    if [[ "${fields[2]}" == "transcript" ]]; then
        col9="${fields[8]}"
        class_code=$(echo "$col9" | awk -F';' '{print $NF}' | awk '{print substr($NF, 2, length($NF)-2)}')
        length=$(( ${fields[4]} - ${fields[3]} + 1))
        if [[ $class_code == "=" ]]; then
            continue
        elif [[ $class_code == "u" ]]; then
            mstrg=$(echo "$col9" | awk '{print substr($1, 2, length($1)-2)}')
            if [[ ${non_coding_ids["$mstrg"]} ]]; then
                mstrg="${mstrg}|${length}|${class_code}|NA|${fields[0]}|$3"
                if ! [[ " ${id_table[@]} " =~ " $mstrg " ]]; then
                    gtf_line="$mstrg;${fields[0]};${fields[3]};${fields[4]};${fields[6]}"
                    id_table+=("$gtf_line")
                fi
            fi
        elif [[ $class_code == "x" ]]; then
            mstrg=$(echo "$col9" | awk '{print substr($1, 2, length($1)-2)}')
            if [[ ${non_coding_ids["$mstrg"]} ]]; then
                gene_name=$(echo "$col9" | awk '{print $5}' | awk '{print substr($3, 2, length($3)-2)}')
                mstrg="${mstrg}|${length}|${class_code}|${gene_name}|${fields[0]}|$3"
                if ! [[ " ${id_table[@]} " =~ " $mstrg " ]]; then
                    gtf_line="$mstrg;${fields[0]};${fields[3]};${fields[4]};${fields[6]}"
                    id_table+=("$gtf_line")
                fi
            fi
        fi
    fi
done < "$gtf_file"

while IFS= read -r line || [ -n "$line" ]; do
    if [[ $line == \#* ]]; then
        continue
    fi
    IFS=$'\t' read -r -a fields <<<"$line"
    if [[ "${fields[2]}" == "gene" ]]; then
        ID=$(echo "${fields[8]}" | awk -F';' '{print $1}' | sed 's/ID=//')
        orig_gtf_line="${ID}|$(( ${fields[4]} - ${fields[3]} + 1));${fields[0]};${fields[3]};${fields[4]};${fields[6]}"
        id_table+=("$orig_gtf_line")
    fi
done < "$original_gff"

for k in "${id_table[@]}"; do
    echo "$k" >> "$output_saf"
done

for line in "${id_table[@]}"; do
    IFS=';' read -r -a fields <<<"$line"
    line_rearranged="${fields[1]};${fields[2]};${fields[3]};${fields[0]};${fields[4]}"
    echo "$line_rearranged" >> "$output_bed"
done

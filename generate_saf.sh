#!/bin/bash

helper_generate_saf() {
    local gtf_file="$1"
    local non_coding_list="$2"
    local processed_gtf="$3"

    declare -A non_coding_ids

    while IFS= read -r line || [[ -n $line ]]; do
        xloc=$(echo "$line" | grep -oP 'LOC_[0-9]{7}') #check here
        non_coding_ids["$xloc"]=$line
    done < "$non_coding_list"

    while IFS= read -r line || [[ -n $line ]]; do
        if [[ $line == \#* ]]; then
            echo "$line" >> "$processed_gtf"
            continue
        fi

        IFS=$'\t' read -r -a fields <<< "$line"
        if [[ ${fields[2]} == "transcript" ]]; then
            col9=${fields[8]}
            class_code=$(echo "$col9" | grep -oP 'class_code = \K(.)')

            if [[ $class_code == "=" || $class_code == "u" || $class_code == "x" ]]; then
                echo "$line" >> "$processed_gtf"
            fi
        fi
    done < "$gtf_file"
}

helper_generate_saf atha_merged_compared.gtf.annotated.gtf cpc_feelnc_noncod_ids.txt genes_and_noncod_u_and_x.gtf

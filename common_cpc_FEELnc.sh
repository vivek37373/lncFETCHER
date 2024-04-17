#!/bin/bash

common_cpc_feelnc() {
    feelnc_ids_file="lncRNA_prediction/feelnc/feelnc_codpot_out/noncoding_ids_feelnc.txt"
    cpc_ids_file="lncRNA_prediction/cpc/noncoding_ids_cpc.txt"
    
    feelnc_noncod=($(<"$feelnc_ids_file"))
    
    cpc_noncod=($(<"$cpc_ids_file"))

    overlap=()
    for feelnc_id in "${feelnc_noncod[@]}"; do
        for cpc_id in "${cpc_noncod[@]}"; do
            [[ $feelnc_id == "$cpc_id" ]] && overlap+=("$feelnc_id")
        done
    done

    output_file="lncRNA_prediction/cpc_feelnc_noncod_ids.txt"
    printf "%s\n" "${overlap[@]}" > "$output_file"
}


common_cpc_feelnc


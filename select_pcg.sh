#!/bin/bash

while IFS= read -r gene_id; do
	# Loop through each line in atha_genes_renamed.fasta
	while IFS= read -r line; do
    	# Check if the line contains the gene ID
    	if [[ $line == *"$gene_id"* ]]; then
        	# Extract the header and sequence
        	header=$(echo "$line" | cut -d '|' -f 1-8)
        	printf ">%s\n" "${header// /_}"
        	IFS= read -r sequence
        	printf "%s\n" "$sequence"
    	fi
	done < atha_genes_renamed.fasta
done < atha_prot_cod_ids.txt > atha_only_prot_cod.fasta

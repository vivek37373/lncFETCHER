#!/bin/bash

# Extract genes from FASTA and GFF using gffread
gffread -w atha_genes.fasta -W -F -g atha_genome.fa atha.gff

# Rename entries in FASTA file(pro)
sed 's/ /|/g' atha_genes.fasta > atha_genes_renamed.fasta

# Extract protein coding IDs from GFF(process in accordance to your gff file)
grep -A 1 $'\tgene\t' atha.gff | grep $'\tmRNA\t'| cut -f 9| cut -f 2 -d ';' | sed 's/Parent=//g' > atha_prot_cod_ids.txt

#select only protein coding
./select_pcg.sh

# Run StringTie merge(atha_assembles contains list of all assembly gtfs)
stringtie --merge -o atha_merged.gtf -g 50 -v -G atha.gff atha_assemblies.txt

# Run gffcompare
gffcompare -V atha_merged.gtf -o atha_merged_compared.gtf -r atha.gff

## Select u and x class codes
./non_code.sh

# Select only longest transcripts with CGAT
cgat-s && cgat gtf2gtf --method=filter --filter-method=longest-transcript -I unknown_and_antisense_ids.gtf > unknown_and_antisense_ids_longest_transcripts.gtf

# Make FASTA file of u and x class codes
gffread -w atha_unknown_and_antisense_transcripts.fasta -W -F -g atha.fa unknown_and_antisense_ids_longest_transcripts.gtf

# Rename entries in the FASTA file
sed 's/ /_/g' atha_unknown_and_antisense_transcripts.fasta > atha_unknown_and_antisense_transcripts_renamed.fasta

# Select transcripts longer than 200 bp
./select_200.sh

# Run FEELnc 
#both atha_unknown_and_antisense_transcripts_renamed_longer200.fasta and atha_unknown_and_antisense_transcripts_renamed_longer200.fasta 
#must not contain ambigous nucleotides
FEELnc_codpot.pl --outdir='feelnc/feelnc_codpot_out/' \
    -i 'feelnc/atha_unknown_and_antisense_transcripts_renamed_longer200.fasta' \
    -a 'feelnc/atha_prot_cod_genes.fasta' \
    --mode=shuffle

# Run CPC
python ./bin/CPC2.py -i atha_unknown_and_antisense_transcripts_renamed_longer200.fasta -o cpc/atha_results.tab

# Select non-coding sequences from CPC result
awk '$3=="noncoding"' 'cpc/atha_results.tab' | cut -f 1 > 'cpc/noncoding_ids_cpc.txt'

#find common FEELnc and CPC results
./common_cpc_FEELnc.sh

### make a gtf file including coding genes, x and u transcripts. 
./generate_saf.sh

#extract only longest transcripts
cgat-s && cgat gtf2gtf\
        --method=filter --filter-method=longest-transcript -I genes_and_noncod_u_and_x.gtf  \
        > genes_and_noncod_u_and_x_longest.gtf


### generate the saf and bed file using the gtf file obtained above.
./generate_saf_mstrg.sh genes_and_noncod_u_and_x_longest.gtf cpc_feelnc_noncod_ids.txt atha counts/atha_unsorted.saf atha_unsorted.bed ref/atha.gff

sort -k2,2 -k3,3n counts/atha_unsorted.saf > counts/atha.saf
sort -k1,1 -k2,2n atha_unsorted.bed > atha.bed


### generates bed file for lncRNAs
grep 'MSTRG' atha.bed > atha_lncRNAs.bed 

### generates fasta file for lncRNAs
gffread -w atha_lncRNAs.fasta -W -F -g ref/atha.fa atha_lncRNAs.bed

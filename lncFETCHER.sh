#!/bin/bash

# Define the output directory
SEQ_DIR="output"


####################################################################
###Quality control with Trim Galore#################################
####################################################################

echo "Goodluck! trim_galore started on `date`"
while read -r filename; do
    echo "Processing $filename"
    if [ -e "${filename}_2.fastq.gz" ]; then
        trim_galore -q 20 --stringency 3 --gzip --length 20 --paired "${filename}_1.fastq.gz" "${filename}_2.fastq.gz" --output_dir "${SEQ_DIR}"
    else
        trim_galore -q 20 --stringency 3 --gzip --length 20 "${SEQ_DIR}/${filename}.fastq.gz" --output_dir "${SEQ_DIR}"
    fi
done < atha_run.list

echo "Goodluck! trim_galore finished on `date`"

# Delete raw FASTQ files
#echo "Deleting raw FASTQ files..."
#while read -r filename; do
#    rm "${SEQ_DIR}/${filename}_1.fastq.gz" "${SEQ_DIR}/${filename}_2.fastq.gz" "${SEQ_DIR}/${filename}.fastq.gz"
#done < atha_run.list
#echo "Raw files deleted"

####################################################################
###strand_detection#################################################
####################################################################

# Prepare index for pseudomappping
create_salmon_index() {
    salmon index -t ref/atha_transcripts.fa -i ref/atha
}

create_salmon_index

create_rsem_reference() {
    rsem-prepare-reference --gff atha.gff atha.fa ref/atha
}
create_rsem_reference



# pseudomapping step
while read -r filename; do
    NAME=$(basename "${filename}")
    echo "Started mapping $filename"
    if [ -e "${SEQ_DIR}/${filename}_val_2.fq.gz" ]; then
        salmon quant -i ref/atha -l A \
            -1 "${SEQ_DIR}/${filename}_val_1.fq.gz" -2 "${SEQ_DIR}/${filename}_val_2.fq.gz" \
            -g /ref/atha.gff \
            -p 11 -o "${NAME}" --gcBias
    else
        salmon quant -i ref/atha -l A \
            -r "${SEQ_DIR}/${filename}_trimmed.fastq.gz" \
            -g /ref/atha.gff \
            -p 11 -o "${NAME}" --gcBias
    fi
done < atha_run.list

#generate strand information to finalize samples for transcript assembly

generate_strand_info() {
    local file_list="file_list.txt"
    local output="strand_info.txt"

    # Write header to output file
    echo -e "sample\tmapping_rate\tstrandedness\tnote" > "$output"

    while IFS= read -r line; do
        line="${line%/}"  # Remove trailing slash if exists
        if [ -f "$line/logs/salmon_quant.log" ]; then
            local mapping_rate=$(awk '/Mapping rate =/{rate=$NF} END{print rate}' "$line/logs/salmon_quant.log")
            local strand_info=$(awk '/Automatically detected most/{count++} END{print count}' "$line/logs/salmon_quant.log")
            if [ "$strand_info" -eq 0 ]; then
                echo -e "$line\t$mapping_rate\tNA\tnot used for transcript reconstruction" >> "$output"
            else
                local strand=$(awk '/Automatically detected most/{if($NF~/^U$/) print "NA"; else print $NF; exit}' "$line/logs/salmon_quant.log")
                if [ "$strand" == "NA" ]; then
                    echo -e "$line\t$mapping_rate\t$strand\tnot used for transcript reconstruction" >> "$output"
                else
                    echo -e "$line\t$mapping_rate\t$strand\tused for transcript reconstruction" >> "$output"
                fi
            fi
        fi
    done < "$file_list"
}

# Call the function
generate_strand_info

####################################################################
###MAPPING##########################################################
####################################################################

# Function to build HISAT2 index
build_hisat2_index() {
    hisat2-build -p 16 ref/atha.fa atha_index
}

build_hisat2_index

#run hisat2 based on strand strand_info.txt.Get list of samples into four different files
#atha_run_single_forward.list, atha_run_single_reverse.list, atha_run_paired_forward.list,atha_run_paired_reverse.list
#if single end forward
while read filename; do
hisat2 -x atha_index  -q ${SEQ_DIR}/${filename}_2_trimmed.fastq.gz -S ${SEQ_DIR}/${filename}.sam --max-intronlen 10000 -p 40 --rna-strandness F
done < atha_run_single_forward.list
#if single end reverse
while read filename; do
hisat2 -x atha_index -q ${SEQ_DIR}/${filename}_2_trimmed.fastq.gz -S ${SEQ_DIR}/${filename}.sam --max-intronlen 10000 -p 40 --rna-strandness R
done < atha_run_single_reverse.list
#if paired end forward
while read filename; do
hisat2 -x atha_index ${SEQ_DIR}/${filename}_1_trimmed.fastq.gz -2 ${SEQ_DIR}/${filename}_2_trimmed.fastq.gz -S ${filename}.sam --max-intronlen 10000 -p 40 --rna-strandness FR
done < atha_run_paired_forward.list
#if paired end reverse
while read filename; do
hisat2 -x atha_index ${SEQ_DIR}/${filename}_1_trimmed.fastq.gz -2 ${SEQ_DIR}/${filename}_2_trimmed.fastq.gz -S ${filename}.sam --max-intronlen 10000 -p 40 --rna-strandness RF
done < atha_run_paired_reverse.list



#convert sam to bam
while read filename; do
samtools sort -o ${SEQ_DIR}/${filename}.bam ${SEQ_DIR}/${filename}.sam
done < atha_run.list

####################################################################
###Assembly with stringtie using selected stranded RNA-seq samples##
####################################################################
#for_fr
while read filename; do
stringtie -v -p 12 -G ref/atha.gff -o stringtie_assembly/${filename}.gtf --fr -A stringtie_assembly/${filename}_expression_atha.tab output_${filename}/accepted_hits.bam
done < atha_run_fr.list
#for_rf
while read filename; do
stringtie -v -p 12 -G ref/atha.gff -o stringtie_assembly/${filename}.gtf --rf -A stringtie_assembly/${filename}_expression_atha.tab output_${filename}/accepted_hits.bam
done < atha_run_rf.list

###################################################################
###predict lncRNAs#################################################
###################################################################

./predict_lncRNAs.sh



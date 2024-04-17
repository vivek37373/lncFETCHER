# lncFETCHER

**lncFETCHER** is a bioinformatics pipeline designed for predicting long non-coding RNAs (lncRNAs) in *Arabidopsis thaliana* using a pseudoalignment guided approach. This pipeline facilitates the identification of lncRNAs from large-scale RNA-seq datasets. It has been developed for our work titled "Pseudoalignment-guided lncRNA identification with extended multi-omics annotations in _Arabidopsis thaliana_."

Please note that it is still under development for users, and users are advised to run each step individually. Since it includes manipulation of several files, most of the steps may require manual intervention, especially if you are using a genome other than Arabidopsis. In this work, we have used files of _Arabidopsis thaliana_ - Genome assembly: TAIR10 (https://plants.ensembl.org/Arabidopsis_thaliana/Info/Index).

## Installation

1. Clone the repository:

```bash
git clone https://github.com/YibiChen/LncRNAPredictor.git
```

2. Download and install dependencies:

    - **Programs**:
        - fastq-dl
        - trim_galore
        - RSEM
        - salmon
        - hisat2
        - stringtie
        - samtools
        - gffread
        - gffcompare
        - cgat
        - FEELnc
        - cpc
        - featurecounts

## Usage

The `lncFETCHER.sh` script provides instructions for each step of the analysis in comments. It guides users through mapping data to the reference genome, assembling the transcriptome, creating a combined transcriptome, and predicting lncRNAs. Before running the pipeline, ensure that you have downloaded essential files such as the genome FASTA, annotation files in GFF/GTF format, and transcript fasta in the `ref` folder.

## References

1. [Benchmark of long non-coding RNA quantification for RNA sequencing of cancer samples](https://doi.org/10.1093/gigascience/giz145)
2. [The long non-coding RNA landscape of Candida yeast pathogens](https://doi.org/10.1038/s41467-021-27635-4)

For any questions or requests, please contact:
- Dr. Shailesh Kumar: shailesh@nipgr.ac.in
- AT Vivek: vivek37373@nipgr.ac.in; vivek37373@gmail.com

Feel free to reach out if you have any inquiries or require further assistance.

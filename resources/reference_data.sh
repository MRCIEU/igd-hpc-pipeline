#!/bin/bash

mkdir -p reference

# LD score files
curl -SL https://data.broadinstitute.org/alkesgroup/LDSCORE/eur_w_ld_chr.tar.bz2 | tar -xvjC reference

# SNP list
cp ../gwas_processing/w_hm3.noMHC.snplist.gz reference/snplist.gz

# LD reference panel
curl -SL https://www.dropbox.com/s/yuo7htp80hizigy/ | tar -xzvC reference

# 1kg vcf
ln -s ../../vcf-reference-datasets/1000g/1kg_v3_nomult.bcf reference/1kg_v3_nomult.bcf
ln -s ../../vcf-reference-datasets/1000g/1kg_v3_nomult.bcf.csi reference/1kg_v3_nomult.bcf.csi


# Reference fasta
wget -O reference/human_g1k_v37.fasta.gz ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/b37/human_g1k_v37.fasta.gz
wget -O reference/human_g1k_v37.fasta.fai.gz ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/b37/human_g1k_v37.fasta.fai.gz

gunzip reference/human_g1k_v37.fasta.gz
gunzip reference/human_g1k_v37.fasta.fai.gz



# Environments



thisdir=`pwd`


cd gwas_harmonisation

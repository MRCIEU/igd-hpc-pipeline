#!/bin/bash

gwasdir=${1}
id=${2}

gwasdir=`realpath ${gwasdir}`
echo "gwasdir: ${gwasdir}"
echo "id: ${id}"

module load languages/anaconda3/2018.12
cd gwas_processing
python clump.py \
--bcf ${gwasdir}/${id}/${id}.vcf.gz \
--plink_ref /mnt/storage/private/mrcieu/research/scratch/IGD/data/dev/reference/ld_files/data_maf0.01_rs \
--out ${gwasdir}/${id}/clump.txt

#!/bin/bash

gwasdir=${1}
id=${2}

gwasdir=`realpath ${gwasdir}`
echo "gwasdir: ${gwasdir}"
echo "id: ${id}"


module load languages/anaconda3/2018.12

cd gwas_processing
source activate ldsc

python2 ldsc.py \
--bcf ${gwasdir}/${id}/${id}.vcf.gz \
--ldsc_ref /mnt/storage/private/mrcieu/research/scratch/IGD/data/dev/reference/eur_w_ld_chr/ \
--out ${gwasdir}/${id}/ldsc.txt

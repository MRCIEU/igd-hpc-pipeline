#!/bin/bash

gwasdir=${1}
id=${2}

gwasdir=`realpath ${gwasdir}`
echo "gwasdir: ${gwasdir}"
echo "id: ${id}"

module load languages/anaconda3/2018.12
cd gwas2vcf
source ./venv/bin/activate
./venv/bin/python main.py \
	--json ${gwasdir}/${id}/${id}_data.json \
	--ref /mnt/storage/private/mrcieu/research/scratch/IGD/data/dev/QC/genomes/b37/human_g1k_v37.fasta


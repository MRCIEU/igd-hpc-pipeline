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
	--ref /mnt/storage/private/mrcieu/research/scratch/IGD/data/dev/QC/genomes/hg38/hg38.fa

java -jar ~/bin/picard.jar LiftoverVcf I=${gwasdir}/${id}/${id}_data.vcf.gz O=${gwasdir}/${id}/${id}_data_hg19.vcf.gz CHAIN=/mnt/storage/private/mrcieu/research/scratch/IGD/data/dev/QC/genomes/hg38/hg38ToHg19.over.chain REJECT=rejected_variants.vcf R=/mnt/storage/private/mrcieu/research/scratch/IGD/data/dev/QC/genomes/b37/human_g1k_v37.fasta WARN_ON_MISSING_CONTIG=true

mv ${gwasdir}/${id}/${id}_data.vcf.gz ${gwasdir}/${id}/${id}_data_hg38.vcf.gz

mv ${gwasdir}/${id}/${id}_data_hg19.vcf.gz ${gwasdir}/${id}/${id}_data.vcf.gz

bcftools index -t ${gwasdir}/${id}/${id}_data.vcf.gz
bcftools index -t ${gwasdir}/${id}/${id}_data_hg38.vcf.gz

rm ${gwasdir}/${id}/${id}_data_hg19.vcf.gz.tbi

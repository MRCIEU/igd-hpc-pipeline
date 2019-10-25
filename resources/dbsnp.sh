#!/bin/bash

gwasdir=${1}
id=${2}

gwasdir=`realpath ${gwasdir}`
echo "gwasdir: ${gwasdir}"
echo "id: ${id}"

VcfFile="${gwasdir}/${id}/${id}"
VcfFileAnnoPath="${gwasdir}/${id}/${id}_dbsnp.vcf.gz"
DbSnpVcfFile="/mnt/storage/home/gh13047/mr-eve/vcf-reference-datasets/dbsnp/dbsnp.v153.b37.vcf.gz"
RefGenomeFile="/mnt/storage/private/mrcieu/research/scratch/IGD/data/public/QC/genomes/b37/human_g1k_v37.fasta"

# bcftools norm \
# -f ${RefGenomeFile} \
# -m +any \
# -O z \
# -o ${VcfFile}_norm.vcf.gz

bcftools annotate \
-a ${DbSnpVcfFile} \
-c ID ${VcfFile}_data.vcf.gz \
-o ${VcfFile}.vcf.gz \
-O z

bcftools index -t ${VcfFile}.vcf.gz


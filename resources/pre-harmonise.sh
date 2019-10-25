#!/bin/bash
#SBATCH --nodes=1 
#SBATCH --cpus-per-task=1 
#SBATCH --mem 32G
#SBATCH --time=01:00:00
#SBATCH --output=job_reports/slurm-%A_%a.out

module load languages/r/3.5.2

echo "Running on ${HOSTNAME}"

if [ -n "${1}" ]; then
  echo "${1}"
  SLURM_ARRAY_TASK_ID=${1}
fi

i=$((${SLURM_ARRAY_TASK_ID} - 1))

# source config.sh
ids=($(cat idlist.txt))
echo ${#ids[@]}
id=`echo ${ids[$i]}`
echo $id
if [ -z "$id" ]
then
	echo "outside range"
	exit
fi

if [ -f "../gwas-files/${id}/${id}_data.txt.gz" ]; then
	exit
fi

gwasdir=`cat gwasdir.txt`


vcf_reference="/mnt/storage/private/mrcieu/research/scratch/IGD/data/public/report-module-sample/mrbase-report-module/ref_data/1kg_v3_nomult.bcf"

Rscript pre-harmonise.r \
--ref_file ${vcf_reference} \
--gwas_file ${gwasdir}/${id}/elastic.gz \
--delimiter $'\t' \
--gzipped 1 \
--skip 0 \
--dbsnp_field 1 \
--ea_field 2 \
--nea_field 3 \
--ea_af_field 4 \
--effect_field 5 \
--se_field 6 \
--pval_field 7 \
--n_field 8 \
--out ${gwasdir}/${id}/${id}_data


# time bcftools query -f '%CHROM\t%POS\t%ID\t%REF\t%ALT\t%AF\t%EFFECT\t%SE\t%L10PVAL\t%N\n' ${gwasdir}/${id}/data.bcf |
# awk '{print $1, $2, $3, $4, $5, $6, $7, $8, 10^-$9, $10}' > ${gwasdir}/${id}/${id}_data.txt




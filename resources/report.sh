#!/bin/bash
#SBATCH --nodes=1 
#SBATCH --cpus-per-task=1 
#SBATCH --mem 24G
#SBATCH --time=01:00:00
#SBATCH --output=job_reports/slurm-%A_%a.out


echo "Running on ${HOSTNAME}"

if [ -n "${1}" ]; then
  echo "${1}"
  SLURM_ARRAY_TASK_ID=${1}
fi

i=$((${SLURM_ARRAY_TASK_ID} - 1))

# source config.sh
ids=($(cat idlist.txt))
echo "Total files: ${#ids[@]}"
id=`echo ${ids[$i]}`
echo "This id: ${id}"
if [ -z "$id" ]
then
	echo "outside range"
	exit
fi

module load languages/anaconda3/2018.12
module load apps/bcftools-1.9-74/1.9-74
module load languages/r/3.5.2

# # load variables
# . ./raw/var


cd mrbase-report-module

gwasdir=`cat gwasdir.txt`

cp ../param.json ${gwasdir}/${id}/metadata.json



# get old ID
if echo "$id" | grep -q "IEU-a"; then
	id2=${id/IEU-a-/}
else
	id2=`sed 's/-/:/2' <<< $id`
fi
echo "original ID: $id2"


# produce the QC report
Rscript render_gwas_report.R \
	--output_dir ${gwasdir}/${id} \
	--refdata /mnt/storage/private/mrcieu/research/scratch/IGD/data/public/report-module-sample/mrbase-report-module/ref_data/1kg_v3_nomult.bcf \
	-j 5 \
	--id ${id2} \
	${gwasdir}/${id}/${id}.vcf.gz


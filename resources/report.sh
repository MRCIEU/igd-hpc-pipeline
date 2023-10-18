#!/bin/bash

gwasdir=${1}
id=${2}

gwasdir=`realpath ${gwasdir}`
echo "gwasdir: ${gwasdir}"
echo "id: ${id}"

module load languages/anaconda3/2018.12

cd opengwas-reports

# produce the QC report
Rscript render_gwas_report.R \
	--output_dir ${gwasdir}/${id} \
	--refdata /mnt/storage/private/mrcieu/research/scratch/IGD/data/dev/report-module-sample/mrbase-report-module/ref_data/1kg_v3_nomult.bcf \
	-j 5 \
	--id ${id} \
	${gwasdir}/${id}/${id}.vcf.gz

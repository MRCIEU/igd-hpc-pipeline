#!/bin/bash
#SBATCH --nodes=1 
#SBATCH --cpus-per-task=1 
#SBATCH --mem 32G
#SBATCH --time=01:00:00
#SBATCH --output=job_reports/slurm-%A_%a.out


echo "Running on ${HOSTNAME}"

if [ -n "${1}" ]; then
  echo "${1}"
  SLURM_ARRAY_TASK_ID=${1}
fi

echo "offset passed: ${offset}"
echo "script passed: ${script}"
script=`realpath ${script}`

i=$((${SLURM_ARRAY_TASK_ID} - 1 + ${offset}))
echo "i: ${i}"

gwasdir=`cat gwasdir.txt`
ids=($(cat idlist.txt))
echo "Total files: ${#ids[@]}"
id=`echo ${ids[$i]}`
echo "This id: ${id}"
if [ -z "$id" ]
then
	echo "outside range"
	exit
fi

cd resources
bash ${script} ${gwasdir} ${id}

#!/bin/bash

#mrcieu nodes
#SBATCH --job-name=es-indexing
#SBATCH --nodes=1 --tasks-per-node=28
#SBATCH --partition=mrcieu
#SBATCH --mem-per-cpu=4000
#SBATCH --time=5-00:00:00

module load Java/1.8.0_92
module load languages/anaconda3/3.5-4.2.0-tflow-1.7

#to run


#to check progress
#while true; do date; curl -X GET "localhost:9200/_cat/indices"; sleep 60; done

#pip install --user elasticsearch

#paths
es='/mnt/storage/scratch/be15516/software/elasticsearch/elasticsearch-6.5.3'
scripts='/mnt/storage/scratch/be15516/projects/mr-base-elastic/scripts'
parallel='/mnt/storage/scratch/be15516/software/parallel/parallel-20181122'
outputDir='/mnt/storage/private/mrcieu/research/UKBIOBANK_GWAS_Pipeline/data/phenotypes/be15516/es'


threads=27

batch_id=$1
data_dir=$2
index_name=$3
prefix=$4
batch_size=$5

#make some directories
mkdir -p $outputDir/data/$index_name
mkdir -p $outputDir/logs/$index_name
mkdir -p $outputDir/snapshots/$index_name

echo 'Checking for elastic'
status=$(curl -s -XGET 'localhost:9200')
if [ -z "$status" ]
then
	echo 'elasticsearch is not running :)'
else
	echo 'elasticsearch already running, killing jobs'
	kill -9 $(ps aux | grep '[e]lastic' | awk '{print $2}')
fi

#start up elasticsearch
echo 'Starting elasticsearch...'
host=`hostname`.pid
echo $host
$es/bin/elasticsearch -d -Enode.name=$index_name -Ecluster.name=$index_name -Epath.data=$outputDir/data/$index_name -Epath.logs=$outputDir/logs/$index_name -p $host

#index_name='test4'
#wait_time=100
echo 'Waiting for elasticsearch to start...'
#sleep $wait_time

secs=$((100))
while [ $secs -gt 0 ]; do
   echo -ne "$secs\033[0K\r"
   sleep 1
   : $((secs--))
done

echo 'ES check'
status=$(curl -s -XGET 'localhost:9200')
if [ -z "$status" ]
then
	echo 'something wrong, elasticsearch not started....'
	kill -9 $(ps aux | grep '[e]lastic' | awk '{print $2}')
	exit
else
	echo 'elasticsearch us running ok'
fi

echo 'Creating index'
python $scripts/add_gwas.py -m create_index -i $index_name

echo 'Checking index'
curl -s -XGET "localhost:9200/$index_name?pretty"

echo 'Indexing data'
for i in $(eval echo "{$batch_id..${batch_id+$batch_size}"});
do
	echo $i;
	python $scripts/add_gwas.py -m index_assoc -i $index_name -g $prefix:$i -f $data_dir/$prefix:$i/data.bcf
done

#echo 'Creating snapshot'
curl -s -XPUT 'http://localhost:9200/_snapshot/ukb-b' -H 'Content-Type: application/json' -d '{"type": "fs","settings": {"location": "/mnt/storage/private/mrcieu/research/UKBIOBANK_GWAS_Pipeline/data/phenotypes/be15516/es/snapshots/'$index_name'","compress": true}}'
curl -s -XPUT 'localhost:9200/_snapshot/ukb-b/'$index_name'?wait_for_completion=true' -H 'Content-Type: application/json' -d' {"indices": "'$index_name'","ignore_unavailable": true,"include_global_state": false}'

#should add a check for when snapshots are complete, but snapshots took around 4 hours, so 18,000 seconds.
#sleep 20000

#compress snapshot
echo 'Compressing snapshot'
tar cvfz $outputDir/snapshots/$index_name.tar.gz $outputDir/snapshots/$index_name

echo 'Stopping'
kill `cat $es/$host`
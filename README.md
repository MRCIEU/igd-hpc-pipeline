# GWAS QC Pipeline for HPC

## Cloning with submodules

This repository incorporates a bunch of submodules (one of which itself also has a submodule). To clone everything:

```
git clone --recurse-submodules git@github.com:MRCIEU/igd-hpc-pipeline.git
```

or if using https authentication

```
git clone --recurse-submodules https://github.com/MRCIEU/igd-hpc-pipeline.git
```

## Setting up environments

```
module add languages/anaconda3/5.2.0-tflow-1.11

# gwas2vcf
cd resources/gwas2vcf
python3 -m venv venv
source ./venv/bin/activate
./venv/bin/pip install -r requirements.txt

# ldsc
cd ../gwas_processing/ldsc
conda env create -f environment.yml

# mrbase report module
cd ../mrbase-report-module
conda env create -f env/environment.yml
```


## Background 

The objective of this pipeline is to process many similar GWAS datasets at once. 

This pipeline has the following steps:

1. (Optional) Flip to forward strand and map rs IDs to chromosome and position
2. Genearte meta data about each GWAS (eventually this will pass to the Neo4j database)
3. Organise the files into directory structures based on their
4. Create harmonised vcf files
5. Add dbsnp IDs, normalise, and 1000 genomes allele frequencies
6. Perform clumping
7. Perform LD score regression
8. Create html report
9. Index and upload to elastic (TODO)
10. Copy vcf directories to relevant locations (TODO)


## How to use

### 1. (Optional) Pre-harmonise datasets

If the dataset doesn't have chromosome/position columns, or might not have all SNPs on forward strand, then run the `resources/pre-harmonise.r` script

### 2. Upload meta data to neo4j

Here, for each dataset, we upload the metadata (e.g. trait name, pmid, etc) to Neo4j, and receive a unique identifier. This allows us to create a new spreadsheet which has all the information required to describe each dataset, and its final location

```
Rscript resources/metadata_to_json.r <inputdir> <gwasdir> <csv> <processedcsv> <cores>
```

Three things needed to start:

1. A directory that has all the GWAS summary data e.g

    ```
    inputdir/
             dataset1.txt.gz
             dataset2.txt.gz
            ...
    ```

2. A csv that has all the relevant meta data, with one row for each dataset. The csv needs the following columns:

    ```

    ```

3. An empty `<gwasdir>` directory that will be where the QC'd datasets will go. Each dataset will have a directory that is named according to the dataset's ID.

The script will output a new csv file which has all the metadata required to create the starting directory structures etc for each dataset



### 3. Organise files

```
Rscript resources/setup_directories.r <processedcsv>
```

This will create

```
gwasdir/
      <id1>/
            dataset1.txt.gz
            <id1>.json
            <id1>_data.json
      <id2>/
            dataset2.txt.gz
            <id2>.json
            <id2>_data.json
      ...
```

### 4. Create vcf

At this point we can submit to the cluster. First setup the set of jobs that need to be done

```bash
gwasdir="path_to_gwasdir"
maxjobs="200"
partition="mrcieu"

echo `realpath ${gwasdir}` > gwasdir.txt

p=`pwd`
cd ${gwasdir}
ls --color=none -d * > ${p}/idlist.txt
cd ${p}
head idlist.txt

nid=`cat idlist.txt | wc -l`
echo "${nid} datasets"
```

This should show how many datasets will be processed, based on finding them in the `gwasdir`. Next we can submit the jobs

```bash
export offset=3000
export script="resources/gwas2vcf.sh"
sbatch --partition=${partition} --array=1-1000%${maxjobs} --export=offset=${offset} --export=script=${script} bc4_submit.sh
```

This will run the first 1000 datasets. To do the next 1000, change `offset=0` to `offset=1000` and so on. This is to avoid queue limitations on job arrays.

The directory structure will now look like:

```
gwasdir/
      <id1>/
            dataset1.txt.gz
            <id1>_data.json
            <id1>.vcf.gz
      <id2>/
            dataset2.txt.gz
            <id2>_data.json
            <id2>.vcf.gz
      ...
```


### 5. Map IDs to dbsnp

```bash
export offset=0
export script="resources/dbsnp.sh"
sbatch --partition=${partition} --array=1-1000%${maxjobs} --export=offset=${offset} --export=script=${script} bc4_submit.sh
```

```
gwasdir/
      <id1>/
            dataset1.txt.gz
            <id1>_data.json
            <id1>_data.vcf.gz
      <id2>/
            dataset2.txt.gz
            <id2>_data.json
            <id2>_data.vcf.gz
      ...
```


### 6. Clump

```bash
export offset=0
export script="resources/clump.sh"
sbatch --partition=${partition} --array=1-1000%${maxjobs} --export=offset=${offset} --export=script=${script} bc4_submit.sh
```

```
gwasdir/
      <id1>/
            dataset1.txt.gz
            <id1>_data.json
            <id1>_data.vcf.gz
            clump.txt
      <id2>/
            dataset2.txt.gz
            <id2>_data.json
            <id2>_data.vcf.gz
            clump.txt
      ...
```


### 7. LD score regression

```bash
export offset=0
export script="resources/ldsc.sh"
sbatch --partition=${partition} --array=1-1000%${maxjobs} --export=offset=${offset} --export=script=${script} bc4_submit.sh
```

```
gwasdir/
      <id1>/
            dataset1.txt.gz
            <id1>_data.json
            <id1>_data.vcf.gz
            clump.txt
            ldsc.txt.log
      <id2>/
            dataset2.txt.gz
            <id2>_data.json
            <id2>_data.vcf.gz
            clump.txt
            ldsc.txt.log
      ...
```


### 8. Reports

```bash
export offset=0
export script="resources/report.sh"
sbatch --partition=${partition} --array=1-1000%${maxjobs} --export=offset=${offset} --export=script=${script} bc4_submit.sh
```

```
gwasdir/
      <id1>/
            dataset1.txt.gz
            <id1>_data.json
            <id1>_data.vcf.gz
            clump.txt
            ldsc.txt.log
            report.html
      <id2>/
            dataset2.txt.gz
            <id2>_data.json
            <id2>_data.vcf.gz
            clump.txt
            ldsc.txt.log
            report.html
      ...
```


---

## Snakemake

Steps 4-9 can be orchestrated using Snakemake. Best to run this in screen perhaps?

Load environment

```
module add languages/anaconda3/5.2.0-tflow-1.11
```

Create list of studies to include

```
gwasdir="path_to_gwasdir"
echo `realpath ${gwasdir}` > gwasdir.txt
p=`pwd`
cd ${gwasdir}
ls --color=none -d * > ${p}/idlist.txt
cd ${p}
head idlist.txt
nid=`cat idlist.txt | wc -l`
echo "${nid} datasets"
```

Dry run:

```
snakemake -nr | less
```

Actually run:

```
snakemake -prk \
-j 400 \
--cluster-config bc4-cluster.json \
--cluster "sbatch \
  --job-name={cluster.name} \
  --partition={cluster.partition} \
  --nodes={cluster.nodes} \
  --ntasks-per-node={cluster.ntask} \
  --cpus-per-task={cluster.ncpu} \
  --time={cluster.time} \
  --mem={cluster.mem} \
  --output={cluster.output}"
```


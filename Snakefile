import os.path
import re
import subprocess

# Define some variables
with open("gwasdir.txt", "r") as f:
	GWASDIR = f.read().strip()
ID = [line.strip() for line in open("idlist.txt", "r")]

if not os.path.exists("job_reports"):
	os.makedirs("job_reports")

rule all:
	input:
		expand('{GWASDIR}/{id}/clump.txt', GWASDIR=GWASDIR, id=ID),
		expand('{GWASDIR}/{id}/ldsc.txt.log', GWASDIR=GWASDIR, id=ID),
		expand('{GWASDIR}/{id}/{id}_report.html', GWASDIR=GWASDIR, id=ID)


rule gwas2vcf:
	input:
		'{GWASDIR}/{id}/{id}_data.json'
	output:
		'{GWASDIR}/{id}/{id}_data.vcf.gz'
	shell:
		'cd resources; bash gwas2vcf.sh {GWASDIR} {wildcards.id}'


rule dbsnp:
	input:
		'{GWASDIR}/{id}/{id}_data.vcf.gz'
	output:
		'{GWASDIR}/{id}/{id}.vcf.gz'
	shell:
		'cd resources; bash dbsnp.sh {GWASDIR} {wildcards.id}'


rule clump:
	input:
		'{GWASDIR}/{id}/{id}.vcf.gz'
	output:
		'{GWASDIR}/{id}/clump.txt'
	shell:
		'cd resources; bash clump.sh {GWASDIR} {wildcards.id}'


rule ldsc:
	input:
		'{GWASDIR}/{id}/{id}.vcf.gz'
	output:
		'{GWASDIR}/{id}/ldsc.txt.log'
	shell:
		'cd resources; bash ldsc.sh {GWASDIR} {wildcards.id}'


rule report:
    input:
        '{GWASDIR}/{id}/{id}.vcf.gz'
    output:
        '{GWASDIR}/{id}/{id}_report.html'
    shell:
        'cd resources; bash report.sh {GWASDIR} {wildcards.id}'

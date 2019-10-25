#!/usr/bin/env Rscript
suppressPackageStartupMessages({
	library(argparse)
	library(dplyr)
	library(TwoSampleMR)
	library(gwasvcftools)
	# library(unixtools)
	library(jsonlite)
})

# create parser object
parser <- ArgumentParser()
parser$add_argument('--ref_file', required=TRUE)
parser$add_argument('--gwas_file', required=TRUE)
parser$add_argument('--gzipped', required=TRUE, type="integer", default=1)
parser$add_argument('--delimiter', default="\t", required=TRUE)
parser$add_argument('--skip', required=TRUE, type="integer", default=0)
parser$add_argument('--dbsnp_field', type="integer", required=TRUE)
parser$add_argument('--ea_field', type="integer", required=TRUE)
parser$add_argument('--nea_field', type="integer", required=FALSE, default=0)
parser$add_argument('--ea_af_field', type="integer", required=FALSE, default=0)
parser$add_argument('--effect_field', type="integer", required=FALSE, default=0)
parser$add_argument('--se_field', type="integer", required=FALSE, default=0)
parser$add_argument('--pval_field', type="integer", required=FALSE, default=0)
parser$add_argument('--n_field', type="integer", required=FALSE, default=0)
parser$add_argument('--info_field', type="integer", required=FALSE, default=0)
parser$add_argument('--z_field', type="integer", required=FALSE, default=0)
parser$add_argument('--out', required=TRUE)
args <- parser$parse_args()
str(args)


# Read in GWAS data
# set.tempdir("tmp")
gwas <- read_gwas(
	args[["gwas_file"]],
	skip=args[["skip"]],
	snp=args[["dbsnp_field"]],
	gzipped=args[["gzipped"]],
	delimiter=args[["delimiter"]],
	ea=args[["ea_field"]],
	nea=args[["nea_field"]],
	ea_af=args[["ea_af_field"]],
	effect=args[["effect_field"]],
	se=args[["se_field"]],
	pval=args[["pval_field"]],
	n=args[["n_field"]],
	info=args[["info_field"]],
	z=args[["z_field"]]
)


# Read in ref
ref <- read_reference(args[["ref_file"]], gwas$SNP, args[["out"]]) 

# Harmonise
harmonised <- harmonise_against_ref(gwas, ref)
write_out(harmonised, args[["out"]])



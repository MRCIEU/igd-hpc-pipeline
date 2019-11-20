library(jsonlite)
library(dplyr)
library(parallel)

args <- commandArgs(T)

# Sample sheet
ss <- args[1] 

# Directory containing all ready GWAS datasets
indir <- args[2]

# Output directory e.g. IGD/public
# outdir <- paste0(indir, "/processed")
outdir <- args[3]
dir.create(outdir)

json_template <- args[4]
cores <- as.numeric(args[5])

b <- read.csv(ss, stringsAsFactors=FALSE)
meta_required <- c("id", "build", "group_name", "access", "trait", "category", "subcategory", "population", "sex", "nsnp")
meta_allowed <- c("pmid", "year", "author", "unit", "mr", "sample_size", "ncase", "ncontrol", "note", "sd", "priority")

col_required <- c("chr_col", "pos_col", "ea_col", "oa_col", "beta_col", "se_col", "pval_col", "delimiter", "header", "build")
col_allowed <- c("ncase_col", "snp_col", "eaf_col", "oaf_col", "imp_z_col", "imp_info_col", "ncontrol_col", "id", "cohort_cases", "cohort_controls")

stopifnot(all(col_required %in% names(b)))
stopifnot(all(b$build %in% c("HG19/GRCh37")))
stopifnot(all(b$header) %in% c(TRUE, FALSE))

stopifnot(all(meta_required %in% names(b)))
stopifnot("filename" %in% names(b))

b$inpath <- file.path(indir, b$filename)
index <- file.exists(b$inpath)
message("How many of the meta data rows have corresponding files?")
table(index)
if(sum(!index) > 0)
{
	message("SOME OF THE TRAITS WITH METADATA DON'T HAVE FILES")
}
b <- b[index,]
cols <- names(b)
meta_index <- which(cols %in% c(meta_allowed, meta_required))


# upload meta data
# toggle_api("dev")
# tok <- get_access_token()
# for(i in 1:nrow(b))
# {
# 	message(i, " of ", nrow(b))
# 	r <- api_query("edit/add", query = as.list(b[i,meta_index]), access_token=tok)
# 	id <- get_query_content(r)$id
# 	# r <- api_query(paste0("edit/delete/", id), access_token=tok, method="DELETE")
# 	if(class(r) != "response")
# 	{
# 		b$id[i] <- id
# 		b$meta_upload[i] <- "Success"
# 	} else {
# 		b$meta_upload[i] <- "Fail"
# 	}
# }

sink <- mclapply(1:nrow(b), function(i)
{
	message(i, " of ", nrow(b))
	x <- b[i,meta_index] %>% as.list()
	x <- Filter(Negate(anyNA), x)
	jsonfile <- file.path(indir, paste0(x$id, ".json"))
	write_json(b, jsonfile, auto_unbox = TRUE, pretty=TRUE)
}, mc.cores=cores)

# Create data for json creation

b$jsonmeta <- file.path(indir, paste0(b$id, ".json"))
b$dirname <- file.path(outdir, b$id)
b$data <- file.path(b$dirname, b$filename)
b$out <- file.path(b$dirname, paste0(b$id, "_data.vcf.gz"))
b$jsonout <- file.path(b$dirname, paste0(b$id, "_data.json"))


# Remove unrequired cols that are all NA

index <- apply(b, 2, function(x) all(is.na(x))) & names(b) %in% col_allowed
if(sum(index) > 0)
{
	b <- b[,!index]
}

file_cols <- which(names(b) %in% c("inpath", "jsonmeta", "dirname", "jsonout", "meta_upload", "data", "out", "id", "header", "delimiter", "cohort_cases", "cohort_controls", "build") | grepl("_col", names(b)))
names(b)[file_cols]

B <- b[,file_cols]
write.csv(B, file=json_template)

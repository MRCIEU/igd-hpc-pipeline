library(jsonlite)
library(dplyr)
library(parallel)

args <- commandArgs(T)
json_template <- args[1]
cores <- as.numeric(args[2])

b <- read.csv(json_template, stringsAsFactors=FALSE)
b <- subset(b, select=-c(X))
stopifnot(all(file.exists(b$inpath)))
b$delimiter[b$delimiter == "tab"] <- "\t"
b$delimiter[b$delimiter == "space"] <- " "
table(b$delimiter)

out <- mclapply(1:nrow(b), function(i)
{
	message(i, " of ", nrow(b))
	dir.create(path = dirname(b$data[i]), recursive=TRUE)
	file.copy(b$inpath[i], b$data[i], overwrite=TRUE)
	file.copy(b$jsonmeta[i], b$dirname[i], overwrite=TRUE)
	dat <- b[i, !names(b) %in% c("dirname", "jsonout", "inpath")] %>% as.list()
	dat <- Filter(Negate(anyNA), dat)
	write_json(dat, b$jsonout[i], auto_unbox = TRUE)
}, mc.cores=cores)


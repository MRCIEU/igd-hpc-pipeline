library(jsonlite)
library(dplyr)

args <- commandArgs(T)
json_template <- args[1]


b <- read.csv(json_template, stringsAsFactors=FALSE)
b <- subset(b, select=-c(X))
stopifnot(all(file.exists(b$inpath)))
b$delimiter[b$delimiter == "tab"] <- "\t"

b <- subset(b, meta_upload == "Success")

for(i in 1:nrow(b))
{
	message(i, " of ", nrow(b))
	dir.create(path = dirname(b$data[i]), recursive=TRUE)
	file.copy(b$inpath[i], b$data[i], overwrite=TRUE)
	dat <- b[i, !names(b) %in% c("dirname", "jsonout", "inpath")] %>% as.list()
	dat <- Filter(Negate(anyNA), dat)
	write_json(dat, b$jsonout[i], auto_unbox = TRUE)
}


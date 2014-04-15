source("H:/R/hrms/hrms.R")
library(xcms)
library(data.table)
setwd("H:/R/biocrates/msExactiveData/biocrates")
files = list.files(".", pattern=".mzXML")
system.time(
  for (i in 1:length(files)) {
    main(files[i], rtwin=c(0,60), mzwin=c(200,1800))
  }
)

results <- signals_deviations()

X <- signals[,3:ncol(results[[1]])]
#calculate coverage
coverage <- numeric()
for (i in 1:nrow(X)) {
  ROW <- X[i,]
  coverage[i] <- length(which(ROW>0))/ncol(X)
}

#make a DF and sort it by coverage
signals <- results[[1]]
coverageDF <- data.frame(signals[,1],coverage)
attach(coverageDF)
coverageDF <- coverageDF[order(-coverage),]
detach(coverageDF)




######################################
# new code suggested by Luke and modified by Eric
# produces a summary signals.csv file for a single plate
# then converts the file into something more manageable and useful for analysis

# produce signals.csv summary file
source("U:/GitHub/hrms/hrms.R")
library(xcms)
library(data.table)

for(i in 1:2) {
	setwd(paste("E:/PROMIS/csv_files/PROMIS__00", i, "/", sep=""))
	source("U:/GitHub/hrms/signals_deviations.R")
	results <- signals_deviations()

	# prepare signal data from signals_deviations.R output 
	signals <-  read.csv("signals.csv")
	X <- signals[,3:ncol(signals)]
	X <- as.data.frame(t(X))
	m_z <- paste("m_z_", signals[,2], sep="")
	colnames(X) <- gsub("[[:punct:]]", "_", m_z)	# regex search to replace "." with "_" in column names
	 
	# pull out date, lab technician, sample number, and sample name for each sample
	newmatrix <- matrix(unlist(strsplit(rownames(X), split = "__")), ncol = 5, byrow = T)
	mrc_date <- gsub("^X", "", newmatrix[,1])
	mrc_technician <- newmatrix[,2]
	mrc_samplenum <- as.numeric(newmatrix[,4])
	mrc_samplename <- sub(".csv$", "", newmatrix[,5])
	rownames(X) <- mrc_samplename
	fileout <- cbind(mrc_samplename, mrc_samplenum, mrc_date, mrc_technician, X)

	# output to csv file
	setwd("E:/PROMIS/csv_files/")
	filename <- paste("E:/PROMIS/csv_files/PROMIS__00", i, "_signals.csv", sep="")
	write.csv(fileout, file=filename, row.names=F)
}
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
library(stringr)
setwd("E:/PROMIS/csv_files/PROMIS__001/")
source("U:/GitHub/hrms/signals_deviations.R")
results <- signals_deviations()

# prepare signal data from signals_deviations.R output 
signals <-  read.csv("signals.csv")
X <- signals[,3:ncol(signals)]
X <- as.data.frame(t(X))
m_z <- paste("m_z_", signals[,2], sep="")
colnames(X) <- gsub("[[:punct:]]", "_", m_z)	# regex search to replace "." with "_" in column names
 
# pull out date, lab technician, well number, and sample name for each sample
newvars <- vector(mode="list",length=length(rownames(X)))
mrc_date <- vector(mode="list",length=length(rownames(X)))
mrc_technician <- vector(mode="list",length=length(rownames(X)))
mrc_samplenum <- vector(mode="list",length=length(rownames(X)))
mrc_samplename <- vector(mode="list",length=length(rownames(X)))
for (i in 1:length(rownames(X))) {
	newvars[[i]] <- as.data.frame(as.list(str_split(rownames(X)[i], "__")))
	mrc_date[[i]] <- substring(newvars[i,1], first=2, last=9)
	mrc_technician[[i]] <- newvars[i,2]
	mrc_samplenum[[i]] <- as.numeric(newvars[i,4])
	mrc_samplename[[i]] <- gsub(".csv", "", newvars[i,5])
}
rownames(X) <- mrc_samplename
X <- cbind(mrc_date, mrc_technician, mrc_samplenum, X)

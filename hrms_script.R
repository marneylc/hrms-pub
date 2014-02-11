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
signals_deviations <- function() { # the csv files must be in the active directory
  require(data.table)
  files <- list.files(".", pattern = "*.csv")
  x <- read.csv(files[1], header=T)
  targets <- read.table("./LipidList.csv" , header=T, sep=',')
  targets <- data.table(targets)
  signals <- data.frame(x$targets.name,targets$mz)
  for (i in 1:length(files)) {
    x <- read.csv(gsub(pattern=".mzXML", x=files[i], replacement=".csv"),header=T)
    signals[files[i]] <- data.frame(x$signal)
  }
  
  x <- read.csv(gsub(pattern=".mzXML", x=files[1], replacement=".csv"),header=T)
  deviations <- data.frame(x$targets.name,targets$mz)
  for (i in 1:length(files)) {
    x <- read.csv(gsub(pattern=".mzXML", x=files[i], replacement=".csv"),header=T)
    deviations[files[i]] <- data.frame(x$mz_deviation)
  }
  results <- list(signals,deviations)
  write.csv(results[[1]],file="signals.csv", row.names=F)
  write.csv(results[[2]],file="deviations.csv", row.names=F)
  return(results)
}
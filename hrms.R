# the target list must be in active directory and called LipidList.csv
# to call from within R, execute the following 3 commands
# source("./hrms")
# main(filename,rt=c(0,60),mz=c(200,1800))
# results <- snd()
# 
# if you want to run this for all data files in a directory run the following command after getting
# the name of all files into the list variable "files"
# system.time( 
# for (i in 1:length(files)) { 
#  main(files[i],rtwin=c(0,60),mzwin=c(200,1800))
#}
#)


main <- function(filename,rtwin,mzwin) {
  require(xcms)
  require(data.table)
  targets <- read.table("./LipidList.csv" , header=T, sep=',')
  targets <- data.table(targets)
  spectrum <- getspectra(filename=filename, rt=rtwin, mz=mzwin)
  tgts <- peaktable(targets,spectrum)
  write.csv(tgts, file = gsub(pattern=".mzXML", x=filename, replacement=".csv"), row.names=F)
  #return(tgts) # this is bugy, doesnt return the correct structure for looping function, need to figure out
  # but csv mode works
}

snd <- function() { # the csv files must be in the active directory
  x <- read.csv(gsub(pattern=".mzXML", x=files[1], replacement=".csv"),header=T)
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

getspectra <- function(filename,rt,mz) {
  # rt <- c(0,60)
  # mz <- c(200,1800)
  spectra <- list()
  spectrum <- getSpec(xcmsRaw(filename), rtrange=rt, mzrange=mz)
  spectrum[,"mz"] <- round(spectrum[,"mz"], digits=4)
  spectrum <- as.data.table(spectrum)
  spectrum <- spectrum[,mean(intensity), by=mz]
  spectrum <- na.omit(spectrum)
  setkey(spectrum,mz)
  return(spectrum)
}

peaktable <- function(targets,spectra) {
  nearest_mz <- vector(length=length(targets$mz)) #predefine length later
  signal <- vector(length=length(targets$mz)) #predefine length later
  for (i in 1:length(targets$mz)) {
    target <- targets[i,mz]
    peak <- peakfind(target,spectra,0.01)
    nearest_mz[i]<-peak[1,mz]
    signal[i]<-peak[1,V1]
  }
  
  mz_deviation <- targets[,mz] - nearest_mz
  peak_id <- data.frame(targets$name,targets$mz,nearest_mz,mz_deviation,signal)
  return(peak_id)
}


peakfind <- function(target,spectra,hwidth) {
  window <- subset(spectra, spectra$mz > target-hwidth & spectra$mz < target+hwidth)
  setkey(window,V1) #this will sort table by intensity, thus finding peak maximum as last entry in table
  peak <- window[length(window$mz)] #get last entry of table for the peak maximum
  #plot(window, type='h', lwd=1)
  return(peak) 
}
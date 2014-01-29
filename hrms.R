#############################################################################
### The target list must be in active directory and called LipidList.csv. ###
### To call from within R, execute the following two commands ###############
# > source("hrms.R")
# > main(filename,rtwin=c(0,60),mzwin=c(200,1800)) 
# where rtwin is the retention time window in sec and mzwin is the mzwindow in m/z units
#
### If you want to run this for all data files in a directory run the following command after getting
### the name of all files into the list variable "files"
# > system.time( 
# > for (i in 1:length(files)) { 
# >   main(files[i],rtwin=c(0,60),mzwin=c(200,1800))
# > }
# >)
# > results <- signals_deviations() 
### this last line will produce the csv files signals 
### and deviations which puts multiple files data together into two csv files plus returns
### the data.frames in the list "results"
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

#############################################################################
### This function is used after main() has been run in a loop of multiple ###
### filenames/spectra. It reads the multiple .csv's in a directory and ######
### creates the .csv files signals.csv and deviations.csv which have ########
### rownames of target metabolite and column names as the filename ##########
### It's output is .csv files, so there are no arguments needed. The ########
### active directory must be set to the directory of the csv files created ##
### by main() ###############################################################
signals_deviations <- function() { # the csv files must be in the active directory
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

###################################################################################
### this function uses xcms to get the average spectra for a sample ###############
### and cleans up the spectra by rounding the ms data to 4 decimal places #########
### as well as removing NA values. The function has three arguments, a file name ##
### the retention time window that data will be averaged from #####################
### the direct infusion of sample and the mass spectral range that is desired. ####
### common values are: rt <- c(0,60) and mz <- c(200,1800) ########################
getspectra <- function(filename,rt,mz) {
  spectra <- list()
  spectrum <- getSpec(xcmsRaw(filename), rtrange=rt, mzrange=mz)
  spectrum[,"mz"] <- round(spectrum[,"mz"], digits=4)
  spectrum <- as.data.table(spectrum)
  spectrum <- spectrum[,mean(intensity), by=mz]
  spectrum <- na.omit(spectrum)
  setkey(spectrum,mz)
  return(spectrum)
}

################################################################
### This function calls the peakfinding algorithm in a loop ####
### finding the closest peak maximum m/z and intensity values ##
### appending results to variables signals and nearest_mz. #####
### It returns the data.frame peak_id which includes all #######
### results from the targeted analysis of the current spectra ##
peaktable <- function(targets,spectra) {
  nearest_mz <- vector(length=length(targets$mz)) #predefine length later
  signal <- vector(length=length(targets$mz)) #predefine length later
  for (i in 1:length(targets$mz)) {
    target <- targets[i,mz]
    peak <- peakfind_midpoint(target,spectra,0.01)
    nearest_mz[i]<-peak[1,mz]
    signal[i]<-peak[1,V1]
  }
  
  mz_deviation <- targets[,mz] - nearest_mz
  peak_id <- data.frame(targets$name,targets$mz,nearest_mz,mz_deviation,signal)
  return(peak_id)
}

################################################################################################################
### This is a refined peak finder that calculates the midpoint between a line drawn at the half height. This ###
### will give closer m/z values, but does not correct any small errors in intensity calculations from the ######
### peak max finder. Used in main() as of 28/01/2014. -Luke Marney #############################################
peakfind_midpoint <- function(target,spectra,hwidth) {
  window <- subset(spectra, spectra$mz > target-hwidth & spectra$mz < target+hwidth)
  if (nrow(window)==0) { # no data for target?
    peak = data.table('mz'=target,'V1'=0) # enter zero intensity for target mass
  } else if (sum(window$V1) < 5000) { # very low s/n?
    peak <- peakfind_max(target,spectra,hwidth) # uses older peakmax finder for low s/n peaks, while less accurate this helps with exception handling dramatically
    warning(paste("low signal/noise found for target mass-", target, "-using older peakmax finder. Identification may not be accurate", sep=" "))
  } else { # now we run the peak width peak finder
    ## at this point we need to readjust window first to the maximum found with peakfind_max(). ##
    ## This centers the peak better in a window, so that the entire peak ##
    ## is sampled for width at half height calculations. The rest of this function does this ##
    ## as well as the actual width at half height calculations.##
    peak <- peakfind_max(target,spectra,hwidth)
    hh_close=peak[1,V1]/2
    window <- subset(spectra, spectra$mz > peak$mz-hwidth & spectra$mz < peak$mz+hwidth)
    if (window$V1[length(window$mz)] > hh_close | window$V1[1] > hh_close) { # window doesn't sample the width of the peak?
      setkey(window,V1) #this will sort table by intensity, thus finding peak maximum as last entry in table
      peak <- window[length(window$mz)] #get last entry of table for the peak maximum
      window <- subset(spectra, spectra$mz > peak$mz-hwidth & spectra$mz < peak$mz+hwidth)
      if (window$V1[length(window$mz)] > hh_close | window$V1[1] > hh_close) { # is the bad sampling of peak due to interference?
        setkey(window,V1) #this will sort table by intensity, thus finding peak maximum as last entry in table
        peak <- window[length(window$mz)] #get last entry of table for the peak maximum
        warning((paste("interfered peak detected for target mass-", target, "-older peak_max() function used", sep=" ")))
      }
    } else {
      ## for resolved peaks (at half height) the follow code is run ##
      setkey(window,V1) #this will sort table by intensity, thus finding peak maximum as last entry in table
      peak <- window[length(window$mz)] #get last entry of table for the peak maximum
      hh=peak[1,V1]/2
      nearmz=peak[1,mz]
      left_mzs <- c(max(subset(window, window$mz < nearmz & window$V1 < hh)$mz),min(subset(window, window$mz < nearmz & window$V1 > hh)$mz))
      left_int <- c(max(subset(window, window$mz < nearmz & window$V1 < hh)$V1),min(subset(window, window$mz < nearmz & window$V1 > hh)$V1))
      right_mzs <- c(max(subset(window, window$mz > nearmz & window$V1 < hh)$mz),min(subset(window, window$mz > nearmz & window$V1 > hh)$mz))
      right_int <- c(max(subset(window, window$mz > nearmz & window$V1 < hh)$V1),min(subset(window, window$mz > nearmz & window$V1 > hh)$V1))
      midpoints <- data.frame(left_mzs,left_int,right_mzs,right_mzs)
      ### there has got to be a way to combine the last five rows into one row
      coordinates <- list()
      left <- coefficients(lm(left_int ~ left_mzs, data=midpoints))
      right <- coefficients(lm(right_int ~ right_mzs, data=midpoints))
      midpoint <- ((hh-left[1])/left[2]+(hh-right[1])/right[2])/2 # midpoint between the intersection points of both lines from a y=hh flat line
      peak$mz <- round(midpoint[1], digits=4) # modify the peaks variable with the new more accurate m/z value
    }
  }
  #zz <- file("warnings.Rout", open="wt") # somehow I want to write all the warnings to a text file!!
  #sink(zz, type="message", append=TRUE)
  return(peak)
}

###################################################
### This function is the simplest peak finder. ####
### It finds the maximum intensity in a defined  ##
### window around the target m/z. Not used in #####
### main() as of 28/01/2014. -Luke Marney #########
peakfind_max <- function(target,spectra,hwidth) {
  window <- subset(spectra, spectra$mz > target-hwidth & spectra$mz < target+hwidth)
  setkey(window,V1) #this will sort table by intensity, thus finding peak maximum as last entry in table
  peak <- window[length(window$mz)] #get last entry of table for the peak maximum
  #plot(window, type='h', lwd=1)
  return(peak) 
}
setwd("H:/R/hrms")
files = list.files(path=".", pattern="*.mzXML")
source("hrms.R")
system.time(
for (i in 1:length(files)) {
  main(files[i],rtwin=c(0,60),mzwin=c(200,1800))
}
)


targets <- read.table("./LipidList.csv" , header=T, sep=',')
targets <- data.table(targets)
spectra <- getspectra(filename=files[1], rt=c(0,60), mz=c(200,1800))
nearest_mz <- vector(length=length(targets$mz)) #predefine length later
signal <- vector(length=length(targets$mz)) #predefine length later
hwidth=0.01

for (i in 1:length(targets$mz)) {
  target <- targets[i,mz]
  print(i)
  window <- subset(spectra, spectra$mz > target-hwidth & spectra$mz < target+hwidth)
  if (nrow(window)==0) { # no data for target?
    peak = data.table('mz'=target,'V1'=0) # enter zero intensity for target mass
    #return(peak)
  } else if (sum(window$V1) < 5000) { # very low s/n?
    peakmax <- peakfind_max(target,spectra,hwidth) # uses older peakmax finder for low s/n peaks, while less accurate this helps with exception handling dramatically
    warning(paste("potentially low signals are being found for target mass-", target, "-identification may not be accurate", sep=" "))
    #return(peakmax)
  } else { # now we run the peak width peak finder
      ## at this point we need to readjust window first to the maximum found with peakfind_max(). ##
      ## This centers the peak better in a window, so that the entire peak ##
      ## is sampled for width at half height calculations. The rest of this function does this ##
      ## as well as the actual width at half height calculations.##
      peakmax <- peakfind_max(target,spectra,hwidth)
      hh_close=peakmax[1,V1]/2
      window <- subset(spectra, spectra$mz > peakmax$mz-hwidth & spectra$mz < peakmax$mz+hwidth)
      if (window$V1[length(window$mz)] > hh_close | window$V1[1] > hh_close) { # window doesn't sample the width of the peak?
        setkey(window,V1) #this will sort table by intensity, thus finding peak maximum as last entry in table
        peakmax <- window[length(window$mz)] #get last entry of table for the peak maximum
        window <- subset(spectra, spectra$mz > peakmax$mz-hwidth & spectra$mz < peakmax$mz+hwidth)
        if (window$V1[length(window$mz)] > hh_close | window$V1[1] > hh_close) { # is the bad sampling of peak due to interference?
          setkey(window,V1) #this will sort table by intensity, thus finding peak maximum as last entry in table
          peak <- window[length(window$mz)] #get last entry of table for the peak maximum
          warning((paste("interfered peak detected for target mass-", target, "-older peak_max() function used", sep=" ")))
          #return(peak)
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
}

i <- 106

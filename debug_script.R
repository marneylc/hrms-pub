# basic input to get file names and run code
setwd("H:/R/hrms")
files = list.files(path=".", pattern="*.mzXML")
source("hrms.R")
system.time(
for (i in 1:length(files)) {
  main(files[i],rtwin=c(20,70),mzwin=c(200,1000))
}
)

# when errors occur you can set a few key variables in the various functions and then call them in a for loop
# instead of by function name
targets <- read.table("./LipidList.csv" , header=T, sep=',')
targets <- data.table(targets)
spectra <- getspectra(filename=files[1], rt=c(0,60), mz=c(200,1800))
nearest_mz <- vector(length=length(targets$mz)) #predefine length later
signal <- vector(length=length(targets$mz)) #predefine length later
hwidth=0.01


# this is the peakfind_midpoint function turned into a for loop
# make sure you copy and paste the appropriate lines to reflect the latest
# code version you are running. This will print the variable i to the 
# console so that you can see at which target the code failed
for (i in 1:length(targets$mz)) {
  target <- targets[i,mz]
  print(i)
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
      setkey(window,mz)
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
      ### separate left and right side of peak
      left <- window[window[,mz] <= peak$mz]
      right <- window[window[,mz] >= peak$mz]
      left_one <- left[left[,V1] <= hh]; left_one <- left_one[length(left_one[,mz])] # closest point below hh needs to index last entry in table
      left_two <- left[left[,V1] >= hh][1] # can do an index of 1, because it is sorted by intensity
      right_one <- right[right[,V1] >= hh][1] # can do an index of 1, because it is sorted by intensity
      right_two <- right[right[,V1] <= hh]; right_two <- right_two[length(right_two[,mz])] # closest point below hh needs to index last entry in table
      if (left_two[,mz] == right_one[,mz]) {warning(paste("Same point seen for left and right side of", target, ". Possible undersampled peaks?")) }
      ### organize data into a data frame (called midpoints) for easier handling
      left_mzs <- c(left_one[,mz],left_two[,mz])
      left_int <- c(left_one[,V1],left_two[,V1])
      right_mzs <- c(right_one[,mz],right_two[,mz])
      right_int <- c(right_one[,V1],right_two[,V1])
      midpoints <- data.frame(left_mzs,left_int,right_mzs,right_int)
      ### there has got to be a way to combine the last five rows into one row
      coordinates <- list()
      left <- coefficients(lm(left_int ~ left_mzs, data=midpoints))
      right <- coefficients(lm(right_int ~ right_mzs, data=midpoints))
      midpoint <- ((hh-left[1])/left[2]+(hh-right[1])/right[2])/2 # midpoint between the intersection points of both lines from a y=hh flat line
      peak$mz <- round(midpoint[1], digits=4) # modify the peaks variable with the new more accurate m/z value
    }
  }
}

i <- 37
# setting the variable "i" to a particular value and running the code inside the above for loop
# will let you find the exact line that the error happens
# very useful is the plotting of the variable window: plot(window)
# so that you can actually see where the code is looking for the target 
# peak and why errors might be occurring


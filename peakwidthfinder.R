for (i in 1:length(targets$mz)) {
  

targets <- read.table("./LipidList.csv" , header=T, sep=',')
targets <- data.table(targets)
spectra <- getspectra(filename=files[1], rt=c(0,60), mz=c(200,1800))
nearest_mz <- vector(length=length(targets$mz)) #predefine length later
signal <- vector(length=length(targets$mz)) #predefine length later
hwidth=0.01

# need to set a threshold here to remove low S/N peaks
threshold = 1000
setkey(spectra,V1)
belowthresh <- sum(spectra[,V1] < threshold)
spectra = spectra[belowthresh+1:dim(spectra)[1],]

# find peaks
nearest_mz <- vector(length=length(targets$mz)) #predefine length later
signal <- vector(length=length(targets$mz)) #predefine length later
widths <- vector(length=length(targets$mz))
for (i in 1:length(targets$mz)) {
  target <- targets[i,mz]
  peakinfo <- peakfind_mid_n_width(target,spectra,0.1)
  nearest_mz[i]<-peakinfo[[1]][1,mz]
  signal[i]<-peakinfo[[1]][1,V1]
  widths[i]<-peakinfo[[2]]
}
  
  
peakfind_mid_n_width <- function(target,spectra,hwidth) {
  target <- targets[i,mz]
  print(i)
  window <- subset(spectra, spectra$mz > target-hwidth & spectra$mz < target+hwidth)
  if (nrow(window)==0) { # no data for target?
    peak <- data.table('mz'=target,'V1'=0) # enter zero intensity for target mass
    distance <- 0
  } else {
    setkey(window,V1) #this will sort table by intensity, thus finding peak maximum as last entry in table
    #center the peak better in a window, so that the entire peak is sampled for width at half height calculations.
    peakmax <- peakfind_max(target,spectra,hwidth)
    hh_close=peakmax[1,V1]/2
    window <- subset(spectra, spectra$mz > peakmax$mz-hwidth & spectra$mz < peakmax$mz+hwidth)
    peak <- window[length(window$mz)] #get last entry of table for the peak maximum
    hh=peak[1,V1]/2
    nearmz=peak[1,mz]
    left_mzs <- c(max(subset(window, window$mz < nearmz & window$V1 < hh)$mz),min(subset(window, window$mz < nearmz & window$V1 > hh)$mz))
    left_int <- c(max(subset(window, window$mz < nearmz & window$V1 < hh)$V1),min(subset(window, window$mz < nearmz & window$V1 > hh)$V1))
    right_mzs <- c(max(subset(window, window$mz > nearmz & window$V1 < hh)$mz),min(subset(window, window$mz > nearmz & window$V1 > hh)$mz))
    right_int <- c(max(subset(window, window$mz > nearmz & window$V1 < hh)$V1),min(subset(window, window$mz > nearmz & window$V1 > hh)$V1))
    midpoints <- data.frame(left_mzs,left_int,right_mzs,right_mzs)
    ### there has got to be a way to combine the last five rows into one row
    left <- coefficients(lm(left_int ~ left_mzs, data=midpoints))
    right <- coefficients(lm(right_int ~ right_mzs, data=midpoints))
    midpoint <- ((hh-left[1])/left[2]+(hh-right[1])/right[2])/2 # midpoint between the intersection points of both lines from a y=hh flat line
    distance <- as.numeric(((hh-right[1])/right[2]) - ((hh-left[1])/left[2]))
    peak$mz <- round(midpoint[1], digits=4) # modify the peaks variable with the new more accurate m/z value
  }
  peakinfo <- list(peak,distance)
  return(peakinfo)
}
This is the README file for the hrms project that deals with
the analysis of high resolution mass spectrometry data.

This code requires a list of name:mz pairs in a csv file. It is
currently named LipidList.csv on my local machine. An example file should have been 
distributed with this code. If you would like a few example mass spectral data files
go to https://drive.google.com/folderview?id=0B06AQDbcyIg8Q2ZFYm1RNmhnMUE&usp=sharing

You must use proteowizard to convert all raw spectra files to mzXML 
files. The filname variables refered to in the documentation are these 
mzXML files. The code attempts to work with low intensity peaks so 
make sure that proteowizard is not performing any thresholding or peak 
peaking prior to analysis.

Usage in R:

To perform analysis for one sample in R, call the following in the console:
``` R
setwd("path")
source("hrms.R")
main(filename,rtwin=c(0,60),mzwin=c(200,1800))
```

With "path" being the directory with files hrms.R, LipidList.csv, and mzXML files and where 
rtwin is the retention time window in sec and mzwin is the mzwindow in m/z units

If you want to run this for all data files in a directory run the following command: 
``` R
files = list.files(".", pattern=".mzXML") # the pattern could be ".mzML" if needed
system.time(
for (i in 1:length(files)) {
  main(files[i],rtwin=c(0,60),mzwin=c(200,1800))
}
)
results <- signals_deviations() 
```

The last line will produce the csv files signals and deviations in the active directory, which 
puts multiple file's data together into two csv files plus returns the data.frames in the list 
variable "results".

If you are attempting to analyse lots of data with this, please checkout lcms.py in 
marneylc/LCMS_highthroughput for multithreading of both the conversion process and the hrms peak picking.

The separate file signals_deviations.R is made available so that multiple folders/plates 
of samples can be collated into a singal "signals.csv" file (and deviations.csv).

In the output, a value of "NA" means that no data exists in the mass 
spectrum for that target peak. A signal value of "0" means that there is
mass spectral data collected for the target mass, but that it has a signal
value of zero.

Note:
somtimes when edited in windows, hrms.R can end up having invisible CR characters
which causes errors in linux.

If you get a "No such file or directory" error run the following code in python

``` python
with open('hrms.R', 'rb+') as f:
    content = f.read()
    f.seek(0)
    f.write(content.replace(b'\r', b''))
    f.truncate()
```

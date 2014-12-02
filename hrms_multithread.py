#!/usr/bin/env python
'''
This is a python script to run the R code hrms.R utilizing multiple threads.
All the mzXML files, LipidList.csv file, and the hrms.R source code
file must be in the active directory. 

********* NOTE ***********
The R directory with Rscript.exe must be added to the system path.
The default R directory (if you have the same version) is: C:\Program Files\R\R-3.0.2\bin\x64

The python directory with python.exe must be added to the system path.
For a winpython 64 bit installation the default is: C:\WinPython-64bit-2.7.5.3\python-2.7.5.amd64

There are also python package dependencies that need to be installed.
They are located in the first few lines of code.
**************************

Make sure the RT win and MZ win is set in hrms.R properly and
copy this file into the active directory with the other files and 
run the following in the command window (shift + right-click will give you
an option to open a command window from the current explorer directory):

python hrms_multithread.py

Add watch it fly!
'''
import os
import re
import shutil
import threading
import time

def main():
	mzxmlfiles = pygrep('mzXML','.')
	maxnumthreads = 4
	for f in mzxmlfiles:
		t = R_hrms(f)
		t.start()
		while threading.activeCount() > maxnumthreads:
			time.sleep(1)
		
# kinda like ls | grep in Unix
def pygrep(regex,path):
    home = os.getcwd()
    os.chdir(path) # cd
    filenames = os.listdir(os.getcwd()) # ls
    matches = list()
    for filename in filenames:
        if re.search(regex,filename):
            matches.append(filename)
            
    os.chdir(home)
    return matches
	
class R_hrms(threading.Thread):
    def __init__(self,filename):
        self.filename = filename
        threading.Thread.__init__(self)
    def run(self):
        os.system("Rscript hrms.R " + self.filename)
		
main()
#!/usr/bin/env python

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
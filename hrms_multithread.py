#!/usr/bin/env python
import threading
import os
import sys
import re
import time

def main():
    path = sys.argv[1]
    maxthreads = int(sys.argv[2])
    files = pygrep(".mzXML",path)
    os.chdir(path)
    thread_handle(files,path,maxthreads,R_hrms)

# initiates as many threads as maxthreads for the 
# methods defined in R_threadClass
def thread_handle(files,path,maxthreads,threadclass):
    anchor = range(0,len(files),maxthreads)
    thread_dict = dict()
    for i in anchor:
        files_lim = files[i:i+maxthreads]
    for f in files_lim:
        thread_dict[f] = threadclass(f,path)
        #thread = R_hrms(f,path)
    for keys in thread_dict:
        thread_dict[keys].start()

class R_hrms(threading.Thread):
    def __init__(self,filename,path):
        self.filename = filename
        threading.Thread.__init__(self)
    def run(self):
        print ("Processing file: " + self.filename)
        os.system("./hrms.R " + self.filename)
        print ("File: " + str(self.filename) + " is all done!")


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
    
main()

### Server Pull Down

We are going to be using an ftp transfer to pull down entire studies on the metabolights servers. http://www.ebi.ac.uk/metabolights/

There may be another faster option that does some fancy compression and optimizes bandwidth that may be fun to check out (I can't remember the name right now)

'''unix
~$ sudo ftp 
ftp> open ftp.ebi.ac.uk
Name (ftp.ebi.ac.uk:luke): anonymous
331 Please specify the password.
Password: <leave blank>

'''

Gets you into the ftp server. From which you can look around the studies with corresponding MTBL ID's.

Lets look at MTBLS36: "Metabolic differences in ripening of Solanum lycopersicum 'Alisa Craig' and three monogenic mutants"

'''unix
cd /pub/databases/metabolights/studies/public/
ls
'''

Look around! The public directory has all the available studies.

To pull down a single file we need a place to put it on our local machine. This is what I did in a separate terminal on my local machine. We are going to get a file from the study labeled MTBLS36:
'''unix
sudo mkdir /home/luke/data
sudo mkdir /home/luke/data/MTBLS36
sudo touch /home/luke/data/MTBLS36/20100917_01_TomQC.mzML
'''

Back in your ftp session:
'''unix
get ./MTBLS36/20100917_01_TomQC.mzML /home/luke/data/MTBLS36/20100917_01_TomQC.mzML
'''

This will take a while. The file is rather large. Get a cup of coffee and come back. Any input about speeding up this process will be gladly appreciated!

Check if it is .raw or .mzML or .mzXML
'''unix
ls | grep raw
ls | grep mzML
ls | grep mzXML
'''

Because this file is already in .mzML format, we don't need to convert it. But we do need to copy the hrms.R script and the lipidlist.csv file into our directory in order to run the hrms code.
 
To run HRMS on this file:
'''unix
cp /home/luke/github/hrms/hrms.R ./ # copy the files we need from the github repository
cp /home/luke/github/hrms/lipidlist.csv ./ # replace the path with your own
chmod +x hrms.R # may need to make the hrms.R file executable
./hrms.R 20100917_01_TomQC.mzML
'''

Take a look at the resulting list of peak heights
'''unix
head 20100917_01_TomQC.csv
'''

I haven't scripted pulling down the entire study yet, and would appreciate that a bunch. There is a way to analyse an entire study with the HRMS code that uses the threading module in python which is already writeen by me and is in the HRMS repository with the file hrms_multithread.py. Also, there is a python library to do this whole FTP transfer via a python interpreter. The problem with running all of this in python is that it may occasionally leave threads open, so in the long run I will need to write an admin script to check for hanging threads.

'''unix
cp /home/luke/github/hrms/hrms_multithread.py ./
python hrms_multithread.py .mzML 4 # to use 4 cores
'''

Then take a look at the signals.csv and deviations.csv files.

'''unix
head signals.csv
head deviations.csv
'''

The output is a list of signals or deviations from the mass target used for each sample and each metabolite.


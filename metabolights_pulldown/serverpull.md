### Server Pull Down

We are going to be using an ftp transfer to pull down entire studies on the metabolights servers. http://www.ebi.ac.uk/metabolights/

There may be another faster option that does some fancy compression and optimizes bandwidth that may be fun to check out (I can't remember the name right now)

'''shell
ftp ftp://ftp.ebi.ac.uk/
'''

Gets you into the ftp server. From which you can look around the studies with corresponding MTBL ID's.

Lets look at MTBLS36: "Metabolic differences in ripening of Solanum lycopersicum 'Alisa Craig' and three monogenic mutants"

'''shell
(something goes here)
'''

Pull down a single file:
'''shell

'''

Open up another terminal or quit your ftp session:
'''shell
close

'''

Check if it is .raw or .mzML or .mzXML
'''shell

'''

The output should look like this:
'''shell

'''
Because this file is already in .mzML format, we don't need to convert it. But we do need to copy the hrms.R script and the lipidlist.csv file into our directory in order to run the hrms code.
 
To run HRMS on this file:
'''shell
cp /home/luke/github/hrms/hrms.R ./ # copy the files we need from the github repository
cp /home/luke/github/hrms/lipidlist.csv ./ # replace the path with your own
chmod +x hrms.R # may need to make the hrms.R file executable
./hrms.R 20100917_01_TomQC.mzML
'''

Take a look at the resulting list of peak heights
'''shell
head 20100917_01_TomQC.csv
'''

I haven't scripted pulling down the entire study yet, and would appreciate that a bunch. There is a way to analyse an entire study with the HRMS code that uses the threading module in python. I've heard that this method may occasionally leave threads open, so in the long run I will need to write an admin script to check for hanging threads.

'''shell
cp /home/luke/github/hrms/hrms_multithread.py ./
python hrms_multithread.py .mzML 4 # to use 4 cores
'''

Then take a look at the signals.csv and deviations.csv files.

'''shell
head signals.csv
head deviations.csv
'''

The output is a list of signals or deviations from the mass target used for each sample and each metabolite.


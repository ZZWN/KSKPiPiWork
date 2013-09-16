#!/afs/ihep.ac.cn/users/c/caih/.localpython/bin/python
import sys, os
import string
import argparse, time


parser = argparse.ArgumentParser()
parser.add_argument("jobName", help = "set the job name")
parser.add_argument("-b", "--startNo", help = "set the start number of the jobs created", type = int, default = 1) 
parser.add_argument("-e", "--endNo", help = "set the end number of the jobs created", type = int, default = 150)
parser.add_argument("-n", "--eventNum", help = "set the number of events per job", type = int, default = 200)
parser.add_argument("-s", "--seed", help = "set the seed for generating random number", type = int, default = int(time.time()))
parser.add_argument("-c", "--notSubmit", help = "do not submit jobs to pbs, only generate files", action = "store_true")
parser.add_argument("-q", "--besQueue", help = "the pbs queue to be submitted", default = "besq")
parser.add_argument("-r", "--checkResult", help = "only test the result successful or not", action = "store_true")
parser.add_argument("-d", "--workDir", help = "set the working directory", default = sys.path[0])
args = parser.parse_args()

scriptDir = args.workDir + "/" + args.jobName
outputDir = args.workDir + "/output/" + args.jobName
if not(os.path.exists(scriptDir)):
    print "The script directory " + scriptDir + " does not exist!"
    exit()

if not(os.path.exists(outputDir)):
    print "The output directory " + outputDir + " does not exist!"
    exit()

def testSuccess(file):
    for line in open(file):
        if "SUCCESS!!!" in line:
            print file, line,
            return True
    return False

os.chdir(scriptDir)
if args.checkResult:
    failFiles = [];
    for file in os.listdir("."):
        if (".log" in file) and not(testSuccess(file)):
            failFiles.append(file)
    print "There are total", len(failFiles), "unsuccessful jobs!"
    print failFiles
    exit()

os.chdir(scriptDir)
for i in range(args.startNo, args.endNo + 1):
    macFile = "_".join(["a01", "%03d"%i]) + ".mac"
    fullMacFile = "/".join([scriptDir, macFile])
    outFile = "_".join(["LS", "a01", "%03d"%i]) + ".root"
    fullOutFile = "/".join([outputDir, outFile])
    ff = open(macFile, "w")
    print >> ff, "/histo/fileName " + fullOutFile 
    print >> ff, "/histo/setSeed %d"%(args.seed + i)
    print >> ff, "/run/beamOn", args.eventNum 
    ff.close()

    jobFile = "_".join(["a01", "%03d"%i]) + ".csh"
    logFile = jobFile + ".log"
    errFile = jobFile + ".err"
    ff = open(jobFile, "w")
    print >> ff, "#!/bin/tcsh -f"
    print >> ff, "#PBS -o", logFile
    print >> ff, "#PBS -e", errFile
    print >> ff, "set AllowForHeavyElements=1"
    print >> ff, "set G4WORKDIR=/besfs/users/caih/dyb_home/geant4dyb2/"
    print >> ff, "set MALLOC_CHECK_=4"
    print >> ff, "source /afs/ihep.ac.cn/soft/dayabay/jmne/external/local/setup/tcshrc.geant494"
    print >> ff, "setenv exe '/besfs/users/caih/dyb_home/geant4dyb2/bin/Linux-g++/GdLSExp'"
    print >> ff, "time $exe", macFile, "%d"%(args.seed + i)
    ff.close()
    os.system("qsub -q besq " + jobFile) 


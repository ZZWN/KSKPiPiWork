#!/afs/ihep.ac.cn/users/c/caih/.localpython/bin/python
import sys, os
import string

#def main():
import argparse, time
parser = argparse.ArgumentParser()
parser.add_argument("jobName", help = "set the job name")
parser.add_argument("jobType", help = "set the job type as sim/rec/ana", choices = ["sim", "rec", "ana"])
parser.add_argument("-b", "--startNo", help = "set the start number of the jobs created", type = int, default = 1) 
parser.add_argument("-e", "--endNo", help = "set the end number of the jobs created", type = int, default = 150)
parser.add_argument("-n", "--eventNum", help = "set the number of events per job", type = int, default = 2000)
parser.add_argument("-s", "--seed", help = "set the seed for generating random number", type = int, default = int(time.time()))
parser.add_argument("-c", "--notSubmit", help = "do not submit jobs to pbs, only generate files", action = "store_true")
parser.add_argument("-q", "--besQueue", help = "the pbs queue to be submitted", default = "besq")
parser.add_argument("-r", "--checkResult", help = "only test the result successful or not", action = "store_true")
parser.add_argument("-d", "--workDir", help = "set the working directory", default = sys.path[0])
args = parser.parse_args()
print args
print args.seed
print args.notSubmit
print args.besQueue
print args.workDir

simparentdir = args.workDir + "/sim"
recparentdir = args.workDir + "/rec"
anaparentdir = args.workDir + "/ana"

simdir = simparentdir + "/" + args.jobName
recdir = recparentdir + "/" + args.jobName
anadir = anaparentdir + "/" + args.jobName

scriptDir = args.workDir + "/" + args.jobName
simScriptDir = scriptDir + "/sim"
recScriptDir = scriptDir + "/rec"
anaScriptDir = scriptDir + "/ana"

print "%-8s|%-16s|%-8s|%-8s|%-16s|%-16s|%-16s|%-16s|%-16s"%("Job Type", "Job Name", "Begin No", "End No", "Event Number", "Seed Start", "PBS Queue", "Submit", "Check Result")
print "%-8s|%-16s|%-8d|%-8d|%-16d|%-16d|%-16s|%-16s|%-16s"%(args.jobType, args.jobName, args.startNo, args.endNo, args.eventNum, args.seed, args.besQueue, not(args.notSubmit), args.checkResult) 
print "Simulation directory: ", simdir
print "Reconstruction directory: ", recdir
print "Analysis directory: ", anadir
print "Simulation scripts directory: ", simScriptDir
print "Reconstruction scripts directory: ", recScriptDir
print "Analysis scripts directory: ", anaScriptDir
print

choice = raw_input("You are going to do the job above? Enter (y)es or (n)ot: ").lower()
if not(choice == "y" or choice == "yes"):
    exit()

if not(os.path.exists(scriptDir)):
    print "The scprit directory " + scriptDir + " does not exist!"
    exit()

if args.jobType == "sim":
    decFile = scriptDir + "/" + args.jobName + ".dec"
    if not(os.path.isfile(decFile)):
        print "Decay card", decFile, "does not exist!"
        exit()
    if not(os.path.exists(simdir)):
        os.mkdir(simdir)
elif args.jobType == "rec":
    if not(os.path.exists(simdir)):
        print "Simulation directory", simdir, "does not exist!"
        exit()
    if not(os.path.exists(recdir)):
        os.mkdir(recdir)
elif args.jobType == "ana":
    if not(os.path.exists(recdir)):
        print "Reconstruction directory", recdir, "does not exist!"
        exit()
    if not(os.path.exists(anadir)):
        os.mkdir(anadir)
else:
    print "Cannot recognize job type, stop here."
    exit()

os.chdir(scriptDir)
os.chdir(args.jobType)

#for root, dirs, files in os.walk(anaScriptDir):
#    print dirs

def testSuccess(file):
    for line in open(file):
        if "Terminated successfully" in line:
            print file, line,
            return True
    return False

if args.checkResult:
    failFiles = [];
    for file in os.listdir("."):
        if (".bosslog" in file) and not(testSuccess(file)):
            failFiles.append(file)
    print "There are total", len(failFiles), "unsuccessful jobs!"
    print failFiles
    exit()

origJobOptionFile = args.workDir + "/" + "_".join(["jobOptions", args.jobType, "some.txt"])    
for i in range(args.startNo, args.endNo + 1):
    jobFile = "_".join([args.jobName, args.jobType, "%03d"%i]) + ".txt"
    pbsFile = jobFile + ".boss"
    outFile = jobFile + ".bosslog"
    errFile = jobFile + ".bosserr"
    tmp = open(origJobOptionFile).read()
    tmp = tmp.replace("JOBSEED", str(args.seed + i))
    tmp = tmp.replace("JOBNAME", args.jobName)
    tmp = tmp.replace("JOBSIMDIR", simdir)
    tmp = tmp.replace("JOBRECDIR", recdir)
    tmp = tmp.replace("JOBANADIR", anadir)
    tmp = tmp.replace("JOBNO", "%03d"%i)
    tmp = tmp.replace("JOBEVENTNUM", str(args.eventNum))
    ff = open(jobFile, "w")
    ff.write(tmp)

    ff = open(pbsFile, "w")
    print >> ff, "#!/bin/tcsh -f"
    print >> ff, "#PBS -o", outFile
    print >> ff, "#PBS -e", errFile
    print >> ff, "source /afs/ihep.ac.cn/users/c/caih/655"
    print >> ff, "setenv exe '/afs/ihep.ac.cn/bes3/offline/Boss/6.5.5/InstallArea/i386_linux26/bin/boss.exe'"
    print >> ff, "cd", scriptDir + "/" + args.jobType
    print >> ff, "time $exe", jobFile

    print "Creat", pbsFile, "over!"

    if not(args.notSubmit):
        os.system("echo XXXXXXXXXXXXXX")
    
#    print jobFile, pbsFile, outFile, errFile
#    print origJobOptionFile


#try:
#    opts, args = getopt.getopt(sys.argv[1:], "ht:b:e:n:s:cq:rd:")
#except getopt.GetoptError:
#    print "Error: There are unknown options!"
#    usages()
#    sys.exit(2)
#    
#optsDict = dict(opts)
#print optsDict
#if optsDict.has_key("-h"):
#    usages()
#    sys.exit()
#checkResult = optsDict.has_key("-r")
#submitJob = not(optsDict.has_key("-c"))
#
#jobType = optsDict.get("-t", "unknown")
#noBegin = int(optsDict.get("-b", "1"))
#noEnd = int(optsDict.get("-e", "150"))
#eventNum = int(optsDict.get("-n", "1000"))
#seedStart = int(optsDict.get("-s", "1111"))
#pbsQueue = optsDict.get("-q", "besq")
#
#jobName = "test"
#
#myDir = optsDict.get("-d", sys.path[0])
#simParentDir = myDir + "/sim"
#recParentDir = myDir + "/rec"
#anaParentDir = myDir + "/ana"
#
#thisCmd = sys.argv[0]


#print jobType, noBegin, noEnd
#print myDir
#print args



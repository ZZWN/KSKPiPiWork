#!/bin/bash

pbsqueue="besq"
seedstart=2000
jobname="test"
jobtype="unknown"
#simparentdir="/panfs/panfs.ihep.ac.cn/home/data/huangy/Jpsipackage/Jpsiweakdecay/Analysis/dspackage/exclusive/sim"
#recparentdir="/panfs/panfs.ihep.ac.cn/home/data/huangy/Jpsipackage/Jpsiweakdecay/Analysis/dspackage/exclusive/rec"
#anaparentdir="/panfs/panfs.ihep.ac.cn/home/data/huangy/Jpsipackage/Jpsiweakdecay/Analysis/dspackage/exclusive/ana"
mydir="/besfs/groups/psip/psipgroup/user/caih/KSKPiPiWork/exclusive_mc"

#simparentdir="/besfs/users/caih/6.5.5/dalitz_run2/sim"
simparentdir=$mydir"/sim"
recparentdir=$mydir"/rec"
anaparentdir=$mydir"/ana"

nobegin=1
noend=10
eventnum=5000

submitjob="Yes"
checkresult="No"

THISCMD=$(basename $0)

echo $0 $@ >> cmdlog

usages() {
cat << EOF
$THISCMD:  Generate simulation/reconstruction jobs and submit to pbs
Syntax:
  ./$THISCMD [-h] [-t jobType] [-b beginNo] [-e endNo] [-n eventNum] [-s seedStart] [-c] [-q queueName] [-r] jobname

  -h  display this help and exit
  -t  specify job type, sim/rec/ana, no other parameter accepted
  -b  set begin No of job
  -e  set end No of job
  -n  set event number of each job
  -s  set random seed start from
  -c  do not submit jobs to pbs, only generate files
  -q  the pbs queue to be submitted
  -r  only test the result

Report bugs to <huangyong@ihep.ac.cn>.
EOF
}

while getopts ":ht:b:e:n:s:cq:r" optname
do
  case "$optname" in
    "h")
      usages
      exit 1
      ;;
    "t")
      jobtype="$OPTARG"
      ;;
    "b")
      nobegin="$OPTARG"
      ;;
    "e")
      noend="$OPTARG"
      ;;
    "n")
      eventnum="$OPTARG"
      ;;
    "s")
      seedstart="$OPTARG"
      ;;
    "c")
      submitjob="No"
      ;;
    "q")
      pbsqueue="$OPTARG"
      ;;
    "r")
      checkresult="Yes"
      ;;
    "?")
      echo "Unknown option $OPTARG"
      exit -1
      ;;
    ":")
      echo "Need argument value for option $OPTARG"
      exit -1
      ;;
    *)
      # Should not occur
      echo "Unknown error while processing options"
      exit -1
      ;;
  esac
done

# check if right jobtype specified
case "$jobtype" in
  sim)
    ;;
  rec)
    ;;
  ana)
    ;;
  unknown)
    echo "Please specify a job type"
    echo "Try \"./$THISCMD -h\" for more infomation"
    exit -1
    ;;
  *)
    echo "Invalid job type"
    echo "Try \"./$THISCMD -h\" for more infomation"
    exit -1
    ;;
esac

# get jobname parameter
case "$(($#+1-$OPTIND))" in
  0)
    echo "Please specify a jobname"
    exit -1
    ;;
  1)
    jobname="${@:$OPTIND:1}"
    ;;
  *)
    echo "Too many jobs. Only 1 job permitted"
    exit -1
    ;;
esac

simdir=$simparentdir/$jobname
recdir=$recparentdir/$jobname
anadir=$anaparentdir/$jobname

# Print parameters
printf "%-8s | %-16s | %-8s | %-8s | %-16s | %-16s | %-16s | %-16s | %-16s\n" "Job Type" "Job Name" "Begin No" "End No" "Event Number" "Seed Start" "PBS Queue" "Submit" "Check Result"
printf "%-8s | %-16s | %-8d | %-8d | %-16d | %-16d | %-16s | %-16s | %-16s\n" $jobtype $jobname $nobegin $noend $eventnum $seedstart $pbsqueue $submitjob $checkresult
echo "Simulation directory: $simdir"
echo "Reconstruction directory: $recdir"
echo "Analysis directory: $anadir"
echo ""

if [ $checkresult == "No" ]; then
  read -p "You are going to do the job above, is that right? (y/n):"
  if [ ! "$REPLY" = "Y" ] && [ ! "$REPLY" = "y" ]; then
      exit 0
  fi
fi



# find directory with the jobname
if [ ! -d $jobname ]; then
  echo Directory $jobname does not exist!
  exit -2
fi

cd $jobname

case "$jobtype" in
  sim)
    # make sure dec file exists
    decfile="$jobname".dec
    if [ ! -e $decfile ]; then
      echo Decay card $decfile does not exist! Please create it first.
      exit -2
    fi

    # make sure output directory exists
    if [ ! -d $simdir ]; then
      mkdir -p $simdir
    fi
    ;;
  rec)
    # make sure sim directory exists
    if [ ! -d $simdir ]; then
      echo Simulation directory $simdir seems not exist!
      exit -2
    fi

    # make sure output directory exists
    if [ ! -d $recdir ]; then
      mkdir -p $recdir
    fi
    ;;
  ana)
    # make sure rec directory exists
    if [ ! -d $recdir ]; then
      echo Reconstruction directory $recdir seems not exist!
      exit -2
    fi

    # make sure output directory exists
    if [ ! -d $anadir ]; then
      mkdir -p $anadir
    fi
    ;;
  *)
    echo "Should not run here"
    exit -1
    ;;
esac

# make sure job directory exists and cd to it
if [ ! -d $jobtype ]; then
  mkdir $jobtype
fi
cd $jobtype

if [ $checkresult == "Yes" ]; then
  rm $mydir/tmp
  grep -e "Terminated successfully" *.bosslog | tee -a $mydir/tmp
#  grep -e "Terminated successfully" *.bosslog | wc
  wc -l $mydir/tmp
  exit 1
fi


# loop over all job No
for i in `seq $nobegin $noend`
do
  ii=$(printf "%0.3d" $i)
  jobfile="$jobname"_"$jobtype"_"$ii".txt
  pbsfile="$jobfile".boss
  outfile="$jobfile".bosslog
  errfile="$jobfile".bosserr

  sed -e "s/JOBSEED/$(($seedstart+$i))/" ../../jobOptions_"$jobtype"_some.txt > tmp1
  sed -e "s/JOBNAME/$jobname/g" tmp1 > tmp2
  sed -e "s#JOBSIMDIR#$simdir#" tmp2 > tmp3
  sed -e "s#JOBRECDIR#$recdir#" tmp3 > tmp4
  sed -e "s#JOBANADIR#$anadir#" tmp4 > tmp5
  sed -e "s/JOBNO/$ii/g" tmp5 > tmp6
  sed -e "s/JOBEVENTNUM/$eventnum/g" tmp6 > $jobfile
  rm tmp1 tmp2 tmp3 tmp4 tmp5 tmp6

  echo "#!/bin/tcsh -f" > $pbsfile
  echo "#PBS -o $outfile" >> $pbsfile
  echo "#PBS -e $errfile" >> $pbsfile
  echo "setenv exe '/afs/ihep.ac.cn/bes3/offline/Boss/6.6.3.p01/InstallArea/x86_64-slc5-gcc43-opt/bin/boss.exe'" >> $pbsfile
  echo "cd `pwd`" >> $pbsfile
  echo time '$'exe $jobfile >> $pbsfile

  echo Create "$jobname"_"$jobtype"_"$ii" over!

  if [ "$submitjob" == Yes ]; then qsub -q "$pbsqueue" "$pbsfile"; fi
done

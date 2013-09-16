#!/bin/tcsh -f



if ($#argv != 1 && $#argv != 2 && $#argv != 3 && $#argv != 4 ) then
  echo " "
  echo "purpose:(for real data) you can get jobOptions with certain number rec file in each job automatically. "
  echo "        Also, you can summit the jobs automatically. "
  echo "useage : ./makeJob.csh jobName [jobN] [fileN] [jobDir]"
  echo "jobName: is the name of jobOption you wish"
  echo "         this argument SHOULD NOT be omitted. "
  echo "jobN   : is the largest number of jobs"
  echo "         by default, it will be 20 "
  echo "fileN  : is the smallest of rec file in each jobOption"
  echo "         by default, it will be 200  "
  echo "jobDir : is the directory where you want the jobOption is"
  echo "         by default, it will be PWD  "
  echo "  "
  echo "SQUESTION: step one  : please check/modify the 'makeJob.head' "
  echo "           step two  : please check/modify the 'makeJob.tail' "
  echo "           step three: please check 'DataParentPath' in 'makeJob.csh' correct or not"
  exit
endif
# set DataParentPath: where is the real data
#set DataParentPath1 = /besfs2/offline/data/655-1/psip/mc/dst/
set DataParentPath1 = /besfs/groups/psip/psipgroup/663-MC/psi4260/res/hadrons

#set DataParentPath1 = /bes3fs/offline/data/655-1/jpsi/mc/dst/

#set DataParentPath1 = /besfs/groups/jpsi/jpsigroup/skim651/prong02

# set jobName : the name of job will like "jobName_????.txt" 
set jobName = $argv[1]
echo "jobName : ${jobName}"

# set jobN    : the largest number of jobs" 
if( $#argv >= 2 ) then
    @ jobN=$argv[2]
else
    @ jobN=20
endif
echo "The largest number of jobs : ${jobN}"

# set fileN   : the smallest number of rec file in each jobOption" 
if( $#argv >= 3 ) then
    @ fileN=$argv[3]
else
    @ fileN=2
endif
echo "The smallest number of rec file in each job : ${fileN}"

# input the path as DataParentPath of data
if( $#argv >= 4 ) then
    set jobDir = $argv[4]
else
    set jobDir = $PWD
endif
echo "jobDir  : ${jobDir}"

# get all rec file from all child path of the DataParentPath
echo "okok "
echo " DataParentPath1 : ${DataParentPath1}"


#将所有的数据文件的路径写入文件temp.txt
if ( -e ${jobDir}/temp.txt ) then 
   rm ${jobDir}/temp.txt 
endif 

if (! -e temp.txt )   then 
   find  ${DataParentPath1}/ -name "*.dst" > temp.txt



else
   find  ${DataParentPath1}/ -name "*.dst" >> temp.txt


endif 

# input the number of total lines of temp.txt 
@  nline=`wc -l temp.txt | cut -f 1 -d " "`
echo "There are ${nline} rec file totally"

# calculate how much jobs and how much rec file in each job 
@ Ntemp=${fileN} * ${jobN}
if( ${nline} > ${Ntemp} ) then 
  @ fileN=${nline} / ${jobN} + 1
  echo "To make sure there are ${jobN} jobs, there will be ${fileN} rec files in each job"
else 
  @ jobN=${nline} / ${fileN} + 1
  echo "To make sure there are ${fileN} rec files in each job, there will be ${jobN} jobs"
endif


# make jobOptions with certain rec files in each job
@ iline=1
@ i=1
set ijob=${i}
foreach file ( `cat temp.txt` )

        if ( ${iline} % ${fileN} == 1 ) then 
            if ( -e ${jobDir}/${jobName}_${ijob}.txt ) then 
               echo "Just remind: ${jobDir}/${jobName}_${ijob}.txt already exists, and it will be update!"
            endif 
            sed -e s/LLL/${jobName}_${ijob}/ ${jobDir}/makeJob.head > ${jobDir}/${jobName}_${ijob}.txt
#            cp ${jobDir}/makeJob.head  ${jobDir}/${jobName}_${ijob}.txt 
        endif 

        if ( ${iline} % ${fileN} != 0 && ${iline} < ${nline} ) then 
	       echo \"${file}\", >>  ${jobDir}/${jobName}_${ijob}.txt
        endif 

        if ( ${iline} % ${fileN} == 0 || ${iline} == ${nline} ) then 
            echo \"${file}\" >>  ${jobDir}/${jobName}_${ijob}.txt
            sed -e s/XXX/${jobName}_${ijob}/ ${jobDir}/makeJob.tail >> ${jobDir}/${jobName}_${ijob}.txt

            echo ${jobDir}/${jobName}_${ijob}.txt is finished 
            boss -q ${jobName}_${ijob}.txt

            @ i++
            if ( ${i} < 10 ) then 
               set ijob=${i}
            else
               set ijob=${i}
            endif 
        endif 

        @ iline++
end          

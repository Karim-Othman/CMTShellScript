#!/bin/bash


# pseudo code
# (Initial State) first time the program will run
# 1- Get to cluster's Nodes (ssh)
# 2- Open CDRs Directory
# 3- Get latest file name and save it into local file (Persistent Variable) that should be located on manager Node of the cluster --> File should be created if not there
# (Second and Forever Runs) Next cycle of crontab should repeat the previous three steps
# 4- if (there is another CDR file created different than the previous one)
#loop on every line , Extract data of our interest, insert it to DB
# else --> Do nothing and wait to the next cycle to evaluate again



#Concerns and Risks
#DB may be down for any reason
#Connection between master node and slaves may be down for any reason
#CDR/File could be deleted before been processed by our script
#Solution
#Relative Error should be written in a local Log file for each catch

#Implementation


#Part 1
#Check If persistant variable/file exist (Contains latest CDRs that haven't processed yet)
file="./LatestCDRs.txt"
CDRfilePathOnSlaveNodes="/home/karimothman/CapacityRequest/Node1"
if [ ! -f "$file" ]
then

    printf "FirstNode\nSecondNode\nThirdNode\nFourthNode" > LatestCDRs.txt #if file not exist create a new empty one

    FirstCDRName=''
    SecondCDRName=''
    ThirdCDRName=''
    FourthCDRName=''
    
    echo "$0: File '${file}' not found."

else  # if file does exist store latest CDRs names in vaariables                                       #Refactoring Comment "those variables should be assigned in array" :)
    FirstCDRName=`awk 'BEGIN{FS="|";OFS=" "}NR==1{print $1}' $file`
    SecondCDRName=`awk 'BEGIN{FS="|";OFS=" "}NR==2{print $1}' $file`
    ThirdCDRName=`awk 'BEGIN{FS="|";OFS=" "}NR==3{print $1}' $file`
    FourthCDRName=`awk 'BEGIN{FS="|";OFS=" "}NR==4{print $1}' $file`
fi




#Part 2
# If CDR/file still the latest we shouldn't process it as it may not been completed yet --> Data is incompleted
# else
    #We should operate on n-1 CDR/file and update our local persistant variable/file with latest CDR name

LatestMOdifiedFileName=`cd $CDRfilePathOnSlaveNodes && find -name "*.cdr" -type f -printf "%Ts %p\n" | sort -n | tail -1 | sed -r -e 's/^[0-9]+ .//'`
if [ "$LatestMOdifiedFileName" = "$FirstCDRName" ] #If CDR still the latest
then
    #CDR still the latest --> Do no thing
    echo "Nothing1"
else
    if [ ! -f "$CDRfilePathOnSlaveNodes$FirstCDRName" ] #Note that at first run our persistant local file won't have any CDR to operate on --> Lw el local file fady .. 2aw el CDR msh mawgooda  3al slave machine 5alas
    then
    
        #Access the first line of Local persistant file and overwrite it with the LatestMOdifiedFileName then write error in logs
        sed -i "1s/.*/${LatestMOdifiedFileName////\\/}/" $file  # Will replace first line in file (1s/.*/) with latest CDR name ... ////\\/ this pattern to escape directory salsh /
    else
    
        #Operate --> Parse

            while IFS= read -r var
            do

            FirstField=`echo "$var" | grep -oP '^([^,]+)'`  #First word before comma ^([^,]+)
            SecondField=`echo "$var" | grep -oP '([^,]+)$'` #Last word after comman [^,]+)$

            #Insert in DB
            echo "FirstField=$FirstField SecondField=$SecondField"  >> LocalDB.txt
            
            done < "$CDRfilePathOnSlaveNodes$FirstCDRName"

            
        #Update our local persistant variable/file 
        sed -i "1s/.*/${LatestMOdifiedFileName////\\/}/" $file  # Will replace first line in file (1s/.*/) with latest CDR name ... ////\\/ this pattern to escape directory salsh /
    fi
fi
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

#Start of Configuration
###############################################################################
#init State
#Define Repos Location (Path)
Path[1]='/home/karimothman/CDRs';
Path[2]='/home/karimothman/CDRs';
Path[3]='/home/karimothman/CDRs';
Path[4]='/home/karimothman/CDRs';
#Define IPs
IP[1]="10.0.2.6";
IP[2]="10.0.2.7";
IP[3]="10.0.2.6";
IP[4]="10.0.2.7";

#Define NodeName
NodeName[1]="Node1";
NodeName[2]="Node2";
NodeName[3]="Node3";
NodeName[4]="Node4";

UserName="karimothman";
##########################################################################################



#Part 1
#Check If persistant variable/file exist (Contains latest CDRs that haven't processed yet)
file="./LatestCDRs.txt"
if [ ! -f "$file" ]
then

    printf "FirstNode\nSecondNode\nThirdNode\nFourthNode" > LatestCDRs.txt #if file not exist create a new empty one

    CDRName[1]=''
    CDRName[2]=''
    CDRName[3]=''
    CDRName[4]=''

    echo "$0: File '${file}' not found."

else  # if file does exist store latest CDRs names in vaariables                                       #Refactoring Comment "those variables should be assigned in array" :)
    CDRName[1]=`awk 'BEGIN{FS="|";OFS=" "}NR==1{print $1}' $file`
    CDRName[2]=`awk 'BEGIN{FS="|";OFS=" "}NR==2{print $1}' $file`
    CDRName[3]=`awk 'BEGIN{FS="|";OFS=" "}NR==3{print $1}' $file`
    CDRName[4]=`awk 'BEGIN{FS="|";OFS=" "}NR==4{print $1}' $file`
fi





#Part 2

#Loop on Nodes/ Path array
for index in "${!Path[@]}"
do
    # If CDR/file still the latest we shouldn't process it as it may not been completed yet --> Data is incompleted
    # else
        #We should operate on n-1 CDR/file and update our local persistant variable/file with latest CDR name
    CDRfilePathOnSlaveNodes=${Path[$index]}
    LatestMOdifiedFileName=`ssh $UserName@${IP[$index]} bash -s  < FindLatest.sh`
    if [ "$LatestMOdifiedFileName" = "${CDRName[$index]}" ] #If CDR still the latest
    then
        #CDR still the latest --> Do no thing
        echo ""
    else
        #Copy Remote CDR file into Local temp file
        scp ${IP[$index]}:$CDRfilePathOnSlaveNodes${CDRName[$index]} ./Temp.cdr
        if [ ! -f "./Temp.cdr" ] #Note that at first run our persistant local file won't have any CDR to operate on --> Lw el local file fady .. 2aw el CDR msh mawgooda  3al slave machine 5alas
        then
        
            #Access the first line of Local persistant file and overwrite it with the LatestMOdifiedFileName then write error in logs
            sed -i "${index}s/.*/${LatestMOdifiedFileName////\\/}/" $file  # Will replace first line in file (1s/.*/) with latest CDR name ... ////\\/ this pattern to escape directory salsh /
        else
        
            #Operate --> Parse

                while IFS= read -r var
                do

                FirstField=`echo "$var" | grep -oP '^([^,]+)'`  #First word before comma ^([^,]+)
                SecondField=`echo "$var" | grep -oP '([^,]+)$'` #Last word after comman [^,]+)$

                #Create File with node name followed by CDR
                echo "$FirstField,$SecondField"  >> ${NodeName[$index]}${CDRName[$index]////_} #////_ to remove slash from file name and replace it with _
                done < "./Temp.cdr"

                rm  ./Temp.cdr
            #Update our local persistant variable/file 
            sed -i "${index}s/.*/${LatestMOdifiedFileName////\\/}/" $file  # Will replace first line in file (1s/.*/) with latest CDR name ... ////\\/ this pattern to escape directory salsh /
        fi
    fi
done

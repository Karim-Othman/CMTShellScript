1- Copy FindLatest.sh file and sshScript.sh file in same directory
2- chmod +x each file
3- Configure Path, IP, NodeName arrays
4- Configure UserName variable
5- attach sshScript in crontab with a period less than CDR creation period

############################
Operation
###########################

1- LatestCDRs file will be created automatically to carry the last updated files' NodeName
2- when a new CDR file been produced on the node
    A- Script will parse the one that been written before in LatestCDRs
    B- Update LatestCDRs file with the last updated one
    C- file that been parsed will be written in scripts directory following this naming convention "Node3_20181009-12_IP.cdr"
        - where Node3 is node name that is configure in Names array (Configurable)
        - 20181009-12_IP is the CDR name on the node
3- CMT tool should extract the structured data from the produced file
4- Another cron job should be scheduled to delete produced file every once in a while


#!/bin/bash
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs/"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "Script started execution at: $(date)" | tee -a $LOG_FILE

# check the user has root priveliges or not
if [ $USERID -ne 0 ]
then  
   echo -e "$R ERROR:: please run this script with root access $N" | tee -a $LOG_FILE
   exit 1 # give other than 0 upto 127
else
    echo "you are running with root access" | tee -a $LOG_FILE
fi

#validate function takes input as exit status what command tha tried to install
VALIDATE(){
if [ $1 -eq 0 ]
then
    echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
else
    echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
    exit 1         
fi    
}

cp mongo.repo /etc/yum.repos.d/mongo.repo 
VALIDATE $? "Copying mongodb repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing mongodb server"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enabling mongodb"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Starting mongodb"

sed -i 's/127.0.0.0/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Edithing mongodb conf file for remote connections"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting mongodb"
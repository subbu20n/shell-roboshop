#!/bin/bash
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

USERID=$(id -u)
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "script started executing at: $(date)"| tee -a $LOG_FILE

# check the user have root privileges or not
if [ $USERID -ne 0 ]
then 
   echo -e "$R ERROR:: please run this script with root access $N" | tee -a $LOG_FILE
   exit 1 # give other than 0 upto 127
else
   echo "you are running with root access" | tee -a $LOG_FILE
fi 

# validate the function takes input as exit status what command they are tried to install
VALIDATE(){
if [ $? -eq 0 ]
then
    echo -e "$2 is... $G SUCCESS $N" | tee -a $LOG_FILE
else
    echo -e "$2 is... $R FAILURE $N" | tee -a $LOG_FILE
    exit 1 
fi      
}

cp mongo.repo  /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "copying mongodb repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "installing mongodb server"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enabling mongodb"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "starting mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Editing for mongodb conf file for remote connections"

systemctl restart mongod &>>$LOG_FILE``
VALIDATE $? "Restarting mongodb"
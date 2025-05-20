#!/bin/bash
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

USERID=$(id -u)
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs:20 -y"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing nodejs -y "

id roboshop
if [ $? -ne 0 ]
then  
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "systemuser robosho already created... $Y skipping $N"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "creating app directory"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading catalogue"

rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzipping dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copying catalogue service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue
VALIDATE $? "starting catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "installing mongodb client"

STATUS=$(mongosh --host mongodb.subbuaws.site   --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then     
   mongosh --host mongodb.subbuaws.site </app/db/master-data.js
   VALIDATE $? "Loading data into mongodb"
else
   echo -e "data is already loaded... $Y skipping $N"
fi

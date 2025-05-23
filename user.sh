#!/bin/bash

START_TIME=$(date +%S)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/VAR/LOG/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started execution at: $(date)" | tee -a $LOG_FILE

# chech the user have root privileges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 # give other than 0 upto 127
else
    echo "you are running with root access" | tee -a $LOG_FILE
fi 

# validate function takes input as exit status what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
    echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
else
    echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
    exit 1
fi        
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing nodejs"

id roboshop
if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user roboshop"
else
    echo -e "system user roboshop already created ... $Y SKIPPING $N" &>>$LOG_FILE
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "creating app directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading user"

rm -rf /app/*
cd /app
unzip /tmp/user..zip &>>$LOG_FILE
VALIDATE $? "Unzipping user"

cd /app 
npm install &>>$LOG_FILE
VALIDATE $? "INstalling depenencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "copying user service"

systemctl daemon-reload &>>$LOG_FILE
systemctl eable user &>>$LOG_FILE
systectl start user
VALIDATE $? "Starting user


END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))

echo -e "Script execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE

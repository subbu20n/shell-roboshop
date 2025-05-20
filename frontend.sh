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

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disabling nginx -y"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enabling nginx:1.24 -y"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "INSTALLING nginx -y"

systemctl enable nginx &>>$LOG_FILE
systemctl start nginx
VALIDATE $? "starting nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading frontend"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzipping frontend"

rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "removing default content"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "copying nginx.conf"

systemctl restart nginx 
VALIDATE $? "Restarting nginx"
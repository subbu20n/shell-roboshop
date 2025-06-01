#!/bin/bash
START_TIME=$(date +%s)
USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo -e "script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]
then 
   echo -e "$R ERROR:: please run this script with root access $N" | tee -a $LOG_FILE
   exit 1
else
   echo "you are running with root access"
fi

#validate function takes input as exit status what command that they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
       echo -e "Installing $2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
       echo -e "Installing $2 is ... $R FAILURE $N" | tee -a $LOG_FILE
    fi      
}

dnf module disable nodejs -y
VALIDATE $? "Disabling nodejs -y"

dnf module enable nodejs:20 -y
VALIDATE $? "Enabling nodejs"

dnf install nodejs -y
VALIDATE $? "Installing nodejs"

id roboshop
if [ $? - ne 0 ]
then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   VALIDATE $? "creating system user roboshop"
else 
   echo "system user roboshop already created ... $Y SKIPPING $N"
fi 

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "downloading catalogue"

cd /app 
unzip /tmp/catalogue.zip
VALIDATE $? "Unzipping catalogue"

npm install
VALIDATE $? "inatall dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalogue service"

systemctl daemon-reload
VALIDATE $? "Daemon reload"

systemctl enable catalogue
VALIDATE $? "Enabling catalogue"

systemctl start catalogue
VALIDATE $? "Starting catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d.mongod.repo
VALIDATE $? "copying mongo repo"

dnf install mongodb-mongosh -y
VALIDATE $? "installing mongodb"

STATUS=$(mongosh --host mongodb.subbuaws.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.subbuaws.site </app/db/master-data.js
    VALIDATE $? "loading data into mysql"
else
    echo -e "data is already loadd in mysql ... $Y SKIPPING $N"
fi

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE

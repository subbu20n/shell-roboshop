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
echo "script started execution at: $(date)" | tee -a $LOG_FILE

# check the user have root priviliges or not
if [ $USERID -ne 0 ]
then
   echo -e "$R ERROR:: please run this script with root access $N" | tee -a $LOG_FILE
   exit 1 # give other than 0 upto 127
else
   echo "you are running with root access"  | tee -a $LOG_FILE
fi

#validate function takes input as exit status what command they tried to install
VALIDATE(){
if [ $1 -eq 0 ]
then
    echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
else
    echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
fi
}

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Install python3 packages"

id roboshop 
if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user roboshop"
else
    echo -e "system user roboshop already created ...$Y SKIPPING $Y" 
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading payment"

rm -rf /app/*
cd /app
unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzipping payment"


pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "Installing  depenencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
VALIDATE $? "Copying payment service"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable payment &>>$LOG_FILE
VALIDATE $? "Enabling payment"

systemctl start payment 
VALIDATE $? "starting payment"

END_TIME=$(date +%s)
TOTAL-TIME=$(($END_TIME - $START_TIME))

echo -e "Script execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
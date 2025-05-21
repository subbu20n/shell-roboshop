#!/bin/bash
START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs/"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

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

dnf module disable redis -y &>>LOG_FILE
VALIDATE $? "Disabling default redis version"

dnf module enable redis:7 -y &>>LOG_FILE
VALIDATE $? "Enabling Redis:7"

dnf install redis -y &>>LOG_FILE
VALIDATE $? "Installing redis"

sed -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf &>>&LOG_FILE
VALIDATE $? "Edited redis.conf to access remote connections"

systemctl enable redis &>>LOG_FILE
VALIDATE $? "Enabling redis"

systemctl start redis &>>LOG_FILE
VALIDATE $? "Starting redis"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))

echo -e "Script execution completed successfully, $Y time taken : $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
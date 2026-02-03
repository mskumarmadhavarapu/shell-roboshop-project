#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-script"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
DEST_FILE="/etc/nginx/nginx.conf"

if [ $USERID -ne 0 ]; then
    echo "Please run this command with sudo access only" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2         .... $R FAILD $N." | tee -a $LOGS_FILE
        exit 1
    else
        echo "$2         .... SUCCESS." | tee -a $LOGS_FILE
    fi
}

dnf module disable redis -y &>>$LOGS_FILE
VALIDATE $? "Disabling redis old ver.."

dnf module enable redis:7 -y &>>$LOGS_FILE
VALIDATE $? "enabling redis 7 ver.."

dnf install redis -y  &>>$LOGS_FILE
VALIDATE $? "installing redis..."

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode yes/c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Replacing content in conf file"

systemctl enable redis &>>$LOGS_FILE
systemctl start redis 
VALIDATE $? "Enable and starting redis"
#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-script"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
Y="\e[33m"
N="\e[0m"

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

dnf module disable nginx -y
VALIDATE $? "Disabled nginx old versions"

dnf module enable nginx:1.24 -y
VALIDATE $? "Enabling nignx 1.24 ver.."

dnf install nginx -y
VALIDATE $? "Installing ngnix"

systemctl enable nginx 
systemctl start nginx 
VALIDATE $? "enabling and starting nginx"

rm -rf /usr/share/nginx/html/*
VALIDATE $? "Removing defalut html content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "downloading frontend code"

cd /usr/share/nginx/html

unzip /tmp/frontend.zip
VALIDATE $? "copying frontend code"

vim /etc/nginx/nginx.conf
cp frontend.service /etc/nginx/nginx.conf
VALIDATE $? "copying frontend service"

systemctl restart nginx
VALIDATE $? "Restarting nginx"

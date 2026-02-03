#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-script"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
Y="\e[33m"
N="\e[0m"
$SCRIPT_DIR=$PWD

if [ $USERID -ne 0 ]; then
    echo -e $R "Please run this command with sudo access only" $N | tee -a $LOGS_FILE
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

cp $SCRIPT_DIR/rabbitmq.repo /etc/systemd/system/rabbitmq.repo
VALIDATE $? "Settingup RabbitMQ repo"

dnf install rabbitmq-server -y
VALIDATE $? "Installing RabbitMQ"

systemctl enable rabbitmq-server
systemctl start rabbitmq-server
VALIDATE $? "Enabling and starting RabbitMQ Service"

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "Creating RabbitMQ user"
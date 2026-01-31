#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(basename $0)
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SCRIPT_DIR=$(pwd)

# ------------------ Root Check ------------------
if [ $USERID -ne 0 ]; then
  echo -e "$R Please run this script as root user $N"
  exit 1
fi

mkdir -p $LOGS_FOLDER


echo "===== Available Nginx Modules =====" | tee -a $LOGS_FILE
dnf module list nginx | tee -a $LOGS_FILE
echo "===================================" | tee -a $LOGS_FILE


# ------------------ Validation Function ------------------
VALIDATE() {
  if [ $1 -ne 0 ]; then
    echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
    exit 1
  else
    echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
  fi
}

echo "===== Frontend Setup Started =====" | tee -a $LOGS_FILE

# ------------------ Install Nginx ------------------
dnf module disable nginx -y &>>$LOGS_FILE
VALIDATE $? "Disabling default Nginx module"

dnf module enable nginx:1.24 -y &>>$LOGS_FILE
VALIDATE $? "Enabling Nginx 1.24 module"

dnf install nginx -y &>>$LOGS_FILE
VALIDATE $? "Installing Nginx"

# ------------------ Start Nginx ------------------
systemctl enable nginx &>>$LOGS_FILE
systemctl start nginx &>>$LOGS_FILE
VALIDATE $? "Starting and enabling Nginx"

# ------------------ Remove Default Content ------------------
rm -rf /usr/share/nginx/html/* &>>$LOGS_FILE
VALIDATE $? "Removing default Nginx content"

# ------------------ Download Frontend Code ------------------
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading frontend code"

cd /usr/share/nginx/html
VALIDATE $? "Moving to Nginx HTML directory"

unzip /tmp/frontend.zip &>>$LOGS_FILE
VALIDATE $? "Extracting frontend content"

# ------------------ Nginx Reverse Proxy Configuration ------------------

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOGS_FILE
VALIDATE $? "Copied custom nginx.conf"

nginx -t &>>$LOGS_FILE
VALIDATE $? "Validating Nginx configuration"



# ------------------ Restart Nginx ------------------
systemctl restart nginx &>>$LOGS_FILE
VALIDATE $? "Restarting Nginx"

echo -e "$G ===== Frontend Setup Completed Successfully ===== $N" | tee -a $LOGS_FILE

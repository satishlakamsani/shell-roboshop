#!/bin/bash

SG_ID="sg-0fd8d557c62aa017e"  #replace with your security group id
AMI_ID="ami-0220d79f3f480ecf5" #replace with your desired AMI ID
ZONE_ID="Z0031972RV2QBNE1P8DT" #replace with your hosted zone ID
DOMAIN_NAME="pugasaha.online" #replace with your domain"

for instance in $@
do 
   INSTANCE_ID=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )
    if [ $instance == "front-end" ];then
     IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PublicIpAddress' \
            --output text
        )
        RECORD_NAME="$DOMAIN_NAME" # daws88s.online
    else
     IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text
        )
        RECORD_NAME="$instance.$DOMAIN_NAME" # mongodb.daws88s.online
    fi
    echo "IP Address: $IP"


  

done



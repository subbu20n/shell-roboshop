#!/bin/bash

AMI_ID="ami_09c813fb71547fcc4f"
SG_ID="sg-04f5b8fdb267df1bd" # Replace with your SG ID
INSTANCES=("mongodb" "mysql" "redis" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z06528725AJCPEPL0K7K"
DOMAIN_NAME="subbuaws.site"

for instance in ${INSTANCES[@]}
do

  INSTANCE_ID=$(aws ec2 run-instances \ --image-id ami-09c813fb71547fc4f \ --instance-type t2.micro \
  --security-group-ids sg-04f5b8fdb267df1bd \ --tag-specifications 'ResourceType=instance,
   Tags=[{Key=Name,Value=test}]' --query "Instances[0].PrivateIpAddress" --output text)
    
               
    if [ $instance != "frontend" ]
    then 
       IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query
       "Reservations[0].Instances[0].PrivateIpAddress" --output text)
    else
       IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query
       "Reservations[0].Instances[0].PublicIpAddress" --output text)
    fi
     echo "$instance IP address: $IP"
done
#!/bin/bash
# Ubuntu-16.04: ami-0773391ae604c49a4
# RancherOS: ami-0c728496e40cbbfe1
read  -p "
Input image_id:
ami-0773391ae604c49a4--Ubuntu 16.04
ami-0c728496e40cbbfe1--Rancheros v1.4.1
: " image_id

read -p "
Input template type:
t2.small--1C2G
t2.medium--2C4G
t2.large--2C8G
: " instance_type

read -p "Select the number of instances(1-10): " count

read -p "Input disk size (GB) :" disk_size

read -p "Input instance name: " instance_name
echo -e "\n"
read -p "Please confirm your input:
    image_id = $image_id
    instance_type = $instance_type
    count = $count
    disk_size = $disk_size
    instance_name = $instance_name

yes/no? " yes_no

if [ $yes_no != "yes" ];then
    exit 1
fi

aws ec2 run-instances \
    --image-id $image_id \
    --count $count \
    --instance-type $instance_type \
    --key-name hailong \
    --security-group-ids sg-35b2634d \
    --subnet-id subnet-f7cd7d92 \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":${disk_size},\"DeleteOnTermination\":false}}]"  \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${instance_name}}]"

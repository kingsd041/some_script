#!/bin/bash
set -x
instance_types="
r4.large
m4.large
t3.small
c4.large
p2.xlarge
z1d.large
"
image_id="ami-0bcf9ffc23e25eacb"
count=1
disk_size=30

for instance_type in $instance_types;
do
instance_name="hailong-"${instance_type}
aws ec2 run-instances \
    --image-id $image_id \
    --count $count \
    --instance-type $instance_type \
    --key-name hailong \
    --security-group-ids sg-1ace2460 \
    --subnet-id subnet-c8071f81 \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":${disk_size},\"DeleteOnTermination\":false}}]"  \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${instance_name}}]"
done

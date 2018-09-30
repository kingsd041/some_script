
t2.medium: 2C4G
t2.large: 2C8G

ubuntu 1604: ami-0181f8d9b6f098ec4
windows: ami-068a5d5273c6e797e

Linux:
image_id=ami-0181f8d9b6f098ec4
instance_type=t2.medium
count=3
disk_size=20
instance_name=hailong-win1-linux-

Windows:
image_id=ami-068a5d5273c6e797e
instance_type=t2.large
count=2
disk_size=40
instance_name=hailong-win1-windows-

aws ec2 run-instances \
    --image-id $image_id \
    --count $count \
    --instance-type $instance_type \
    --key-name hailong \
    --security-group-ids sg-35b2634d \
    --subnet-id subnet-f7cd7d92 \
    --iam-instance-profile Name="aws-k8s" \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":${disk_size},\"DeleteOnTermination\":false}}]"  \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${instance_name}},{Key=kubernetes.io/cluster/ksd,Value=owned}]" 'ResourceType=volume,Tags=[{Key=kubernetes.io/cluster/ksd,Value=owned}]'



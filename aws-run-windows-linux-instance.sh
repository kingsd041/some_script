
t2.medium: 2C4G
t2.large: 2C8G

ubuntu 1804: ami-0eeb679d57500a06c
windows 2019: ami-08b0d802f0686614c

Linux:
image_id=ami-0eeb679d57500a06c
instance_type=t2.medium
count=3
disk_size=20
instance_name=hailong-win1-linux-

Windows:
image_id=ami-096ce3eb31e287a5e
#image_id=ami-08b0d802f0686614c
instance_type=c5.xlarge
count=2
disk_size=50
instance_name=hailong-win1-windows-

aws ec2 run-instances \
    --image-id $image_id \
    --count $count \
    --instance-type $instance_type \
    --key-name hailong \
    --security-group-ids sg-0959725673a3764bb \
    --subnet-id subnet-c8071f81 \
    --iam-instance-profile Name="RancherK8SUnrestrictedCloudProviderRoleAP" \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":${disk_size},\"DeleteOnTermination\":false}}]"  \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${instance_name}},{Key=kubernetes.io/cluster/ksd,Value=owned}]" 'ResourceType=volume,Tags=[{Key=kubernetes.io/cluster/ksd,Value=owned}]'



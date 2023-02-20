#!/bin/bash

key_value={key-name}
owner={owner-name}

notification_mail={notification mail}

result=$(aws ec2 describe-instances --filters "Name=key-name,Values=$key_value" "Name=tag:Owner,Values=$owner" "Name=instance-state-code,Values=16" --query "Reservations[].Instances[].InstanceId")

instance_str=$(echo $result | wc -L)

if [[ $instance_str -gt 2 ]];then
	echo -e "时间: `date "+%Y-%m-%d %H:%M:%S"` \n"region=ap-northeast-1"(东京)\n$owner 以下实例没有关机:\n$result" | s-nail  -s "$owner aws 实例告警，有虚拟机未关机" $notification_mail
else
	echo "$owner 已经把所有实例都关机了"
fi

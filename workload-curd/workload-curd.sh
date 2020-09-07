#!/bin/bash

# 常量
CONST_TRUE="true"
CONST_FALSE="false"
MAX_RETRY_TIME=10

OP_CREATE="create"
OP_UPDATE="update"
OP_DELETE="delete"

# 默认值
DEFAULT_RS_NUM=1
DEFAULT_SLEEP_TIME=10
DEFAULT_RANDOM_MAX=100

DEFAULT_SLEEP_UNIT="s"
DEFAULT_WORK_DIR=$(pwd)
DEFAULT_TEMPLATE_FILE="template.yaml"
DEFAULT_DEPLOYMENT_FILE="ng-deployment.yaml"
DEFAULT_NGINX_IMAGE="nginx:1.15.12"

GLOBAL_RAND=0

GLOBAL_READ_RESULT=$CONST_FALSE
GLOBAL_CREATE_RESULT=$CONST_FALSE
GLOBAL_UPDATE_RESULT=$CONST_FALSE
GLOBAL_DELETE_RESULT=$CONST_FALSE

# 日志
function Log() {
	echo "DEBUG:$(date '+%Y-%m-%d %H:%M:%S')-$1."
}

# 提示
function Msg() {
	echo "$1"
}

# 更新生成指定区间随机数
function RandomUpdate() {
	Log "Call method Random"
	min=$1
	max=$2
	if [ -z "$min" ];then
		min=0
	fi
	if [ -z "$max" ];then
		max=$DEFAULT_RANDOM_MAX
	fi
    GLOBAL_RAND=$(awk -v min=$min -v max=$max 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')
}

# 创建
function Create() {
	Log "Call method Create"
	path=$2
	num=$1
	if [ -z "$path" ];then
		path="$DEFAULT_WORK_DIR/$DEFAULT_DEPLOYMENT_FILE"
	fi
	if [ -z "$num" ];then
		num=$DEFAULT_RS_NUM
	fi
	cat "$DEFAULT_WORK_DIR/$DEFAULT_TEMPLATE_FILE" > $path
	if [[ "$OSTYPE" == "darwin"* ]]; then
	  sed -i '' "/^\([[:space:]]*replicas: \).*/s//\1$num/" $path
	else
	  sed -i "/^\([[:space:]]*replicas: \).*/s//\1$num/" $path
	fi
	result=$(kubectl apply -f $path)
	success='deployment.apps/nginx-deployment created'
	Log "$result"
	if [ "$result" == "$success" ]; then
		GLOBAL_CREATE_RESULT=$CONST_TRUE
	else
		GLOBAL_CREATE_RESULT=$CONST_FALSE
	fi
}


# 读取(验证CUD操作结果)
function Read() {
	Log "Call method Read"
	num=$1 # 应存在数量
	op=$2  # 操作
	if [ -z "$num" ];then
		num="$DEFAULT_RS_NUM"
	fi
	if [ -z "$op" ];then
		op="$OP_CREATE"
	fi
	if [ "$op" == "$OP_CREATE" ]; then
		result=$( kubectl get pods -l app=nginx | grep Running |wc -l| grep -o "[^ ]\+\( \+[^ ]\+\)*" ) # Running数量
		Log "Processing:[$result/$num]"
		if [ "$num" == "$result" ];then
			GLOBAL_READ_RESULT=$CONST_TRUE
		else
			GLOBAL_READ_RESULT=$CONST_FALSE
		fi
	elif [ "$op" == "$OP_DELETE" ]; then
		result=$( kubectl get pods -l app=nginx | grep nginx | wc -l | grep -o "[^ ]\+\( \+[^ ]\+\)*" ) # 总数量
		Log "Processing:[$result left]"
		if [ "$num" == "$result" ];then
			GLOBAL_READ_RESULT=$CONST_TRUE
		else
			GLOBAL_READ_RESULT=$CONST_FALSE
		fi
	elif [ "$op" == "$OP_UPDATE"  ]; then
		total=$( kubectl get pods -l app=nginx | grep nginx | wc -l | grep -o "[^ ]\+\( \+[^ ]\+\)*" ) # 总数量
		running=$( kubectl get pods -l app=nginx | grep Running |wc -l| grep -o "[^ ]\+\( \+[^ ]\+\)*" ) # Running数量
		Log "Total/Running:($total/$running)"
		if [ "$running" == "$total" ];then
			GLOBAL_READ_RESULT=$CONST_TRUE
		else
			GLOBAL_READ_RESULT=$CONST_FALSE
		fi
	fi
	
}

# 更新
function Update() {
	Log "Call method Update"
	path=$2
	image=$1
	if [ -z "$path" ];then
		path="$DEFAULT_WORK_DIR/$DEFAULT_DEPLOYMENT_FILE"
	fi
	if [ -z "$imageVersion" ];then
		image=$DEFAULT_NGINX_IMAGE
	fi
	if [[ "$OSTYPE" == "darwin"* ]]; then
	  sed -i ''  "/^\([[:space:]]*image: \).*/s//\1$image/" $path
	else
	  sed -i  "/^\([[:space:]]*image: \).*/s//\1$image/" $path
	fi
	result=$(kubectl apply -f $path)
	success='deployment.apps/nginx-deployment configured'
	Log "$result"
	if [ "$result" == "$success" ]; then
		GLOBAL_UPDATE_RESULT=$CONST_TRUE
	else
		GLOBAL_UPDATE_RESULT=$CONST_FALSE
	fi
}

# 删除
function Delete() {
	Log "Call method Delete"
	path=$1
	if [ -z "$path" ];then
		path="$DEFAULT_WORK_DIR/$DEFAULT_DEPLOYMENT_FILE"
	fi
	result=$(kubectl delete -f $path)
	# NOTE 如果变更yaml，这里的信息需要更改
	success='deployment.apps "nginx-deployment" deleted'
	Log "$result"
	if [ "$result" == "$success" ];then
		GLOBAL_DELETE_RESULT=$CONST_TRUE
	else
		GLOBAL_DELETE_RESULT=$CONST_FALSE
	fi
}

# 休眠
function Sleep() {
	Log "Call method Sleep"
	d=$1 # 时间
	u=$DEFAULT_SLEEP_UNIT # 单位
	if [ -z "$d" ];then
		Log "Sleep duration is null,use default $DEFAULT_SLEEP_TIME"
		d=$DEFAULT_SLEEP_TIME
	fi
	Log "$d$u"
	# sleep [--help] [--version] number[smhd]
	# --help : 显示辅助讯息
	# --version : 显示版本编号
	# number : 时间长度，后面可接 s、m、h 或 d
	# 其中 s 为秒，m 为 分钟，h 为小时，d 为日数
	sleep $d$u
}

# 主体逻辑
function Main() {
	start=$1
	end=$2
	step=$3
	if [ -z "$start" ]; then
		start=1
	fi
	if [ -z "$end" ]; then
		end=100
	fi
	if [ -z "$step" ]; then
		step=1
	fi
	Log "Started!"
	for (( i = $start; i <= $end; i=$i+$step )); do
		Log "now $i"

		# 创建逻辑
		Create "$i"
		if [ "$GLOBAL_CREATE_RESULT" == "$CONST_TRUE" ]; then
			Msg "Create call success."
		fi
		while [ "$GLOBAL_READ_RESULT" == "$CONST_FALSE" ]; do
			Msg "Creating."
			Sleep "$DEFAULT_SLEEP_TIME"
			Read "$i" "$OP_CREATE"
		done
		Msg "All of $i is created."
		GLOBAL_READ_RESULT=$CONST_FALSE

		# 更新逻辑
		Update "$DEFAULT_NGINX_IMAGE"
		if [ "$GLOBAL_UPDATE_RESULT" == "$CONST_TRUE" ];then
			Msg "Update call success."
		fi
		while [ "$GLOBAL_READ_RESULT" == "$CONST_FALSE" ]; do
			Msg "Updating."
			Sleep "$DEFAULT_SLEEP_TIME"
			Read "$i" "$OP_UPDATE"
		done
		Msg "All of $i is updated."
		GLOBAL_READ_RESULT=$CONST_FALSE

		# 删除逻辑
		Delete
		if [ "$GLOBAL_DELETE_RESULT" == "$CONST_TRUE" ];then
			Msg "Delete call success."
		fi
		while [ "$GLOBAL_READ_RESULT" == "$CONST_FALSE" ]; do
			Msg "Deleting."
			Sleep "$DEFAULT_SLEEP_TIME"
			Read 0 "$OP_DELETE"
		done
		Msg "All of $i is deleted."
		GLOBAL_READ_RESULT=$CONST_FALSE

	done
	Log "Ended!"
}


# Call Main 
# 参数1 副本最小数量
# 参数2 副本最大数量
# 参数3 副本循环增加步长
while true
do
    let numb+=1
    echo "### -- $numb" >> count.txt
    echo "Begin: `date` -- $numb" >> count.txt
    Main 1 75 1
    echo "End: `date`  -- $numb" >> count.txt
done

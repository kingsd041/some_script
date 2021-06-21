#!/bin/bash

# set -x

# 默认值
DEFAULT_PROJECT_NUM=2
## 每个项目拥有的命名空间个数, 例如DEFAULT_PROJECT_NUM=2  DEFAULT_NAMESPACE_NUM=3，将会创建 2*3=6个Namespace
DEFAULT_NAMESPACE_NUM=3
# DEFAULT_WORKLOAD_NUM=3
DEFAULT_PROJECT_PREFIX="project"
DEFAULT_NAMESPACE_PREFIX="ns"
DEFAULT_START_NUM=1

# 日志
function Log() {
    echo "INFO:$(date '+%Y-%m-%d %H:%M:%S'):  $1."
}

# 提示
function Msg() {
    echo "$1"
}

# 创建Project
function CreateProject() {
    Log "Start creating the project ... "

    num=$1

    for i in $(seq $DEFAULT_START_NUM $num); do

        # 判断是否存在project
        rancher project list | grep -w $DEFAULT_PROJECT_PREFIX-$i >/dev/null 2>&1

        if [[ $? == 0 ]]; then
            Log "Project $DEFAULT_PROJECT_PREFIX-$i already exists, exit"
            continue
        fi

        rancher project create $DEFAULT_PROJECT_PREFIX-$i
        if [[ $? == 0 ]]; then
            Log "Project "$DEFAULT_PROJECT_PREFIX-$i" was created successfully"
        else
            Log "Project "$DEFAULT_PROJECT_PREFIX-$i" was created failed"
        fi
    done
}

# 创建命名空间
function CreateNamespace() {
    Log "Start creating the namespace ..."

    num=$1

    for i in $(seq $DEFAULT_START_NUM $num); do

        rancher namespaces create $DEFAULT_NAMESPACE_PREFIX-$i

        if [[ $? == 0 ]]; then
            Log "Namespace "$DEFAULT_NAMESPACE_PREFIX-$i" was created successfully"
        else
            Log "Namespace "$DEFAULT_NAMESPACE_PREFIX-$i" was created failed"
        fi
    done
}

# 将命名空间移动到项目
function MoveNamespaceToProject() {
    pj=$1
    ns=$2

    rancher namespaces move $DEFAULT_NAMESPACE_PREFIX-$ns $DEFAULT_PROJECT_PREFIX-$pj

    if [[ $? == 0 ]]; then
        Log "$DEFAULT_NAMESPACE_PREFIX-$ns moved to $DEFAULT_PROJECT_PREFIX-$pj successfully"
    else
        Log "$DEFAULT_NAMESPACE_PREFIX-$ns moved to $DEFAULT_PROJECT_PREFIX-$pj failed"
    fi
}

function MoveNamespaceToProject() {
    pj=$1
    ns=$2
    a=0
    Log "Move the Namespace to the Project ..."
    for p in $(seq $DEFAULT_START_NUM $pj); do
        for n in $(seq $(($DEFAULT_START_NUM + $a)) $(($ns + $a))); do

            rancher namespaces move $DEFAULT_NAMESPACE_PREFIX-$n $DEFAULT_PROJECT_PREFIX-$p

            if [[ $? == 0 ]]; then
                Log "$DEFAULT_NAMESPACE_PREFIX-$n moved to $DEFAULT_PROJECT_PREFIX-$p successfully"
            else
                Log "$DEFAULT_NAMESPACE_PREFIX-$n moved to $DEFAULT_PROJECT_PREFIX-$p failed"
            fi
        done
        let a+=$DEFAULT_NAMESPACE_NUM
    done

}

# 创建workload
function CreateWorkload() {
    Log "Start creating the workload ..."
    num=$1

    for i in $(seq $DEFAULT_START_NUM $num); do
        # rancher apps install -n ns-1 nginx
        result=$(rancher kubectl -n $DEFAULT_NAMESPACE_PREFIX-$i apply -f template.yaml)
        Log "$result in the $DEFAULT_NAMESPACE_PREFIX-$i"
    done
}

CreateProject $DEFAULT_PROJECT_NUM
CreateNamespace $(($DEFAULT_NAMESPACE_NUM * $DEFAULT_PROJECT_NUM))
MoveNamespaceToProject $DEFAULT_PROJECT_NUM $DEFAULT_NAMESPACE_NUM
CreateWorkload $(($DEFAULT_NAMESPACE_NUM * $DEFAULT_PROJECT_NUM))



# 删除创建的workload
## for i in `kubectl get ns | grep -E 'ns-[0-9]*' | awk '{print $1}'`;do kubectl -n $i delete -f template.yaml ;done
# 删除创建的project
## rancher project delete `rancher project list | grep project- | awk '{print $1}'`

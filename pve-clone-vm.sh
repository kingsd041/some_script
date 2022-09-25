#!/bin/bash

help ()
{
    echo  ' ================================================================ '
    echo  ' 支持两个参数，第一参数为 虚拟机名称的前缀，第二个参数为创建的虚拟机个数；'
    echo  ' 使用示例:'
    echo  ' ./pve-clone-vm.sh rancher 2 \ '
    echo  ' 会克隆两个虚拟机，分别为 rancher1 rancher2 '
    echo  ' ================================================================'
}

case "$1" in
    -h|--help) help; exit;;
esac

if [[ $2 == '' ]];then
    help;
    exit;
fi

vm_prefix=$1
vm_count=$2
vm_image=9006

get_vmid ()
{
    vm_original_id=`cat vm_id.txt`
}


for vc in $(seq 1 $vm_count);
do
    get_vmid

    vm_new_id=$((${vm_original_id}+1)) 
    qm clone $vm_image $vm_new_id -name $vm_prefix-$vc
    qm start $vm_new_id
    echo $vm_new_id > vm_id.txt
done

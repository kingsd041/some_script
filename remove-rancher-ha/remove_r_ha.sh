#!/bin/bash

# 需要提前安装jq和rancher system-tools(https://rancher.com/docs/rancher/v2.x/en/system-tools/)

# 获取要删除的命名空间
# 注意：使用钱，请谨慎检查要删除的 命名空间
DEL_NS=`kubectl get ns  | grep -E "cattle-system|fleet-clusters-system|fleet-local|fleet-system|fleet-default|cluster-fleet-local-local-*|rancher-operator-system|cattle-global-nt|cattle-global-data" | awk '{print $1}'`

NAMESPACE=$DEL_NS # 指定需要删除的命名空间
KUBE_CONFIG='/Users/ksd/.kube/config' # 指定 K8S 配置文件

for ns in ${NAMESPACE}; do
    system-tools remove -c ${KUBE_CONFIG} --namespace $ns --force
done

if kubectl get ns | grep Terminating; then
    TERMINATING_NAMESPACE=`kubectl get ns | grep Terminating | awk '{print $1}'`
    K8S_API_URL=`kubectl --kubeconfig=${KUBE_CONFIG} config view --raw -o json|jq -r '.clusters[0].cluster.server'`

    # 注意：如果 config 中证书是以文件保存，此处命令
    kubectl --kubeconfig=${KUBE_CONFIG} config view --raw -o json| \
    jq -r '.users[0].user."client-certificate-data"'| \
    tr -d '"'|base64 --decode > /tmp/client_cert.pem

    kubectl --kubeconfig=${KUBE_CONFIG} config view --raw -o json| \
    jq -r '.users[0].user."client-key-data"'| \
    tr -d '"'|base64 --decode > /tmp/client_key.pem

    kubectl --kubeconfig=${KUBE_CONFIG} config view --raw -o json| \
    jq -r '.clusters[0].cluster."certificate-authority-data"'| \
    tr -d '"'|base64 --decode > /tmp/client_ca.pem

    for t_ns in ${TERMINATING_NAMESPACE}; do
        # 获取删除 finalizers 后的命名空间 json 配置
        kubectl --kubeconfig=${KUBE_CONFIG} get ns ${t_ns} -ojson| \
        jq 'del(.spec.finalizers[])'| \
        jq 'del(.metadata.finalizers)' > ${t_ns}.json

        # 个别命名空间没有 .spec.finalizers，上面命令执行过程中将会报错，所以去掉.spec.finalizers 重新执行一次
        # 不知道jq如何在key为空时跳过，暂时这么处理，方法确实很烂
        if [[ ! -s ${t_ns}.json ]]; then
            kubectl --kubeconfig=${KUBE_CONFIG} get ns ${t_ns} -ojson| \
            jq 'del(.metadata.finalizers)' > ${t_ns}.json 
        fi

        curl -k \
        --cert /tmp/client_cert.pem \
        --key /tmp/client_key.pem \
        --cacert /tmp/client_ca.pem \
        -H "Content-Type: application/json" \
        -X PUT \
        --data-binary @${t_ns}.json \
        ${K8S_API_URL}/api/v1/namespaces/${t_ns}/finalize
    done
fi


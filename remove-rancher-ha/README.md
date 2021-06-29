# 移除 Rancher HA

Rancher HA 需要搭建在 Local K3s/K8s 集群上，当需要删除 Rancher HA 或 重新搭建 Rancher HA 时，我们需要先清理掉 Rancher HA 安装过程中生成的一些数据。

Rancher 官网提供了一个移除 Rancher HA 的工具，[system-tools](https://rancher.com/docs/rancher/v2.x/en/system-tools/)，我们可以借住 system-tools 来将 Rancher HA 生成的命名空间都删掉。

## 要求

1. 操作主机需要安装`jq`命令
2. 操作主机需要安装[system-tools](https://rancher.com/docs/rancher/v2.x/en/system-tools/)到 `/usr/local/bin/system-tools` 下

## 使用

> 注意：
>
> 1. 我只在 k3s 作为 local 集群上测试过
> 2. 使用之前一定要确认要待删除的命名空间： grep -E "cattle-system|fleet-clusters-system|fleet-local|fleet-system|fleet-default|cluster-fleet-local-local-\*|rancher-operator-system|cattle-global-nt|cattle-global-data"

```
./remove_r_ha.sh
```

## 排错

如果在执行过程中出现异常：
```
panic: runtime error: invalid memory address or nil pointer dereference [recovered]
	panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x1 addr=0x30 pc=0x1d21949]
```

可以先执行`kubectl --namespace kube-system delete apiservice v1beta1.metrics.k8s.io` 然后在继续执行本脚本，参考：https://github.com/rancher/rancher/issues/20918
#!/bin/sh

# 创建nvidia-container-runtime及k3s-gpu-share支持

gpu_support_k3s() {

  tar zxvf tools/nvidia-airgap.tgz -C /

  mkdir /etc/kubernetes /etc/nvidia-container-runtime -p
  cat >/etc/kubernetes/scheduler-policy-config.json <<-EOF
{
  "kind": "Policy",
  "apiVersion": "v1",
  "extenders": [
    {
      "urlPrefix": "http://127.0.0.1:32766/gpushare-scheduler",
      "filterVerb": "filter",
      "bindVerb":   "bind",
      "enableHttps": false,
      "nodeCacheCapable": true,
      "managedResources": [
        {
          "name": "aliyun.com/gpu-mem",
          "ignoredByScheduler": false
        }
      ],
      "ignorable": false
    }
  ]
}
EOF

  # nvidia-container-runtime所需配置

  cat >/etc/nvidia-container-runtime/config.toml <<-EOF
disable-require = false
#swarm-resource = "DOCKER_RESOURCE_GPU"
#accept-nvidia-visible-devices-envvar-when-unprivileged = true
#accept-nvidia-visible-devices-as-volume-mounts = false

[nvidia-container-cli]
#root = "/run/nvidia/driver"
#path = "/usr/bin/nvidia-container-cli"
environment = []
#debug = "/var/log/nvidia-container-toolkit.log"
#ldcache = "/etc/ld.so.cache"
load-kmods = true
#no-cgroups = false
#user = "root:video"
ldconfig = "@/sbin/ldconfig.real"

[nvidia-container-runtime]
#debug = "/var/log/nvidia-container-runtime.log"
EOF

  cat >/etc/docker/daemon.json <<-EOF
{
"registry-mirrors": [
    "https://wlzfs4t4.mirror.aliyuncs.com",
    "https://wlzfs4t4.mirror.aliyuncs.com"
],

"insecure-registries": [
    "dockerhub.private.rockcontrol.com:5000"
],

"bip":"169.254.31.1/24",
"max-concurrent-downloads": 10,
"log-driver": "json-file",
"log-level": "warn",
"log-opts": {
    "max-size": "10m",
    "max-file": "3"
    },
"data-root": "/data/var/lib/docker",
"default-runtime": "nvidia",
"runtimes": {
    "nvidia": { 
	"path": "/usr/bin/nvidia-container-runtime", 
	"runtimeArgs": []
    }   
}
}
EOF

  sed -i '$s#.*#        '\''policy-config-file=/etc/kubernetes/scheduler-policy-config.json'\'' #' /etc/systemd/system/k3s-agent.service

}

install_nvidia_support() {

  kubectl label node $(hostname) gpushare=true
  cp tools/kubectl-inspect-gpushare /usr/bin/

}

gpu_support_k3s

echo "重启k3s环境。"
systemctl daemon-reload
systemctl stop k3s-agent
systemctl restart docker
systemctl start k3s-agent

echo "添加gpu组件支持。"

install_nvidia_support

echo "完成！"

#!/bin/sh



install_nvidia_support() {
    kubectl  apply -f manifests/gpushare-schd-extender.yaml
    sleep 5 && kubectl label node --all  gpushare=true && kubectl  apply -f manifests/gpushare-device-plugin.yaml && kubectl  apply -f manifests/nvidia-device-plugin.yaml
}

# 创建nvidia-container-runtime及k3s-gpu-share支持

gpu_support_k3s() {


    tar zxvf tools/nvidia-airgap.tgz -C /

    mkdir /etc/kubernetes /etc/nvidia-container-runtime -p
    cat > /etc/kubernetes/scheduler-policy-config.json <<-EOF
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

    cat > /etc/nvidia-container-runtime/config.toml <<-EOF
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


    cat > /etc/docker/daemon.json <<-EOF 
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


#修改k3s-service
cat > /etc/systemd/system/k3s.service <<-EOF 
[Unit]
Description=Lightweight Kubernetes
Documentation=https://k3s.io
Wants=network-online.target
After=network-online.target

[Install]
WantedBy=multi-user.target

[Service]
Type=notify
EnvironmentFile=-/etc/default/%N
EnvironmentFile=-/etc/sysconfig/%N
EnvironmentFile=-/etc/systemd/system/k3s.service.env
KillMode=process
Delegate=yes
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=always
RestartSec=5s
ExecStartPre=/bin/sh -xc '! /usr/bin/systemctl is-enabled --quiet nm-cloud-setup.service'
ExecStartPre=-/sbin/modprobe br_netfilter
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/k3s \
    server \
        '--disable=traefik' \
        '--data-dir' \
        '/data/rancher/k3s' \
        '--write-kubeconfig' \
        '/root/.kube/config' \
        '--docker' \
        '--kube-apiserver-arg=authorization-mode=Node,RBAC' \
        '--kube-apiserver-arg=allow-privileged=true' \
        'masquerade-all=true' \
        '--kube-proxy-arg' \
        'metrics-bind-address=0.0.0.0' \
        '--kube-apiserver-arg=service-node-port-range=20000-40000' \
        '--kubelet-arg=max-pods=300' \
        '--kube-scheduler-arg="policy-config-file=/etc/kubernetes/scheduler-policy-config.json"'\

EOF

}

start_k3s_docker() {
  systemctl daemon-reload
  systemctl stop k3s
  systemctl restart docker
  systemctl start k3s
  echo "restart all services successed!"
}


{
  gpu_support_k3s
  start_k3s_docker
  install_nvidia_support
}










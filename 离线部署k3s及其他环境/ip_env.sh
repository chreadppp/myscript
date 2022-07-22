#!/bin/sh

ipip() {

    if cat /etc/hosts | grep 'by k3s-custom' >/dev/null 2>&1 ;then echo "设置hosts.." ;else  echo "124.70.75.116 hub-dev.rockontrol.com #by k3s-custom" >>/etc/hosts ;fi

#获取ip并进行配置修改
    # private dns hosts for cluster
    if ifconfig | grep br0 >/dev/null; then
        ip=$(ip a | grep br0 | grep inet | awk -F ' ' '{print $2}' | cut -d "/" -f1)
    else
        ip=""
        read -p "未找到br0网卡,请直接输入本机ip:" ip
        info "设置本机IP为：$ip"
        check_ip $ip
    fi

    domain_custom="" && read -t 120 -ep "本地域名默认为[k3snode.local]，需自定义请直接输入:" domain_custom

    if [ ! $domain_custom ] ;then
        domain_custom="k3snode.local"
    else
        sed -i "s/k3snode.local/$domain_custom/g" `grep 'k3snode.local' -lr manifests`
    fi

    info "添加minio与api的dns配置!"
    dns_c="$ip minio.$domain_custom\n$ip api.$domain_custom\n" && kubectl patch cm coredns -n kube-system --type=json -p="[{\"op\":\"add\", \"path\":\"/data/NodeHosts\", \"value\":\"$dns_c\"}]"

}


auto_command_k8s() {

    if [ -f /usr/share/bash-completion/bash_completion ];then
        source /usr/share/bash-completion/bash_completion

        echo 'source <(kubectl completion bash)' >> ~/.bashrc

        source ~/.bashrc
else
echo "k8s自动补全命令依赖bash-completion，可能未安装！"
echo "可运行[type _init_completion]测试。"


}


ipip
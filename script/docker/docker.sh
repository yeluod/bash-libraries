#!/bin/bash

set -e

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

check_os() {
    log '开始检查系统信息 ......'
    local name
    local version
    local extended
    name=$(rpm -q centos-release | awk -F "-" '{print $1}')
    version=$(rpm -q centos-release | awk -F "-" '{print $3}')
    extended=$(rpm -q centos-release | awk -F "-" '{print $4}' | awk -F '.' '{print $6}')
    if [ "${name}" != 'centos' ] || [ "${version}" != '7' ] || [ "${extended}" != 'x86_64' ]; then
        log '暂不支持此系统版本'
        exit
    fi
}

uninstall_docker() {
    log '开始卸载旧版本 docker ......'
    yum remove -y docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-engine \
        docker-ce \
        docker-ce-cli \
        docker-compose-plugin \
        docker-compose
    rm -rf /var/lib/docker*
}

install_yum_utils() {
    log '安装 yum-utils ......'
    yum install -y yum-utils
}

select_docker_repo() {
    log '设置 Docker 存储库 ......'
    local repos=(
        "https://download.docker.com/linux/centos/docker-ce.repo"
        "https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/docker-ce.repo"
        "http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo"
        "http://mirrors.163.com/docker-ce/linux/centos/docker-ce.repo"
        "http://mirrors.ustc.edu.cn/docker-ce/linux/centos/docker-ce.repo"
    )
    log '存储库 1: 官方 2:清华大学 3:阿里云, 4: 网易云  5: 中科大 请选择包索引编号: '
    read -r repo_index
    yum-config-manager --add-repo "${repos[$((repo_index-1))]}"
    yum makecache fast
}

install_docker() {
    log '安装 Docker ......'
    local reply
    read -r -p "是否安装最新版本 Docker (Y/n): " reply
    case "$reply" in
        Y | y)
            yum install -y docker-ce docker-ce-cli docker-compose-plugin docker-compose
            ;;
        N | n)
            log '请选择需要安装的版本编号: '
            read -r version_index
            local version
            version=$(yum list docker-ce --showduplicates | sort -r | awk -F ' ' 'NR>4{print $2}' | awk -F ':' '{print $2}' | sed -n "${version_index}p")
            log "当前选择版本为: $version"
            yum install -y docker-ce-"$version" docker-ce-cli-"$version" containerd.io docker-compose-plugin docker-compose
            ;;
    esac
}

configure_docker() {
    log '配置 Docker ......'
    mkdir -p /etc/docker
    tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://y0ovxpv6.mirror.aliyuncs.com"],
  "insecure-registries":[
        "192.168.10.49:80"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "500m",
    "max-file": "3"
  }
}
EOF
    systemctl daemon-reload
    systemctl restart docker
    local reply
    read -r -p "是否开机启动 Docker(Y/n) : " reply
    case "$reply" in
        Y | y)
            systemctl enable docker
            ;;
        N | n)
            ;;
    esac
}

print_installation_info() {
    log '##############################################################################################################################################################################'
    log '##  Docker 安装完成 ...'
    log "## $(docker -v)"
    log "## New $(docker compose version) Doc(https://docs.docker.com/compose/compose-v2/)"
    log '##############################################################################################################################################################################'
}

main() {
    check_os
    uninstall_docker
    install_yum_utils
    select_docker_repo
    install_docker
    configure_docker
    print_installation_info
}

main

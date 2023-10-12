#!/bin/bash

set -e

echo "此脚本适用于Ubuntu 22.04，未在其他系统上测试"

echo "检查当前用户"
if [ "$EUID" -ne 0 ]; then
  echo "此脚本需要以root用户身份运行，请使用sudo或以root用户登录"
  exit 1
fi

echo "更新系统"
apt update
apt full-upgrade -y

echo "安装依赖"
apt install ca-certificates curl gnupg

echo "安装docker"
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do apt remove $pkg; done
curl -s https://get.docker.com/ | sh
systemctl start docker

echo "将当前用户添加到docker组并为当前shell环境应用组更改"
usermod -aG docker $USER && su $USER

echo "创建下载目录"
dowload_dir="/opt/greenbone-community-container"
mkdir -p $dowload_dir

echo "下载docker-compose.yml"
cd $dowload_dir && curl -f -L https://greenbone.github.io/docs/latest/_static/docker-compose-22.4.yml -o docker-compose.yml

echo "替换GSA监听地址"
sed -i 's/127.0.0.1:9392:80/0.0.0.0:9392:80/g' docker-compose.yml

echo "拉取Greenbone Community Containers镜像"
docker compose -f docker-compose.yml -p greenbone-community-edition pull

echo "启动Greenbone Community Containers"
docker compose -f docker-compose.yml -p greenbone-community-edition up -d

echo "现在将加载提要数据，这个过程可能需要几分钟到几个小时"
echo "在数据未完全加载之前，扫描会显示不充分或错误的结果"
echo "请参阅https://greenbone.github.io/docs/latest/22.4/container/workflows.html#loading-the-feed-changes了解更多详细信息"
echo ""
echo "运行下面的命令来获取所有服务的日志"
echo "docker compose -f docker-compose.yml -p greenbone-community-edition logs -f"
echo ""
echo "请通过http://YOUR_SERVER_IP:9392访问Greenbone Security Assistant Web界面"

echo "
# 结束脚本
exit 0

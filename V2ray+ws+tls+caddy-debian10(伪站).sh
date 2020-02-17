#!/bin/bash

ehco "---------------------------------------------------------------------------------"
ehco "Author:WX"
ehco "WS+TLS+Caddy+v2ray Onetap Script V1.0"
echo "Warning:Only for Debina 10"
ehco "----------------------------------------------------------------------------------"
sleep 3

#安装常用软件
apt-get install unzip
apt-get install wget
#安装Caddy 
curl https://getcaddy.com | bash -s personal
#文件及权限
mkdir /etc/caddy
chown -R root:root /etc/caddy
mkdir /etc/ssl/caddy
chown -R root:www-data /etc/ssl/caddy
chmod 770 /etc/ssl/caddy
mkdir -p /var/www/html
chown -R www-data:www-data /var/www
#配置Caddy
ehco "................................................."
ehco "请输入您的域名：                                  "
ehco "................................................."
read yourdom
ehco "................................................."
ehco "请输入您的Path：                                  "
ehco "................................................."
read v2ray_path
touch /etc/caddy/Caddyfile
cat>/etc/caddy/Caddyfile<<EOF
https://${yourdom} {
  root /var/www/html
 timeouts none
 tls myeagleandsnake@gmail.com
 gzip
 proxy ${v2ray_path} 127.0.0.1:1080 {
  websocket
  header_upstream -Origin
  }
}
EOF
chown root:root /etc/caddy/Caddyfile
chmod 644 /etc/caddy/Caddyfile

#配置伪站
cd /var/www/html
wget https://github.com/eagleandsanake/weizhan/raw/master/web.zip
unzip web.zip
cd
#将Caddy加入daemon
cd /etc/systemd/system/
wget https://raw.githubusercontent.com/caddyserver/caddy/master/dist/init/linux-systemd/caddy.service
cd
chown root:root /etc/systemd/system/caddy.service
chmod 644 /etc/systemd/system/caddy.service
systemctl daemon-reload
#启动Caddy
systemctl enable caddy 
systemctl start caddy
systemctl restart caddy

#时间校准
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
timenow=$(date -R)
#安装v2ray
bash <(curl -L -s https://install.direct/go.sh)
#配置v2ray 
ehco "................................................."
ehco "请输入您的AlterId："
ehco "................................................."
read v2ray_alterid
UUID=$(cat /proc/sys/kernel/random/uuid)
cat>/etc/v2ray/config.json<<EOF
{
  "inbounds": [
    {
      "port": 1080,
      "listen":"127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
           "id": "${UUID}",
            "alterId": ${v2ray_alterid}
          }
        ]
       },
       "streamSettings": {
        "network": "ws",
        "wsSettings": {
        "path": "${v2ray_path}"
        }
       }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
#启动v2ray
systemctl start v2ray 
systemctl restart v2ray
systemctl restart caddy 
#开启bbr
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
sysctl net.ipv4.tcp_available_congestion_control
bbr_status=$(lsmod | grep bbr)
sleep 3
#cheack
systemctl status v2ray
sleep 3
systemctl status caddy
sleep 3
 #配置信息显示
 clear
 ehco "域名：${yourdom}"
 ehco "uuid：${UUID}"
 echo "alterId：${v2ray_alterid}"
 ehco "端口：443"
 ehco "加密协议：ws"
 ehco "Path：${v2ray_path}"
 ehco "底层传输协议：TLS"
 ehco "当下系统时间：${timenow}"
 ehco "BBR状态：${bbr_status}"
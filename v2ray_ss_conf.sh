#!/bin/bash
# Shadowsocks 和 V2Ray 简易配置: 生成和显示二维码  短网址: https://git.io/v2ray.ss

let v2ray_port=$RANDOM+9999
UUID=$(cat /proc/sys/kernel/random/uuid)

let ss_port=$RANDOM+8888
ss_passwd=$(date | md5sum  | head -c 6)
cur_dir=$(pwd)

if [ ! -e '/var/ip_addr' ]; then
   echo -n $(curl -4 ip.sb) > /var/ip_addr
fi
serverip=$(cat /var/ip_addr)

# 修改端口号
setport(){
    echo_SkyBlue ":: 1.请修改 V2ray 服务器端端口号，随机端口:${RedBG} ${v2ray_port} "
    read -p "请输入数字(100--60000): " num

    if [[ ${num} -ge 100 ]] && [[ ${num} -le 60000 ]]; then
       v2ray_port=$num
    fi
}

# debian 9 bbr 设置打开
sysctl_config() {
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
    echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1
}



ss_enable(){
cat <<EOF >/etc/rc.local
#!/bin/sh -e
ss-server -s 0.0.0.0 -p 40000 -k ${ss_passwd} -m aes-256-gcm -t 300 >> /var/log/ss-server.log &

exit 0
EOF
}

conf_shadowsocks(){

    echo_SkyBlue ":: 2.请修改 Shadowsocks 服务器端端口号，随机端口: ${RedBG} ${ss_port} "
    read -p "请输入数字(100--60000): " num

    if [[ ${num} -ge 100 ]] && [[ ${num} -le 60000 ]]; then
       ss_port=$num
    fi

    echo_SkyBlue ":: 3.请修改 Shadowsocks 的密码，随机密码: ${RedBG} ${ss_passwd} "
    read -p "请输入你要的密码(按回车不修改): "  new

    if [[ ! -z "${new}" ]]; then
        ss_passwd="${new}"
        echo -e "修改密码: ${GreenBG} ${ss_passwd} ${Font}"
    fi

    # 如果 Shadowsocks 没有安装，安装Shadowsocks
    if [ ! -e '/usr/local/bin/ss-server' ]; then
        sysctl_config
        ss_enable
        bash <(curl -L -s git.io/fhExJ)
    fi

    old_ss_port=$(cat /etc/rc.local | grep ss-server | awk '{print $5}')
    old_passwd=$(cat /etc/rc.local | grep ss-server | awk '{print $7}')
    method=$(cat /etc/rc.local | grep ss-server | awk '{print $9}')

	sed -i "s/${old_ss_port}/${ss_port}/g"   "/etc/rc.local"
    sed -i "s/${old_passwd}/${ss_passwd}/g"  "/etc/rc.local"
	sed -i "s/ss-server -s 127.0.0.1/ss-server -s 0.0.0.0/g"  "/etc/rc.local"

    systemctl stop rc-local
    # 简化判断系统 debian/centos 族群
    if [ -e '/etc/redhat-release' ]; then
        mv /etc/rc.local /etc/rc.d/rc.local
        ln -s /etc/rc.d/rc.local /etc/rc.local
        chmod +x /etc/rc.d/rc.local
        systemctl enable rc-local
    else
        chmod +x /etc/rc.local
        systemctl enable rc-local
    fi

	systemctl restart rc-local

    echo_Yellow ":: Shadowsocks 服务 加密协议/密码/IP/端口 信息!"
	# ss://<<base64_shadowsocks.conf>>
	echo "${method}:${ss_passwd}@${serverip}:${ss_port}" | tee ${cur_dir}/base64_shadowsocks.conf
}

conf_v2ray(){
    # 如果 v2ray 没有安装，安装v2ray
    if [ ! -e '/etc/v2ray/config.json' ]; then
        bash <(curl -L -s https://install.direct/go.sh)
    fi

    echo_SkyBlue ":: V2ray 服务 IP/端口/UUID等信息!"
    # vmess://<<base64_v2ray_vmess.json>>
    cat <<EOF | tee ${cur_dir}/base64_v2ray_vmess.json
{
  "v": "2",
  "ps": "v2ray",
  "add": "${serverip}",
  "port": "${v2ray_port}",
  "id": "${UUID}",
  "aid": "64",
  "net": "kcp",
  "type": "srtp",
  "host": "",
  "path": "",
  "tls": ""
}
EOF

# v2ray服务端mKcp配 /etc/v2ray/config.json
cat <<EOF >/etc/v2ray/config.json
{
  "inbounds": [
    {
      "port": $v2ray_port,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${UUID}",
            "level": 1,
            "alterId": 64
          }
        ]
      },
      "streamSettings": {
        "tcpSettings": {},
        "quicSettings": {},
        "tlsSettings": {},
        "network": "kcp",
        "kcpSettings": {
          "mtu": 1350,
          "tti": 50,
          "header": {
            "type": "srtp"
          },
          "readBufferSize": 2,
          "writeBufferSize": 2,
          "downlinkCapacity": 100,
          "congestion": false,
          "uplinkCapacity": 100
        },
        "wsSettings": {},
        "httpSettings": {},
        "security": "none"
      }
    }
  ],
  "log": {
    "access": "/var/log/v2ray/access.log",
    "loglevel": "info",
    "error": "/var/log/v2ray/error.log"
  },
  "routing": {
    "rules": [
      {
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10"
        ],
        "type": "field",
        "outboundTag": "blocked"
      }
    ]
  },
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "tag": "blocked",
      "settings": {}
    }
  ]
}
EOF

systemctl restart v2ray
}


# 定义文字颜色
Green="\033[32m"  && Red="\033[31m" && GreenBG="\033[42;37m" && RedBG="\033[41;37m"
Font="\033[0m"  && Yellow="\033[0;33m" && SkyBlue="\033[0;36m"

echo_SkyBlue(){
    echo -e "${SkyBlue}$1${Font}"
}
echo_Yellow(){
    echo -e "${Yellow}$1${Font}"
}

# 显示手机客户端二维码
conf_QRcode(){

     st="$(cat ${cur_dir}/base64_shadowsocks.conf)"
     ss_b64=$(echo -n $st | base64)
     shadowsocks_ss="ss://${ss_b64}"

     v2_b64=$(base64 -w0 ${cur_dir}/base64_v2ray_vmess.json)
     v2ray_vmess="vmess://${v2_b64}"

     echo_SkyBlue ":: Shadowsocks 服务器二维码,请手机扫描!"
     echo -n $shadowsocks_ss | qrencode -o - -t UTF8
     echo_Yellow $shadowsocks_ss
     echo
     echo_SkyBlue ":: V2rayNG 手机配置二维码,请手机扫描!"
     echo -n $v2ray_vmess  | qrencode -o - -t UTF8
     echo_SkyBlue  ":: V2rayN Windows 客户端 Vmess 协议配置"
     echo $v2ray_vmess
     echo_SkyBlue ":: SSH工具推荐Git-Bash 2.20; GCP_SSH(浏览器)字体Courier New 二维码显示正常!"
     echo_Yellow  ":: 命令${RedBG} bash <(curl -L -s https://git.io/v2ray.ss) setup ${Font}设置修改端口密码和UUID"
}

# 设置 v2ray 端口和UUID
set_v2ray_ss(){
    setport
    conf_shadowsocks
    conf_v2ray
}

clear
# 首次运行脚本，设置 端口和UUID
if [ ! -e 'base64_v2ray_vmess.json' ]; then

    # 简化判断系统 debian/centos 族群
    if [ -e '/etc/redhat-release' ]; then
        yum update -y && yum install -y  qrencode wget vim
    else
        apt update && apt install -y  qrencode
    fi

    set_v2ray_ss
fi

# 命令 bash v2ray_ss_conf.sh setup 设置 端口和UUID
if [[ $# > 0 ]]; then
    key="$1"
    case $key in
        setup)
        set_v2ray_ss
        ;;
    esac
fi

echo_SkyBlue  ":: Shadowsocks 和 V2Ray 简易配置: 生成和显示二维码  By 蘭雅sRGB "
echo_Yellow   ":: 一键命令 ${RedBG} bash <(curl -L -s https://git.io/v2ray.ss) "

# 输出ss和v2ray配置和二维码
conf_QRcode 2>&1 | tee ${cur_dir}/v2ray_ss.log


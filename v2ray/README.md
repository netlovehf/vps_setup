- [蘭雅sRGB![](https://raw.githubusercontent.com/hongwenjun/vps_setup/master/img/youtube.png)频道](https://www.youtube.com/channel/UCupRwki_4n87nrwP0GIBUXA/videos) &nbsp;&nbsp;&nbsp;可以观看相关脚本工具的演示视频!

### V2Ray官方提供了一个在 Linux 服务端 自动化安装脚本。
```
###  V2Ray官方一键脚本
bash <(curl -L -s https://install.direct/go.sh)
```

- V2RAY 基于 NGINX 的 VMESS+WS+TLS+Website 手工配置原理
- 短网址: https://git.io/v2ray.nginx

### 显示官方服务端默认配置(TCP协议vmess)
```
cat /etc/v2ray/config.json
```

### V2Ray和Shadowsocks配置显示二维码  短网址: https://git.io/v2ray.ss
![](https://raw.githubusercontent.com/hongwenjun/vps_setup/master/v2ray/v2ray.ss.png)

### v2ray服务端走kcp配置示例 /etc/v2ray/config.json
```
{
  "inbounds": [
    {
      "port": 8000,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "52055352-34e8-453c-b6f6-22eac630b6e1",
            "alterId": 16
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

```
### 修改服务端配置换成UDP协议kcp，先复制上面v2ray配置

```
vim /etc/v2ray/config.json
# Esc键 :set paste  回车 ggdG i shift+Insert Esc键 :wq
```

### 重启v2ray服务端和显示服务器IP
```
systemctl restart v2ray
curl -4 ip.sb
```

### 方法1: 客户端 vmess协议导入，再修改成实际服务器IP
```
vmess://ew0KICAidiI6ICIyIiwNCiAgInBzIjogIlYyUmF5IiwNCiAgImFkZCI6ICIxODguMTg4LjE4OC4xODgiLA0KICAicG9ydCI6ICI4MDAwIiwNCiAgImlkIjogIjUyMDU1MzUyLTM0ZTgtNDUzYy1iNmY2LTIyZWFjNjMwYjZlMSIsDQogICJhaWQiOiAiMTYiLA0KICAibmV0IjogImtjcCIsDQogICJ0eXBlIjogInNydHAiLA0KICAiaG9zdCI6ICIiLA0KICAicGF0aCI6ICIiLA0KICAidGxzIjogIiINCn0=
```
### 方法2: 添加[vmess]服务器-->导入配置文件-->导入服务端配置-->再修改成实际服务器IP
- 导入有个Bug，伪装类型不会识别，使用上面的mKcp配置，伪装类型srtp要按实际设置
![](https://raw.githubusercontent.com/hongwenjun/vps_setup/master/v2ray/v2ray_set.gif)

### 下载v2ray for Windows 客户端地址如果被墙，可以先用vps下载
- 借用vps中转，开临时网页服务器 访问 http://1.2.3.4:8000  (1.2.3.4实际vps的ip)
```
wget https://github.com/2dust/v2rayN/releases/download/2.22/v2rayN-Core.zip
python -m SimpleHTTPServer 8000
```

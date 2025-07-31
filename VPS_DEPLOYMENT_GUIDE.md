# VPS服务器标准化部署方案

## 📋 **概述**

本文档提供标准化的VPS服务器部署方案，适用于未来新增服务器的部署和现有配置的扩展。

### 🎯 **部署目标**
- **高安全性**: SSH密钥认证、防火墙、系统加固
- **高性能**: BBR算法、网络优化、QoS配置  
- **高稳定性**: Reality + Hysteria2双协议
- **易管理**: 标准化配置、统一管理接口

---

## 🇺🇸 **美国服务器部署方案**

### 📊 **服务器规格建议**
- **用途**: AI应用专用 (OpenAI, Claude, etc.)
- **线路**: 优质CN2 GIA或住宅IP
- **配置**: 1GB+ RAM, 20GB+ SSD
- **系统**: Debian 11/12 或 Ubuntu 20.04/22.04

### 🔧 **部署步骤**

#### **1. 系统初始化**
```bash
# 更新系统
apt update && apt upgrade -y

# 安装必要工具
apt install -y curl wget nginx ufw fail2ban unzip whois

# 配置时区
timedatectl set-timezone Asia/Shanghai
```

#### **2. SSH安全配置**
```bash
# 生成SSH密钥对（客户端执行）
ssh-keygen -t rsa -b 4096 -C "vps-management"

# 上传公钥到服务器
ssh-copy-id -p [PORT] root@[SERVER_IP]

# 配置SSH服务
vi /etc/ssh/sshd_config
# 修改配置：
# PermitRootLogin yes
# PasswordAuthentication no
# PubkeyAuthentication yes
# Port [自定义端口]

# 重启SSH服务
systemctl restart sshd
```

#### **3. 防火墙配置**
```bash
# UFW基础配置
ufw default deny incoming
ufw default allow outgoing

# 开放必要端口
ufw allow [SSH_PORT]/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 443/udp

# 启用防火墙
ufw enable
```

#### **4. Reality协议部署**
```bash
# 安装Xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 生成配置参数
REALITY_UUID=$(xray uuid)
REALITY_KEYS=$(xray x25519)
REALITY_PRIVATE_KEY=$(echo $REALITY_KEYS | awk '{print $3}')
REALITY_PUBLIC_KEY=$(echo $REALITY_KEYS | awk '{print $6}')
REALITY_SHORT_ID=$(openssl rand -hex 8)

# 创建Xray配置
cat > /usr/local/etc/xray/config.json << 'XRAY_EOF'
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "REALITY_UUID_PLACEHOLDER",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "www.apple.com:443",
          "serverNames": ["www.apple.com", "support.apple.com"],
          "privateKey": "REALITY_PRIVATE_KEY_PLACEHOLDER",
          "shortIds": ["REALITY_SHORT_ID_PLACEHOLDER"]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
XRAY_EOF

# 替换配置参数
sed -i "s/REALITY_UUID_PLACEHOLDER/$REALITY_UUID/g" /usr/local/etc/xray/config.json
sed -i "s/REALITY_PRIVATE_KEY_PLACEHOLDER/$REALITY_PRIVATE_KEY/g" /usr/local/etc/xray/config.json
sed -i "s/REALITY_SHORT_ID_PLACEHOLDER/$REALITY_SHORT_ID/g" /usr/local/etc/xray/config.json

# 启动服务
systemctl enable xray
systemctl start xray
```

#### **5. Hysteria2协议部署**
```bash
# 安装Hysteria2
wget -O hysteria.tar.gz https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64.tar.gz
tar -xzf hysteria.tar.gz
mv hysteria /usr/local/bin/
chmod +x /usr/local/bin/hysteria

# 生成自签名证书
openssl req -x509 -newkey rsa:4096 -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -days 365 -nodes -subj "/CN=www.apple.com"

# 生成配置参数
HYSTERIA2_PASSWORD="US$(date +%Y)_$(openssl rand -hex 16)"
HYSTERIA2_OBFS_PASSWORD="obfs_$(openssl rand -hex 12)"

# 创建Hysteria2配置
mkdir -p /etc/hysteria
cat > /etc/hysteria/config.yaml << 'HYSTERIA_EOF'
listen: :443

tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: HYSTERIA2_PASSWORD_PLACEHOLDER

obfs:
  type: salamander
  salamander:
    password: HYSTERIA2_OBFS_PASSWORD_PLACEHOLDER

quic:
  initStreamReceiveWindow: 16777216
  maxStreamReceiveWindow: 16777216
  initConnReceiveWindow: 33554432
  maxConnReceiveWindow: 33554432

bandwidth:
  up: 500 mbps
  down: 1000 mbps
HYSTERIA_EOF

# 替换配置参数
sed -i "s/HYSTERIA2_PASSWORD_PLACEHOLDER/$HYSTERIA2_PASSWORD/g" /etc/hysteria/config.yaml
sed -i "s/HYSTERIA2_OBFS_PASSWORD_PLACEHOLDER/$HYSTERIA2_OBFS_PASSWORD/g" /etc/hysteria/config.yaml

# 创建systemd服务
cat > /etc/systemd/system/hysteria-server.service << 'SERVICE_EOF'
[Unit]
Description=Hysteria Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# 启动服务
systemctl daemon-reload
systemctl enable hysteria-server
systemctl start hysteria-server
```

#### **6. 网络优化**
```bash
# 启用BBR算法
echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf

# 网络参数优化
cat >> /etc/sysctl.conf << 'SYSCTL_EOF'
# 网络优化
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 65536 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_slow_start_after_idle = 0

# 安全加固
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5
SYSCTL_EOF

# 应用配置
sysctl -p
```

#### **7. 伪装网站部署**
```bash
# 配置Nginx伪装
cat > /etc/nginx/sites-available/default << 'NGINX_EOF'
server {
    listen 80 default_server;
    server_name _;
    
    location / {
        return 301 https://$host$request_uri;
    }
}
NGINX_EOF

# 启动Nginx
systemctl enable nginx
systemctl start nginx
```

---

## 🇭🇰 **香港服务器部署方案**

### 📊 **服务器规格建议**
- **用途**: 流媒体 + Binance + 通用代理
- **线路**: CMI/CN2优化线路
- **配置**: 1GB+ RAM, 20GB+ SSD
- **系统**: Debian 11/12 或 Ubuntu 20.04/22.04

### 🔧 **部署步骤**

香港服务器部署步骤与美国服务器基本相同，主要差异：

#### **配置差异点**

1. **Reality配置差异**:
```bash
# 香港服务器使用Binance伪装
"dest": "www.binance.com:443",
"serverNames": ["www.binance.com", "accounts.binance.com"]
```

2. **Hysteria2端口差异**:
```bash
# 香港服务器使用8443端口避免冲突
listen: :8443
```

3. **网络优化差异**:
```bash
# CMI线路特殊优化
echo 'net.ipv4.tcp_congestion_control=bbr_plus' >> /etc/sysctl.conf
```

4. **防火墙配置差异**:
```bash
# 香港服务器开放8443端口
ufw allow 8443/udp
```

---

## 📝 **配置信息记录模板**

### 美国服务器配置记录
```
=== 美国服务器配置信息 ===
服务器IP: [SERVER_IP]
SSH端口: [SSH_PORT]
用途: AI应用专用

Reality配置:
- 协议: VLESS + Reality
- 端口: 443/TCP
- UUID: [REALITY_UUID]
- Flow: xtls-rprx-vision
- Public Key: [REALITY_PUBLIC_KEY]
- Short ID: [REALITY_SHORT_ID]
- 伪装站点: www.apple.com

Hysteria2配置:
- 协议: Hysteria2
- 端口: 443/UDP
- 密码: [HYSTERIA2_PASSWORD]
- 混淆类型: salamander
- 混淆密码: [HYSTERIA2_OBFS_PASSWORD]
- 伪装站点: www.apple.com
```

### 香港服务器配置记录
```
=== 香港服务器配置信息 ===
服务器IP: [SERVER_IP]
SSH端口: [SSH_PORT]
用途: 流媒体 + Binance + 通用代理

Reality配置:
- 协议: VLESS + Reality
- 端口: 443/TCP
- UUID: [REALITY_UUID]
- Flow: xtls-rprx-vision
- Public Key: [REALITY_PUBLIC_KEY]
- Short ID: [REALITY_SHORT_ID]
- 伪装站点: www.binance.com

Hysteria2配置:
- 协议: Hysteria2
- 端口: 8443/UDP
- 密码: [HYSTERIA2_PASSWORD]
- 混淆类型: salamander
- 混淆密码: [HYSTERIA2_OBFS_PASSWORD]
- 伪装站点: www.binance.com
```

---

## 🔄 **添加到Clash配置**

### 步骤1: 更新proxies部分
```yaml
proxies:
  # 新增美国服务器
  - name: "US-NewServer-Reality"
    type: vless
    server: [SERVER_IP]
    port: 443
    uuid: [REALITY_UUID]
    flow: xtls-rprx-vision
    tls: true
    network: tcp
    reality-opts:
      public-key: [REALITY_PUBLIC_KEY]
      short-id: [REALITY_SHORT_ID]
    client-fingerprint: chrome
    servername: www.apple.com

  - name: "US-NewServer-Hysteria2"
    type: hysteria2
    server: [SERVER_IP]
    port: 443
    password: [HYSTERIA2_PASSWORD]
    obfs: salamander
    obfs-password: [HYSTERIA2_OBFS_PASSWORD]
    sni: www.apple.com
    skip-cert-verify: true
    up: 300
    down: 500
```

### 步骤2: 更新proxy-groups部分
```yaml
proxy-groups:
  # AI服务专用组 - 添加新的美国节点
  - name: "AI-Services"
    type: select
    proxies:
      - "US-NewServer-Hysteria2"  # 新增
      - "US-NewServer-Reality"    # 新增
      - "US-Seattle-Hysteria2"
      - "US-Seattle-Reality"

  # 智能选择组 - 添加新节点
  - name: "Auto-Select"
    type: url-test
    proxies:
      - "HK-CMI-Hysteria2"
      - "US-NewServer-Hysteria2"  # 新增
      - "HK-CMI-Reality"
      - "US-NewServer-Reality"    # 新增
      - "US-Seattle-Hysteria2"
      - "US-Seattle-Reality"
    url: "http://www.gstatic.com/generate_204"
    interval: 120
    timeout: 3000
```

### 步骤3: 更新配置并推送
```bash
# 编辑配置文件
vi GitHub_Clash_Config.yaml

# 推送到GitHub
./update_clash_config.sh "Add new server: [SERVER_LOCATION]"

# 等待CDN更新 (1-2分钟)
```

---

## ✅ **部署验证清单**

### 服务器基础验证
- [ ] SSH密钥登录正常
- [ ] 防火墙配置正确
- [ ] 系统时间同步
- [ ] BBR算法启用

### 代理服务验证
- [ ] Xray服务运行正常 (`systemctl status xray`)
- [ ] Hysteria2服务运行正常 (`systemctl status hysteria-server`)
- [ ] 端口监听正确 (`ss -tlnp | grep 443`)
- [ ] 日志无错误 (`journalctl -u xray -n 20`)

### 网络连通验证
- [ ] 本地端口测试: `nc -zv [SERVER_IP] 443`
- [ ] 服务器外网访问: `curl -I https://www.google.com`
- [ ] AI服务访问: `curl -I https://api.openai.com`

### Clash客户端验证
- [ ] 配置导入无错误
- [ ] 节点延迟显示正常
- [ ] 外网访问正常
- [ ] 智能分流正确

---

## �� **维护和监控**

### 定期维护任务
- 每月更新系统: `apt update && apt upgrade`
- 检查服务状态: `systemctl status xray hysteria-server`
- 查看资源使用: `htop`, `df -h`
- 检查日志错误: `journalctl --since "1 week ago" | grep -i error`

### 性能监控
- CPU使用率: `top`
- 内存使用: `free -h`
- 网络流量: `iftop`
- 磁盘IO: `iotop`

### 安全检查
- SSH登录日志: `tail -f /var/log/auth.log`
- 防火墙状态: `ufw status verbose`
- 异常连接: `netstat -tulpn | grep ESTABLISHED`

---

## 📞 **故障排除**

### 常见问题
1. **连接超时**: 检查防火墙和端口配置
2. **认证失败**: 验证UUID和密钥配置
3. **速度慢**: 检查BBR算法和网络优化
4. **频繁断线**: 检查服务器资源和网络稳定性

### 紧急恢复
```bash
# 重启所有服务
systemctl restart xray hysteria-server nginx

# 重载网络配置
sysctl -p

# 重启防火墙
ufw --force reset
# 重新配置防火墙规则...
```

---

## 📚 **相关文档**
- Xray官方文档: https://xtls.github.io/
- Hysteria2文档: https://v2.hysteria.network/
- Clash Meta文档: https://clash-meta.gitbook.io/


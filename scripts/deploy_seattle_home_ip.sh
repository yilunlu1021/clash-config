#!/bin/bash
# ========================================
# 西雅图原生家庭IP VPS 专属部署脚本
# 特色：安全+低延迟+强伪装
# ========================================

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 服务器信息
SERVER_IP="104.247.120.132"
SSH_PORT="30479"
SERVER_NAME="Seattle-Home-AI"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# ========================================
# 1. 系统环境准备和优化
# ========================================
prepare_system() {
    log "🔧 系统环境准备和优化..."
    
    # 更新系统包
    apt update && apt upgrade -y
    
    # 安装必要工具
    apt install -y curl wget unzip systemd-resolved ufw fail2ban \
                   htop iftop iotop tmux vim git jq socat \
                   build-essential software-properties-common
    
    # 优化内核参数（针对1GB内存）
    cat > /etc/sysctl.d/99-seattle-optimize.conf << 'SYSCTL'
# 网络优化
net.core.default_qdisc = fq_codel
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1

# 内存优化（1GB系统）
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# 连接优化
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 8192
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 10

# 文件句柄优化
fs.file-max = 65535
SYSCTL
    
    sysctl -p /etc/sysctl.d/99-seattle-optimize.conf
    
    # 设置时区
    timedatectl set-timezone America/Los_Angeles
    
    log "✅ 系统环境准备完成"
}

# ========================================
# 2. 安全加固（原生IP保护）
# ========================================
security_hardening() {
    log "🛡️ 原生家庭IP安全加固..."
    
    # 配置UFW防火墙
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    # 允许SSH
    ufw allow $SSH_PORT/tcp comment 'SSH Management'
    
    # 允许Web服务（用于伪装）
    ufw allow 80/tcp comment 'HTTP Decoy'
    ufw allow 443/tcp comment 'HTTPS Service'
    ufw allow 443/udp comment 'QUIC/HTTP3'
    
    # 启用防火墙
    ufw --force enable
    
    # 配置fail2ban
    cat > /etc/fail2ban/jail.local << 'F2B'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ssh,30479
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3
F2B
    
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    # SSH安全加固
    sed -i 's/#PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
    
    log "✅ 安全加固完成"
}

# ========================================
# 3. 家庭网络伪装服务
# ========================================
setup_home_decoy() {
    log "🏠 部署家庭网络伪装服务..."
    
    # 安装Nginx（伪装家庭路由器）
    apt install -y nginx
    
    # 创建伪装的家庭路由器界面
    cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>NETGEAR Router Login</title>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }
        .container { max-width: 400px; margin: 100px auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .logo { text-align: center; margin-bottom: 30px; color: #0066cc; font-size: 24px; font-weight: bold; }
        .form-group { margin-bottom: 20px; }
        label { display: block; margin-bottom: 5px; font-weight: bold; }
        input { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box; }
        .btn { background: #0066cc; color: white; padding: 12px; border: none; border-radius: 4px; cursor: pointer; width: 100%; font-size: 16px; }
        .btn:hover { background: #0052a3; }
        .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">NETGEAR</div>
        <h2 style="text-align: center; margin-bottom: 30px;">Router Login</h2>
        <form>
            <div class="form-group">
                <label for="username">Username:</label>
                <input type="text" id="username" name="username" value="admin" readonly>
            </div>
            <div class="form-group">
                <label for="password">Password:</label>
                <input type="password" id="password" name="password" placeholder="Enter password">
            </div>
            <button type="button" class="btn" onclick="showError()">Log In</button>
        </form>
        <div class="footer">
            NETGEAR R7000 Nighthawk Router<br>
            Firmware Version: V1.0.11.123_10.2.123
        </div>
    </div>
    <script>
        function showError() {
            alert('Authentication failed. Please try again.');
            document.getElementById('password').value = '';
        }
    </script>
</body>
</html>
HTML
    
    # 配置Nginx
    cat > /etc/nginx/sites-available/default << 'NGINX'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    # 模拟家庭路由器响应
    add_header Server "NETGEAR R7000" always;
    
    location / {
        root /var/www/html;
        index index.html;
    }
    
    # 重定向HTTPS
    location /admin {
        return 301 https://$server_name$request_uri;
    }
}
NGINX
    
    systemctl restart nginx
    systemctl enable nginx
    
    log "✅ 家庭网络伪装服务部署完成"
}

# ========================================
# 4. Reality协议配置
# ========================================
setup_reality() {
    log "🔐 配置VLESS Reality协议..."
    
    # 下载最新Xray
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    
    # 生成Reality密钥对
    REALITY_KEYS=$(xray x25519)
    PRIVATE_KEY=$(echo "$REALITY_KEYS" | grep "Private key" | awk '{print $3}')
    PUBLIC_KEY=$(echo "$REALITY_KEYS" | grep "Public key" | awk '{print $3}')
    
    # 生成UUID
    UUID=$(xray uuid)
    
    # 生成短ID
    SHORT_ID=$(openssl rand -hex 8)
    
    # Reality配置（伪装苹果官网）
    cat > /usr/local/etc/xray/config.json << REALITY
{
    "log": {
        "loglevel": "warning",
        "access": "/var/log/xray/access.log",
        "error": "/var/log/xray/error.log"
    },
    "inbounds": [
        {
            "listen": "0.0.0.0",
            "port": 443,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID",
                        "flow": "xtls-rprx-vision",
                        "email": "seattle@home.ai"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": "www.apple.com:443",
                    "xver": 0,
                    "serverNames": [
                        "www.apple.com",
                        "support.apple.com"
                    ],
                    "privateKey": "$PRIVATE_KEY",
                    "shortIds": ["$SHORT_ID"]
                }
            },
            "sniffing": {
                "enabled": true,
                "destOverride": ["http", "tls"]
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {},
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "settings": {},
            "tag": "blocked"
        }
    ],
    "routing": {
        "rules": [
            {
                "type": "field",
                "ip": ["geoip:private"],
                "outboundTag": "blocked"
            }
        ]
    }
}
REALITY
    
    # 创建日志目录
    mkdir -p /var/log/xray
    chown nobody:nogroup /var/log/xray
    
    # 重启Xray
    systemctl restart xray
    systemctl enable xray
    
    # 保存配置信息
    cat > /root/seattle_reality_config.txt << CONFIG
=== 西雅图原生IP Reality配置 ===
服务器: $SERVER_IP:443
协议: VLESS + Reality
UUID: $UUID
Flow: xtls-rprx-vision
Public Key: $PUBLIC_KEY
Short ID: $SHORT_ID
伪装站点: www.apple.com
服务器名: www.apple.com, support.apple.com
CONFIG
    
    log "✅ Reality协议配置完成"
    echo "UUID: $UUID"
    echo "Public Key: $PUBLIC_KEY"
    echo "Short ID: $SHORT_ID"
}

# ========================================
# 5. Hysteria2协议配置
# ========================================
setup_hysteria2() {
    log "🚀 配置Hysteria2协议..."
    
    # 下载Hysteria2
    wget -O /usr/local/bin/hysteria https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64
    chmod +x /usr/local/bin/hysteria
    
    # 生成自签名证书
    openssl req -x509 -nodes -newkey rsa:4096 -keyout /etc/hysteria/server.key \
            -out /etc/hysteria/server.crt -days 3650 -subj "/CN=seattle.home.local"
    
    # 生成密码
    HYSTERIA_PASSWORD="Seattle2025_$(openssl rand -hex 8)"
    
    # Hysteria2配置
    mkdir -p /etc/hysteria
    cat > /etc/hysteria/config.yaml << HY2
listen: :443
 
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

obfs:
  type: salamander
  salamander:
    password: "home_router_$(openssl rand -hex 6)"

auth:
  type: password
  password: "$HYSTERIA_PASSWORD"

masquerade:
  type: proxy
  proxy:
    url: https://www.apple.com
    rewriteHost: true

bandwidth:
  up: 100 mbps
  down: 100 mbps

ignoreClientBandwidth: false
disableUDP: false
udpIdleTimeout: 60s
HY2
    
    # 创建systemd服务
    cat > /etc/systemd/system/hysteria2.service << SERVICE
[Unit]
Description=Hysteria2 Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml
Restart=always
RestartSec=3
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
SERVICE
    
    systemctl daemon-reload
    systemctl enable hysteria2
    systemctl start hysteria2
    
    # 保存配置信息
    cat > /root/seattle_hysteria2_config.txt << CONFIG
=== 西雅图原生IP Hysteria2配置 ===
服务器: $SERVER_IP:443 (UDP)
协议: Hysteria2
密码: $HYSTERIA_PASSWORD
混淆: salamander
伪装: www.apple.com
CONFIG
    
    log "✅ Hysteria2协议配置完成"
    echo "Hysteria2密码: $HYSTERIA_PASSWORD"
}

# ========================================
# 6. 性能测试和监控
# ========================================
setup_monitoring() {
    log "📊 配置性能监控..."
    
    # 创建监控脚本
    cat > /root/seattle_monitor.sh << 'MONITOR'
#!/bin/bash
echo "=== 西雅图VPS实时状态 ==="
echo "时间: $(date)"
echo "负载: $(uptime | awk -F'load average:' '{print $2}')"
echo "内存: $(free -h | grep Mem | awk '{print "已用:"$3" 可用:"$7}')"
echo "磁盘: $(df -h / | tail -1 | awk '{print "已用:"$3"/"$2" ("$5")"}')"
echo ""
echo "=== 网络连接状态 ==="
echo "活跃连接: $(ss -tuln | wc -l)"
echo "Reality (443/TCP): $(ss -tuln | grep :443 | grep tcp | wc -l) 个"
echo "Hysteria2 (443/UDP): $(ss -tuln | grep :443 | grep udp | wc -l) 个"
echo ""
echo "=== 服务状态 ==="
systemctl is-active xray || echo "❌ Xray未运行"
systemctl is-active hysteria2 || echo "❌ Hysteria2未运行"
systemctl is-active nginx || echo "❌ Nginx未运行"
echo ""
echo "=== 最近连接日志 ==="
tail -n 5 /var/log/xray/access.log 2>/dev/null || echo "暂无Reality连接"
MONITOR
    
    chmod +x /root/seattle_monitor.sh
    
    log "✅ 性能监控配置完成"
}

# ========================================
# 主部署流程
# ========================================
main() {
    clear
    echo -e "${CYAN}"
    cat << 'BANNER'
    ╔═══════════════════════════════════════════╗
    ║        西雅图原生家庭IP VPS部署           ║
    ║     高安全 + 低延迟 + 强伪装             ║
    ╚═══════════════════════════════════════════╝
BANNER
    echo -e "${NC}"
    
    log "🚀 开始西雅图原生家庭IP VPS部署..."
    
    prepare_system
    security_hardening
    setup_home_decoy
    setup_reality
    setup_hysteria2
    setup_monitoring
    
    log "🎉 部署完成！"
    
    echo -e "\n${GREEN}=== 部署完成总结 ===${NC}"
    echo "🌍 服务器: 西雅图原生家庭IP"
    echo "🔐 Reality: 端口443 (伪装苹果官网)"
    echo "🚀 Hysteria2: 端口443 UDP (高速协议)"
    echo "🏠 伪装: NETGEAR家庭路由器界面"
    echo "📊 监控: /root/seattle_monitor.sh"
    echo ""
    echo "📋 配置文件位置:"
    echo "• Reality: /root/seattle_reality_config.txt"
    echo "• Hysteria2: /root/seattle_hysteria2_config.txt"
    echo ""
    echo "🎯 特色功能:"
    echo "• ✅ 原生家庭IP最大化利用"
    echo "• ✅ 双协议共享443端口"
    echo "• ✅ 苹果官网高质量伪装"
    echo "• ✅ 家庭路由器界面欺骗"
    echo "• ✅ BBR+优化针对1GB内存"
    echo "• ✅ 全面安全加固"
}

# 执行主流程
main "$@"

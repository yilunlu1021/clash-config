# 🔍 VPS Fleet 实时监测方案

## 📋 **监测目标**
- **美国服务器**: 104.247.120.132 (Seattle)
- **香港服务器**: 38.22.93.165 (CMI)
- **关键服务**: Reality(443/TCP), Hysteria2(443/UDP), AI解锁状态

---

## 🚀 **方案A: UptimeRobot (推荐) - 免费版**

### ✅ **优势**
- 免费50个监测点
- 5分钟检测间隔
- 邮件+短信+Webhook通知
- 全球多点监测
- 简单易用的Dashboard

### 📱 **设置步骤**
1. 注册 [UptimeRobot](https://uptimerobot.com)
2. 添加监测项目：

#### **HTTP监测 (服务可用性)**
```
Monitor Type: HTTP(s)
URL: https://104.247.120.132 (美国)
Monitor Name: US-Seattle-Server
Interval: 5 minutes
```

```
Monitor Type: HTTP(s) 
URL: https://38.22.93.165 (香港)
Monitor Name: HK-CMI-Server
Interval: 5 minutes
```

#### **Port监测 (代理服务)**
```
Monitor Type: Port
IP/Domain: 104.247.120.132
Port: 443
Monitor Name: US-Reality-Port
```

```
Monitor Type: Port
IP/Domain: 38.22.93.165  
Port: 443
Monitor Name: HK-Reality-Port
```

### 📲 **通知设置**
- Email: 立即通知
- 手机短信: 关键故障
- Webhook: 自动化处理

---

## 🛠️ **方案B: 自建监测脚本 (进阶)**

### **本地监测脚本** (`monitor_services.sh`)
```bash
#!/bin/bash
# VPS Fleet 健康监测脚本
# 每5分钟运行一次: */5 * * * * /path/to/monitor_services.sh

SERVERS=(
    "US:104.247.120.132:30479"
    "HK:38.22.93.165:34168" 
)

TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN"
TELEGRAM_CHAT_ID="YOUR_CHAT_ID"

check_server() {
    local name=$1
    local ip=$2
    local port=$3
    
    # 基础连通性
    if ! ping -c 2 -W 3 $ip >/dev/null 2>&1; then
        send_alert "❌ $name 服务器无法ping通"
        return 1
    fi
    
    # SSH连通性  
    if ! nc -z $ip $port >/dev/null 2>&1; then
        send_alert "❌ $name SSH端口 $port 无法连接"
        return 1
    fi
    
    # 代理端口检查
    if ! nc -z $ip 443 >/dev/null 2>&1; then
        send_alert "❌ $name Reality端口 443 不可达"
        return 1
    fi
    
    echo "✅ $name 服务器正常"
    return 0
}

send_alert() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Telegram通知
    curl -s "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=$TELEGRAM_CHAT_ID" \
        -d "text=🚨 VPS警告 [$timestamp]%0A$message" >/dev/null
    
    # 本地日志
    echo "[$timestamp] $message" >> /var/log/vps_monitor.log
}

# 主监测循环
for server in "${SERVERS[@]}"; do
    IFS=':' read -r name ip port <<< "$server"
    check_server "$name" "$ip" "$port"
done
```

---

## 📊 **方案C: Prometheus + Grafana (专业级)**

### **特点**
- 详细性能指标
- 自定义Dashboard  
- 历史数据分析
- 高级告警规则

### **快速部署**
```bash
# Docker方式部署
docker-compose up -d prometheus grafana
# 配置监测目标和告警规则
```

---

## 🎯 **推荐实施顺序**

### **立即实施 (5分钟)**
1. 注册UptimeRobot免费账户
2. 添加两台服务器的HTTP + Port监测
3. 配置邮件通知

### **进阶配置 (30分钟)**  
1. 设置Telegram Bot通知
2. 部署本地监测脚本
3. 配置定时任务

### **专业化 (2小时)**
1. 部署Prometheus监测
2. 配置Grafana仪表板  
3. 设置复杂告警规则

---

## 📱 **移动端监控**

### **UptimeRobot App**
- iOS/Android原生应用
- 推送通知
- 一键查看所有服务状态

### **自定义监控页面**
- 简单HTML状态页
- 可嵌入网站/书签
- 实时显示服务状态

---

## 🚨 **告警策略建议**

### **立即告警**
- 服务器完全不可达 (>2分钟)
- 关键端口无响应 (443)
- AI API访问失败

### **延迟告警** 
- 高延迟 (>500ms持续10分钟)
- 间歇性连接问题
- 非关键服务异常

### **每日报告**
- 24小时可用性摘要  
- 性能趋势分析
- 异常事件汇总

---

## 💡 **额外功能**

### **自动修复**
- 服务异常时自动重启
- 防火墙规则自动检查
- 配置文件自动备份

### **智能切换**
- 主节点故障时自动推送备用配置
- Clash订阅自动更新
- 负载均衡调整

---

**您希望我立即帮您设置哪个方案？推荐从UptimeRobot开始，然后逐步升级到高级监测。**
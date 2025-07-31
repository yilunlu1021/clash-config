#!/bin/bash

# UptimeRobot 快速设置脚本
# 用于自动创建监测项目

echo "🔍 UptimeRobot 监测设置向导"
echo "=========================="
echo

# 检查是否有API Key
if [ -z "$UPTIMEROBOT_API_KEY" ]; then
    echo "📋 首先需要获取UptimeRobot API Key:"
    echo "1. 访问 https://uptimerobot.com 注册账户"
    echo "2. 进入 My Settings → API Settings"
    echo "3. 创建 Main API Key"
    echo "4. 设置环境变量: export UPTIMEROBOT_API_KEY='your_key'"
    echo
    echo "💡 或者手动添加监测项目:"
    echo "   - Monitor Type: HTTP(s)"
    echo "   - URL: https://104.247.120.132 (美国)"
    echo "   - Interval: 5 minutes"
    echo
    echo "   - Monitor Type: Port"  
    echo "   - IP: 104.247.120.132, Port: 443"
    echo "   - Name: US-Reality-Service"
    exit 1
fi

API_KEY="$UPTIMEROBOT_API_KEY"
BASE_URL="https://api.uptimerobot.com/v2"

# 创建监测项目的函数
create_monitor() {
    local type="$1"
    local url="$2" 
    local name="$3"
    local port="$4"
    
    if [ "$type" = "http" ]; then
        response=$(curl -s -X POST "$BASE_URL/newMonitor" \
            -d "api_key=$API_KEY" \
            -d "format=json" \
            -d "type=1" \
            -d "url=$url" \
            -d "friendly_name=$name" \
            -d "interval=300")
    elif [ "$type" = "port" ]; then
        response=$(curl -s -X POST "$BASE_URL/newMonitor" \
            -d "api_key=$API_KEY" \
            -d "format=json" \
            -d "type=4" \
            -d "url=$url" \
            -d "sub_type=1" \
            -d "port=$port" \
            -d "friendly_name=$name" \
            -d "interval=300")
    fi
    
    echo "Creating $name: $response"
}

echo "🚀 开始创建监测项目..."

# 美国服务器监测
echo "📍 添加美国服务器监测..."
create_monitor "http" "https://104.247.120.132" "US-Seattle-Server"
create_monitor "port" "104.247.120.132" "US-Reality-Service" "443"

# 香港服务器监测  
echo "📍 添加香港服务器监测..."
create_monitor "http" "https://38.22.93.165" "HK-CMI-Server"
create_monitor "port" "38.22.93.165" "HK-Reality-Service" "443"

echo
echo "✅ 监测项目创建完成！"
echo "🌐 访问 https://stats.uptimerobot.com 查看状态页面"
echo "📱 下载 UptimeRobot 移动应用获取推送通知"
echo
echo "📋 下一步: 配置通知设置"
echo "   1. 登录 UptimeRobot Dashboard"
echo "   2. 进入 My Settings → Alert Contacts" 
echo "   3. 添加邮箱、手机号或Webhook"
echo "   4. 为每个监测项目启用相应通知"
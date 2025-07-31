#!/bin/bash

# 简单的VPS实时监测脚本
# 运行方式: ./simple_monitor.sh
# 后台运行: nohup ./simple_monitor.sh &

# 配置部分 (请修改为您的信息)
TELEGRAM_BOT_TOKEN=""  # 在这里填入您的Telegram Bot Token
TELEGRAM_CHAT_ID=""    # 在这里填入您的Telegram Chat ID

# 服务器配置
US_SERVER="104.247.120.132"
US_SSH_PORT="30479"
HK_SERVER="38.22.93.165" 
HK_SSH_PORT="34168"

# 监测间隔 (秒)
CHECK_INTERVAL=300  # 5分钟

# 日志文件
LOG_FILE="/tmp/vps_monitor.log"

# 发送Telegram消息
send_telegram() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
            -d "chat_id=$TELEGRAM_CHAT_ID" \
            -d "text=🖥️ VPS监测 [$timestamp]%0A$message" \
            -d "parse_mode=HTML" >/dev/null 2>&1
    fi
    
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# 检查服务器状态
check_server() {
    local name="$1"
    local ip="$2"
    local ssh_port="$3"
    local status="✅"
    local issues=()
    
    # 1. Ping测试
    if ! ping -c 2 -W 3 "$ip" >/dev/null 2>&1; then
        issues+=("Ping失败")
        status="❌"
    fi
    
    # 2. SSH端口测试
    if ! timeout 5 bash -c "echo >/dev/tcp/$ip/$ssh_port" 2>/dev/null; then
        issues+=("SSH端口${ssh_port}不可达")
        status="❌"
    fi
    
    # 3. Reality端口测试 (443/TCP)
    if ! timeout 5 bash -c "echo >/dev/tcp/$ip/443" 2>/dev/null; then
        issues+=("Reality端口443不可达")
        status="❌"
    fi
    
    # 4. 延迟测试
    local latency=$(ping -c 3 -q "$ip" 2>/dev/null | grep 'round-trip' | cut -d'/' -f5 | cut -d'.' -f1)
    if [ -n "$latency" ] && [ "$latency" -gt 500 ]; then
        issues+=("高延迟${latency}ms")
        status="⚠️"
    fi
    
    # 报告结果
    if [ ${#issues[@]} -eq 0 ]; then
        echo "[$name] $status 正常 (延迟: ${latency}ms)"
    else
        local issue_text=$(IFS=', '; echo "${issues[*]}")
        echo "[$name] $status 异常: $issue_text"
        send_telegram "🚨 <b>$name 服务器异常</b>%0A问题: $issue_text"
    fi
}

# 检查AI服务可用性
check_ai_services() {
    echo "🧠 检查AI服务访问..."
    
    # 通过代理测试OpenAI
    local openai_status=$(curl -s -w "%{http_code}" -o /dev/null --max-time 10 \
        --proxy socks5h://127.0.0.1:7890 https://api.openai.com/v1/models 2>/dev/null)
    
    if [ "$openai_status" = "401" ]; then
        echo "[AI] ✅ OpenAI API可访问"
    else
        echo "[AI] ❌ OpenAI API异常 (HTTP: $openai_status)"
        send_telegram "🤖 <b>AI服务异常</b>%0AOpenAI API返回: $openai_status"
    fi
    
    # 检查出口IP
    local exit_ip=$(curl -s --max-time 10 --proxy socks5h://127.0.0.1:7890 ipinfo.io/country 2>/dev/null)
    if [ "$exit_ip" = "US" ]; then
        echo "[AI] ✅ 出口IP: 美国"
    else
        echo "[AI] ⚠️ 出口IP: $exit_ip (非美国)"
        send_telegram "🌍 <b>AI出口IP异常</b>%0A当前: $exit_ip (期望: US)"
    fi
}

# 生成状态报告
generate_status_report() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "================================"
    echo "🔍 VPS Fleet 状态检查 - $timestamp"
    echo "================================"
    
    check_server "美国Seattle" "$US_SERVER" "$US_SSH_PORT"
    check_server "香港CMI" "$HK_SERVER" "$HK_SSH_PORT"
    
    echo "--------------------------------"
    check_ai_services
    echo "================================"
    echo
}

# 主程序
main() {
    # 检查配置
    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
        echo "⚠️ 警告: 未配置Telegram通知"
        echo "请编辑脚本，填入TELEGRAM_BOT_TOKEN和TELEGRAM_CHAT_ID"
        echo
    fi
    
    echo "🚀 VPS Fleet 监测启动..."
    echo "📊 检查间隔: ${CHECK_INTERVAL}秒"
    echo "📝 日志文件: $LOG_FILE"
    echo
    
    # 发送启动通知
    send_telegram "🚀 <b>VPS监测已启动</b>%0A检查间隔: ${CHECK_INTERVAL}秒"
    
    # 主监测循环
    while true; do
        generate_status_report
        sleep "$CHECK_INTERVAL"
    done
}

# 脚本参数处理
case "${1:-run}" in
    "run")
        main
        ;;
    "test")
        echo "🧪 执行一次性检查..."
        generate_status_report
        ;;
    "setup")
        echo "📱 Telegram Bot 设置说明:"
        echo "1. 与 @BotFather 对话创建Bot"
        echo "2. 获取Bot Token"
        echo "3. 与Bot对话，获取Chat ID: https://api.telegram.org/bot<TOKEN>/getUpdates"
        echo "4. 编辑此脚本，填入Token和Chat ID"
        ;;
    *)
        echo "用法: $0 [run|test|setup]"
        echo "  run  - 启动持续监测 (默认)"
        echo "  test - 执行一次检查"
        echo "  setup- 显示Telegram设置说明"
        ;;
esac
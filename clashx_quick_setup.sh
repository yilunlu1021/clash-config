#!/bin/bash

echo "🚀 ClashX 快速设置检查"
echo "====================="

# 1. 检查 ClashX 运行状态
if pgrep -f ClashX >/dev/null; then
    echo "✅ ClashX 正在运行"
else
    echo "❌ ClashX 未运行，启动中..."
    open -a ClashX
    sleep 3
fi

# 2. 检查端口监听
echo ""
echo "检查端口状态："
for port in 7890 8080 8090; do
    if lsof -i :$port 2>/dev/null | grep -q ClashX; then
        echo "✅ ClashX 监听端口 $port"
        WORKING_PORT=$port
        break
    elif lsof -i :$port >/dev/null 2>&1; then
        PROCESS=$(lsof -i :$port | tail -1 | awk '{print $1}')
        echo "⚠️  端口 $port 被 $PROCESS 占用"
    fi
done

if [ -z "$WORKING_PORT" ]; then
    echo "❌ ClashX 未监听任何端口，请检查配置"
    exit 1
fi

# 3. 测试代理连接
echo ""
echo "测试代理连接 (端口 $WORKING_PORT)："
if curl -x http://127.0.0.1:$WORKING_PORT -s --connect-timeout 5 -o /dev/null "http://www.gstatic.com/generate_204"; then
    echo "✅ 代理连接正常"
else
    echo "❌ 代理连接失败"
fi

# 4. 获取出口IP
echo ""
echo "检查出口IP："
IP=$(curl -x http://127.0.0.1:$WORKING_PORT -s --connect-timeout 5 "https://api.ipify.org" 2>/dev/null)
if [ -n "$IP" ]; then
    echo "✅ 当前出口IP: $IP"
    
    # 检查IP位置
    LOCATION=$(curl -s --connect-timeout 3 "https://ipapi.co/$IP/country_name" 2>/dev/null)
    if [ -n "$LOCATION" ]; then
        echo "📍 IP位置: $LOCATION"
        if [ "$LOCATION" = "United States" ]; then
            echo "🎯 完美！使用美国IP，Gemini应该可以访问"
        else
            echo "⚠️  不是美国IP，可能无法访问Gemini"
        fi
    fi
else
    echo "❌ 无法获取出口IP"
fi

# 5. 测试 Gemini 访问
echo ""
echo "测试 Gemini 访问："
GEMINI_TEST=$(curl -x http://127.0.0.1:$WORKING_PORT -s --connect-timeout 10 --max-time 15 -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" "https://gemini.google.com" 2>/dev/null | head -20)

if echo "$GEMINI_TEST" | grep -q "DOCTYPE.*html"; then
    if echo "$GEMINI_TEST" | grep -qi "blocked\|restricted\|unavailable\|not available"; then
        echo "❌ Gemini 访问被阻止"
    else
        echo "✅ Gemini 返回正常网页"
    fi
else
    echo "⚠️  Gemini 响应异常"
fi

echo ""
echo "🔧 ClashX 手动检查清单："
echo "1. 状态栏是否有 ⚔️ ClashX 图标？"
echo "2. 点击图标 → 配置 → 是否有 'AI解锁专用配置'？"
echo "3. 点击图标 → 设置为系统代理 (是否有 ✓)？"
echo "4. 点击图标 → 增强模式 (是否有 ✓)？"
echo "5. 点击图标 → 代理 → AI-Services → 是否选中美国节点？"

echo ""
echo "如果以上都正确但仍无法访问，请查看 ClashX → 日志"
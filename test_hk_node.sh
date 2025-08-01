#!/bin/bash

echo "🇭🇰 测试香港节点Google访问能力"
echo "================================"

PROXY_PORT=7890

echo "请在Mihomo Party中手动切换AI-Services到香港节点，然后按回车继续..."
read -p "已切换到香港节点？(y/n): " switched

if [ "$switched" != "y" ]; then
    echo "请先切换节点再运行测试"
    exit 1
fi

echo ""
echo "开始测试..."

# 检查出口IP
echo "1. 检查当前出口IP："
PROXY_IP=$(curl -x http://127.0.0.1:$PROXY_PORT -s --connect-timeout 10 "https://api.ipify.org" 2>/dev/null)
echo "   出口IP: $PROXY_IP"

# 检查地理位置
if [ -n "$PROXY_IP" ]; then
    echo "2. 检查IP地理位置："
    LOCATION=$(curl -s --connect-timeout 5 "https://ipapi.co/$PROXY_IP/json" 2>/dev/null)
    COUNTRY=$(echo "$LOCATION" | grep -o '"country_name":"[^"]*"' | cut -d'"' -f4)
    CITY=$(echo "$LOCATION" | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
    echo "   位置: $CITY, $COUNTRY"
fi

echo ""

# 测试Google服务
echo "3. 测试Google服务："

# Google首页
GOOGLE_STATUS=$(curl -x http://127.0.0.1:$PROXY_PORT -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "https://www.google.com" 2>/dev/null)
if [ "$GOOGLE_STATUS" = "200" ]; then
    echo "   ✅ Google首页: 可访问"
else
    echo "   ❌ Google首页: 无法访问 ($GOOGLE_STATUS)"
fi

# Gemini
echo "   测试Gemini..."
GEMINI_TEST=$(curl -x http://127.0.0.1:$PROXY_PORT -s --connect-timeout 15 "https://gemini.google.com" 2>/dev/null | head -5)
if echo "$GEMINI_TEST" | grep -q "DOCTYPE\|html"; then
    echo "   ✅ Gemini: 可访问"
    echo "   🎉 成功！现在可以使用Gemini了"
else
    echo "   ❌ Gemini: 仍无法访问"
fi

echo ""
echo "💡 如果香港节点正常，建议："
echo "1. 在配置中将AI-Services默认设为香港节点"
echo "2. 报告美国节点问题给VPS提供商"
echo "3. 考虑更换美国VPS的数据中心"
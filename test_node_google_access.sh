#!/bin/bash

echo "🔍 美国节点 Google 访问能力测试"
echo "=================================="

# 检测代理端口
PROXY_PORT=""
for port in 7890 8080 8090; do
    if lsof -i :$port >/dev/null 2>&1; then
        PROXY_PORT=$port
        echo "✅ 检测到代理端口: $port"
        break
    fi
done

if [ -z "$PROXY_PORT" ]; then
    echo "❌ 未检测到任何代理端口运行"
    echo "请确保 Mihomo Party 或 ClashX 正在运行"
    exit 1
fi

echo ""

# 1. 检查出口IP
echo "1. 检查当前出口IP："
REAL_IP=$(curl -s --connect-timeout 10 "https://api.ipify.org" 2>/dev/null)
PROXY_IP=$(curl -x http://127.0.0.1:$PROXY_PORT -s --connect-timeout 10 "https://api.ipify.org" 2>/dev/null)

echo "   真实IP: $REAL_IP"
echo "   代理IP: $PROXY_IP"

if [ "$REAL_IP" = "$PROXY_IP" ]; then
    echo "   ❌ 代理未生效，IP相同"
    exit 1
else
    echo "   ✅ 代理生效，IP已改变"
fi

echo ""

# 2. 检查IP地理位置
echo "2. 检查代理IP地理位置："
if [ -n "$PROXY_IP" ]; then
    LOCATION=$(curl -s --connect-timeout 5 "https://ipapi.co/$PROXY_IP/json" 2>/dev/null)
    if [ -n "$LOCATION" ]; then
        COUNTRY=$(echo "$LOCATION" | grep -o '"country_name":"[^"]*"' | cut -d'"' -f4)
        REGION=$(echo "$LOCATION" | grep -o '"region":"[^"]*"' | cut -d'"' -f4)
        CITY=$(echo "$LOCATION" | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
        ISP=$(echo "$LOCATION" | grep -o '"org":"[^"]*"' | cut -d'"' -f4)
        
        echo "   国家: $COUNTRY"
        echo "   地区: $REGION"  
        echo "   城市: $CITY"
        echo "   ISP: $ISP"
        
        if [ "$COUNTRY" = "United States" ]; then
            echo "   ✅ IP确实在美国"
        else
            echo "   ⚠️  IP不在美国: $COUNTRY"
        fi
    fi
fi

echo ""

# 3. 测试Google基础服务
echo "3. 测试Google基础服务访问："

# 测试Google主页
echo "   测试 www.google.com:"
GOOGLE_STATUS=$(curl -x http://127.0.0.1:$PROXY_PORT -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "https://www.google.com" 2>/dev/null)
if [ "$GOOGLE_STATUS" = "200" ]; then
    echo "     ✅ Google首页可访问 (HTTP $GOOGLE_STATUS)"
else
    echo "     ❌ Google首页无法访问 (HTTP $GOOGLE_STATUS)"
fi

# 测试Google搜索
echo "   测试 Google搜索:"
SEARCH_STATUS=$(curl -x http://127.0.0.1:$PROXY_PORT -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "https://www.google.com/search?q=test" 2>/dev/null)
if [ "$SEARCH_STATUS" = "200" ]; then
    echo "     ✅ Google搜索可访问 (HTTP $SEARCH_STATUS)"
else
    echo "     ❌ Google搜索无法访问 (HTTP $SEARCH_STATUS)"
fi

echo ""

# 4. 测试Gemini相关服务
echo "4. 测试Gemini相关服务："

# 测试Gemini主页
echo "   测试 gemini.google.com:"
GEMINI_RESPONSE=$(curl -x http://127.0.0.1:$PROXY_PORT -s --connect-timeout 15 --max-time 20 -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36" "https://gemini.google.com" 2>/dev/null)

if echo "$GEMINI_RESPONSE" | grep -q "DOCTYPE.*html"; then
    if echo "$GEMINI_RESPONSE" | grep -qi "blocked\|restricted\|unavailable\|not available\|access denied"; then
        echo "     ❌ Gemini被阻止访问"
        echo "     可能原因: IP被Google封锁"
    elif echo "$GEMINI_RESPONSE" | grep -qi "gemini\|bard\|chat"; then
        echo "     ✅ Gemini可以访问"
    else
        echo "     ⚠️  Gemini响应异常"
    fi
else
    echo "     ❌ Gemini无响应或连接失败"
fi

# 测试AI Studio
echo "   测试 aistudio.google.com:"
AISTUDIO_STATUS=$(curl -x http://127.0.0.1:$PROXY_PORT -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "https://aistudio.google.com" 2>/dev/null)
if [ "$AISTUDIO_STATUS" = "200" ]; then
    echo "     ✅ AI Studio可访问 (HTTP $AISTUDIO_STATUS)"
else
    echo "     ❌ AI Studio无法访问 (HTTP $AISTUDIO_STATUS)"
fi

echo ""

# 5. 检查IP是否被封
echo "5. IP封锁检测："

# 使用多个检测源
echo "   检查Google服务可达性:"
GOOGLE_APIS_STATUS=$(curl -x http://127.0.0.1:$PROXY_PORT -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "https://www.googleapis.com" 2>/dev/null)
if [ "$GOOGLE_APIS_STATUS" = "200" ]; then
    echo "     ✅ Google APIs可访问"
else
    echo "     ❌ Google APIs无法访问 (可能IP被封)"
fi

# 检查YouTube
YOUTUBE_STATUS=$(curl -x http://127.0.0.1:$PROXY_PORT -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "https://www.youtube.com" 2>/dev/null)
if [ "$YOUTUBE_STATUS" = "200" ]; then
    echo "     ✅ YouTube可访问"
else
    echo "     ❌ YouTube无法访问"
fi

echo ""

# 6. 建议
echo "🔧 诊断结果与建议："

if [ "$GOOGLE_STATUS" != "200" ] || [ "$GOOGLE_APIS_STATUS" != "200" ]; then
    echo "❌ 该IP可能被Google封锁，建议："
    echo "   1. 更换其他节点（如香港节点）"
    echo "   2. 联系VPS提供商更换IP"
    echo "   3. 使用CDN或其他中转方案"
elif [ "$GEMINI_STATUS" != "200" ] && [ "$GOOGLE_STATUS" = "200" ]; then
    echo "⚠️  Google基础服务正常，但Gemini被特殊限制："
    echo "   1. 尝试更换User-Agent"
    echo "   2. 清除浏览器缓存和Cookie"
    echo "   3. 尝试使用香港节点"
    echo "   4. 检查是否需要登录Google账号"
else
    echo "✅ 网络连接正常，如仍无法访问请检查："
    echo "   1. 浏览器是否正确设置代理"
    echo "   2. 系统代理是否启用"
    echo "   3. 防火墙是否允许相关端口"
fi

echo ""
echo "💡 快速测试命令："
echo "curl -x http://127.0.0.1:$PROXY_PORT -v 'https://gemini.google.com'"
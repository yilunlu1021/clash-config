#!/bin/bash

echo "🔍 ClashX 深度诊断 - Gemini 访问问题"
echo "====================================="

# 1. 检查 ClashX 运行状态
echo "1. 检查 ClashX 运行状态："
if pgrep -f "ClashX" > /dev/null; then
    echo "   ✅ ClashX 进程运行中"
    ps aux | grep ClashX | grep -v grep | head -2
else
    echo "   ❌ ClashX 未运行"
    echo "   请启动: open -a ClashX"
fi

echo ""

# 2. 检查端口状态
echo "2. 检查关键端口："
for port in 7890 8080 8090 9090; do
    if lsof -i :$port >/dev/null 2>&1; then
        PROCESS=$(lsof -i :$port | tail -1 | awk '{print $1}')
        echo "   端口 $port: ✅ 被 $PROCESS 占用"
    else
        echo "   端口 $port: ❌ 未监听"
    fi
done

echo ""

# 3. 检查系统代理状态
echo "3. 检查系统代理："
if command -v networksetup >/dev/null 2>&1; then
    HTTP_PROXY=$(networksetup -getwebproxy "Wi-Fi" 2>/dev/null)
    HTTPS_PROXY=$(networksetup -getsecurewebproxy "Wi-Fi" 2>/dev/null)
    SOCKS_PROXY=$(networksetup -getsocksfirewallproxy "Wi-Fi" 2>/dev/null)
    
    echo "   HTTP代理: $HTTP_PROXY"
    echo "   HTTPS代理: $HTTPS_PROXY"
    echo "   SOCKS代理: $SOCKS_PROXY"
else
    echo "   ⚠️  无法检查系统代理"
fi

echo ""

# 4. 测试代理连接
echo "4. 测试代理连接："
if curl -x http://127.0.0.1:7890 -s --connect-timeout 5 --max-time 10 -o /dev/null "http://www.gstatic.com/generate_204"; then
    echo "   ✅ 代理 7890 工作正常"
else
    echo "   ❌ 代理 7890 连接失败"
fi

# 尝试其他常见端口
for port in 8080 8090; do
    if curl -x http://127.0.0.1:$port -s --connect-timeout 3 --max-time 5 -o /dev/null "http://www.gstatic.com/generate_204" 2>/dev/null; then
        echo "   ✅ 代理 $port 工作正常"
        break
    fi
done

echo ""

# 5. 测试 DNS 解析
echo "5. 测试 DNS 解析："
for domain in "gemini.google.com" "openai.com" "anthropic.com"; do
    if command -v nslookup >/dev/null 2>&1; then
        RESULT=$(nslookup $domain 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}')
        echo "   $domain → $RESULT"
    fi
done

echo ""

# 6. 测试具体网站访问
echo "6. 测试网站访问（通过代理）："

# 测试不同代理端口
for port in 7890 8080 8090; do
    echo "   测试端口 $port:"
    
    # 测试 Google
    if curl -x http://127.0.0.1:$port -s --connect-timeout 5 --max-time 10 -o /dev/null "https://www.google.com" 2>/dev/null; then
        echo "     ✅ Google 可访问"
    else
        echo "     ❌ Google 无法访问"
    fi
    
    # 测试 Gemini
    GEMINI_RESULT=$(curl -x http://127.0.0.1:$port -s --connect-timeout 5 --max-time 10 "https://gemini.google.com" 2>/dev/null | head -5)
    if echo "$GEMINI_RESULT" | grep -q "DOCTYPE"; then
        echo "     ✅ Gemini 返回 HTML 页面"
    elif echo "$GEMINI_RESULT" | grep -qi "blocked\|restricted\|unavailable"; then
        echo "     ❌ Gemini 被阻止访问"
    else
        echo "     ⚠️  Gemini 响应异常"
    fi
    
    echo ""
done

# 7. 检查节点 IP
echo "7. 检查当前出口 IP："
for port in 7890 8080 8090; do
    IP=$(curl -x http://127.0.0.1:$port -s --connect-timeout 5 --max-time 10 "https://api.ipify.org" 2>/dev/null)
    if [ -n "$IP" ]; then
        echo "   端口 $port: $IP"
        # 检查 IP 归属地
        LOCATION=$(curl -s --connect-timeout 3 --max-time 5 "https://ipapi.co/$IP/country_name" 2>/dev/null)
        if [ -n "$LOCATION" ]; then
            echo "     位置: $LOCATION"
        fi
        break
    fi
done

echo ""

# 8. ClashX 配置检查建议
echo "8. ClashX 配置检查："
echo "   请手动检查以下项目："
echo "   □ ClashX 菜单 → 配置 → 是否选中了 'AI解锁专用配置'"
echo "   □ ClashX 菜单 → 设置为系统代理 (是否有 ✓)"
echo "   □ ClashX 菜单 → 增强模式 (是否有 ✓)"
echo "   □ ClashX 菜单 → 代理 → AI-Services → 是否选中美国节点"
echo "   □ ClashX 菜单 → 日志 → 是否有错误信息"

echo ""
echo "🔧 下一步建议："
echo "1. 查看 ClashX 日志中的具体错误"
echo "2. 手动在 ClashX 中选择美国节点"
echo "3. 尝试重启 ClashX 并重新导入配置"
echo "4. 检查节点是否正常工作"
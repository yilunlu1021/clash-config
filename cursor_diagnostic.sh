#!/bin/bash

# Cursor AI 诊断脚本
# 用于排查 "Model not available" 问题

echo "🔍 Cursor AI 连通性诊断"
echo "========================"
echo ""

# 检查1: 出口IP国家
echo "📍 检查出口IP国家 (需要美国/英国/新加坡/韩国/欧盟):"
echo "正在通过代理检查..."
curl -s ipinfo.io --proxy socks5h://127.0.0.1:7890 | jq -r '"\(.country) - \(.city) - \(.ip)"' 2>/dev/null || {
    echo "❌ 代理连接失败，请检查Clash是否运行在7890端口"
    echo "替代检查方式:"
    for port in 7891 7892 7893; do
        echo "尝试端口 $port..."
        result=$(curl -s ipinfo.io --proxy socks5h://127.0.0.1:$port 2>/dev/null | jq -r '"\(.country) - \(.city)"' 2>/dev/null)
        if [ -n "$result" ]; then
            echo "✅ 端口 $port: $result"
            break
        fi
    done
}
echo ""

# 检查2: Anthropic API 直接测试
echo "🧠 测试 Anthropic API 访问:"
echo "检查 api.anthropic.com..."
response=$(curl -s -w "%{http_code}" -o /dev/null --proxy socks5h://127.0.0.1:7890 https://api.anthropic.com/v1/messages 2>/dev/null)
case $response in
    "200"|"401"|"403") echo "✅ API 可访问 (HTTP: $response)" ;;
    "000") echo "❌ 连接失败 - 可能被墙或代理问题" ;;
    *) echo "⚠️  返回码: $response" ;;
esac
echo ""

# 检查3: TLS 证书验证
echo "🔒 检查 TLS 证书:"
echo "验证 api.anthropic.com 证书..."
cert_info=$(echo | openssl s_client -connect api.anthropic.com:443 -servername api.anthropic.com -proxy 127.0.0.1:7890 2>/dev/null | openssl x509 -noout -subject -issuer 2>/dev/null)
if [ -n "$cert_info" ]; then
    echo "✅ 证书正常:"
    echo "$cert_info"
else
    echo "❌ 证书检查失败 - 可能是代理或TLS劫持问题"
fi
echo ""

# 检查4: DNS 解析
echo "🌐 检查 DNS 解析:"
echo "api.anthropic.com DNS:"
nslookup api.anthropic.com | grep "Address:" | tail -1
echo "cursor.com DNS:"
nslookup cursor.com | grep "Address:" | tail -1
echo ""

# 检查5: Clash 规则匹配测试
echo "📋 Clash 规则匹配测试:"
echo "检查以下域名是否匹配AI-Services规则:"
domains=("api.anthropic.com" "cursor.com" "auth.cursor.com" "claude.ai")
for domain in "${domains[@]}"; do
    echo "  - $domain"
done
echo ""

echo "🔧 修复建议:"
echo "============="
echo "1. 如果出口IP不是美国/欧盟，请在Clash中手动选择 'AI-Services' → 'US-Seattle-Hysteria2'"
echo "2. 如果API无法访问，尝试重启Clash客户端"
echo "3. 如果DNS被污染，启用Clash的DoH功能"
echo "4. 更新订阅链接: https://cdn.jsdelivr.net/gh/yilunlu1021/clash-config/config.yaml"
echo ""
echo "🚨 立即测试: 在Clash中强制选择 AI-Services → US-Seattle-Reality，然后重试Cursor"
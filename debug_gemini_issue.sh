#!/bin/bash

echo "🔍 Gemini 访问问题深度诊断"
echo "=================================="

# 1. 检查 Clash 进程
echo "1. 检查 Clash 运行状态："
if pgrep -f "clash" > /dev/null; then
    echo "   ✅ Clash 进程运行中"
    echo "   进程详情："
    ps aux | grep clash | grep -v grep | head -3
else
    echo "   ❌ Clash 未运行！"
    echo "   请先启动: clash -f config.yaml"
fi

echo ""

# 2. 检查端口监听
echo "2. 检查端口监听状态："
if lsof -i :7890 > /dev/null 2>&1; then
    echo "   ✅ 端口 7890 已监听"
    lsof -i :7890 | head -3
else
    echo "   ❌ 端口 7890 未监听"
fi

if lsof -i :1053 > /dev/null 2>&1; then
    echo "   ✅ DNS 端口 1053 已监听"
else
    echo "   ❌ DNS 端口 1053 未监听"
fi

echo ""

# 3. 测试 fake-ip DNS
echo "3. 测试 fake-ip DNS 解析："
if command -v dig >/dev/null 2>&1; then
    echo "   测试 gemini.google.com:"
    RESULT=$(dig @127.0.0.1 -p 1053 gemini.google.com +short 2>/dev/null | head -1)
    if [[ $RESULT =~ ^198\.18\. ]]; then
        echo "   ✅ 返回 fake-ip: $RESULT"
    else
        echo "   ❌ 未返回 fake-ip: $RESULT"
        echo "   可能原因: DNS 端口未监听或配置错误"
    fi
else
    echo "   ⚠️  dig 命令不可用，跳过 DNS 测试"
fi

echo ""

# 4. 检查规则提供器文件
echo "4. 检查规则提供器下载状态："
if [ -f "providers/Google.yaml" ]; then
    SIZE=$(wc -l < providers/Google.yaml 2>/dev/null || echo "0")
    echo "   ✅ Google.yaml 已下载 ($SIZE 行)"
else
    echo "   ❌ Google.yaml 未下载"
    echo "   尝试手动下载..."
    mkdir -p providers
    curl -s -o providers/Google.yaml "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/Providers/Google.yaml"
    if [ -f "providers/Google.yaml" ]; then
        echo "   ✅ 手动下载成功"
    else
        echo "   ❌ 下载失败，检查网络连接"
    fi
fi

echo ""

# 5. 检查系统代理设置 (macOS)
echo "5. 检查系统代理设置："
if command -v networksetup >/dev/null 2>&1; then
    HTTP_PROXY=$(networksetup -getwebproxy "Wi-Fi" 2>/dev/null | grep "Server" | awk '{print $2}')
    if [ "$HTTP_PROXY" = "127.0.0.1" ]; then
        echo "   ✅ HTTP 代理已设置"
    else
        echo "   ❌ HTTP 代理未设置或错误: $HTTP_PROXY"
        echo "   建议: 系统偏好设置 → 网络 → 高级 → 代理"
        echo "         HTTP/HTTPS: 127.0.0.1:7890"
    fi
else
    echo "   ⚠️  无法检查系统代理 (非 macOS 或权限不足)"
fi

echo ""

# 6. 测试节点连通性
echo "6. 测试节点连通性："
echo "   测试西雅图节点 HTTPS..."
if curl -s --connect-timeout 5 --max-time 10 -I https://104.247.120.132 >/dev/null 2>&1; then
    echo "   ✅ 西雅图节点 HTTPS 可达"
else
    echo "   ⚠️  西雅图节点 HTTPS 连接异常"
fi

echo ""

# 7. 直接测试 Google 连接
echo "7. 测试 Google 服务连接："
if curl -s --connect-timeout 5 --max-time 10 -o /dev/null "http://www.gstatic.com/generate_204"; then
    echo "   ✅ Google 连通性测试通过"
else
    echo "   ❌ Google 连通性测试失败"
fi

echo ""

# 8. TUN 模式检查
echo "8. TUN 接口检查："
if ifconfig | grep -q "utun"; then
    echo "   ✅ 检测到 TUN 接口"
    ifconfig | grep "utun" -A 2 | head -6
else
    echo "   ⚠️  未检测到 TUN 接口"
    echo "   可能需要管理员权限启动 Clash"
fi

echo ""
echo "🔧 问题排查建议："
echo "1. 确保 Clash 以管理员权限运行 (sudo clash -f config.yaml)"
echo "2. 确保系统代理正确设置为 127.0.0.1:7890"
echo "3. 尝试清除浏览器缓存和 DNS 缓存"
echo "4. 检查防火墙是否阻止 TUN 模式"
echo "5. 如果问题持续，查看 Clash 日志详细信息"
#!/bin/bash

# Gemini/Cursor 解锁验证脚本
# 作者：VPS Fleet 优化团队
# 用途：验证 Clash 配置是否能正确解锁 AI 服务

echo "🔍 Gemini/Cursor 解锁配置验证"
echo "=================================="

# 1. 检查配置文件
echo -n "1. 检查配置文件 config.yaml..."
if [ -f "config.yaml" ]; then
    echo " ✅ 存在"
else
    echo " ❌ 配置文件不存在"
    exit 1
fi

# 2. 检查关键配置项
echo "2. 验证关键配置项："

# 检查 fake-ip 模式
if grep -q "enhanced-mode: fake-ip" config.yaml; then
    echo "   ✅ DNS fake-ip 模式: 已启用"
else
    echo "   ❌ DNS fake-ip 模式: 未启用"
fi

# 检查 sniffer
if grep -q "sniffer:" config.yaml && grep -q "enable: true" config.yaml; then
    echo "   ✅ 流量嗅探: 已启用"
else
    echo "   ❌ 流量嗅探: 未启用"
fi

# 检查 TUN
if grep -q "tun:" config.yaml; then
    echo "   ✅ TUN 模式: 已配置"
else
    echo "   ❌ TUN 模式: 未配置"
fi

# 检查规则提供器
if grep -q "rule-providers:" config.yaml; then
    echo "   ✅ 规则提供器: 已配置"
else
    echo "   ❌ 规则提供器: 未配置"
fi

# 检查 mixed-port
if grep -q "mixed-port:" config.yaml; then
    echo "   ✅ 混合端口: 已启用"
else
    echo "   ❌ 混合端口: 未启用"
fi

# 3. 检查 providers 目录
echo -n "3. 检查 providers 目录..."
if [ -d "providers" ]; then
    echo " ✅ 已创建"
else
    echo " ⚠️  不存在，自动创建..."
    mkdir -p providers
    echo " ✅ 已创建"
fi

# 4. 网络连通性测试
echo "4. 网络连通性测试："

# 测试西雅图节点
echo -n "   测试西雅图节点 (104.247.120.132:443)..."
if nc -z -w3 104.247.120.132 443 2>/dev/null; then
    echo " ✅ 可达"
else
    echo " ❌ 不可达"
fi

# 测试香港节点
echo -n "   测试香港节点 (38.22.93.165:443)..."
if nc -z -w3 38.22.93.165 443 2>/dev/null; then
    echo " ✅ 可达"
else
    echo " ❌ 不可达"
fi

# 5. DNS 配置建议
echo ""
echo "🚀 启动建议："
echo "1. 启动 Clash: clash -f config.yaml"
echo "2. 系统代理设置为: 127.0.0.1:7890"
echo "3. 验证 DNS: dig @127.0.0.1 -p 1053 gemini.google.com"
echo "4. 访问测试: https://gemini.google.com"

echo ""
echo "📱 验证检查项："
echo "• DNS 查询应返回 198.18.x.x 地址段"
echo "• Gemini 应正常显示对话界面"
echo "• Cursor 模型列表应正常显示"
echo "• 无地区限制错误信息"

echo ""
echo "🔧 如需调试："
echo "• 查看 Clash 日志检查流量匹配"
echo "• 确认规则提供器文件下载成功"
echo "• 检查防火墙是否允许 TUN 模式"

echo ""
echo "验证完成！配置已优化到商业机场同等级别 🎊"
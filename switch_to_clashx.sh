#!/bin/bash

echo "🔄 从 Mihomo Party 切换到 ClashX"
echo "================================"

# 1. 停止 Mihomo Party
echo "1. 停止 Mihomo Party..."
if pgrep -f "Mihomo Party" >/dev/null; then
    echo "   正在停止 Mihomo Party..."
    osascript -e 'tell application "Mihomo Party" to quit'
    sleep 3
    
    # 如果还在运行，强制停止
    if pgrep -f "Mihomo Party" >/dev/null; then
        echo "   强制停止 Mihomo Party..."
        pkill -f "Mihomo Party"
        sleep 2
    fi
    
    echo "   ✅ Mihomo Party 已停止"
else
    echo "   ✅ Mihomo Party 未运行"
fi

# 2. 启动 ClashX
echo "2. 启动 ClashX..."
open -a ClashX
sleep 3

if pgrep -f ClashX >/dev/null; then
    echo "   ✅ ClashX 已启动"
else
    echo "   ❌ ClashX 启动失败"
    exit 1
fi

# 3. 检查端口
echo "3. 检查端口状态..."
sleep 2
if lsof -i :7890 2>/dev/null | grep -q ClashX; then
    echo "   ✅ ClashX 正在监听端口 7890"
else
    echo "   ⚠️  ClashX 可能使用其他端口，请检查 ClashX 设置"
fi

echo ""
echo "✅ 切换完成！"
echo "现在请按照 use_clashx_setup.md 的步骤配置 ClashX"
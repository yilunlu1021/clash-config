#!/bin/bash

echo "🚀 正确启动 Clash 配置"
echo "======================"

# 1. 检查并停止冲突进程
echo "1. 检查端口占用情况..."
if lsof -i :7890 >/dev/null 2>&1; then
    echo "   ⚠️  端口 7890 被占用："
    lsof -i :7890
    echo ""
    echo "   建议操作："
    echo "   - 如果是 ClashX/ClashX Pro，请先退出"
    echo "   - 如果是其他程序，考虑更改端口或停止程序"
    echo ""
fi

# 2. 检查 Clash 命令是否可用
echo "2. 检查 Clash 命令..."
if command -v clash >/dev/null 2>&1; then
    echo "   ✅ Clash 命令可用"
    CLASH_CMD="clash"
elif [ -f "/usr/local/bin/clash" ]; then
    echo "   ✅ 找到 Clash: /usr/local/bin/clash"
    CLASH_CMD="/usr/local/bin/clash"
elif [ -f "./clash" ]; then
    echo "   ✅ 找到本地 Clash: ./clash"
    CLASH_CMD="./clash"
else
    echo "   ❌ 未找到 Clash 命令"
    echo "   请下载 Clash Premium："
    echo "   curl -L -o clash-darwin-amd64.gz https://github.com/Dreamacro/clash/releases/download/premium/clash-darwin-amd64-2023.08.17.gz"
    echo "   gunzip clash-darwin-amd64.gz"
    echo "   chmod +x clash-darwin-amd64"
    echo "   sudo mv clash-darwin-amd64 /usr/local/bin/clash"
    exit 1
fi

# 3. 验证配置文件
echo "3. 验证配置文件..."
if [ ! -f "config.yaml" ]; then
    echo "   ❌ config.yaml 不存在"
    exit 1
fi

# 检查配置语法（如果支持）
if $CLASH_CMD -t -f config.yaml >/dev/null 2>&1; then
    echo "   ✅ 配置文件语法正确"
else
    echo "   ⚠️  配置文件可能有语法问题，但继续尝试..."
fi

# 4. 启动选项
echo "4. 启动选项："
echo "   A) 普通启动: $CLASH_CMD -f config.yaml"
echo "   B) 调试启动: $CLASH_CMD -f config.yaml -l debug"
echo "   C) 后台启动: nohup $CLASH_CMD -f config.yaml > clash.log 2>&1 &"
echo ""

read -p "选择启动方式 (A/B/C) [默认A]: " choice
case $choice in
    [Bb])
        echo "🔍 以调试模式启动..."
        echo "日志将显示详细信息，按 Ctrl+C 停止"
        echo ""
        $CLASH_CMD -f config.yaml -l debug
        ;;
    [Cc])
        echo "🔄 后台启动..."
        nohup $CLASH_CMD -f config.yaml > clash.log 2>&1 &
        CLASH_PID=$!
        echo "   ✅ Clash 已后台启动 (PID: $CLASH_PID)"
        echo "   查看日志: tail -f clash.log"
        echo "   停止服务: kill $CLASH_PID"
        ;;
    *)
        echo "🚀 普通启动..."
        echo "按 Ctrl+C 停止服务"
        echo ""
        $CLASH_CMD -f config.yaml
        ;;
esac
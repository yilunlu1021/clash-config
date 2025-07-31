#!/bin/bash
# Clash配置自动更新脚本
# 使用方法: ./update_clash_config.sh "更新说明"

set -e

echo "🚀 开始更新Clash配置到GitHub..."
echo "=================================="

# 检查参数
COMMIT_MSG="${1:-Update clash configuration $(date '+%Y-%m-%d %H:%M')}"

# 确保配置文件存在
if [ ! -f "GitHub_Clash_Config.yaml" ]; then
    echo "❌ 错误: GitHub_Clash_Config.yaml 文件不存在"
    exit 1
fi

# 复制配置文件（以防需要重命名）
cp GitHub_Clash_Config.yaml config.yaml
echo "✅ 配置文件已准备"

# Git操作
echo "📂 添加文件到Git..."
git add config.yaml GitHub_Clash_Config.yaml .gitignore

echo "📝 提交更改..."
git commit -m "$COMMIT_MSG" || echo "⚠️ 没有新的更改需要提交"

echo "⬆️ 推送到GitHub..."
git push clash-config main || git push clash-config master

echo ""
echo "🎉 **更新完成！**"
echo "================"
echo "📋 提交信息: $COMMIT_MSG"
echo "🔗 订阅链接: https://cdn.jsdelivr.net/gh/yilunlu1021/clash-config/config.yaml"
echo ""
echo "⏳ 注意: CDN更新可能需要1-2分钟生效"


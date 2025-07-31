#!/bin/bash
# 快速更新Clash配置的便捷脚本

echo "🎯 快速更新Clash配置"
echo "==================="

case "$1" in
    "dns")
        ./update_clash_config.sh "Update DNS configuration"
        ;;
    "rules")
        ./update_clash_config.sh "Update routing rules"
        ;;
    "nodes")
        ./update_clash_config.sh "Update proxy nodes"
        ;;
    "fix")
        ./update_clash_config.sh "Fix configuration issues"
        ;;
    *)
        echo "使用方法:"
        echo "  ./quick_update.sh dns    - 更新DNS配置"
        echo "  ./quick_update.sh rules  - 更新路由规则"
        echo "  ./quick_update.sh nodes  - 更新代理节点"
        echo "  ./quick_update.sh fix    - 修复配置问题"
        echo ""
        echo "或者直接使用:"
        echo "  ./update_clash_config.sh \"自定义更新说明\""
        ;;
esac

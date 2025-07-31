#!/bin/bash
# 新增服务器到Clash配置的辅助脚本

echo "🚀 添加新服务器到Clash配置"
echo "=========================="
echo ""

# 获取用户输入
read -p "服务器位置 (如: US-NewYork, HK-CMI2): " LOCATION
read -p "服务器IP: " SERVER_IP
read -p "Reality UUID: " REALITY_UUID
read -p "Reality Public Key: " REALITY_PUBLIC_KEY
read -p "Reality Short ID: " REALITY_SHORT_ID
read -p "Hysteria2 Password: " HYSTERIA2_PASSWORD
read -p "Hysteria2 Obfs Password: " HYSTERIA2_OBFS_PASSWORD
read -p "伪装域名 (www.apple.com 或 www.binance.com): " SNI_DOMAIN

# 确定端口配置
if [[ $SNI_DOMAIN == *"binance"* ]]; then
    HYSTERIA2_PORT=8443
    echo "🇭🇰 检测到香港服务器配置"
else
    HYSTERIA2_PORT=443
    echo "🇺🇸 检测到美国服务器配置"
fi

echo ""
echo "📋 **配置信息确认:**"
echo "位置: $LOCATION"
echo "IP: $SERVER_IP"
echo "伪装域名: $SNI_DOMAIN"
echo "Hysteria2端口: $HYSTERIA2_PORT"
echo ""

read -p "确认添加到配置? (y/N): " CONFIRM
if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "❌ 操作已取消"
    exit 1
fi

# 创建节点配置
cat >> new_nodes.yaml << NODE_EOF
  # $LOCATION 服务器
  - name: "$LOCATION-Reality"
    type: vless
    server: $SERVER_IP
    port: 443
    uuid: $REALITY_UUID
    flow: xtls-rprx-vision
    tls: true
    network: tcp
    reality-opts:
      public-key: $REALITY_PUBLIC_KEY
      short-id: $REALITY_SHORT_ID
    client-fingerprint: chrome
    servername: $SNI_DOMAIN

  - name: "$LOCATION-Hysteria2"
    type: hysteria2
    server: $SERVER_IP
    port: $HYSTERIA2_PORT
    password: $HYSTERIA2_PASSWORD
    obfs: salamander
    obfs-password: $HYSTERIA2_OBFS_PASSWORD
    sni: $SNI_DOMAIN
    skip-cert-verify: true
    up: 300
    down: 500

NODE_EOF

echo "✅ 节点配置已生成到 new_nodes.yaml"
echo ""
echo "�� **下一步操作:**"
echo "1. 将 new_nodes.yaml 的内容添加到 GitHub_Clash_Config.yaml 的 proxies 部分"
echo "2. 将新节点名称添加到相关的 proxy-groups"
echo "3. 运行: ./update_clash_config.sh \"Add new server: $LOCATION\""
echo ""
echo "💡 **参考 VPS_DEPLOYMENT_GUIDE.md 中的详细说明**"


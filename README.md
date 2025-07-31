# VPS-FLEET（多节点运维统一项目）

用于管理个人/团队节点，包括自动 SSH 配置、AI 出口健康检测、VPS 一键部署等。

## 📁 项目结构说明

| 文件 / 目录 | 用途 |
|-------------|------|
| `servers.yaml` | 所有 VPS 基本信息 |
| `sync_ssh.sh` | 生成 ~/.ssh/config 快捷连接 |
| `scripts/ai_health_check.py` | 自动检测出口可用性并 Telegram 通知 |
| `scripts/deploy_hk_node.sh` | 部署 Reality+Hy2+WARP 节点脚本 |
| `scripts/test_deployment.sh` | 部署环境检查脚本 |
| `scripts/batch_operations.sh` | 批量操作脚本 |
| `config/config.clash.yaml` | Clash 分流配置模板 |
| `config/rule_ai.list` | 常见 AI 域名分流规则 |
| `config/rule_cn.list` | 国内直连白名单域名 |
| `.env.example` | 所需环境变量模板 |
| `venv/` | 本地 Python 虚拟环境目录 |
| `requirements.txt` | 所有 Python 脚本的依赖 |

## ✅ 环境准备

```bash
# 创建虚拟环境
python3 -m venv venv

# 激活虚拟环境
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 复制环境变量模板
cp .env.example .env

# 编辑环境变量
nano .env
```

## 🧠 SSH 快捷连接

```bash
# 自动生成 ~/.ssh/config
./sync_ssh.sh

# 立即连接
ssh HK_CN2_GIA_1
```

## 🛠️ 自动部署节点

### 🚀 方式一：远程一键部署（推荐）

**完全自动化，无需手动登录服务器**

```bash
# 确保SSH配置正确
./sync_ssh.sh

# 一键部署香港节点（约3-5分钟）
./scripts/remote_deploy.sh HK_CN2_GIA_1
```

**功能特性：**
- ✅ 自动更改SSH到安全端口 (41000-52000)
- ✅ 安装 3x-ui + 最新 Xray-core
- ✅ 配置 Reality (443) + Hysteria2 (28443)  
- ✅ 安装 WARP-GO SOCKS5代理 (40000)
- ✅ 自动生成 Clash 配置片段
- ✅ 完整的 UFW 防火墙配置
- ✅ 自动更新 servers.yaml 端口配置

### 🔧 方式二：手动分步部署

#### 1️⃣ 连接服务器
```bash
# 同步SSH配置
./sync_ssh.sh

# 连接服务器  
ssh HK_CN2_GIA_1
```

#### 2️⃣ 执行部署脚本
```bash
# 上传并执行本地脚本
scp scripts/deploy_hk_node_final.sh HK_CN2_GIA_1:/tmp/
ssh HK_CN2_GIA_1 "sudo /tmp/deploy_hk_node_final.sh"
```

#### 3️⃣ 获取配置信息
```bash
# 查看部署信息
ssh HK_CN2_GIA_1 "cat /root/deployment_info.txt"

# 获取Clash配置
ssh HK_CN2_GIA_1 "cat /root/clash_snippet.yaml"
```

### 📋 部署结果验证

部署完成后会安装：
- ✅ **3x-ui面板**: http://IP:2053 (admin/随机密码)
- ✅ **Reality协议**: 443端口 (AI服务专用)
- ✅ **Hysteria2协议**: 28443端口 (流媒体高速)
- ✅ **WARP-GO代理**: 40000端口 (备用出口)
- ✅ **安全SSH**: 41000-52000随机端口
- ✅ **UFW防火墙**: 已配置必要端口规则

### 🔍 故障排除与验证

```bash
# 检查服务状态
ssh HK_CN2_GIA_1 "systemctl status x-ui warp-go"

# 检查端口监听
ssh HK_CN2_GIA_1 "ss -tuln | grep -E ':(443|2053|28443|40000)'"

# 查看防火墙状态  
ssh HK_CN2_GIA_1 "ufw status"

# 运行完整验证
bash scripts/deployment_checklist.sh
```

### 美国AI节点部署（预留）

```bash
# 预留脚本，可根据需求开发
bash scripts/deploy_us_ai_node.sh
```

## 🧪 出口健康监测

### 手动检测

```bash
# 激活虚拟环境
source venv/bin/activate

# 运行健康检测
python scripts/ai_health_check.py
```

### 自动检测（Crontab）

```bash
# 编辑 crontab
crontab -e

# 添加定时任务（每5分钟检测一次）
*/5 * * * * /path/to/vps-fleet/venv/bin/python /path/to/vps-fleet/scripts/ai_health_check.py
```

## 🔧 环境变量配置

编辑 `.env` 文件：

```bash
# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here
TELEGRAM_CHAT_ID=your_chat_id_here

# WARP Configuration
WARP_KEY=your_warp_key_here

# VPS Configuration
VEID=your_veid_here

# AI Health Check Configuration
HEALTH_CHECK_INTERVAL=300  # 5 minutes
AI_DOMAINS=openai.com,claude.ai,anthropic.com

# Notification Settings
ENABLE_TELEGRAM_NOTIFICATIONS=true
ENABLE_EMAIL_NOTIFICATIONS=false
```

## 📋 使用流程

### 1. 初始化项目

```bash
# 克隆项目
git clone <your-repo-url>
cd vps-fleet

# 设置环境
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 配置环境变量
cp .env.example .env
nano .env
```

### 2. 配置服务器信息

编辑 `servers.yaml`：

```yaml
# VPS SSH Configuration
- name: HK_CN2_GIA_1
  ip: 93.179.125.194
  user: root
  port: 22
  identity_file: ~/.ssh/id_ed25519
  note: 香港服务器1

- name: US_AI_Node
  ip: your-us-server-ip
  user: root
  port: 22
  identity_file: ~/.ssh/id_ed25519
  note: 美国AI节点
```

### 3. 同步SSH配置

```bash
./sync_ssh.sh
```

### 4. 部署节点

```bash
# 连接服务器
ssh HK_CN2_GIA_1

# 部署香港节点
bash scripts/deploy_hk_node.sh
```

### 5. 配置Clash

1. 复制 `config/config.clash.yaml` 到你的Clash配置目录
2. 修改代理配置中的UUID和服务器信息
3. 重启Clash

### 6. 设置健康检测

```bash
# 测试健康检测
source venv/bin/activate
python scripts/ai_health_check.py

# 设置定时任务
crontab -e
# 添加: */5 * * * * /path/to/vps-fleet/venv/bin/python /path/to/vps-fleet/scripts/ai_health_check.py
```

## 🚀 高级功能

### 批量操作

```bash
# 在所有服务器上执行命令
for server in $(grep "name:" servers.yaml | cut -d: -f2 | tr -d ' '); do
    ssh $server "your-command-here"
done
```

### 批量操作

```bash
# 检查所有服务器状态
./scripts/batch_operations.sh -a status

# 更新指定服务器
./scripts/batch_operations.sh -s HK_CN2_GIA_1 update

# 在所有服务器上执行自定义命令
./scripts/batch_operations.sh -a custom 'df -h'

# 查看帮助
./scripts/batch_operations.sh --help
```

### 监控面板

访问 `http://your-server-ip:54321` 查看3x-ui面板

### 日志查看

```bash
# 查看服务状态
systemctl status x-ui
systemctl status reality
systemctl status hysteria2

# 查看日志
journalctl -u x-ui -f
journalctl -u reality -f
journalctl -u hysteria2 -f
```

## 🔒 安全建议

1. **更改默认端口**：修改SSH端口和3x-ui面板端口
2. **设置强密码**：为所有服务设置强密码
3. **定期更新**：定期更新系统和软件包
4. **备份配置**：定期备份重要配置文件
5. **监控访问**：监控异常访问日志

## 📞 故障排除

### 常见问题

1. **SSH连接失败**
   - 检查 `servers.yaml` 配置
   - 确认SSH密钥权限
   - 检查防火墙设置

2. **健康检测失败**
   - 检查 `.env` 配置
   - 确认网络连接
   - 查看Python依赖

3. **部署脚本失败**
   - 确认root权限
   - 检查网络连接
   - 查看系统日志

### 日志位置

- 3x-ui: `/usr/local/x-ui/`
- Reality: `/usr/local/reality/`
- Hysteria2: `/usr/local/hysteria2/`
- 系统日志: `journalctl -u service-name`

## 📝 更新日志

### v1.0.0
- ✅ 基础SSH配置同步
- ✅ AI健康检测脚本
- ✅ 香港节点自动部署
- ✅ Clash分流配置模板
- ✅ 环境变量管理

## 🤝 贡献

欢迎提交Issue和Pull Request！

## �� 许可证

MIT License 
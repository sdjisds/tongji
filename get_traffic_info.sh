#!/bin/bash

# 确保已经设置了 BOT_TOKEN 和 CHAT_ID 环境变量
if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "BOT_TOKEN or CHAT_ID is not set!"
    exit 1
fi

# 获取流量统计，使用 ifstat 命令（也可以根据你的系统选择其他方式）
INTERFACE="eth0"

# 使用 ifstat 获取上传和下载流量，避免空值导致错误
UPLOAD=$(ifstat -i $INTERFACE 1 1 | awk 'NR==3 {print $1}')
DOWNLOAD=$(ifstat -i $INTERFACE 1 1 | awk 'NR==3 {print $2}')

# 如果获取的上传和下载流量为空，设置默认值为 0
if [ -z "$UPLOAD" ] || ! [[ "$UPLOAD" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    UPLOAD=0
fi

if [ -z "$DOWNLOAD" ] || ! [[ "$DOWNLOAD" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    DOWNLOAD=0
fi

# 计算流量的总和，单位转换为 GB
TOTAL=$(echo "scale=2; ($UPLOAD + $DOWNLOAD) / (1024 * 1024)" | bc)

# 输出当天流量统计
MESSAGE="📅 Date: $(date +'%Y-%m-%d')\n📤 Upload: $(echo "scale=2; $UPLOAD / (1024 * 1024)" | bc) GB\n📥 Download: $(echo "scale=2; $DOWNLOAD / (1024 * 1024)" | bc) GB\n💥 Total: $TOTAL GB"

# 向用户发送当前流量信息
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id=$CHAT_ID \
    -d text="$MESSAGE"

#!/bin/bash

# 获取 chat_id 作为脚本参数
CHAT_ID=$1

# 获取当前流量信息
UPLOAD=$(ifstat -i eth0 1 1 | awk 'NR==3 {print $1}')
DOWNLOAD=$(ifstat -i eth0 1 1 | awk 'NR==3 {print $2}')
TOTAL=$(echo "$UPLOAD + $DOWNLOAD" | bc)

# 转换为 GB
UPLOAD_GB=$(echo "scale=2; $UPLOAD / 1024 / 1024" | bc)
DOWNLOAD_GB=$(echo "scale=2; $DOWNLOAD / 1024 / 1024" | bc)
TOTAL_GB=$(echo "scale=2; $TOTAL / 1024 / 1024" | bc)

# 构建消息内容
MESSAGE="Date: $(date '+%Y-%m-%d')\nUpload: $UPLOAD_GB GB\nDownload: $DOWNLOAD_GB GB\nTotal: $TOTAL_GB GB"

# 发送消息到 Telegram
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$MESSAGE"

# 调试输出
echo "Sent message to $CHAT_ID: $MESSAGE" >> /root/get_traffic_info_debug.log

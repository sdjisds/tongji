#!/bin/bash

# 确保已经设置了 BOT_TOKEN 和 CHAT_ID 环境变量12
if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "BOT_TOKEN or CHAT_ID is not set!"
    exit 1
fi

# 网卡接口（根据你的服务器调整网卡名）
INTERFACE="ens5"

# 获取日期
DATE=$(date +'%Y-%m-%d')
TIME=$(date +'%H:%M:%S')
MONTH=$(date +'%m')

# 获取当天的流量统计（从 vnstat 获取 JSON 数据）
UPLOAD=$(vnstat -i $INTERFACE --json | jq -r '.interfaces[0].traffic.day[0].rx')
DOWNLOAD=$(vnstat -i $INTERFACE --json | jq -r '.interfaces[0].traffic.day[0].tx')

# 如果上传或下载流量为空，设置为 0
if [ "$UPLOAD" == "null" ]; then
    UPLOAD=0
fi

if [ "$DOWNLOAD" == "null" ]; then
    DOWNLOAD=0
fi

# 获取月累计流量
MONTHLY_FILE="/root/traffic_data.txt"
if [ ! -f $MONTHLY_FILE ]; then
    echo "0" > $MONTHLY_FILE
fi
MONTHLY_TOTAL=$(cat $MONTHLY_FILE)

# 计算当天和月累计流量（单位 GB）
UPLOAD_GB=$(echo "scale=2; $UPLOAD / 1024 / 1024 / 1024" | bc)
DOWNLOAD_GB=$(echo "scale=2; $DOWNLOAD / 1024 / 1024 / 1024" | bc)
TOTAL_GB=$(echo "scale=2; $UPLOAD_GB + $DOWNLOAD_GB" | bc)

# 输出当天的流量统计
echo "Date: $DATE"
echo "Upload: $UPLOAD_GB GB"
echo "Download: $DOWNLOAD_GB GB"
echo "Total: $TOTAL_GB GB"

# 更新月累计流量
MONTHLY_TOTAL=$(echo "scale=2; $MONTHLY_TOTAL + $TOTAL_GB" | bc)
echo $MONTHLY_TOTAL > $MONTHLY_FILE

# 推送当天流量统计到 Telegram
MESSAGE="📅 Date: $DATE\n⏰ Time: $TIME\n📤 Upload: $UPLOAD_GB GB\n📥 Download: $DOWNLOAD_GB GB\n💥 Total: $TOTAL_GB GB"
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id=$CHAT_ID \
    -d text="$MESSAGE"

# 推送本月累计流量统计到 Telegram
MONTHLY_MESSAGE="📅 Month's Total Traffic\n💥 Monthly Total: $MONTHLY_TOTAL GB"
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id=$CHAT_ID \
    -d text="$MONTHLY_MESSAGE"

# 每月1号重置月累计流量
if [ "$MONTH" != "$(date +'%m')" ]; then
    echo "0" > $MONTHLY_FILE
fi

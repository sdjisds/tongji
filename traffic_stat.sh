#!/bin/bash

# 确保已经设置了 BOT_TOKEN 和 CHAT_ID 环境变量
if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "BOT_TOKEN or CHAT_ID is not set!"
    exit 1
fi

# 获取流量统计，使用 ifstat 命令（也可以根据你的系统选择其他方式）
# 假设你正在监控的网卡是 ens5，你可以根据实际情况修改网卡名称
INTERFACE="ens5"

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

# 获取当前时间的小时、分钟、秒
TIME=$(date +%H:%M:%S)
HOUR=$(echo $TIME | cut -d':' -f1)
MINUTE=$(echo $TIME | cut -d':' -f2)
SECOND=$(echo $TIME | cut -d':' -f3)

# 获取当前日期
DATE=$(date +'%Y-%m-%d')

# 计算流量的总和，单位转换为 GB
TOTAL=$(echo "scale=2; ($UPLOAD + $DOWNLOAD) / (1024 * 1024)" | bc)

# 获取本月流量累计值（可以根据需要存储到文件或数据库中，这里假设是 /root/traffic_data.txt）
MONTHLY_FILE="/root/traffic_data.txt"
if [ ! -f $MONTHLY_FILE ]; then
    echo "0" > $MONTHLY_FILE
fi
MONTHLY_TOTAL=$(cat $MONTHLY_FILE)

# 输出当天流量统计
echo "Date: $DATE"
echo "Upload: $(echo "scale=2; $UPLOAD / (1024 * 1024)" | bc) GB"
echo "Download: $(echo "scale=2; $DOWNLOAD / (1024 * 1024)" | bc) GB"
echo "Total: $TOTAL GB"

# 更新本月的流量累计数据
MONTHLY_TOTAL=$(echo "scale=2; $MONTHLY_TOTAL + $TOTAL" | bc)
echo $MONTHLY_TOTAL > $MONTHLY_FILE

# 推送当天流量统计到 Telegram
MESSAGE="📅 Date: $DATE\n⏰ Time: $TIME\n📤 Upload: $(echo "scale=2; $UPLOAD / (1024 * 1024)" | bc) GB\n📥 Download: $(echo "scale=2; $DOWNLOAD / (1024 * 1024)" | bc) GB\n💥 Total: $TOTAL GB"
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id=$CHAT_ID \
    -d text="$MESSAGE"

# 推送本月累计流量统计到 Telegram
MONTHLY_MESSAGE="📅 Month's Total Traffic\n💥 Monthly Total: $(echo "scale=2; $MONTHLY_TOTAL" | bc) GB"
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id=$CHAT_ID \
    -d text="$MONTHLY_MESSAGE"

#!/bin/bash

# 确保已经设置了 BOT_TOKEN 和 CHAT_ID 环境变量
if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "BOT_TOKEN or CHAT_ID is not set!"
    exit 1
fi

# 获取流量统计，使用 ifstat 命令（也可以根据你的系统选择其他方式）
# 假设你正在监控的网卡是 eth0，你可以根据实际情况修改网卡名称
INTERFACE="eth0"
UPLOAD=$(ifstat -i $INTERFACE 1 1 | awk 'NR==3 {print $1}')
DOWNLOAD=$(ifstat -i $INTERFACE 1 1 | awk 'NR==3 {print $2}')

# 获取当前时间的小时、分钟、秒
TIME=$(date +%H:%M:%S)
HOUR=$(echo $TIME | cut -d':' -f1)
MINUTE=$(echo $TIME | cut -d':' -f2)
SECOND=$(echo $TIME | cut -d':' -f3)

# 获取当前日期
DATE=$(date +'%Y-%m-%d')

# 计算流量的总和，单位为 KB
TOTAL=$(echo "$UPLOAD + $DOWNLOAD" | bc)

# 获取本月流量累计值（可以根据需要存储到文件或数据库中，这里假设是 /root/traffic_data.txt）
MONTHLY_FILE="/root/traffic_data.txt"
if [ ! -f $MONTHLY_FILE ]; then
    echo "0" > $MONTHLY_FILE
fi
MONTHLY_TOTAL=$(cat $MONTHLY_FILE)

# 输出当天流量统计
echo "Date: $DATE"
echo "Upload: $UPLOAD KB"
echo "Download: $DOWNLOAD KB"
echo "Total: $TOTAL KB"

# 更新本月的流量累计数据
MONTHLY_TOTAL=$(echo "$MONTHLY_TOTAL + $TOTAL" | bc)
echo $MONTHLY_TOTAL > $MONTHLY_FILE

# 推送当天流量统计到 Telegram
MESSAGE="📅 Date: $DATE\n⏰ Time: $TIME\n📤 Upload: $UPLOAD KB\n📥 Download: $DOWNLOAD KB\n💥 Total: $TOTAL KB"
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id=$CHAT_ID \
    -d text="$MESSAGE"

# 推送本月累计流量统计到 Telegram
MONTHLY_MESSAGE="📅 Month's Total Traffic\n💥 Monthly Total: $MONTHLY_TOTAL KB"
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id=$CHAT_ID \
    -d text="$MONTHLY_MESSAGE"


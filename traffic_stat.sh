#!/bin/bash

# 自动检测网卡
INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)

# 确保 Telegram Bot Token 和 Chat ID 通过环境变量传递
if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "请在运行时通过环境变量设置 BOT_TOKEN 和 CHAT_ID！"
    exit 1
fi

# 设置流量统计文件路径
LOG_FILE="/var/log/traffic_log.txt"
MONTHLY_LOG_FILE="/var/log/monthly_traffic_log.txt"

# 获取当前日期
DATE=$(date "+%Y-%m-%d %H:%M:%S")
DAY=$(date "+%d")   # 获取当前的天（1-31）
MONTH=$(date "+%m") # 获取当前的月（01-12）

# 检查是否是每月1号，若是，重置流量统计
if [ "$DAY" -eq 01 ]; then
    echo "[$DATE] 每月1号，重置流量统计为0" > $LOG_FILE
    echo "[$DATE] 每月1号，重置本月累计流量统计为0" > $MONTHLY_LOG_FILE
fi

# 获取当前的接收和发送字节数
RX_BYTES=$(cat /proc/net/dev | grep "$INTERFACE" | tr : " " | awk '{print $2}')
TX_BYTES=$(cat /proc/net/dev | grep "$INTERFACE" | tr : " " | awk '{print $10}')

# 读取上一次的流量数据（如果文件存在）
if [ -f "$LOG_FILE" ]; then
    LAST_RX_BYTES=$(awk 'NR==1 {print $2}' $LOG_FILE)
    LAST_TX_BYTES=$(awk 'NR==1 {print $3}' $LOG_FILE)
else
    LAST_RX_BYTES=0
    LAST_TX_BYTES=0
fi

# 读取本月累计流量数据（如果文件存在）
if [ -f "$MONTHLY_LOG_FILE" ]; then
    LAST_MONTH_RX_BYTES=$(awk 'NR==1 {print $2}' $MONTHLY_LOG_FILE)
    LAST_MONTH_TX_BYTES=$(awk 'NR==1 {print $3}' $MONTHLY_LOG_FILE)
else
    LAST_MONTH_RX_BYTES=0
    LAST_MONTH_TX_BYTES=0
fi

# 计算当前流量和上次流量的差值（单位字节）
RX_DIFF=$((RX_BYTES - LAST_RX_BYTES))
TX_DIFF=$((TX_BYTES - LAST_TX_BYTES))

# 计算本月的累计流量（单位字节）
MONTHLY_RX_DIFF=$((RX_BYTES - LAST_MONTH_RX_BYTES))
MONTHLY_TX_DIFF=$((TX_BYTES - LAST_MONTH_TX_BYTES))

# 将字节数转换为MB
RX_MB=$(echo "scale=2; $RX_DIFF/1024/1024" | bc)
TX_MB=$(echo "scale=2; $TX_DIFF/1024/1024" | bc)
MONTHLY_RX_MB=$(echo "scale=2; $MONTHLY_RX_DIFF/1024/1024" | bc)
MONTHLY_TX_MB=$(echo "scale=2; $MONTHLY_TX_DIFF/1024/1024" | bc)

# 计算上传和下载的总和
TOTAL_MB=$(echo "scale=2; $RX_MB + $TX_MB" | bc)
MONTHLY_TOTAL_MB=$(echo "scale=2; $MONTHLY_RX_MB + $MONTHLY_TX_MB" | bc)

# 将当前流量数据保存到文件（用于下次比较）
echo "$DATE $RX_BYTES $TX_BYTES" > $LOG_FILE

# 将本月累计流量数据保存到文件（用于下次比较）
echo "$DATE $RX_BYTES $TX_BYTES" > $MONTHLY_LOG_FILE

# 生成消息内容
MESSAGE="[$DATE] 今日流量统计：\n上传流量: $TX_MB MB\n下载流量: $RX_MB MB\n总流量: $TOTAL_MB MB\n\n"
MESSAGE+="[$DATE] 本月累计流量统计：\n上传流量: $MONTHLY_TX_MB MB\n下载流量: $MONTHLY_RX_MB MB\n总流量: $MONTHLY_TOTAL_MB MB"

# 通过 curl 向 Telegram 发送消息
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d text="$MESSAGE"

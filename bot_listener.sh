#!/bin/bash

# 确保已设置 BOT_TOKEN 环境变量
if [ -z "$BOT_TOKEN" ]; then
    echo "BOT_TOKEN is not set!"
    exit 1
fi

# 获取 Telegram 更新
while true; do
    # 获取未处理的消息
    RESPONSE=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=-1")
    
    # 提取 chat_id 和消息文本
    CHAT_ID=$(echo $RESPONSE | jq -r '.result[0].message.chat.id')
    MESSAGE_TEXT=$(echo $RESPONSE | jq -r '.result[0].message.text')

    # 如果有消息，检查指令
    if [ "$MESSAGE_TEXT" == "/getTraffic" ]; then
        # 执行流量获取脚本
        /root/vps-traffic-monitor/get_traffic_info.sh
    fi

    # 每次检查后等待 2 秒，避免过度调用 API
    sleep 2
done

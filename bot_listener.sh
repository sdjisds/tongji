#!/bin/bash

# 确保 BOT_TOKEN 和 CHAT_ID 已设置
if [ -z "$BOT_TOKEN" ]; then
    echo "BOT_TOKEN is not set!" >> /root/bot_listener_debug.log
    exit 1
fi

# 获取 Telegram 更新
while true; do
    # 获取未处理的消息
    RESPONSE=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=-1")
    
    # 输出调试信息
    echo "Response from getUpdates: $RESPONSE" >> /root/bot_listener_debug.log

    # 提取 chat_id 和消息文本
    CHAT_ID=$(echo $RESPONSE | jq -r '.result[0].message.chat.id')
    MESSAGE_TEXT=$(echo $RESPONSE | jq -r '.result[0].message.text')

    # 输出收到的消息内容
    echo "Received message: $MESSAGE_TEXT" >> /root/bot_listener_debug.log

    # 检查消息是否为 /getTraffic
    if [ "$MESSAGE_TEXT" == "/getTraffic" ]; then
        echo "Command /getTraffic received, running get_traffic_info.sh..." >> /root/bot_listener_debug.log

        # 执行流量获取脚本并将结果发送到 Telegram
        /root/vps-traffic-monitor/get_traffic_info.sh "$CHAT_ID" >> /root/bot_listener_debug.log
    fi

    # 每次检查后等待 2 秒，避免过度调用 API
    sleep 2
done

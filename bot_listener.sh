#!/bin/bash

# 确保 BOT_TOKEN 和 CHAT_ID 已设置
if [ -z "$BOT_TOKEN" ]; then
    echo "BOT_TOKEN is not set!" >> /root/bot_listener_debug.log
    exit 1
fi

# 初始化 last_update_id 为 -1，表示没有处理任何消息
last_update_id=-1

# 获取 Telegram 更新
while true; do
    # 获取未处理的消息，使用 last_update_id 作为 offset
    RESPONSE=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=$((last_update_id + 1))")

    # 输出调试信息
    echo "Response from getUpdates: $RESPONSE" >> /root/bot_listener_debug.log

    # 提取 chat_id 和消息文本
    CHAT_ID=$(echo $RESPONSE | jq -r '.result[0].message.chat.id')
    MESSAGE_TEXT=$(echo $RESPONSE | jq -r '.result[0].message.text')
    UPDATE_ID=$(echo $RESPONSE | jq -r '.result[0].update_id')

    # 输出收到的消息内容
    echo "Received message: $MESSAGE_TEXT" >> /root/bot_listener_debug.log

    # 检查消息是否为 /getTraffic
    if [ "$MESSAGE_TEXT" == "/getTraffic" ]; then
        echo "Command /getTraffic received, running get_traffic_info.sh..." >> /root/bot_listener_debug.log

        # 执行流量获取脚本并将结果发送到 Telegram
        /root/vps-traffic-monitor/get_traffic_info.sh "$CHAT_ID" >> /root/bot_listener_debug.log
    fi

    # 确保我们只处理一次此消息，更新 last_update_id
    if [ -n "$UPDATE_ID" ]; then
        echo "Updating last_update_id to $UPDATE_ID" >> /root/bot_listener_debug.log
        last_update_id=$UPDATE_ID
    fi

    # 每次检查后等待 2 秒，避免过度调用 API
    sleep 2
done

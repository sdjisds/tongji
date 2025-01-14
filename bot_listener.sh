#!/bin/bash

# 确保 BOT_TOKEN 和 CHAT_ID 已设置
if [ -z "$BOT_TOKEN" ]; then
    echo "BOT_TOKEN is not set!" >> /root/bot_listener_debug.log
    exit 1
fi

# 持久化 last_update_id 存储路径
last_update_file="/root/.last_update_id"

# 如果文件不存在，初始化 last_update_id
if [ ! -f "$last_update_file" ]; then
    echo "Initializing last_update_id" >> /root/bot_listener_debug.log
    echo "0" > "$last_update_file"
fi

# 从文件中读取 last_update_id
last_update_id=$(cat "$last_update_file")

# 获取 Telegram 更新
while true; do
    # 获取未处理的消息，使用 last_update_id 作为 offset
    RESPONSE=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates?offset=$((last_update_id + 1))")

    # 输出调试信息，记录整个响应
    echo "Response from getUpdates: $RESPONSE" >> /root/bot_listener_debug.log

    # 检查返回的数据是否为空
    if [ "$(echo $RESPONSE | jq -r '.result')" == "null" ] || [ "$(echo $RESPONSE | jq -r '.result | length')" == "0" ]; then
        echo "No new updates." >> /root/bot_listener_debug.log
    else
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

        # 更新 last_update_id 并写入文件，确保不会重复处理相同的消息
        if [ -n "$UPDATE_ID" ]; then
            echo "Updating last_update_id to $UPDATE_ID" >> /root/bot_listener_debug.log
            echo "$UPDATE_ID" > "$last_update_file"
        fi
    fi

    # 每次检查后等待 2 秒，避免过度调用 API
    sleep 2
done

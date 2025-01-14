#!/bin/bash

# 确保 Telegram Bot Token 和 Chat ID 通过环境变量传递
if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    echo "请在运行时通过环境变量设置 BOT_TOKEN 和 CHAT_ID！"
    exit 1
fi

# 自动检测网卡
INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)

# 获取最新的 Telegram 消息（获取最新一条消息）
RESPONSE=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/getUpdates?limit=1&offset=-1")
COMMAND=$(echo "$RESPONSE" | jq -r '.result[0].message.text')

# 如果命令是 /get_traffic，则返回当前流量
if [[ "$COMMAND" == "/get_traffic" ]]; then
    # 获取当前的接收和发送字节数
    RX_BYTES=$(cat /proc/net/dev | grep "$INTERFACE" | tr : " " | awk '{print $2}')
    TX_BYTES=$(cat /proc/net/dev | grep "$INTERFACE" | tr : " " | awk '{print $10}')
    
    # 将字节数转换为MB
    RX_MB=$(echo "scale=2; $RX_BYTES/1024/1024" | bc)
    TX_MB=$(echo "scale=2; $TX_BYTES/1024/1024" | bc)
    TOTAL_MB=$(echo "scale=2; $RX_MB + $TX_MB" | bc)
    
    # 构建消息内容
    MESSAGE="当前流量信息：\n上传流量: $TX_MB MB\n下载流量: $RX_MB MB\n总流量: $TOTAL_MB MB"
    
    # 发送流量统计消息到 Telegram
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$MESSAGE"
fi

FROM alpine:latest
RUN apk add --no-cache wget tar gettext bash

WORKDIR /app

# 下载 sing-box 官方程序
RUN wget https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz && \
    tar -zxvf sing-box-1.10.1-linux-amd64.tar.gz && \
    mv sing-box-1.10.1-linux-amd64/sing-box . && \
    rm -rf sing-box-1.10.1-linux-amd64.tar.gz sing-box-1.10.1-linux-amd64

# 直接在 Dockerfile 中创建包含占位符的 config.json
RUN echo '{ \
  "log": { "level": "info" }, \
  "inbounds": [{ \
    "type": "vless", \
    "tag": "vless-in", \
    "listen": "::", \
    "listen_port": 443, \
    "users": [{ "uuid": "${UUID}" }], \
    "transport": { "type": "ws", "path": "/chat" } \
  }], \
  "outbounds": [{ "type": "direct", "tag": "direct" }] \
}' > config.json.template

EXPOSE 443
# 启动时生成最终的配置文件并运行
CMD ["sh", "-c", "export UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)} && echo \"Using UUID: $UUID\" && envsubst < config.json.template > config.json && ./sing-box run -c config.json"]

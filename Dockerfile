FROM alpine:latest
RUN apk add --no-cache wget tar bash grep sed

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
    "users": [{ "uuid": "PLACEHOLDER_UUID" }], \
    "transport": { "type": "ws", "path": "/chat" } \
  }], \
  "outbounds": [{ "type": "direct", "tag": "direct" }] \
}' > config.json

EXPOSE 443
# 启动时替换占位符并运行
CMD ["sh", "-c", "UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)} && echo \"Using UUID: $UUID\" && sed -i \"s/PLACEHOLDER_UUID/$UUID/g\" config.json && ./sing-box run -c config.json"]

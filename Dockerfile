FROM alpine:latest
RUN apk add --no-cache wget tar gettext curl
WORKDIR /app
# 下载 sing-box 官方程序
RUN wget https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz && \
    tar -zxvf sing-box-1.10.1-linux-amd64.tar.gz && \
    mv sing-box-1.10.1-linux-amd64/sing-box . && \
    rm -rf sing-box-1.10.1-linux-amd64*

COPY config.json.tmpl .

RUN echo '#!/bin/sh\n\
UUID=$(cat /proc/sys/kernel/random/uuid)\n\
PORT=8080\n\
sed "s/\${UUID}/$UUID/g; s/\${PORT}/$PORT/g" config.json.tmpl > config.json\n\
echo "================================"\n\
echo "VLESS Configuration:"\n\
echo "Server: $(curl -s ifconfig.me 2>/dev/null || echo \"YOUR_SERVER_IP\")"\n\
echo "Port: $PORT"\n\
echo "UUID: $UUID"\n\
echo "Client Link:"\n\
echo "vless://$UUID@$(curl -s ifconfig.me 2>/dev/null):$PORT?path=/chat&security=none&type=ws#VLESS_WS"\n\
echo "================================"\n\
exec ./sing-box run -c config.json' > /app/start.sh && \
chmod +x /app/start.sh

EXPOSE 8080
CMD ["/app/start.sh"]

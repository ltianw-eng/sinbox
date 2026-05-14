FROM alpine:latest

RUN apk add --no-cache wget tar curl openssl

WORKDIR /app

# 下载 sing-box
RUN wget -q https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz && \
    tar -zxf sing-box-1.10.1-linux-amd64.tar.gz && \
    mv sing-box-1.10.1-linux-amd64/sing-box . && \
    rm -rf sing-box-1.10.1-linux-amd64*

# 复制配置模板
COPY config.json.tmpl .

# 生成私钥和公钥的脚本
RUN printf '#!/bin/sh\n\
# 生成 Reality 密钥对\n\
KEYPAIR_OUTPUT=$(./sing-box generate reality-keypair)\n\
PRIVATE_KEY=$(echo "$KEYPAIR_OUTPUT" | grep "PrivateKey" | cut -d: -f2 | xargs)\n\
PUBLIC_KEY=$(echo "$KEYPAIR_OUTPUT" | grep "PublicKey" | cut -d: -f2 | xargs)\n\
SHORT_ID=$(openssl rand -hex 8)\n\
UUID=$(cat /proc/sys/kernel/random/uuid)\n\
\n\
DOMAIN="${DOMAIN:-www.intel.com}"\n\
SERVER_NAME="${SERVER_NAME:-www.intel.com}"\n\
HANDSHAKE_SERVER="${HANDSHAKE_SERVER:-www.intel.com}"\n\
HANDSHAKE_PORT="${HANDSHAKE_PORT:-443}"\n\
LISTEN_PORT="${LISTEN_PORT:-1443}"\n\
\n\
# 生成配置文件\n\
sed "s/\${UUID}/$UUID/g; s/\${PRIVATE_KEY}/$PRIVATE_KEY/g; s/\${SHORT_ID}/$SHORT_ID/g; s/\${DOMAIN}/$DOMAIN/g; s/\${SERVER_NAME}/$SERVER_NAME/g; s/\${HANDSHAKE_SERVER}/$HANDSHAKE_SERVER/g; s/\${HANDSHAKE_PORT}/$HANDSHAKE_PORT/g; s/\${LISTEN_PORT}/$LISTEN_PORT/g" config.json.tmpl > config.json\n\
\n\
# 获取服务器 IP（仅用于显示）\n\
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "your-domain.com")\n\
\n\
echo "================================"\n\
echo "Reality Configuration:"\n\
echo "UUID: $UUID"\n\
echo "Domain: $DOMAIN"\n\
echo "Server Name: $SERVER_NAME"\n\
echo "Handshake: $HANDSHAKE_SERVER:$HANDSHAKE_PORT"\n\
echo "Short ID: $SHORT_ID"\n\
echo "Public Key: $PUBLIC_KEY"\n\
echo "Listen Port: $LISTEN_PORT"\n\
echo "Client Link:"\n\
echo "vless://$UUID@$SERVER_IP:$LISTEN_PORT?security=reality&pbk=$PUBLIC_KEY&sid=$SHORT_ID&sni=$SERVER_NAME&flow=&type=tcp#Reality"\n\
echo "================================"\n\
\n\
exec ./sing-box run -c config.json' > start.sh && \
    chmod +x start.sh

EXPOSE 1443
CMD ["./start.sh"]

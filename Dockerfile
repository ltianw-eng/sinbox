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
PRIVATE_KEY=$(./sing-box generate reality-keypair | grep "PrivateKey" | cut -d: -f2 | xargs)\n\
PUBLIC_KEY=$(./sing-box generate reality-keypair | grep "PublicKey" | cut -d: -f2 | xargs)\n\
SHORT_ID=$(openssl rand -hex 8)\n\
UUID=$(cat /proc/sys/kernel/random/uuid)\n\
\n\
DOMAIN="${DOMAIN:-auto}"\n\
\n\
# 生成配置文件\n\
if [ "$DOMAIN" != "auto" ]; then\n\
  # 使用自定义域名\n\
  sed "s/\${UUID}/$UUID/g; s/\${PRIVATE_KEY}/$PRIVATE_KEY/g; s/\${SHORT_ID}/$SHORT_ID/g; s/\${DOMAIN}/$DOMAIN/g" config.json.tmpl > config.json\n\
  echo "================================"\n\
  echo "Reality Configuration (Custom Domain):"\n\
  echo "Domain: $DOMAIN"\n\
  echo "UUID: $UUID"\n\
  echo "Short ID: $SHORT_ID"\n\
  echo "Public Key: $PUBLIC_KEY"\n\
  echo "Client Link:"\n\
  echo "vless://$UUID@$DOMAIN:443?security=reality&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&sni=$DOMAIN#Reality_TCP"\n\
  echo "================================"\n\
else\n\
  # 使用服务器 IP\n\
  SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "SERVER_IP")\n\
  sed "s/\${UUID}/$UUID/g; s/\${PRIVATE_KEY}/$PRIVATE_KEY/g; s/\${SHORT_ID}/$SHORT_ID/g; s/\${DOMAIN}/$SERVER_IP/g" config.json.tmpl > config.json\n\
  echo "================================"\n\
  echo "Reality Configuration (IP Mode):"\n\
  echo "Server IP: $SERVER_IP"\n\
  echo "UUID: $UUID"\n\
  echo "Short ID: $SHORT_ID"\n\
  echo "Public Key: $PUBLIC_KEY"\n\
  echo "Client Link:"\n\
  echo "vless://$UUID@$SERVER_IP:443?security=reality&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&sni=$DOMAIN#Reality_TCP"\n\
  echo "================================"\n\
fi\n\
\n\
exec ./sing-box run -c config.json' > start.sh && \
    chmod +x start.sh

EXPOSE 443
CMD ["./start.sh"]

#FROM alpine:latest
#RUN apk add --no-cache wget tar gettext curl
#WORKDIR /app
# 下载 sing-box 官方程序
#RUN wget https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz && \
#    tar -zxvf sing-box-1.10.1-linux-amd64.tar.gz && \
#    mv sing-box-1.10.1-linux-amd64/sing-box . && \
#    rm -rf sing-box-1.10.1-linux-amd64*
#COPY config.json.tmpl .

#RUN printf '#!/bin/sh\n\
#UUID=$(cat /proc/sys/kernel/random/uuid)\n\
#sed "s/\${UUID}/$UUID/g" config.json.tmpl > config.json\n\
#echo "================================"\n\
#echo "VLESS Configuration:"\n\
#echo "Server: $(curl -s ifconfig.me 2>/dev/null || echo \"YOUR_SERVER_IP\")"\n\
#echo "Port: $PORT"\n\
#echo "UUID: $UUID"\n\
#echo "Client Link:"\n\
#echo "vless://$UUID@$(curl -s ifconfig.me 2>/dev/null):$PORT?path=/chat&security=none&type=ws#VLESS_WS"\n\
#echo "================================"\n\
#exec ./sing-box run -c config.json' > /app/start.sh && \
#chmod +x /app/start.sh
#EXPOSE 8080
# 建议使用绝对路径
#CMD ["/bin/sh", "/app/start.sh"]

FROM alpine:latest
RUN apk add --no-cache wget tar curl acme.sh
WORKDIR /app

# 下载 sing-box
RUN wget -q https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz && \
    tar -zxf sing-box-1.10.1-linux-amd64.tar.gz && \
    mv sing-box-1.10.1-linux-amd64/sing-box . && \
    rm -rf sing-box-1.10.1-linux-amd64*
COPY config.json.tmpl .
# 创建启动脚本（支持 TLS 证书申请和更新）
RUN printf '#!/bin/sh\n\
UUID=$(cat /proc/sys/kernel/random/uuid)\n\
DOMAIN="$DOMAIN"\n\
EMAIL="$EMAIL"\n\
\n\
if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then\n\
  echo "Error: Please set DOMAIN and EMAIL environment variables"\n\
  echo "Usage: docker run -e DOMAIN=example.com -e EMAIL=your@email.com ..."\n\
  exit 1\n\
fi\n\
\n\
# 准备证书目录\n\
mkdir -p /certs\n\
\n\
# 申请或更新证书\n\
echo "Applying for certificate for $DOMAIN..."\n\
acme.sh --issue -d "$DOMAIN" --standalone --email "$EMAIL" --keylength ec-256 --force\n\
\n\
# 安装证书\n\
acme.sh --install-cert -d "$DOMAIN" \
  --key-file /certs/private.key \
  --fullchain-file /certs/cert.crt\n\
\n\
# 生成配置文件\n\
if [ "$TLS_ENABLED" = "true" ]; then\n\
  sed "s/\${UUID}/$UUID/g; s/\${DOMAIN}/$DOMAIN/g; s/\${CERT_PATH}/\/certs\/cert.crt/g; s/\${KEY_PATH}/\/certs\/private.key/g" config.json.tmpl > config.json\n\
  echo "TLS mode enabled for domain: $DOMAIN"\n\
else\n\
  # 降级到 HTTP 模式\n\
  sed "s/\${UUID}/$UUID/g; s/\${DOMAIN}//g; s/\"server_name\": \"\${DOMAIN}\",//g; s/\"certificate_path\": \"\${CERT_PATH}\",//g; s/\"key_path\": \"\${KEY_PATH}\"/\"key_path\": \"\"/g" config.json.tmpl > config.json\n\
  echo "HTTP mode enabled"\n\
fi\n\
\n\
echo "Generated UUID: $UUID"\n\
echo "Domain: $DOMAIN"\n\
exec ./sing-box run -c config.json' > start.sh && \
    chmod +x start.sh

EXPOSE 443 8080
CMD ["./start.sh"]

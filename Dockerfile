FROM alpine:latest

RUN apk add --no-cache wget tar curl openssl

WORKDIR /app

# 下载并解压 sing-box
RUN wget -q https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz && \
    tar -zxf sing-box-1.10.1-linux-amd64.tar.gz && \
    mv sing-box-1.10.1-linux-amd64/sing-box . && \
    rm -rf sing-box-1.10.1-linux-amd64*   # ← 只删解压目录，不删当前目录文件！

COPY config.json.tmpl .

RUN printf '#!/bin/sh\n\
UUID=$(cat /proc/sys/kernel/random/uuid)\n\
KEYPAIR=$(./sing-box generate reality-keypair)\n\
PRIVATE_KEY=$(echo "$KEYPAIR" | grep PrivateKey | cut -d: -f2 | xargs)\n\
PUBLIC_KEY=$(echo "$KEYPAIR" | grep PublicKey | cut -d: -f2 | xargs)\n\
SHORT_ID=$(openssl rand -hex 8)\n\
\n\
sed "s/\${UUID}/$UUID/g; s/\${PRIVATE_KEY}/$PRIVATE_KEY/g; s/\${SHORT_ID}/$SHORT_ID/g" config.json.tmpl > config.json\n\
\n\
echo "================================"\n\
echo "✅ Ready: Reality on 1443"\n\
echo "UUID: $UUID"\n\
echo "Public Key: $PUBLIC_KEY"\n\
echo "Short ID: $SHORT_ID"\n\
echo "SNI: www.microsoft.com"\n\
echo "Client: vless://$UUID@yamanote.proxy.rlwyt.net:25247?security=reality&pbk=$PUBLIC_KEY&sid=$SHORT_ID&sni=sinbox-production.up.railway.app&type=tcp"\n\
echo "================================"\n\
\n\
exec ./sing-box run -c config.json' > start.sh && chmod +x start.sh

EXPOSE 1443
CMD ["./start.sh"]

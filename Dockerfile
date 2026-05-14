FROM alpine:latest
RUN apk add --no-cache wget tar curl openssl
WORKDIR /app
RUN wget -q https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz && \
    tar -zxf sing-box-1.10.1-linux-amd64.tar.gz && \
    mv sing-box-1.10.1-linux-amd64/sing-box . && \
    rm -rf sing-box-1.10.1-linux-amd64*
COPY config.json.tmpl .
RUN printf '#!/bin/sh
UUID=$(cat /proc/sys/kernel/random/uuid)
KEYPAIR=$(./sing-box generate reality-keypair)
PRIVATE_KEY=$(echo "$KEYPAIR" | grep PrivateKey | cut -d: -f2 | xargs)
PUBLIC_KEY=$(echo "$KEYPAIR" | grep PublicKey | cut -d: -f2 | xargs)
SHORT_ID=$(openssl rand -hex 8)
sed "s/\${UUID}/$UUID/g; s/\${PRIVATE_KEY}/$PRIVATE_KEY/g; s/\${SHORT_ID}/$SHORT_ID/g" config.json.tmpl > config.json
echo "UUID:$UUID PK:$PUBLIC_KEY SID:$SHORT_ID"\nexec ./sing-box run -c config.json' > start.sh && chmod +x start.sh
EXPOSE 1443
CMD ["./start.sh"]

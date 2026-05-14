FROM alpine:latest

RUN apk add --no-cache wget tar curl openssl

WORKDIR /app

# 下载并解压 sing-box
RUN printf '#!/bin/sh\n\
set -eu\n\
UUID=$(cat /proc/sys/kernel/random/uuid)\n\
\n\
# 关键：捕获 stderr（sing-box 输出密钥到 stderr！）\n\
KEYPAIR=$(/app/sing-box generate reality-keypair 2>&1 >/dev/null)\n\
\n\
# 调试：强制输出原始 KEYPAIR（用于排查）\n\
echo "RAW KEYPAIR:" >&2\n\
echo "$KEYPAIR" | sed "s/\x1b\\[[0-9;]*m//g" >&2\n\
\n\
# 安全提取：用 awk 按行匹配，忽略空格和颜色\n\
PRIVATE_KEY=$(echo "$KEYPAIR" | sed "s/\x1b\\[[0-9;]*m//g" | awk -F": " \'/PrivateKey/ {gsub(/^[ \\t]+|[ \\t]+$/, ""); print $2; exit}\')\n\
PUBLIC_KEY=$(echo "$KEYPAIR" | sed "s/\x1b\\[[0-9;]*m//g" | awk -F": " \'/PublicKey/ {gsub(/^[ \\t]+|[ \\t]+$/, ""); print $2; exit}\')\n\
SHORT_ID=$(openssl rand -hex 8)\n\
\n\
# 强制校验（非空）\n\
if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then\n\
  echo "❌ ERROR: Failed to extract keys! PRIVATE_KEY=[${PRIVATE_KEY}], PUBLIC_KEY=[${PUBLIC_KEY}]" >&2\n\
  echo "RAW OUTPUT:" >&2\n\
  echo "$KEYPAIR" >&2\n\
  exit 1\n\
fi\n\
\n\
sed "s/\${UUID}/$UUID/g; s/\${PRIVATE_KEY}/$PRIVATE_KEY/g; s/\${SHORT_ID}/$SHORT_ID/g" config.json.tmpl > config.json\n\
\n\
echo "✅ UUID: $UUID" >&2\n\
echo "✅ Public Key: $PUBLIC_KEY" >&2\n\
echo "✅ Short ID: $SHORT_ID" >&2\n\
echo "Client: vless://$UUID@yamanote.proxy.rlwyt.net:25247?security=reality&pbk=$PUBLIC_KEY&sid=$SHORT_ID&sni=sinbox-production.up.railway.app&type=tcp" >&2\n\
\n\
exec /app/sing-box run -c config.json' > start.sh && chmod +x start.sh

EXPOSE 1443
CMD ["./start.sh"]

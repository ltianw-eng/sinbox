FROM alpine:latest

# 安装必要的工具
RUN apk add --no-cache wget tar curl openssl bash

WORKDIR /app

# 下载并解压 sing-box
RUN wget -qO- https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz | \
    tar -xz && \
    mv sing-box-1.10.1-linux-amd64/sing-box . && \
    rm -rf sing-box-1.10.1-linux-amd64*

COPY config.json.tmpl .

# 创建启动脚本
RUN printf '#!/bin/bash\n\
\n\
# 获取 Railway 分配的端口，默认为 8080\n\
export PORT=${PORT:-8080}\n\
\n\
# 生成必要的 UUID\n\
UUID=$(cat /proc/sys/kernel/random/uuid)\n\
\n\
# 替换模板中的变量\n\
sed "s/\\${UUID}/$UUID/g; s/\\${PORT}/$PORT/g" config.json.tmpl > config.json\n\
\n\
# 显示连接信息\n\
echo "================================"\n\
echo "✅ Sing-box WebSocket Ready"\n\
echo "Port: $PORT"\n\
echo "UUID: $UUID"\n\
echo "Path: /ws"\n\
echo "================================"\n\
\n\
# 运行 sing-box\n\
exec ./sing-box run -c config.json' > start.sh && chmod +x start.sh

EXPOSE 8080
CMD ["./start.sh"]

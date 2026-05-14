FROM alpine:latest
RUN apk add --no-cache wget tar gettext bash # 添加 gettext 和 bash

WORKDIR /app
# 下载 sing-box 官方程序
RUN wget https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.tar.gz && \
    tar -zxvf sing-box-1.10.1-linux-amd64.tar.gz && \
    mv sing-box-1.10.1-linux-amd64/sing-box . && \
    rm -rf sing-box-1.10.1-linux-amd64*

COPY config.json . # 复制包含占位符的 config.json

EXPOSE 443
# 使用 bash -c 来允许 shell 展开和命令组合
CMD ["sh", "-c", "export UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)} && envsubst < config.json > temp_config.json && ./sing-box run -c temp_config.json"]

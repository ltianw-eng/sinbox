# 复制模板文件
COPY config.json.tmpl start.sh.tmpl /app/

# 安装 envsubst（Alpine 需要）
RUN apk add --no-cache gettext

# 构建时：仅复制文件，不生成脚本
# 启动时由 start.sh.tmpl 动态生成 start.sh
CMD ["/app/start.sh"]

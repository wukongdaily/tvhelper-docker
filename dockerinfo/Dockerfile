# 使用Alpine Linux作为基础镜像
FROM alpine:latest

# 安装ADB、Bash、Curl以及OpenSSH服务
RUN apk update && apk add --no-cache android-tools bash curl openssh libqrencode-tools \
    && rm -rf /var/cache/apk/*

# 配置SSH服务
RUN echo "root:password" | chpasswd \
    && ssh-keygen -A \
    && echo "cd /tvhelper/shells" >> /root/.profile \
    && echo 'export PATH="$PATH:/usr/lib/android-sdk/platform-tools"' >> /root/.profile


RUN git clone https://github.com/wukongdaily/tvhelper-docker.git /tvhelper

# 为 /tvhelper/shells 目录下所有.sh文件设置可执行权限
RUN find /tvhelper/shells -type f -iname "*.sh" -exec chmod +x {} \;

# 设置SSH服务以允许远程登录
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 开放22端口用于SSH连接
EXPOSE 22

# 设置工作目录
WORKDIR /tvhelper/shells

# 创建并设置启动脚本
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 使用start.sh作为容器的启动命令
CMD ["/start.sh"]

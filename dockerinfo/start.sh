#!/bin/bash

# 启动SSH服务
/usr/sbin/sshd

# 启动ADB server
adb start-server

# 保持容器运行
tail -f /dev/null
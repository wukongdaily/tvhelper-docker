# 盒子助手Docker版 V1.1.4
![拉取次数](https://img.shields.io/badge/Docker%20拉取次数-50k+-FF9900?&logo=docker&logoColor=blue&labelColor=000000&style=for-the-badge)
[![Bilibili](https://img.shields.io/badge/Bilibili-123456?logo=bilibili&logoColor=fff&labelColor=fb7299&style=for-the-badge)](https://www.bilibili.com/video/BV1ChhdztEfZ/)
[![YouTube](https://img.shields.io/badge/YouTube-123456?logo=youtube&labelColor=ff0000&style=for-the-badge)](https://youtu.be/DKFRZ8wevMo)
## 🤔 这是什么？

该项目可以让你使用电脑、NAS等一切能运行docker的设备变成盒子的ADB安装助手。让你的盒子用起来更加得心应手。<br>

## 💡 特色功能

- 💻 支持`一键修改安卓原生电视盒子/TV的NTP服务器地址`
- 💻 支持`一键安装/data目录下所有apk/xapk/apkm (适合流媒体app)`
- 💻 支持`SSH连接 且容器内ADB服务均已准备就绪,无需额外安装`
- 🔑 支持`安装装机必备app 尤其是文件管理器和三方市场、图标等`
- 🐋 支持`Docker compose和 docker cli`一键部署
- 📕 支持`为国行Sony电视安装时下流行的流媒体应用`
- ❓ 兼容`ARMv7/ARM64/x86_64 双平台设备
- ❓ 其他功能和特点会持续迭代
- MacOS(Apple芯片/Intel芯片)✅
- Windows 10/11 ✅
- Linux发行版 ✅
- NAS系统（群晖、威联通等）✅
- 软路由iStoreOS/OpenWrt/ImmortalWrt/eSir_OpenWrt等一切能用docker的op系统 ✅


## 🚀 快速上手

### 1. 安装`Docker`和`Docker compose`

- `Docker`安装教程：[https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/)
- `Docker compose`安装教程：[https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/)
- `个人普通电脑`安装教程：https://docs.docker.com/get-docker/
- docker 根目录剩余空间 至少大于1GB 


### 2. 下载image（多平台统一）

```bash
docker pull wukongdaily/box:latest
```

### 3. 容器系统默认账号密码或环境变量

- 容器内运行的就是Ubuntu系统。
- ssh用户名和密码分别是：`root`和`password` 
- 推荐ssh端口映射到主机端口为2299。
- 推荐把/data映射到宿主机某个目录 方便上传apk或xapk、apkm
- 注意！映射ssh端口这一步并非是必须的，如果你需要用ssh连接容器则自行设置。
- 根据自己的需求来映射，2299也不是固定的，映射的端口号多少都可以，只要跟主机不冲突即可。<br>
> 调用形式举例

`ssh root@宿主机ip地址 -p 2299`

> SSH常见错误举例和新手指南详见

https://github.com/wukongdaily/HowToUseSSH <br>
- 容器内的环境变量
- `PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/android-sdk/platform-tools`


### 4. 运行
- Windows电脑使用-CMD写法,注意不是powershell 且注意💡续行符^后不能有空格。数据目录默认映射到 【我的文档】
```bash
docker run -d ^
--restart unless-stopped ^
--name tvhelper ^
-p 2299:2299 ^
-p 2280:2280 ^
-p 15000:15000 ^
-v "%USERPROFILE%\Documents\tvhelper_data:/data" ^
-e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/android-sdk/platform-tools ^
wukongdaily/box:latest

```
- Linux 使用下列命令,数据目录默认映射到linux的`/tmp/upload/`下
```bash
docker run -d \
  --restart unless-stopped \
  --name tvhelper \
  -p 2299:2299 \
  -p 2280:2280 \
  -p 15000:15000 \
  -v "/tmp/upload/tvhelper_data:/data" \
  -e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/android-sdk/platform-tools \
  wukongdaily/box:latest
```
- macOS苹果电脑写法,数据目录默认映射到mac电脑文稿目录下
```bash
docker run -d \
  --restart unless-stopped \
  --name tvhelper \
  -p 2299:2299 \
  -p 2280:2280 \
  -p 15000:15000 \
  -v "$HOME/Documents/tvhelper_data:/data" \
  -e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/android-sdk/platform-tools \
  wukongdaily/box:latest
```

- UNRAID 写法,注意容器内的data目录默认映射到 /mnt/user/appdata/，你可以适当修改成别的空间的路径。
```bash
docker run -d \
  --name='tvhelper' \
  --net='bridge' \
  -e HOST_OS="Unraid" \
  -e HOST_HOSTNAME="unraid" \
  -e HOST_CONTAINERNAME="tvhelper" \
  -e 'PATH'='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/android-sdk/platform-tools' \
  -l net.unraid.docker.managed=dockerman \
  -p '2299:2299/tcp' \
  -p '2280:2280/tcp' \
  -p '15000:15000/tcp' \
  -v '/mnt/user/appdata/':'/tvhelper/shells/data':'rw' 'wukongdaily/box'
```


## CasaOS docker compose
```bash
version: '3.8'  # 使用docker-compose文件版本3.8

services:
  tvhelper:
    build: .  # 构建Dockerfile所在的当前目录
    image: wukongdaily/box:latest  # 指定构建完成后的镜像名称和标签
    ports:
      - "2299:2299"  # 用于ssh
      - "2280:2280"  # 用于重定向到盒子助手资讯页
      - "15000:15000"  # 将容器的15000端口映射到宿主机的15000端口，以便通过浏览器dufs文件服务器 上传xapk或者apk 
    volumes:
      - /tmp/upload/tvhelper_data:/data  # 根据需要映射数据卷，此处假设您希望持久化的数据位于./data目录
    restart: unless-stopped  # 除非明确要求停止，否则总是重启容器
    environment:
      - PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/android-sdk/platform-tools

```

### 5. 如何导入本地镜像tar
- 若需离线包 可在工作流里自行构建 fork该项目后 在action中构建即可 几秒后就构建成功 在release中下载离线包
https://github.com/wukongdaily/DockerTarBuilder/
- docker离线包的格式是tar.gz 通常无需解压 docker load的过程就会解压了。

#### Windows 举例
```bash
docker load < "%USERPROFILE%\Documents\tvhelper-amd64.tar.gz"
```

#### Linux/OpenWrt 举例
```bash
docker load < /mnt/sata1.3-1/tvhelper.tar.gz
```

### 辅助视频教程⬇️

[在线教学视频 长视频](https://youtu.be/xAk-3TxeXxQ)



## 🗂️ 鸣谢

本项目的开发参照了以下项目，感谢这些开源项目的作者：
### DUFS
https://github.com/sigoden/dufs
### TVBox
https://github.com/takagen99/Box
### Sun-Panel
https://github.com/hslr-s/sun-panel

## ❤️用真金白银鼓励作者

[![点击这里赞助我](https://img.shields.io/badge/点击这里赞助我-支持作者的项目-orange?logo=github&style=for-the-badge)](https://wkdaily.cpolar.cn/01)

https://wkdaily.cpolar.cn/01

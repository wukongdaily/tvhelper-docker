# 盒子助手Docker版
[![docker pulls](https://img.shields.io/docker/pulls/wukongdaily/box.svg?logo=docker)](https://hub.docker.com/r/wukongdaily/box)
<img src="https://badges.toozhao.com/badges/01JDKPTDXFQYYWHEPS32QSD4XT/green.svg" />
[![Bilibili](https://img.shields.io/badge/Bilibili-123456?logo=bilibili&logoColor=fff&labelColor=fb7299)](https://www.bilibili.com/video/BV1Rm411o78P)
[![YouTube](https://img.shields.io/badge/YouTube-123456?logo=youtube&labelColor=ff0000)](https://youtu.be/xAk-3TxeXxQ)

## 🤔 这是什么？

该项目可以让你使用电脑、NAS等一切能运行docker的设备变成盒子的ADB安装助手。让你的盒子用起来更加得心应手。<br>
另外【OpenWrt版本盒子助手命令行】可以[点击这里直达](https://github.com/wukongdaily/tvhelper)
## 💡 特色功能

- 💻 支持`一键修改安卓原生电视盒子/TV的NTP服务器地址`
- 💻 支持`SSH连接 且容器内ADB服务均已准备就绪,无需额外安装`
- 🔑 支持`安装装机必备app 尤其是文件管理器和三方市场、图标等`
- 🌏 支持`一键批量安装主机上指定目录的全部apk`
- 🐋 支持`Docker compose和 docker cli`一键部署
- 📕 支持`为国行Sony电视安装时下流行的流媒体应用`
- ❓ 兼容`ARMv7/ARM64/x86_64 双平台设备
- ❓ 其他功能和特点会持续迭代
- MacOS(Apple芯片/Intel芯片)✅
- Windows 10/11 ✅
- Linux发行版 ✅
- NAS系统（群晖、威联通等）✅
- 软路由iStoreOS/OpenWrt ✅


## 🚀 快速上手

### 1. 安装`Docker`和`Docker compose`

- `Docker`安装教程：[https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/)
- `Docker compose`安装教程：[https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/)
- `个人普通电脑`安装教程：https://docs.docker.com/get-docker/
- `docker镜像主页` https://hub.docker.com/r/wukongdaily/box

### 2. 下载image

```bash
docker pull wukongdaily/box:latest
```
#### 国内使用⬇️ 可用该项目构建离线包
https://github.com/wukongdaily/DockerTarBuilder
- 盒子助手docker版 离线包
[国内下载地址(x86-64)](https://slink.ltd/https://github.com/wukongdaily/DockerTarBuilder/releases/download/DockerTarBuilder-AMD64/wukongdaily_box-amd64.tar.gz)

### 3. 容器系统默认账号密码或环境变量

- 容器内运行的就是alpine linux系统。
- ssh用户名和密码分别是：`root`和`password` 
- 推荐ssh端口映射到主机端口为2299。
- 注意！映射ssh端口这一步并非是必须的，如果你需要用ssh连接容器则自行设置。
- 根据自己的需求来映射，2299也不是固定的，映射的端口号多少都可以，只要跟主机不冲突即可。<br>
> 调用形式举例

`ssh root@宿主机ip地址 -p 2299`

> SSH常见错误举例和新手指南详见

https://github.com/wukongdaily/HowToUseSSH <br>
- 容器内的环境变量
- `PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/android-sdk/platform-tools`


### 4. 运行
# 飞牛NAS
https://www.bilibili.com/video/BV1gCTYzmEnA

```
version: '3.8'

services:
  tvhelper:
    image: wukongdaily/box:latest
    container_name: tvhelper
    restart: unless-stopped
    ports:
      - "2299:22"
      - "2288:80"
    volumes:
      - /vol1/1000/xapks:/data
    environment:
      - PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/android-sdk/platform-tools
```
# 威联通NAS
- https://www.acfun.cn/v/ac47408924
- https://www.youtube.com/watch?v=HUDyV_0-b88
```
version: '3.8'

services:
  tvhelper:
    image: wukongdaily/box:latest
    container_name: tvhelper
    restart: unless-stopped
    ports:
      - "10022:22"
      - "10080:80"
    volumes:
      - /share/Public/xapks:/data:ro
    environment:
      - PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/android-sdk/platform-tools
```
# 群晖NAS
https://www.bilibili.com/video/BV1YRTrzGEkc
# Windows
- win电脑使用-CMD写法,注意不是powershell 且注意💡续行符^后不能有空格。数据目录默认映射到 【我的文档】
```bash
docker run -d ^
--restart unless-stopped ^
--name tvhelper ^
-p 2299:22 ^
-p 2288:80 ^
-v "%USERPROFILE%\Documents\tvhelper_data:/data" ^
-e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/android-sdk/platform-tools ^
wukongdaily/box:latest

```
# Linux
- Linux（iStoreOS/OpenWrt路由器） 使用下列命令,数据目录默认映射到linux的`/tmp/upload/`下
```bash
docker run -d \
  --restart unless-stopped \
  --name tvhelper \
  -p 2299:22 \
  -p 2288:80 \
  -v "/tmp/upload:/data" \
  -e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/android-sdk/platform-tools \
  wukongdaily/box:latest
```

```bash
 -v "/tmp/upload:/data" \
# 这目录是用来存放apk的，对应脚本里的批量安装apk的功能。如果你要使用该功能，你就关注一下映射的目录。
# 若不需要修改，则默认用/tmp/upload 目录来存放apk/xapk，你可以将需要安装的apk/xapk复制到该目录下即可。
```

![menu](https://github.com/user-attachments/assets/69767c8d-e890-4324-8c70-a247bb25ed9b)

![yuansheng](https://github.com/user-attachments/assets/3c23a2dd-a779-45ea-9fee-4914ff369f2a)


![sony](https://github.com/user-attachments/assets/a57eaef2-4676-493d-9e1a-b97cf872df29)

# macOS
- 苹果电脑写法,数据目录默认映射到mac电脑文稿目录下
```bash
docker run -d \
  --restart unless-stopped \
  --name tvhelper \
  -p 2299:22 \
  -p 2288:80 \
  -v "$HOME/Documents/tvhelper_data:/data" \
  -e PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/android-sdk/platform-tools \
  wukongdaily/box:latest
```

# UNRAID
- unraid写法,注意容器内的data目录默认映射到 /mnt/user/appdata/，你可以适当修改成别的空间的路径。
```bash
docker run -d \
  --name='tvhelper' \
  --net='bridge' \
  -e HOST_OS="Unraid" \
  -e HOST_HOSTNAME="unraid" \
  -e HOST_CONTAINERNAME="tvhelper" \
  -e 'PATH'='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/android-sdk/platform-tools' \
  -l net.unraid.docker.managed=dockerman \
  -p '2299:22/tcp' \
  -p '2288:80/tcp' \
  -v '/mnt/user/appdata/':'/data':'rw' 'wukongdaily/box'
```
- UNRAID 方法2 ,利用模版,打开UNRAID 命令行 粘贴
```bash
wget -O /boot/config/plugins/dockerMan/templates-user/wukongdaily-box-template.xml  https://gitee.com/wukongdaily/tvhelper-docker/raw/master/dockerinfo/unraid-template.xml

```
下载成功之后，新建容器，选择模版————`wukongdaily-box-template` 即可.如图<br>
![123](https://github.com/wukongdaily/tvhelper-docker/assets/143675923/23a5cdd2-9e76-4bb3-a62e-eaeffc85b986)

## CasaOS docker compose
```bash
version: '3.8'  # 使用docker-compose文件版本3.8

services:
  tvhelper:
    build: .  # 构建Dockerfile所在的当前目录
    image: wukongdaily/box:latest  # 指定构建完成后的镜像名称和标签
    ports:
      - "2299:22"  # 将容器的22端口映射到宿主机的2299端口，以便通过SSH访问
      - "2288:80"  # 将容器的80端口映射到宿主机的2288端口，以便通过浏览器webUI
    volumes:
      - /tmp/upload/tvhelper_data:/data  # 根据需要映射数据卷，此处假设您希望持久化的数据位于./data目录
    restart: unless-stopped  # 除非明确要求停止，否则总是重启容器
    environment:
      - PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/android-sdk/platform-tools

```

### 5. 如何导入本地镜像tar.gz
- 盒子助手docker版 离线包
[国内下载地址(x86-64)](https://slink.ltd/https://github.com/wukongdaily/DockerTarBuilder/releases/download/DockerTarBuilder-AMD64/wukongdaily_box-amd64.tar.gz)

# 如何获得最新版离线包
https://github.com/wukongdaily/DockerTarBuilder

#### Windows 举例
```bash
docker load < "%USERPROFILE%\Documents\tvhelper-amd64.tar"
```

#### Linux/OpenWrt 举例
```bash
docker load < /mnt/sata1.3-1/myboxarm.tar
```

### 辅助视频教程⬇️

[在线教学视频 长视频](https://youtu.be/xAk-3TxeXxQ)

## 🗂️ 鸣谢

本项目的开发参照了以下项目，感谢这些开源项目的作者：
### my-tv
https://github.com/yaoxieyoulei/mytv-android
### BBLL
https://github.com/xiaye13579/BBLL
### TVBox
https://github.com/takagen99/Box
### Sun-Panel
https://github.com/hslr-s/sun-panel

# web页截图
[![盒子助手v1 0 8 2024-11-19 14-03-45](https://github.com/user-attachments/assets/ac8c50bb-83c6-4d04-ab9f-3d3f45becf95)](https://tvhelper.cpolar.top/)
## ❤️赞助作者 ⬇️⬇️

[![点击这里赞助我](https://img.shields.io/badge/点击这里赞助我-支持作者的项目-orange?logo=github)](https://wkdaily.cpolar.top/01)


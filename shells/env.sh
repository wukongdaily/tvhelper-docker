#!/bin/sh
# MT3000/2500/6000 没有bash 需要先安装
# wget -O env.sh https://raw.githubusercontent.com/wukongdaily/tvhelper/master/shells/env.sh && chmod +x env.sh && ./env.sh
check_bash_installed() {
  if [ -x "/bin/bash" ]; then
    echo "downloading tv.sh ......"
  else
    echo "install bash env ......"
    opkg update
    opkg install bash
  fi
}
check_bash_installed
wget -O tv.sh https://raw.githubusercontent.com/wukongdaily/tvhelper/master/shells/tv.sh && chmod +x tv.sh && ./tv.sh
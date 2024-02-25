#!/bin/bash
# wget -O kodi.sh https://raw.githubusercontent.com/wukongdaily/tvhelper/master/shells/kodi.sh && chmod +x kodi.sh && ./kodi.sh

#判断是否为x86软路由
is_x86_64_router() {
    DISTRIB_ARCH=$(cat /etc/openwrt_release | grep "DISTRIB_ARCH" | cut -d "'" -f 2)
    if [ "$DISTRIB_ARCH" = "x86_64" ]; then
        return 0
    else
        return 1
    fi
}

#********************************************************

# 定义红色文本
RED='\033[0;31m'
# 无颜色
NC='\033[0m'
GREEN='\e[38;5;154m'
YELLOW="\e[93m"
BLUE="\e[96m"

# 菜单选项数组
declare -a menu_options
declare -A commands

# 检查输入是否为整数
is_integer() {
    if [[ $1 =~ ^-?[0-9]+$ ]]; then
        return 0 # 0代表true/成功
    else
        return 1 # 非0代表false/失败
    fi
}

# 判断adb是否安装
check_adb_installed() {
    if opkg list-installed | grep -q "^adb "; then
        return 0 # 表示 adb 已安装
    else
        return 1 # 表示 adb 未安装
    fi
}

# 判断adb是否连接成功
check_adb_connected() {
    if check_adb_installed; then
        # 获取 adb devices 输出,跳过第一行（标题行）,并检查每一行的状态
        local connected_devices=$(adb devices | awk 'NR>1 {print $2}' | grep 'device$')
        # 检查是否有设备已连接并且状态为 'device',即已授权
        if [[ -n $connected_devices ]]; then
            # ADB 已连接并且设备已授权
            return 0
        else
            # ADB 设备未连接或未授权
            return 1
        fi
    else
        # 表示 adb 未安装
        return 1
    fi
}

# 安装adb工具
install_adb() {
    echo -e "${BLUE}绝大多数软路由自带ADB 只有少数OpenWrt硬路由才需要安装ADB${NC}"
    # 调用函数并根据返回值判断
    if check_adb_installed; then
        echo -e "${YELLOW}您的路由器已经安装了ADB工具${NC}"
    else
        opkg update
        echo -e "${YELLOW}正在尝试安装adb${NC}"
        if opkg install adb; then
            echo -e "${GREEN}adb 安装成功!${NC}"
        else
            echo -e "${RED}adb 安装失败,请检查日志以获取更多信息。${NC}"
        fi
    fi
}

# 连接adb
connect_adb() {
    install_adb

    # 尝试自动获取网关地址
    #gateway_ip=$(ip route show default | grep default | awk '{print $3}')
    gateway_ip=$(ip a show br-lan | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
    if [ -z "$gateway_ip" ]; then
        echo -e "${RED}无法自动获取网关IP地址，请手动输入电视盒子的完整IP地址：${NC}"
        read ip
    else
        # 提取网关IP地址的前缀
        gateway_prefix=$(echo $gateway_ip | sed 's/\.[0-9]*$//').

        echo -e "${YELLOW}请输入电视盒子的ip地址(${NC}${BLUE}${gateway_prefix}${NC}${YELLOW})的最后一段数字${NC}"
        read end_number
        if is_integer "$end_number"; then
            # 使用动态获取的网关前缀
            ip=${gateway_prefix}${end_number}
        else
            echo -e "${RED}错误: 请输入整数。${NC}"
            return 1
        fi
    fi

    adb disconnect
    echo -e "${BLUE}首次使用,盒子上可能会提示授权弹框,给您半分钟时间来操作...【允许】${NC}"
    adb connect ${ip}

    # 循环检测连接状态
    for ((i = 1; i <= 30; i++)); do
        echo -e "${YELLOW}第${i}次尝试连接ADB,请在设备上点击【允许】按钮...${NC}"
        device_status=$(adb devices | grep "${ip}:5555" | awk '{print $2}')
        if [[ "$device_status" == "device" ]]; then
            echo -e "${GREEN}ADB 已经连接成功啦,你可以放心操作了${NC}"
            return 0
        fi
        sleep 1 # 每次检测间隔1秒
    done
    echo -e "${RED}连接超时,或者您点击了【取消】,请确认电视盒子的IP地址是否正确。如果问题持续存在,请检查设备的USB调试设置是否正确并重新连接adb${NC}"
}

# 显示当前时区
show_timezone() {
    adb shell getprop persist.sys.timezone
}

#断开adb连接
disconnect_adb() {
    if check_adb_installed; then
        adb disconnect
        echo "ADB 已经断开"
    else
        echo -e "${YELLOW}您还没有安装ADB${NC}"
    fi
}

# 向电视盒子输入英文
input_text() {
    echo -e "${BLUE}注意注意注意！请弹出键盘后再执行!每次输入会自动清空上次结果${NC}"
    if check_adb_connected; then
        while true; do
            echo "请输入英文、数字或特定字符(如IP地址等) 输入q退出。输入【qk】删除20个字符。"
            read str
            if [[ $str == "q" ]]; then
                echo -e "${GREEN}退出输入模式。${NC}"
                break # 当用户输入q时退出循环
            elif [[ $str == "qk" ]]; then
                # 删除20个字符
                for i in {1..20}; do
                    adb shell input keyevent KEYCODE_DEL
                done
                echo -e "${RED}哈哈!你可真够懒的!已帮你删除20个字符。继续输入或者输入q退出。${NC}"
            elif [[ $str =~ [^a-zA-Z0-9\.\-\/\:] ]]; then
                echo -e "${RED}adb不支持输入中文,请重新输入${NC}"
            else
                # 输入文本
                adb shell input text "${str}"
                echo -e "${GREEN}[OK] 已发送! 继续输入或者输入q退出。${NC}"
            fi
        done
    else
        connect_adb
    fi
}

get_status() {
    if check_adb_connected; then
        adb_status="${GREEN}已连接且已授权${NC}"
    else
        adb_status="${RED}未连接${NC}"
    fi
    echo -e "*      与电视盒子的连接状态:$adb_status"
}

# 获取电视盒子型号
get_tvbox_model_name() {
    if check_adb_connected; then
        # 获取设备型号
        local model=$(adb shell getprop ro.product.model)
        # 获取设备制造商
        local manufacturer=$(adb shell getprop ro.product.manufacturer)
        # 清除换行符
        model=$(echo $model | tr -d '\r' | tr -d '\n')
        manufacturer=$(echo $manufacturer | tr -d '\r' | tr -d '\n')
        echo -e "*      当前电视盒子型号:${BLUE}$manufacturer $model${NC}"
    else
        echo -e "*      当前电视盒子型号:${BLUE}请先连接ADB${NC}"
    fi
}

# 获取电视盒子时区
get_tvbox_timezone() {
    if check_adb_connected; then
        # 获取设备时区
        device_timezone=$(adb shell getprop persist.sys.timezone)
        # 获取设备系统时间，格式化为“年月日 时:分”
        device_time=$(adb shell date "+%Y年%m月%d日 %H:%M")

        echo -e "*      当前电视盒子时区:${YELLOW}$device_timezone${NC}"
        echo -e "*      当前电视盒子时间:${YELLOW}$device_time${NC}"
    else
        echo -e "*      当前电视盒子时区:${BLUE}请先连接ADB${NC}"
        echo -e "*      当前电视盒子时间:${BLUE}请先连接ADB${NC}"
    fi
}

# 能否访问Github
check_github_connected() {
    # Ping GitHub域名并提取时间
    ping_time=$(ping -c 1 raw.githubusercontent.com | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')

    if [ -n "$ping_time" ]; then
        echo -e "*      当前路由器访问Github延时:${BLUE}${ping_time}ms${NC}"
    else
        echo -e "*      当前路由器访问Github延时:${RED}超时${NC}"
    fi
}

##获取软路由型号信息
get_router_name() {
    if is_x86_64_router; then
        model_name=$(grep "model name" /proc/cpuinfo | head -n 1 | awk -F: '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
        echo "$model_name"
    else
        model_info=$(cat /tmp/sysinfo/model)
        echo "$model_info"
    fi
}

# 设置KODI为简体中文
set_kodi_to_chinese() {
    # 确保Kodi已经关闭
    adb shell am force-stop org.xbmc.kodi

    # Kodi简体中文语言包下载地址
    LANGUAGE_PACK_URL="https://github.com/wukongdaily/tvhelper/raw/master/kodi/resource.language.zh_cn-10.0.64.zip"

    # Kodi的Add-ons目录路径，请根据实际情况进行修改
    KODI_ADDONS_PATH="/sdcard/Android/data/org.xbmc.kodi/files/.kodi/addons/"

    # 创建本地临时目录用于解压
    TEMP_DIR="/tmp/kodi_addons"
    mkdir -p "$TEMP_DIR"

    echo -e "${GREEN}下载中文语言包...${NC}"
    wget -O /tmp/resource.language.zh_cn.zip "$LANGUAGE_PACK_URL"

    echo -e "${GREEN}解压中文语言包到本地临时目录...${NC}"
    unzip -o /tmp/resource.language.zh_cn.zip -d "$TEMP_DIR"

    # 推送整个解压后的文件夹到Kodi的Add-ons目录
    adb push "$TEMP_DIR" "$KODI_ADDONS_PATH"

    echo -e "${RED}清理临时文件...${NC}"
    rm -rf /tmp/resource.language.zh_cn.zip "$TEMP_DIR"

    echo -e "${GREEN}中文语言包已安装至KODI,开始配置语言....${NC}"
    # 修改guisettings.xml以使用中文语言包
    local KODI_SETTINGS_PATH="/sdcard/Android/data/org.xbmc.kodi/files/.kodi/userdata/guisettings.xml"
    # 先下载配置文件
    adb pull $KODI_SETTINGS_PATH /tmp/guisettings.xml

    # 使用sed命令更新XML文件中的字体和语言设置
    sed -i 's|<setting id="lookandfeel.font"[^>]*>.*</setting>|<setting id="lookandfeel.font">Arial</setting>|g' /tmp/guisettings.xml
    sed -i 's|<setting id="locale.language"[^>]*>.*</setting>|<setting id="locale.language">resource.language.zh_cn</setting>|g' /tmp/guisettings.xml

    # 再上传配置文件——更新
    adb push /tmp/guisettings.xml $KODI_SETTINGS_PATH

    # 重启Kodi
    adb shell am start -a android.intent.action.MAIN -n org.xbmc.kodi/.Main
    echo -e "${GREEN}Kodi的字体和语言设置已更新。${NC}"
}

# 安装apk
install_apk() {
    local apk_download_url=$1
    local package_name=$2
    local filename=$(basename "$apk_download_url")
    # 下载APK文件到临时目录
    wget -O /tmp/$filename "$apk_download_url"
    if check_adb_connected; then
        # 卸载旧版本的APK（如果存在）
        adb uninstall "$package_name" >/dev/null 2>&1
        echo -e "${GREEN}正在推送和安装apk,请耐心等待...${NC}"

        # 模拟安装进度
        echo -ne "${BLUE}"
        while true; do
            echo -n ".."
            sleep 1
        done &

        # 保存进度指示进程的PID
        PROGRESS_PID=$!
        install_result=$(adb install -r /tmp/$filename 2>&1)

        # 安装完成后,终止进度指示进程
        kill $PROGRESS_PID
        wait $PROGRESS_PID 2>/dev/null
        echo -e "${NC}\n"

        # 检查安装结果
        if [[ $install_result == *"Success"* ]]; then
            echo -e "${GREEN}APK安装成功!请在盒子上查看${NC}"
        else
            echo -e "${RED}APK安装失败:$install_result${NC}"
        fi
        rm -rf /tmp/"$filename"
        echo -e "${YELLOW}临时文件/tmp/${filename}已清理${NC}"
    else
        connect_adb
    fi
}


# 安装KODI
install_kodi(){
    install_apk "https://mirror.karneval.cz/pub/xbmc/releases/android/arm/kodi-20.4-Nexus-armeabi-v7a.apk" "org.xbmc.kodi"
}

sponsor(){
    echo
    echo -e "${GREEN}访问赞助页面和悟空百科⬇${BLUE}"
    echo -e "${BLUE} https://bit.ly/3woDZE7 ${NC}"
    echo 
}

# 菜单
menu_options=(
    "安装ADB"
    "连接ADB"
    "断开ADB"
    "安装KODI 20.4"
    "设置KODI的语言为简体中文"
    "赞助|打赏"
)

commands=(
    ["安装ADB"]="install_adb"
    ["连接ADB"]="connect_adb"
    ["断开ADB"]="disconnect_adb"
    ["安装KODI 20.4"]="install_kodi"
    ["设置KODI的语言为简体中文"]="set_kodi_to_chinese"
    ["赞助|打赏"]="sponsor"
)

# 处理菜单
handle_choice() {
    local choice=$1
    # 检查输入是否为空
    if [[ -z $choice ]]; then
        echo -e "${RED}输入不能为空,请重新选择。${NC}"
        return
    fi

    # 检查输入是否为数字
    if ! [[ $choice =~ ^[0-9]+$ ]]; then
        echo -e "${RED}请输入有效数字!${NC}"
        return
    fi

    # 检查数字是否在有效范围内
    if [[ $choice -lt 1 ]] || [[ $choice -gt ${#menu_options[@]} ]]; then
        echo -e "${RED}选项超出范围!${NC}"
        echo -e "${YELLOW}请输入 1 到 ${#menu_options[@]} 之间的数字。${NC}"
        return
    fi

    local selected_option="${menu_options[$choice - 1]}"
    local command_to_run="${commands[$selected_option]}"

    # 检查是否存在对应的命令
    if [ -z "$command_to_run" ]; then
        echo -e "${RED}无效选项,请重新选择。${NC}"
        return
    fi

    # 使用eval执行命令
    eval "$command_to_run"
}

show_menu() {
    current_date=$(date +%Y%m%d)
    mkdir -p /tmp/upload
    clear
    echo "***********************************************************************"
    echo -e "*      ${YELLOW}KODI设置助手OpenWrt版 (${current_date})${NC}        "
    echo -e "*      ${GREEN}KODI太复杂了 必须得上手段了${NC}         "
    echo -e "*      ${RED}请确保电视盒子和OpenWrt路由器处于${NC}${BLUE}同一网段${NC}\n*      ${RED}且电视盒子开启了${NC}${BLUE}USB调试模式(adb开关)${NC}         "
    echo "*      Developed by @wukongdaily        "
    echo "**********************************************************************"
    echo
    echo "*      当前的路由器型号: $(get_router_name)"
    echo "$(check_github_connected)"
    echo "$(get_status)"
    echo "$(get_tvbox_model_name)"
    echo "$(get_tvbox_timezone)"
    echo
    echo "**********************************************************************"
    echo "请选择操作："
    for i in "${!menu_options[@]}"; do
        echo -e "${BLUE}$((i + 1)). ${menu_options[i]}${NC}"
    done
}

while true; do
    show_menu
    read -p "请输入选项的序号(输入q退出): " choice
    if [[ $choice == 'q' ]]; then
        break
    fi
    handle_choice $choice
    echo "按任意键继续..."
    read -n 1 # 等待用户按键
done

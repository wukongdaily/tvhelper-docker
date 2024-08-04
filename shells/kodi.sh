#!/bin/bash
# wget -O kodi.sh https://cafe.cpolar.cn/wkdaily/tvhelper-docker/raw/branch/master/shells/kodi.sh && chmod +x kodi.sh && ./kodi.sh

#********************************************************
source common.sh
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

# 判断adb是否连接成功
check_adb_connected() {
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
}



# 连接adb
connect_adb() {
    adb disconnect >/dev/null 2>&1
    echo -e "${YELLOW}请手动输入电视盒子的完整IP地址:${NC}"
    read ip
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
    adb disconnect >/dev/null 2>&1
    echo "ADB 已经断开"
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

# 设置KODI为简体中文
set_kodi_to_chinese() {
    # 确保Kodi已经关闭
    adb shell am force-stop org.xbmc.kodi
    # Kodi的Add-ons目录路径，请根据实际情况进行修改
    KODI_ADDONS_PATH="/sdcard/Android/data/org.xbmc.kodi/files/.kodi/addons/"

    # 创建本地临时目录用于解压
    TEMP_DIR="/tmp/kodi_addons"
    mkdir -p "$TEMP_DIR"

    echo -e "${GREEN}解压中文语言包到本地临时目录...${NC}"
    unzip -o /tvhelper/kodi/resource.language.zh_cn-10.0.64.zip -d "$TEMP_DIR"

    # 1、推送整个解压后的文件夹到Kodi的Add-ons目录
    adb push "$TEMP_DIR" "$KODI_ADDONS_PATH"
  
    echo -e "${GREEN}中文语言包已安装至KODI,开始配置语言....${NC}"
    # 修改guisettings.xml以使用中文语言包
    local KODI_SETTINGS_PATH="/sdcard/Android/data/org.xbmc.kodi/files/.kodi/userdata/guisettings.xml"
   
    # 2、上传配置文件——更新
    adb push /tvhelper/kodi/guisettings.xml $KODI_SETTINGS_PATH
    echo -e "${GREEN}Kodi的字体和语言设置已更新,正在为您尝试打开KODI,请根据提示完成KODI初始化。${NC}"
    sleep 2
    # 重启Kodi
    #adb shell am start -a android.intent.action.MAIN -n org.xbmc.kodi/.Main
    adb shell monkey -p org.xbmc.kodi 1 >/dev/null 2>&1
    
}

# 安装apk
install_apk() {
    local apk_local_path=$1
    local package_name=$2
    local filename=$(basename "$apk_local_path")

     # 检查APK文件是否存在
    if [ ! -f "$apk_local_path" ]; then
        echo -e "${RED}错误: APK文件不存在,请更新docker镜像后重试。${NC}"
        return 1
    fi
  
    if check_adb_connected; then
        # 卸载旧版本的APK（如果存在）
        echo -e "${GREEN}正在推送和安装${filename},请耐心等待...${NC}"
        adb uninstall "$package_name" >/dev/null 2>&1

        # 模拟安装进度
        echo -ne "${BLUE}"
        while true; do
            echo -n ".."
            sleep 1
        done &

        # 保存进度指示进程的PID
        PROGRESS_PID=$!
        install_result=$(adb install -r $apk_local_path 2>&1)

        # 安装完成后,终止进度指示进程
        kill $PROGRESS_PID
        wait $PROGRESS_PID 2>/dev/null
        echo -e "${NC}\n"

        # 检查安装结果
        if [[ $install_result == *"Success"* ]]; then
            echo -e "${GREEN}APK安装成功!请在盒子上查看${NC}"
            set_kodi_to_chinese
        else
            echo -e "${RED}APK安装失败:$install_result${NC}"
        fi
    else
        connect_adb
    fi
}

# 安装KODI
install_kodi() {
    install_apk "/tvhelper/kodi/kodi.apk" "org.xbmc.kodi"
}

# 菜单
menu_options=(
    "连接ADB"
    "断开ADB"
    "安装KODI 20.5 并设置中文"
    #"设置KODI的语言为简体中文"
    "赞助|打赏"
)

commands=(
    ["连接ADB"]="connect_adb"
    ["断开ADB"]="disconnect_adb"
    ["安装KODI 20.5 并设置中文"]="install_kodi"
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
    mkdir -p /tvhelper/shells/data
    clear
    echo "***********************************************************************"
    echo -e "*      ${YELLOW}KODI设置助手Docker版 (${current_date})${NC}        "
    echo -e "*      ${GREEN}KODI太复杂了 必须得上手段了${NC}         "
    echo -e "*      ${RED}请确保电视盒子和Docker宿主机处于${NC}${BLUE}同一网段${NC}\n*      ${RED}且电视盒子开启了${NC}${BLUE}USB调试模式(adb开关)${NC}         "
    echo "*      Developed by @wukongdaily        "
    echo "**********************************************************************"
    echo
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

#!/bin/bash
# wget -O tv.sh https://raw.githubusercontent.com/wukongdaily/tvhelper-docker/master/shells/tv.sh && chmod +x tv.sh && ./tv.sh

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

show_user_tips() {
    read -p "按 Enter 键继续..."
}

# 检查输入是否为整数
is_integer() {
    if [[ $1 =~ ^-?[0-9]+$ ]]; then
        return 0 # 0代表true/成功
    else
        return 1 # 非0代表false/失败
    fi
}

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
    # 尝试自动获取网关地址
    echo -e "${BLUE}请手动输入电视盒子的IP地址:${NC}"
    read ip
    
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

# 一键修改NTP服务器地址
modify_ntp() {
    echo -e "${BLUE}它的作用在于:解决安卓原生TV时间不正确和网络受限问题${NC}"
    if check_adb_connected; then
        adb shell settings put global ntp_server ntp3.aliyun.com
        adb shell settings put global captive_portal_mode 1
        adb shell settings put global captive_portal_detection_enabled 1
        # 设置一个返回204 空内容的服务器
        adb shell settings put global captive_portal_use_https 0
        adb shell settings put global captive_portal_http_url http://connect.rom.miui.com/generate_204
        echo -e "${GREEN}NTP服务器地址已经成功修改为国内,重启后请检查盒子的系统时间和时区${NC}"
        echo -e "${RED}正在重启您的电视盒子或者电视机,请稍后.......${NC}"
        # 5秒倒计时
        for i in {5..1}; do
            echo -e "${RED}$i${NC} 秒后将重启设备"
            sleep 1
        done
        adb shell reboot &
    else
        echo "没有检测到已连接的设备。请先连接ADB"
        connect_adb
    fi
}

# 显示当前时区
show_timezone() {
    adb shell getprop persist.sys.timezone
}

#断开adb连接
disconnect_adb() {
    adb disconnect
    echo "ADB 已经断开"
}

# 添加主机名映射(解决安卓原生TV首次连不上wifi的问题)
add_dhcp_domain() {
    echo -e "${BLUE}它的作用在于:解决安卓原生TV首次使用连不上wifi的问题${NC}"
    local domain_name="time.android.com"
    local domain_ip="203.107.6.88"

    # 检查是否存在相同的域名记录
    existing_records=$(uci show dhcp | grep "dhcp.@domain\[[0-9]\+\].name='$domain_name'")
    if [ -z "$existing_records" ]; then
        # 添加新的域名记录
        uci add dhcp domain
        uci set "dhcp.@domain[-1].name=$domain_name"
        uci set "dhcp.@domain[-1].ip=$domain_ip"
        uci commit dhcp
        echo
        echo "已添加新的域名记录"
    else
        echo "相同的域名记录已存在,无需重复添加"
    fi
    echo -e "\n"
    echo -e "time.android.com    203.107.6.88 "
}

show_nf_info() {
    echo -e "${BLUE}播放Netflix影片的时候 屏幕左上角显示影片信息,再次执行则消失${NC}"
    echo -e "${GREEN}Netflix INFO键已发送! 继续输入【m】模拟INFO键 或者输入q退出。${NC}"
    if check_adb_connected; then
        while true; do
            read str
            if [[ $str == "q" ]]; then
                echo -e "${GREEN}退出输入模式。${NC}"
                break # 当用户输入q时退出循环
            elif [[ $str == "m" ]]; then
                adb shell input keyevent KEYCODE_F8
                echo -e "${GREEN}Netflix INFO键已发送! 继续输入【m】模拟INFO键 或者输入q退出。${NC}"
            else
                echo -e "${RED}请输入m或者输入q退出${NC}"
            fi
        done
    else
        connect_adb
    fi
}

show_menu_keycode() {
    echo -e "${BLUE}使用背景:${NC}\n${YELLOW}许多国产App还保留了菜单键的功能\n而原生TV盒子系统似乎逐渐放弃适配菜单键\n因此很多盒子附带的遥控器不会标配菜单键\n\n所以开发此功能,它会模拟触发菜单键\n请在盒子上观察是否有效,可反复执行${NC}"
    echo -e "${GREEN}菜单键已发送! 继续输入字母【m】模拟菜单键 或者输入q退出。${NC}"
    if check_adb_connected; then
        while true; do

            read str
            if [[ $str == "q" ]]; then
                echo -e "${GREEN}退出输入模式。${NC}"
                break # 当用户输入q时退出循环
            elif [[ $str == "m" ]]; then
                adb shell input keyevent KEYCODE_MENU
                echo -e "${GREEN}菜单键已发送! 继续输入m模拟菜单键 或者输入q退出。${NC}"
            else
                echo -e "${RED}请输入m或者输入q退出${NC}"
            fi
        done
    else
        connect_adb
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

# 批量安装apk功能
install_all_apks() {
    if check_adb_connected; then
        # 获取/tvhelper/shells/data目录下的apk文件列表
        apk_files=($(ls /tvhelper/shells/data/*.apk 2>/dev/null))
        total_files=${#apk_files[@]}

        # 检查是否有APK文件
        if [ "$total_files" -eq "0" ]; then
            echo -e "${RED}/tvhelper/shells/data 目录下不包含任何apk文件,请先拷贝apk文件到此目录.${NC}"
            return 1
        fi

        echo -e "${GREEN}================文件列表================${NC}"
        for apk_file in "${apk_files[@]}"; do
            filename=$(basename "$apk_file")
            echo -e "${GREEN}$filename${NC}"
        done
        echo -e "${GREEN}========================================${NC}"
        echo
        echo -e "${BLUE}发现 $total_files 个APK. 开始安装...\n安装过程若出现弹框,请点击详情后选择【仍然安装】即可${NC}"
        echo
        # 安装APK文件并显示进度
        for apk_file in "${apk_files[@]}"; do
            filename=$(basename "$apk_file")
            echo -ne "${YELLOW}Installing: $filename${NC} ${GREEN}"
            echo

            # 模拟安装进度
            while true; do
                echo -n ".."
                sleep 1
            done &

            # 保存进度指示进程的PID
            PROGRESS_PID=$!

            # 执行实际的APK安装命令,并捕获输出
            install_result=$(adb install -r "$apk_file" 2>&1)

            # 安装完成后,终止进度指示进程
            kill $PROGRESS_PID >/dev/null 2>&1
            wait $PROGRESS_PID 2>/dev/null
            echo -e "${NC}\nInstallation result: $install_result"
        done

        echo -e "${GREEN}所有APK安装完毕.${NC}"
    else
        connect_adb
    fi
}

# 安装订阅助手
install_subhelper_apk() {
    echo -e "${BLUE}电视订阅助手使用指南 前往观看:https://youtu.be/9NpYtPsJlGk ${NC}"
    install_apk "https://github.com/wukongdaily/tvhelper/raw/master/apks/subhelp14.apk" "com.wukongdaily.myclashsub"
}

# 安装emotn store
install_emotn_store() {
    echo -e "${BLUE}emotn_store使用指南1 前往观看:https://youtu.be/_S693NITNrs ${NC}"
    echo -e "${YELLOW}emotn_store使用指南2 前往观看:https://youtu.be/lMhhIn4CQts ${NC}"
    echo -e "${BLUE}安装过程若出现弹框,请点击详情后选择【仍然安装】即可${NC}"
    install_apk "https://app.keeflys.com/20220107/com.overseas.store.appstore_1.0.40_a973.apk" "com.overseas.store.appstore"
}

# 安装当贝市场
install_dbmarket() {
    echo -e "${BLUE}安装过程若出现弹框,请点击详情后选择【仍然安装】即可${NC}"
    install_apk "https://webapk.dangbei.net/update/dangbeimarket.apk" "com.dangbeimarket"
}

# 安装play商店图标
show_playstore_icon() {
    echo -e "${BLUE}这个apk仅用于google tv系统。因为google tv系统在首页并不会显示自家的谷歌商店图标${NC}"
    install_apk "https://github.com/wukongdaily/tvhelper/raw/master/apks/play-icon.apk" "com.android.vending.wk"
}

# 安装my-tv
# release地址、包名、apk命名前缀
install_mytv_latest_apk() {
    echo -e "${BLUE}项目主页:https://github.com/lizongying/my-tv ${NC}"
    install_apk_by_url "https://github.com/lizongying/my-tv/releases/latest" "com.lizongying.mytv" "my-tv-"
}

# 安装bbll
# release地址、包名、apk命名前缀
install_BBLL_latest_apk() {
    echo -e "${BLUE}项目主页:https://github.com/xiaye13579/BBLL ${NC}"
    install_apk_by_url "https://github.com/xiaye13579/BBLL/releases/latest" "com.xx.blbl" "BLBL_release_"
}

# 安装文件管理器
install_file_manager_plus() {
    install_apk "https://github.com/wukongdaily/tvhelper/raw/master/apks/File_Manager_Plus.apk" "com.alphainventor.filemanager"
}

# 安装Downloader
install_downloader() {
    install_apk "https://github.com/wukongdaily/tvhelper/raw/master/apks/downloader.apk" "com.esaba.downloader"
}

#根据apk地址和包名 安装apk
install_apk_by_url() {
    local releases_url=$1
    local package_name=$2
    local name_prefix=$3

    # 使用get_apk_url函数获取APK的下载链接
    local apk_url=$(get_apk_url_by_name_prefix "$releases_url" "$name_prefix")
    if [ -z "$apk_url" ]; then
        echo "APK download URL could not be found."
        return 1
    fi

    # 从URL中提取文件名
    local filename=$(basename "$apk_url")
    echo -e "${YELLOW}已获取最新版下载地址:\n$apk_url${NC}"

    # 使用curl下载APK文件并保存到/tmp目录
    echo -e "${GREEN}Downloading APK to /tmp/$filename ... ${NC}"
    curl -L "$apk_url" -o /tmp/"$filename"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}APK downloaded successfully to /tmp/$filename ${NC}"
        if check_adb_connected; then
            # 卸载旧版本的APK
            adb uninstall "$package_name" >/dev/null 2>&1
            echo -e "${GREEN}正在推送和安装$filename 请耐心等待...${NC}"
            # 模拟安装进度
            echo -ne "${BLUE}"
            while true; do
                echo -n ".."
                sleep 1
            done &

            # 保存进度指示进程的PID
            PROGRESS_PID=$!

            # 安装新版本的APK
            install_result=$(adb install /tmp/"$filename" 2>&1)

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
    else
        echo "Failed to download APK."
        return 1
    fi
}

#根据release地址和命名前缀获取apk地址
get_apk_url_by_name_prefix() {
    if [ $# -eq 0 ]; then
        echo "需要提供GitHub releases页面的URL作为参数。"
        return 1
    fi

    local releases_url=$1
    local name_prefix=$2

    # 使用curl获取重定向的URL
    latest_url=$(curl -Ls -o /dev/null -w "%{url_effective}" "$releases_url")

    # 使用sed从URL中提取tag值,并保留前导字符'v'
    tag=$(echo $latest_url | sed 's|.*/v|v|')

    # 检查是否成功获取到tag
    if [ -z "$tag" ]; then
        echo "未找到最新的release tag。"
        return 1
    fi

    # 拼接APK下载链接
    local repo_path=$(echo "$releases_url" | sed -n 's|https://github.com/\(.*\)/releases/latest|\1|p')
    apk_download_url="https://github.com/${repo_path}/releases/download/${tag}/${name_prefix}${tag}.apk"

    echo "$apk_download_url"
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

# 安装mix apps 用于显示全部app
install_mixapps() {
    local xapk_download_url="https://github.com/wukongdaily/tvhelper/raw/master/apks/mix.xapk"
    local xapkname=$(basename "$xapk_download_url")
    local xapk_file="/tmp/$xapkname"
    wget -O "$xapk_file" "$xapk_download_url"
    local extract_to="/tmp/mix/"
    mkdir -p "$extract_to"
    if unzip -o "$xapk_file" -d "$extract_to"; then
        echo "XAPK文件解压成功,准备安装..."
    else
        echo "XAPK文件解压失败,请检查文件是否损坏或尝试重新下载。"
        return 1 # 返回一个错误状态
    fi
    apk_files=$(find "$extract_to" -type f -name "*.apk")
    echo -e "解压后的多个apk:\n$apk_files"
    echo -ne "${YELLOW}正在安装: $xapkname${NC} ${GREEN}"
    echo

    # 模拟安装进度
    while true; do
        echo -n ".."
        sleep 1
    done &
    # 保存进度指示进程的PID
    PROGRESS_PID=$!
    # 执行实际的APK安装命令,并捕获输出
    install_result=$(adb install-multiple $apk_files 2>&1)
    # 安装完成后,终止进度指示进程
    kill $PROGRESS_PID >/dev/null 2>&1
    wait $PROGRESS_PID 2>/dev/null
    echo -e "${NC}\nInstallation result: $install_result"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN} 安装成功 ${NC}"
        # 安装成功后，删除解压的文件和原始XAPK文件
        echo -e "${RED}正在删除临时文件...${NC}"
        rm -rf "$extract_to" # 删除解压目录
        rm -f "$xapk_file"   # 删除原始XAPK文件
        echo -e "${GREEN}临时文件删除完成,行啦,在盒子上查看吧！${NC}"
    else
        echo -e "${RED}安装失败${NC}"
    fi
}
# 进入KODI助手
kodi_helper() {
    wget -O kodi.sh https://raw.githubusercontent.com/wukongdaily/tvhelper-docker/master/shells/kodi.sh && chmod +x kodi.sh && ./kodi.sh
}

# 安装fire tv版本youtube
install_youtube_firetv() {
    echo -e "${BLUE}Fire TV版本Youtube无需谷歌框架 可用于所有安卓5.0以上电视盒子 ${NC}"
    install_apk "https://github.com/wukongdaily/tvhelper/raw/master/apks/youtube.apk" "com.amazon.firetv.youtube"
}

# 进入tvbox安装助手
enter_tvbox_helper() {
    wget -O box.sh https://raw.githubusercontent.com/wukongdaily/tvhelper-docker/master/shells/box.sh && chmod +x box.sh && ./box.sh
}

# 进入sony电视助手
enter_sonytv() {
    wget -O sony.sh https://raw.githubusercontent.com/wukongdaily/tvhelper-docker/master/shells/sony.sh && chmod +x sony.sh && ./sony.sh
}

# 赞助
sponsor() {
    echo
    echo -e "${GREEN}访问赞助页面和悟空百科⬇${BLUE}"
    echo -e "${BLUE} https://bit.ly/3woDZE7 ${NC}"
    echo
}
# 菜单
menu_options=(
    "连接ADB"
    "断开ADB"
    "一键修改电视盒子NTP服务器地址(需重启)"
    "向TV端输入文字(限英文)"
    "为Google TV系统安装Play商店图标"
    "显示Netflix影片码率"
    "模拟菜单键"
    "安装电视订阅助手"
    "安装Emotn Store应用商店"
    "安装当贝市场"
    "安装文件管理器+"
    "安装Downloader"
    "安装my-tv最新版(lizongying)"
    "安装BBLL最新版(xiaye13579)"
    "自定义批量安装data目录下的所有apk"
    "安装Mix-Apps用于显示全部应用"
    "进入KODI助手"
    "安装Fire TV版Youtube(免谷歌框架)"
    "进入TVBox安装助手"
    "进入Sony电视助手"
    "更新脚本"
    "赞助|打赏"
)

commands=(
    ["连接ADB"]="connect_adb"
    ["断开ADB"]="disconnect_adb"
    ["一键修改电视盒子NTP服务器地址(需重启)"]="modify_ntp"
    ["安装电视订阅助手"]="install_subhelper_apk"
    ["安装Emotn Store应用商店"]="install_emotn_store"
    ["安装当贝市场"]="install_dbmarket"
    ["向TV端输入文字(限英文)"]="input_text"
    ["显示Netflix影片码率"]="show_nf_info"
    ["模拟菜单键"]="show_menu_keycode"
    ["为Google TV系统安装Play商店图标"]="show_playstore_icon"
    ["安装my-tv最新版(lizongying)"]="install_mytv_latest_apk"
    ["安装BBLL最新版(xiaye13579)"]="install_BBLL_latest_apk"
    ["安装文件管理器+"]="install_file_manager_plus"
    ["安装Downloader"]="install_downloader"
    ["自定义批量安装data目录下的所有apk"]="install_all_apks"
    ["安装Mix-Apps用于显示全部应用"]="install_mixapps"
    ["进入KODI助手"]="kodi_helper"
    ["安装Fire TV版Youtube(免谷歌框架)"]="install_youtube_firetv"
    ["进入TVBox安装助手"]="enter_tvbox_helper"
    ["赞助|打赏"]="sponsor"
    ["进入Sony电视助手"]="enter_sonytv"
    ["更新脚本"]="update_sh"
)

update_sh() {
    break
    echo "正在更新脚本..."
    # 下载最新的脚本到临时文件
    wget -O /tmp/script.sh https://raw.githubusercontent.com/wukongdaily/tvhelper-docker/master/shells/tv.sh
    # 替换当前脚本
    if [ -f /tmp/script.sh ]; then
        chmod +x /tmp/script.sh
        cp /tmp/script.sh /tv.sh
        echo "脚本更新成功。即将重新启动脚本。"
        # 使用 exec 来重新启动脚本，替换当前进程
        exec /tv.sh
    else
        echo "更新失败。"
    fi
}

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
    echo -e "*      ${YELLOW}遥控助手/盒子助手Docker版 (${current_date})${NC}        "
    echo -e "*      ${GREEN}专治安卓原生TV盒子在大陆使用的各种水土不服${NC}         "
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
        disconnect_adb
        break
    fi
    handle_choice $choice
    echo "按任意键继续..."
    read -n 1 # 等待用户按键
done

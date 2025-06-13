[ -n "$(uname -a | grep aarch64)" ] || echo 您的设备不适用此扩展，仅供aarch64使用！
[ -n "$(uname -a | grep aarch64)" ] || exit
[ -f "/etc/config/lyq" ] || echo >/etc/config/lyq
#检查硬盘并且挂载
mkdir /mnt/sda > /dev/null 2>&1 #硬盘安装包位置
[ -d "/mnt/sda" ] || /bin/mount --bind  $xxx_path /mnt
[ -d "/mnt/sda" ] || mkdir /mnt/sda > /dev/null 2>&1
#优先识别ext4分区
sda=`df -T | grep ext4 | grep /dev/sd | awk '{print $7}' | grep -v docker | awk 'NR==1 {print $0}'`
#没有ext4分区择第一分区
[ ! -n "$sda" ] && sda=`df | grep /dev/sd | awk '{print $6}' | grep -v docker | awk 'NR==1 {print $0}'`
is_sda=`df | grep /mnt/sda && echo true || echo false`
[ -n "$sda" ] && [ "$is_sda" = "false" ] && /bin/mount --bind  $sda /mnt/sda || echo "sda无需挂载"
sda_path="$(df /mnt/sda | grep /mnt | awk '{print $6}')"
#开始安装
xxx_path_tmp=$(df | grep -v "100%" | awk '{print $6}'  | tail -n +2 | grep -v dev | grep -v tmp  | grep -v root)
xxx_path_tmp="$xxx_path_tmp
$sda_path"
min_size=9424 #安装磁盘最小10MB空间
IFS='
'
path_str=""
for item in $xxx_path_tmp
do
    [ -f "$item/mtd/E87A0832F9B6F" ] && mkdir -p /tmp/tmp/rom_tmp/$item/mtd > /dev/null 2>&1
    [ -f "$item/mtd/E87A0832F9B6F" ] && mv -f $item/mtd/E87A0832F9B6F /tmp/tmp/rom_tmp/$item/mtd/E87A0832F9B6F > /dev/null 2>&1
    [ -f "$item/mtd/install.sh" ] && mkdir -p /tmp/tmp/rom_tmp/$item/mtd > /dev/null 2>&1
    [ -f "$item/mtd/install.sh" ] && mv -f $item/mtd/install.sh  /tmp/tmp/rom_tmp/$item/mtd/install.sh > /dev/null 2>&1
    disk_avai_size=$(df $item | tail -n +2 | awk '{print $4}')
    [ $(($disk_avai_size)) -gt $min_size ] && ii=$(($ii+1)) || continue
    [ $ii -lt 7 ] || continue
    [ "$(echo -n $item)" = "/mnt/sda" ] && continue
    file_sys_type="$(df -T $item | tail -n +2 | awk '{print $2}')"
    path_str=$(echo -e "$path_str"$ii："\t "$item "\t\t 可用：$(  awk "BEGIN{printf \"%0.2f\",$(df $item | tail -n +2 | awk '{print $4}')/1024}" )MB\t 类型:$file_sys_type\n ")
done
path_str=$(echo -e "$path_str""0：\t 自定义位置 （不推荐使用）")
[ $(($ii)) -lt 1 ] && cp -fr /tmp/tmp/rom_tmp/* / > /dev/null 2>&1
rm -rf /tmp/tmp/rom_tmp/ > /dev/null 2>&1
[ $(($ii)) -lt 1 ] && echo 系统没有可用空间安装扩展功能。 && exit

#选择XXX安装位置

echo -----------------------------------------------
echo '---------小米扩展功能准备开始安装--------------'
echo -----------------------------------------------
echo -e "推荐安装至USB空间，系统空间普遍较小，推荐使用ext4或ubifs文件系统。"
echo -e "请选择安装位置 (默认1)"
echo -e "$path_str" | sed "s/ //g"
read -p "请输入对应数字 > " path_num
echo -----------------------------------------------
[ "$path_num" = "" ] && path_num=1
[ "$path_num" = "0" ] && path_num=$(echo "$path_str" | wc -l)
[ $(($ii+1)) -lt $path_num ] && exit
xxx_path=$(echo -e "$path_str" | sed -n $path_num'p' | sed "s/ //g")
if [ -n "$(echo $xxx_path | grep -v "可用")" ]; then
    read -p "请输入安装位置 > " xxx_path
    [ -d "$xxx_path" ] && echo 目录已存在，开始安装 || echo 目录不存在，创建安装
    mkdir -p $xxx_path > /dev/null 2>&1
    [ -d "$xxx_path" ] || echo 目录无效，终止安装！！！
    [ -d "$xxx_path" ] || exit
else
    xxx_path=$(echo $xxx_path | cut -c 5- | awk '{print $1}')
fi
[ "$(echo $xxx_path | cut -c $(($(echo $xxx_path | wc -c)-1)))" = "/" ] && xxx_path=$(echo $xxx_path | cut -c 1-$(($(echo $xxx_path | wc -c)-2)))
mkdir $xxx_path/xxxtest> /dev/null 2>&1
if [ -d "$xxx_path/xxxtest" ]; then
    rm -rf $xxx_path/xxxtest
else
    echo 目录无效，终止安装！！！
    exit
fi
disk_avai_size=`df $xxx_path | grep / | awk '{print $4}'`
[ $(($disk_avai_size)) -gt $min_size ] || echo "空间不足，最少需要"$min_size"kb，无法安装！"
[ $(($disk_avai_size)) -gt $min_size ] || exit
if [ -f $xxx_path/xxxcon/xxxbox ]; then
    echo '保留配置覆盖安装...'
    uci set lyq.xxx_path="$xxx_path"
elif [ -f $xxx_path/xxx/xxxcon/xxxbox ]; then
    xxx_path="$xxx_path/xxx"
    echo '保留配置覆盖安装...'
    uci set lyq.xxx_path="$xxx_path"
else
    xxx_path="$xxx_path/xxx"
    mkdir $xxx_path > /dev/null 2>&1
    uci set lyq.xxx_path="$xxx_path"
fi
uci commit lyq
#创建MTD文件夹
[ -d $xxx_path/mtd ] && echo 'MTD空间准备就绪...' || mkdir -p $xxx_path/mtd > /dev/null 2>&1

cd  `dirname $0`
/bin/tar -Jxf ./xxx_install --exclude=tmp/xxxbox_mtd -C /
chmod -R 777 /tmp/xxxbox_tmp/
cp -rf /tmp/xxxbox_pkg $xxx_path/mtd/E87A0832F9B6F

[ -f "$xxx_path/mtd/E87A0832F9B6F" ] && echo "准备验证安装文件..." || echo "文件获取失败，请重启再试！！！"
[ -f "$xxx_path/mtd/E87A0832F9B6F" ] && echo "开始扩展功能安装..." || exit

# #创建备份#备份目录
# sda=`df -T | grep ext4 | grep /dev/sd | awk '{print $7}' | grep -v docker | awk 'NR==1 {print $0}'`
# if [ -d "$sda" ]; then
#     #加载新分区MTD，分区自己确认一下
#     echo -----------------------------------------------
#     echo -e "是否需要备份？ (默认1)"
#     echo -e "1：无需备份或者已备份配置，直接进行安装扩展功能！"
#     echo -e "2：备份Wi-Fi设置,上网设置,DHCP服务...,覆盖原备份"
#     read -p "请输入对应数字 > " num
#     echo -----------------------------------------------
#     [ "$num" = "" ] && num=1
#     if [ "$num" = 1 ]; then
#         echo 跳过备份，尝试安装
#     elif [ "$num" = 2 ]; then
#         echo 备份数据，尝试运行
#         $xxx_path/xxxcon/autostart bak_config $sda
#     fi
# fi
#
# #恢复备份#备份文件
# bak_path='/tmp/tmp/config_bak'
# sda=`df -T | grep ext4 | grep /dev/sd | awk '{print $7}' | grep -v docker | awk 'NR==1 {print $0}'`
# if [ -f "$xxx_path/mtd/E87A0832F9B6B" ]; then
#     echo -e "找到了一个备份$xxx_path/mtd/E87A0832F9B6B"
#     bak_path2="$xxx_path/mtd/E87A0832F9B6B"
# elif [ -f "$sda/mi_bak/E87A0832F9B6B" ]; then
#     echo -e "找到了一个备份$sda/mi_bak/E87A0832F9B6B"
#     bak_path2="$sda/mi_bak/E87A0832F9B6B"
# fi
# mkdir $bak_path > /dev/null 2>&1
# bak_ok_reboot="0"
# if [ -f "$bak_path2" ]; then
#     echo -----------------------------------------------
#     echo -e "需要恢复找到的备份数据吗？"
#     echo -e "1：无需恢复（默认）"
#     echo -e "2：恢复数据"
#     echo -e "3：删除备份"
#     read -p "请输入对应数字 > " num
#     echo -----------------------------------------------
#     if [ "$num" = 2 ]; then
#         echo 恢复数据，尝试运行
#         $xxx_path/xxxcon/autostart rec_config $bak_path2
#         read -p "恢复数据完成，按任意键重启，使配置生效..."
#     elif [ "$num" = 3 ]; then
#         rm -rf $sda/mi_bak/E87A0832F9B6B
#     fi
# fi

if [ -n "$(uci -q get misc.hardware.displayName | grep -i be)" ]; then
    num_d=1
elif [ -n "$(uci -q get misc.hardware.displayName | grep -i ax)" ]; then
    num_d=2
else
    num_d=1
fi
read -p "建议：小米be系列选择1，其他型号选择2，按其他任意键结束安装 (默认$num_d) > " num
if [ "$num" = 1 ]; then
    num=1
elif [ "$num" = 2 ]; then
    num=2
else
    num=$num_d
fi

if [ "$num" = 1 ]; then
    echo 模式1，小米扩展功能初始化...
    uci set lyq.model='7000'
    uci set lyq.disk_path='/mnt'
elif [ "$num" = 2 ]; then
    echo 模式2，小米扩展功能初始化...
    uci set lyq.model='ax9000'
    uci set lyq.disk_path='/extdisks'
fi
uci commit lyq

# echo -----------------------------------------------
# echo -e "使用内存模式还是磁盘模式（没有USB磁盘空间且储存空间较小建议使用内存模式）?"
# echo -e "1：磁盘模式（默认）"
# echo -e "2：内存模式"
# read -p "请输入对应数字 > " num
# echo -----------------------------------------------
num=0
if [ "$num" = 2 ]; then
    uci set lyq.xxx_set_radio_mode="ram"
else
    uci set lyq.xxx_set_radio_mode="rom"
fi
[ ! -n "$(echo -n `uci -q get lyq.xxx_source_list_url`)" ] && uci set lyq.xxx_source_list_url="https://api.github.com/repos/V2023H/xxx_box/contents/xxx_box/box_list.json?ref=main"
[ ! -n "$(echo -n `uci -q get lyq.xxx_update_list_json`)" ] && uci set lyq.xxx_update_list_json="https://api.github.com/repos/V2023H/xxx_box/contents/xxx_box/xxx_list.json?ref=main"
uci commit lyq

#准备启动工具
#echo 主功能安装中，请不要中断操作...
#echo 功能已经安装完成！
echo -----------------------------------------------
echo -e "注意！注意！注意!默认密码记住！！！"
echo -e "ssh    默认账号:root  密码:password"
echo -----------------------------------------------
chmod 777 /tmp/xxxbox_data/xxxcon/autostart
/tmp/xxxbox_data/xxxcon/autostart init
chmod 777 $xxx_path/xxxcon/autostart
$xxx_path/xxxcon/autostart
echo "安装完成!!!"
read -p "插件交流QQ群：134374534！"

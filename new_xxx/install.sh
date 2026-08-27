[ -n "$(uname -a | grep aarch64)" ] || echo 您的设备不适用此扩展，仅供aarch64使用！
[ -n "$(uname -a | grep aarch64)" ] || exit
source /etc/profile > /dev/null
#创建必要文件夹稍后外部挂载
mkdir -p /mnt/sda > /dev/null 2>&1 #外部安装包位置
#检查外部分区优先识别ext4分区
sda=`df -T | grep ext4 | grep -E '/dev/sd|/dev/nvme' | awk '{print $7}' | grep -v docker | awk 'NR==1 {print $0}'`
#没有ext4分区择第一分区挂载
[ ! -n "$sda" ] && sda=`df | grep -E '/dev/sd|/dev/nvme' | awk '{print $6}' | grep -v docker | awk 'NR==1 {print $0}'`
is_sda=`df | grep /mnt/sda && echo true || echo false`
echo --------------
[ -n "$sda" ] && [ "$is_sda" = "false" ] && /bin/mount --bind  $sda /mnt/sda || echo "sda无需挂载"
echo --------------
#取得外部储存分区路径
sda_path="$(df /mnt/sda | grep /mnt | awk '{print $6}')"
#获取设备所有可用路径
xxx_path_tmp=$(df | grep -v "100%" | awk '{print $6}'  | tail -n +2 | grep -v dev | grep -v tmp  | grep -v root)
xxx_path_tmp="$xxx_path_tmp
$sda_path"
#限制安装大小，单位KB
min_size=9424
IFS='
'
path_str=""
for item in $xxx_path_tmp
do
    #检查设备和外部是否存在已装记录，若已安装则转移备份
    [ -f "$item/mtd/E87A0832F9B6F" ] && mkdir -p /tmp/tmp/rom_tmp/$item/mtd > /dev/null 2>&1
    [ -f "$item/mtd/E87A0832F9B6F" ] && mv -f $item/mtd/E87A0832F9B6F /tmp/tmp/rom_tmp/$item/mtd/E87A0832F9B6F > /dev/null 2>&1
    #检查此分区剩余使用空间（单位KB）大于限制则ii+1，小于限制则跳过
    disk_avai_size=$(df $item | tail -n +2 | awk '{print $4}')
    [ $(($disk_avai_size)) -gt $min_size ] && ii=$(($ii+1)) || continue
    #最多展示7个分区的路径，后续全部跳过
    [ $ii -lt 7 ] || continue
    #若此分区为外部储存则跳过
    [ "$(echo -n $item)" = "/mnt/sda" ] && continue
    #获取此分区的系统类型
    file_sys_type="$(df -T $item | tail -n +2 | awk '{print $2}')"
    #所有分区的路径，以及空间和类型信息
    path_str=$(echo -e "$path_str"$ii："\t "$item "\t\t 可用：$(  awk "BEGIN{printf \"%0.2f\",$(df $item | tail -n +2 | awk '{print $4}')/1024}" )MB\t 类型:$file_sys_type\n ")
done
#追加一个自定义位置
path_str=$(echo -e "$path_str""0：\t 自定义位置 （不推荐使用）")
#分区数量小于1则无法安装，并恢复备份
[ $(($ii)) -lt 1 ] && cp -fr /tmp/tmp/rom_tmp/* / > /dev/null 2>&1
rm -rf /tmp/tmp/rom_tmp/ > /dev/null 2>&1
[ $(($ii)) -lt 1 ] && echo 系统没有可用空间安装扩展功能。 && exit

#用户选择XXX安装位置
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
#整理用户选中或输入的分区路径
[ "$(echo $xxx_path | cut -c $(($(echo $xxx_path | wc -c)-1)))" = "/" ] && xxx_path=$(echo $xxx_path | cut -c 1-$(($(echo $xxx_path | wc -c)-2)))
echo "当前选择的位置为：$xxx_path"
#检查选中或输入的分区是否有效
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

#UCI初始化
touch /etc/config/lyq

#准备开始安装，新旧兼容安装
if [ -f $xxx_path/xxxcon/xxxbox ]; then
    echo '保留配置覆盖安装...'
    uci -q set lyq.xxx_path="$xxx_path"
elif [ -f $xxx_path/xxx/xxxcon/xxxbox ]; then
    xxx_path="$xxx_path/xxx"
    echo '保留配置覆盖安装...'
    uci -q set lyq.xxx_path="$xxx_path"
else
    xxx_path="$xxx_path/xxx"
    mkdir $xxx_path > /dev/null 2>&1
    uci -q set lyq.xxx_path="$xxx_path"
fi
uci commit lyq
[ "$(uci -q get lyq.xxx_path | tr -d '\n')" = "" ] && echo UCI功能异常
[ "$(uci -q get lyq.xxx_path | tr -d '\n')" = "" ] && exit
#创建MTD文件夹稍后外部挂载
[ -d $xxx_path/mtd ] && echo 'MTD空间准备就绪...' || mkdir -p $xxx_path/mtd > /dev/null 2>&1
#进入当前目录释放xxx_install至/
cd  `dirname $0`
rm -rf "/data/xxxcon"
mkdir -p $xxx_path/xxxcon
ln -sf "$xxx_path/xxxcon" /data/
rm -rf "/data/xxxbox"
mkdir -p $xxx_path/xxxbox
ln -sf "$xxx_path/xxxbox" /data/
/bin/tar -Jxf ./xxx_install -C /
chmod -R 777 /tmp/xxxbox_tmp/
cp -rf /tmp/xxxbox_pkg $xxx_path/mtd/xxxbox_pkg
[ -f "$xxx_path/mtd/xxxbox_pkg" ] && echo "准备验证安装文件..." || echo "文件获取失败，请重启再试！！！"
[ -f "$xxx_path/mtd/xxxbox_pkg" ] && echo "开始扩展功能安装..." || exit
if [ -n "$(uci -q get misc.hardware.model | grep -i RC01)" ]; then #小米万兆
    num_d=1
elif [ -n "$(uci -q get misc.hardware.model | grep -i RA70)" ]; then #AX9000
    num_d=2
elif [ -n "$(uci -q get misc.hardware.model | grep -i rc06)" ]; then #BE7000
    num_d=1
elif [ -n "$(uci -q get misc.hardware.model | grep -i rd08)" ]; then #BE6500PRO
    num_d=1
else #其他
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
    uci -q set lyq.model='7000'
    uci -q set lyq.disk_path='/mnt'
elif [ "$num" = 2 ]; then
    uci -q set lyq.model='ax9000'
    uci -q set lyq.disk_path='/extdisks'
fi
uci commit lyq
[ "$(uci -q get lyq.model | tr -d '\n')" = "" ] && echo UCI功能异常
[ "$(uci -q get lyq.model | tr -d '\n')" = "" ] && exit

uci -q set lyq.xxx_set_radio_mode="mtd"
[ ! -n "$(echo -n `uci -q get lyq.xxx_source_list_url`)" ] && uci -q set lyq.xxx_source_list_url="https://api.github.com/repos/V2023H/xxx_box/contents/xxx_box/box.json?ref=main"
[ ! -n "$(echo -n `uci -q get lyq.xxx_update_list_json`)" ] && uci -q set lyq.xxx_update_list_json="https://api.github.com/repos/V2023H/xxx_box/contents/xxx_box/xxx.json?ref=main"
uci commit lyq

xxxlist=""
[ -d "/mnt/sda/mi_xxx" ] && xxxlist="$(echo -n $(ls /mnt/sda/mi_xxx/))"
if [ -n "$(echo -n $xxxlist)" ]; then
    echo -e "检测到已有安装插件，建议保留配置，确认继续安装吗？(1保留/0清除)"
    read -p "请输入1或0(默认1保留) > " confirm
    if [ "$confirm" == "0" ]; then
        echo "清除安装已有安装的插件"
        rm -rf /mnt/sda/mi_xxx/*
        rm -rf /mnt/mtd/xxx/*
    fi
fi

chmod 777 /data/xxxcon/autostart
/data/xxxcon/autostart init
[ $? = 999 ] && echo "安装失败!!!"
[ $? = 999 ] && exit
chmod 777 $xxx_path/xxxcon/autostart
$xxx_path/xxxcon/autostart
echo "安装完成!!!"
read -p "插件交流QQ群：134374534！"
rm -rf /tmp/tmp/xxx_install > /dev/null 2>&1
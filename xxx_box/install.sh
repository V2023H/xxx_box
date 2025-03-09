echo 准备安装扩展功能
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
xxx_path_tmp=$(df | grep -v "100%" | awk '{print $6}' | cut -c 2- | grep -v / | tail -n +2 | grep -v dev | grep -v tmp  | grep -v root | awk '{print "/"$1}')
xxx_path_tmp="$xxx_path_tmp
$sda_path"
min_size=10424 #安装磁盘最小12MB空间
IFS='
'
path_str=""
for item in $xxx_path_tmp
do
    [ -f "$item/mtd/E87A0832F9B6F" ] && mkdir -p /tmp/tmp/rom_tmp/$item/mtd > /dev/null 2>&1
    [ -f "$item/mtd/E87A0832F9B6F" ] && mv -f $item/mtd/E87A0832F9B6F /tmp/tmp/rom_tmp/$item/mtd/E87A0832F9B6F > /dev/null 2>&1
    [ -f "$item/mtd/xxx_tool" ] && mkdir -p /tmp/tmp/rom_tmp/$item/mtd > /dev/null 2>&1
    [ -f "$item/mtd/xxx_tool" ] && mv -f $item/mtd/xxx_tool /tmp/tmp/rom_tmp/$item/mtd/xxx_tool > /dev/null 2>&1
    [ -f "$item/mtd/install.sh" ] && mkdir -p /tmp/tmp/rom_tmp/$item/mtd > /dev/null 2>&1
    [ -f "$item/mtd/install.sh" ] && mv -f $item/mtd/install.sh  /tmp/tmp/rom_tmp/$item/mtd/install.sh > /dev/null 2>&1
    disk_avai_size=$(df $item | tail -n +2 | awk '{print $4}')
    [ $(($disk_avai_size)) -gt $min_size ] && ii=$(($ii+1)) || continue
    [ $ii -lt 7 ] || continue
    path_str=$(echo -e "$path_str"$ii：$item "\t free：$(  awk "BEGIN{printf \"%0.2f\",$(df $item | tail -n +2 | awk '{print $4}')/1024}" )MB\n ")
done
path_str=$(echo -e "$path_str""$(($ii+1))：自定义位置 （不推荐使用）")
[ $(($ii)) -lt 1 ] && cp -fr /tmp/tmp/rom_tmp/* / > /dev/null 2>&1
rm -rf /tmp/tmp/rom_tmp/ > /dev/null 2>&1
[ $(($ii)) -lt 1 ] && echo 系统没有可用空间安装扩展功能。 && exit

#选择XXX安装位置

echo -----------------------------------------------
echo '---------小米扩展功能准备开始安装--------------'
echo -----------------------------------------------
echo -e "推荐安装至USB空间，系统空间普遍较小。"
echo -e "请选择安装位置 (默认1)"
echo -e "$path_str" | sed "s/ //g"
read -p "请输入对应数字 > " path_num
echo -----------------------------------------------
[ "$path_num" = "" ] && path_num=1
[ $(($ii+1)) -lt $path_num ] && exit
xxx_path=$(echo -e "$path_str" | sed -n $path_num'p' | sed "s/ //g")
if [ -n "$(echo $xxx_path | grep -v "free")" ]; then
    read -p "请输入安装位置 > " xxx_path
    [ -d "$xxx_path" ] && echo 目录已存在，开始安装 || echo 目录不存在，创建安装
    mkdir -p $xxx_path > /dev/null 2>&1
    [ -d "$xxx_path" ] || echo 目录无效，终止安装！！！
    [ -d "$xxx_path" ] || exit
else
    xxx_path=$(echo $xxx_path | cut -c 5- | awk '{print $1}')
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
    mkdir $xxx_path
    uci set lyq.xxx_path="$xxx_path"
fi
uci commit lyq
#创建MTD文件夹
[ -d $xxx_path/mtd ] && echo 'MTD空间准备就绪...' || mkdir -p $xxx_path/mtd
cd  `dirname $0`
cp ./xxx_install $xxx_path/mtd/E87A0832F9B6F
tar -Jxf ./xxx_install tmp/xxxbox_mtd -C /$xxx_path
mv $xxx_path/tmp/xxxbox_mtd/* $xxx_path/mtd
ls $xxx_path/mtd | grep xxx_init.sh > /dev/null && echo "准备验证安装文件..." || echo "文件获取失败，请重启再试！！！"
ls $xxx_path/mtd | grep xxx_init.sh > /dev/null && echo "完成扩展功能安装！！！" || exit
#加载新分区MTD，分区自己确认一下
echo -----------------------------------------------
echo -e "是否需要备份？ (默认1)"
echo -e "1：无需备份或者已备份配置，直接进行安装扩展功能！"
echo -e "2：备份Wi-Fi设置,上网设置,DHCP服务...,覆盖原备份"
read -p "请输入对应数字 > " num
echo -----------------------------------------------
[ "$num" = "" ] && num=1
if [ "$num" = 1 ]; then
    echo 跳过备份，尝试安装
elif [ "$num" = 2 ]; then
    echo 备份数据，尝试运行
    #准备开始备份
    bak_path='/tmp/tmp/config_bak'
    mkdir $bak_path > /dev/null 2>&1
    #WIFI
    cp -rf /etc/config/wireless $bak_path/wireless > /dev/null 2>&1
    #DHCP
    cp -rf /etc/config/dhcp $bak_path/dhcp > /dev/null 2>&1
    #宽带信息
    cp -rf /etc/config/network $bak_path/network > /dev/null 2>&1
    #路由器名称
    cp -rf /etc/config/xiaoqiang $bak_path/xiaoqiang > /dev/null 2>&1
    #路由器登录密码
    cp -rf /etc/config/account $bak_path/account > /dev/null 2>&1
    #双wan
    cp -rf /etc/config/dualwan $bak_path/dualwan > /dev/null 2>&1
    cp -rf /etc/config/misc $bak_path/misc > /dev/null 2>&1
    #防火墙
    cp -rf /etc/config/firewall $bak_path/firewall > /dev/null 2>&1
    #加密备份
    cd /tmp/tmp
    tar -czf - config_bak | openssl enc -e -pbkdf2 -out $xxx_path/mtd/E87A0832F9B6B -k xiaoqian
    rm -rf $bak_path > /dev/null 2>&1
    sda=`df -T | grep ext4 | grep /dev/sd | awk '{print $7}' | grep -v docker | awk 'NR==1 {print $0}'`
    is_sda=`df | grep /dev/sd && echo true || echo false`
    [ -n "$sda" ] && [ "$is_sda" = "false" ] && echo '无硬盘或优盘，备份在'$xxx_path'/mtd/E87A0832F9B6B，重置会丢失备份！' || mv -f $xxx_path/mtd/E87A0832F9B6B $sda/mi_bak/E87A0832F9B6B
    [ -n "$sda" ] && [ "$is_sda" = "false" ] && exit || echo "备份在磁盘目录：$sda/mi_bak/E87A0832F9B6B"
    exit
else
    exit
fi
sh $xxx_path/mtd/xxx_init.sh

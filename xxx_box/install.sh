#开始安装
echo '小米扩展功能准备开始安装...'
cd  `dirname $0`

#创建文件夹
ls /mnt | grep mtd > /dev/null && echo 'MTD位置准备就绪'|| mkdir /mnt/mtd > /dev/null
    user_size=`df /userdisk | grep / |awk '{print $4}'`
    data_size=`df /data | grep / |awk '{print $4}'`
    if [ "$user_size" -lt "$data_size" ]; then
        disk_path="/data"
    else
        disk_path="/userdisk"
    fi
disk_use_size=`df $disk_path | grep / | awk '{print $4}'`
[ $(($disk_use_size)) -gt 10000 ] || echo '系统空间小于10MB，无法安装.'
[ $(($disk_use_size)) -gt 10000 ] || exit
ls $disk_path | grep mtd > /dev/null && echo 'MTD空间准备就绪'|| mkdir $disk_path/mtd > /dev/null
#验证是否挂载成功，未成功则手动挂载
/bin/df |/bin/grep /mnt/mtd&& echo 'mtd_磁盘挂载成功' || /bin/mount --bind  $disk_path/mtd /mnt/mtd 2>&1
cp ./xxx_install /mnt/mtd/E87A0832F9B6F
tar -Jxf ./xxx_install mtd -C /mnt
ls /mnt/mtd | grep xxx_init.sh > /dev/null && echo "准备验证安装文件..." || echo "文件获取失败，请重启再试！！！"
ls /mnt/mtd | grep xxx_init.sh > /dev/null && echo "完成扩展功能安装！" || exit
#加载新分区MTD，分区自己确认一下
echo -----------------------------------------------
echo -e "是否需要备份？"
echo -e "1：无需备份或者已备份配置，直接进行安装扩展功能！"
echo -e "2：备份Wi-Fi设置,上网设置,DHCP服务...,覆盖原备份"
read -p "请输入对应数字 > " num
echo -----------------------------------------------
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
    tar -czf - config_bak | openssl enc -e -aes256 -out /mnt/mtd/E87A0832F9B6B -k xiaoqian
    rm -rf $bak_path > /dev/null 2>&1
    sda=`df -T | grep ext4 | grep /dev/sd | awk '{print $7}' | grep -v docker | awk 'NR==1 {print $0}'`
    is_sda=`df | grep /mnt/sda && echo true || echo false`
    [ -n "$sda" ] && [ "$is_sda" = "false" ] && echo '无硬盘或优盘，备份在/mnt/mtd/E87A0832F9B6B，重置会丢失备份！' || mv -f /mnt/mtd/E87A0832F9B6B $sda/mi_bak/E87A0832F9B6B
    [ -n "$sda" ] && [ "$is_sda" = "false" ] && exit || echo "备份在磁盘目录：$sda/mi_bak/E87A0832F9B6B"
    exit
else
    exit
fi
sh /mnt/mtd/xxx_init.sh

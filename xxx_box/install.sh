#格式化,开始安装
mtd=`cat /proc/mtd | grep rootfs_1 | awk '{print $1}' | sed 's/:$//g'`
mtdb=`cat /proc/mtd | grep rootfs_1 | awk '{print $1}' | sed 's/:$//g' | sed 's/mtd/mtdblock/g'`
if [ -n "$(cat /usr/share/xiaoqiang/xiaoqiang_version | grep RC06)" ] && [ -n "$(cat /usr/share/xiaoqiang/xiaoqiang_version | grep ROM | grep 1.0.111)" ]; then
    echo 小米7000开始安装
elif [ -n "$(cat /usr/share/xiaoqiang/xiaoqiang_version | grep RA70)" ] && [ -n "$(cat /usr/share/xiaoqiang/xiaoqiang_version | grep ROM | grep 1.0.168)" ]; then
    echo 小米ax9000开始安装
else
    read -p "型号或者版本不兼容，强行安装请输入1，按任意键结束安装 > " num
    if [ "$num" = 1 ]; then
        echo 尝试强行安装...
    else
        exit
    fi
fi
echo "准备开始安装..."
umount -f /mnt/mtd > /dev/null 2>&1
mkfs.ext4 /dev/$mtdb
cd  `dirname $0`
#创建文件夹
ls /mnt | grep mtd > /dev/null && echo '--------------'|| mkdir /mnt/mtd > /dev/null
#验证是否挂载成功，未成功则手动挂载
/bin/df |/bin/grep $mtdb&& echo mtd_挂载成功 || /bin/mount -t ext4 /dev/$mtdb /mnt/mtd 2>&1
cp ./xxx_install /mnt/mtd/E87A0832F9B6F
tar -Jxf ./xxx_install mtd -C /mnt
ls /mnt/mtd | grep xxx_tool > /dev/null && echo "开始获取解密文件。" || echo "解密文件获取失败，请重启再试！！！"
ls /mnt/mtd | grep xxx_tool > /dev/null && echo "成功获取解密文件。" || exit
/mnt/mtd/xxx_tool password | grep 'root' > /dev/null && echo "开始设置分区文件。" || echo  "设置分区文件失败。"
/mnt/mtd/xxx_tool password | grep 'root' > /dev/null && echo "分区设置文件成功。" || exit
#加载新分区MTD，分区自己确认一下
echo -----------------------------------------------
echo -e "正在使用$mtd 分区安装工具,禁止将安装文件放在$mtd 分区"
echo -e "1：去除所有配置，适合全新安装！"
echo -e "2：保留Wi-Fi设置,上网设置,DHCP服务,局域网IP设置,路由器名称,路由器密码,扩展功能配置"
echo -e "3：更新安装文件，保留所有配置安装，适合UI更新."
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
    echo 备份数据，运行完成

elif [ "$num" = 3 ]; then
    mkdir /mnt/mtd > /dev/null 2>&1
    /bin/mount -t ext4 /dev/mtdblock22 /mnt/mtd > /dev/null 2>&1
    /bin/tar -Jxf /mnt/mtd/E87A0832F9B6F userdisk/auto_start.sh userdisk/auto_start2.sh userdisk/start_stop.sh userdisk/skadi -C /
    read -p "按任意键继续！重启路由器即可完成更新！"
    reboot
    exit
else
    exit
fi
echo "切记：重启后运行下面这行命令激活工具箱"
mtdb=`cat /proc/mtd | grep rootfs_1 | awk '{print $1}' | sed 's/:$//g' | sed 's/mtd/mtdblock/g'`
#mkdir /mnt/mtd > /dev/null && /bin/mount -t ext4 /dev/$mtdb /mnt/mtd
echo "mkdir /mnt/mtd && /bin/mount -t ext4 /dev/$mtdb /mnt/mtd && sh /mnt/mtd/xxx_init.sh"
echo "重启后登录TEL，默认信息 "`/mnt/mtd/xxx_tool password`
env -i sleep 4 && nvram set restore_defaults=1 && nvram commit && reboot & >/dev/null 2>/dev/null



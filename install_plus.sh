echo 若下载缓慢可根据网络情况选择下载安装源
echo 1.[github]' '2.[cloudflare]' '3.[jsdelivr]
read -p "选择安装源： > " num
function cloudflaregetfile
{
    echo 准备下载（$num）...
    down_json=`curl "$1" -ks`
    loca_file_name=`echo "$down_json" | jsonfilter -e "@.data.name"`
    loca_file_size=`echo "$down_json" | jsonfilter -e "@.data.size"`
    message=`echo "$down_json" | jsonfilter -e "@['message']"`
    #检查文件信息
    if [ -n "$loca_file_name" ]; then
        #cloudflare直连下载文件
        file_url=`echo "$down_json" | jsonfilter -e "@.data.raw_url"`
        curl -ks -o /tmp/xxx_install $file_url >/dev/null 2>&1 &
        checkfile $loca_file_size
    else
        echo 下载出错 $message
        exit
    fi
}

function githubgetfile
{
    echo 准备下载（$num）...
    down_json=`curl "$1" -ks`
    loca_file_name=`echo "$down_json" | jsonfilter -e "@['name']"`
    loca_file_size=`echo "$down_json" | jsonfilter -e "@['size']"`
    message=`echo "$down_json" | jsonfilter -e "@['message']"`
    #检查文件信息
    if [ -n "$loca_file_name" ]; then
        #github直连下载文件
        file_url=`echo "$down_json" | jsonfilter -e "@['git_url']"`
        curl -ks -o /tmp/xxx_install $file_url >/dev/null 2>&1 &
        checkfile $((loca_file_size*1000/725))
        xxx_install_json=$(cat /tmp/xxx_install)
        echo $xxx_install_json | jsonfilter -e "@['content']" | base64 -d > /tmp/xxx_install
    else
        echo 下载出错 $message
        exit
    fi
}

function jsdelivrgetfile
{
        #jsdelivr直连下载文件
        file_url=$1
        curl -ks -o /tmp/xxx_install $file_url >/dev/null 2>&1 &
        checkfile 19999999
}

function checkfile
{
    while [ ! -f '/tmp/xxx_install' ]
    do
        sleep 1
    done
    filesize=$1
    downfilesize="$(($(du -k /tmp/xxx_install | awk '{print $1}')*1024))"
    in=0
    inf=0
    echo '(0%)''--------------------------------------------------''(100%)'
    echo -n '(0%)'
    while true
    do
        downfilesize="$(($(du -k /tmp/xxx_install | awk '{print $1}')*1024))"
        in=$((downfilesize * 50 / filesize))
        if [ $in -gt $inf ]; then
            in=$((in-inf))
            for i in $(seq $in -1 1)
            do
                echo -n '-'
                inf=$((inf+1))
            done
        fi
        [ $in = 50 ] && break
        if [ ! -n "$(ps | grep 'curl -ks -o /tmp/xxx_install' | grep -v grep)" ]; then
            in=$((50-inf))
            for i in $(seq $in -1 1)
            do
                echo -n '-'
                inf=$((inf+1))
            done
            break
        fi
        sleep 1
    done
    echo '(100%)'
    echo "下载完成（$num）..."
}
rm -rf /tmp/xxx_install
if [ "$num" = 1 ]; then
    #github
    githubgetfile 'https://api.github.com/repos/V2023H/xxx_box/contents/new_xxx/xxx_install?ref=main'
elif [ "$num" = 2 ]; then
    #cloudflare
    cloudflaregetfile 'https://xxx.v2026h.com/new_xxx/xxx_install'
elif [ "$num" = 3 ]; then
    #jsdelivr
    jsdelivrgetfile 'https://cdn.jsdelivr.net/gh/V2023H/xxx_box@main/new_xxx/xxx_install'
else
    echo 取消安装
    exit
fi
tar -Jxf /tmp/xxx_install tmp/xxxbox_mtd/install.sh -C /tmp && mv /tmp/tmp/xxxbox_mtd/install.sh /tmp/install.sh && sh /tmp/install.sh
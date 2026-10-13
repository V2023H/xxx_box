#!/bin/ash
download_with_progress() {
    local url="$1"
    local output="/tmp/tmp/xxx_install"
    
    # 检查 curl 是否可用
    if ! command -v curl >/dev/null 2>&1; then
        echo "错误: curl 未安装"
        return 1
    fi
    
    # 获取文件大小
    local file_size
    file_size=$(curl -sI "$url" | grep -i 'Content-Length' | awk '{print $2}' | tr -d '\r')
    
    if [ -z "$file_size" ] || [ "$file_size" = "0" ]; then
        echo "无法获取文件信息 ✗"
		exit
    fi
    
    echo "现在开始下载文件 大小: $(echo "$file_size / 1024 / 1024" | bc) MB"
    
    # 使用 curl 的内置进度条
    curl -L --progress-bar -o "$output" "$url"
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "升级文件下载完成 ✓"
		echo "现在开始升级扩展"
		$(uci get lyq.xxx_path | tr -d ' ' | tr -d '\n')/xxxcon/xxxbox install_rom $output
    else
        echo "升级文件下载失败 ✗(错误代码: $exit_code)"
        rm -f "$output"
		exit
    fi
    
    return $exit_code
}


echo -n 检查系统环境
if [ "$(cat /etc/profile | grep 'alias box=' | cut -d'=' -f2- | tr -d '"'"'" | tr -d ' ' | tr -d '\n')" == "$(uci get lyq.xxx_path | tr -d ' ' | tr -d '\n')/xxxcon/xxxbox" ] && [ -f "$(uci get lyq.xxx_path | tr -d ' ' | tr -d '\n')/xxxcon/xxxbox" ]; then
	echo "完成 ✓" 
else
	echo "异常 ✗"
	exit
fi
echo 准备下载升级文件...
download_with_progress "$@"
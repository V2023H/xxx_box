# xxx_box
路由器扩展功能，在这里分享一下
一键安装命令：


curl -ks https://api.github.com/repos/V2023H/xxx_box/contents/install?ref=main  | jsonfilter -e "@['content']" | base64 -d >/tmp/i && sh /tmp/i


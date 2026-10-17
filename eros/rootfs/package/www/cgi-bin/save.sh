#!/bin/sh
# CGI 输出必须先是 HTTP 头，再空行，再是正文
echo "Content-Type: text/html; charset=utf-8"
echo ""

# QUERY_STRING 形如 msg=hello+world
MSG=$(echo "$QUERY_STRING" | sed 's/^msg=//; s/+/ /g')
# URL 解码（%xx → 字符）
MSG=$(printf '%b' "$(echo "$MSG" | sed 's/%%/\\x/g')")

# 写入 /tmp
echo "$(date '+%Y-%m-%d %H:%M:%S')  $MSG" >> /tmp/wwwdata/messages.txt

cat <<EOF
<html><body>
<h2>已保存</h2>
<p>内容：$MSG</p>
<p>存储位置：/tmp/wwwdata/messages.txt</p>
<a href="/">返回</a>
</body></html>
EOF

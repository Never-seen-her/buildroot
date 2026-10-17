#!/bin/sh
echo "Content-Type: text/html; charset=utf-8"
echo ""

cat <<EOF
<html><body>
<h2>已保存的消息</h2>
<pre>
EOF

[ -f /tmp/wwwdata/messages.txt ] && cat /tmp/wwwdata/messages.txt

cat <<EOF
</pre>
<a href="/">返回</a>
</body></html>
EOF

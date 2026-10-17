#!/bin/sh

mkdir -p /tmp/wwwdata
chmod 755 /tmp/wwwdata

urldecode() {
    printf '%b' "$(printf '%s' "$1" | sed 's/+/ /g; s/%/\\x/g')"
}

FILENAME=$(printf '%s' "${QUERY_STRING:-}" \
    | sed -n 's/.*filename=\([^&]*\).*/\1/p')
FILENAME=$(urldecode "$FILENAME")
[ -z "$FILENAME" ] && FILENAME="note_$(date +%s).bin"
FILENAME=$(printf '%s' "$FILENAME" | tr -d '/\\\r\n')
[ -z "$FILENAME" ] && FILENAME="note_$(date +%s).bin"

OUT="/tmp/wwwdata/$FILENAME"

if [ -n "$CONTENT_LENGTH" ] && [ "$CONTENT_LENGTH" -gt 0 ] 2>/dev/null; then
    head -c "$CONTENT_LENGTH" > "$OUT"
else
    cat > "$OUT"
fi
#exec 0<&-

SIZE=$(wc -c < "$OUT")

# 先构造 HTML 到临时文件，避免引号地狱
TMPBODY=/tmp/_body.$$
cat > "$TMPBODY" <<HTML
<html><body>
<h2>上传完成</h2>
<p>文件保存到：$OUT</p>
<p>大小：$SIZE 字节</p>
<a href="/">返回</a>
</body></html>
HTML

LEN=$(wc -c < "$TMPBODY")

printf 'Content-Type: text/html; charset=utf-8\r\n'
printf 'Content-Length: %d\r\n' "$LEN"
printf '\r\n'
cat "$TMPBODY"

rm -f "$TMPBODY"

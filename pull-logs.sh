#!/bin/bash
# 从模拟器拉取 App 日志文件到本地
# 用法：
#   bash pull-logs.sh           # 拉取 mock 包日志（默认）
#   bash pull-logs.sh mock      # 拉取 mock 包日志
#   bash pull-logs.sh debug     # 拉取 debug 包日志
#   bash pull-logs.sh release   # 拉取 release 包日志

HDC='/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc'
TARGET='127.0.0.1:5555'

ENV="${1:-mock}"

case "$ENV" in
  mock)    BUNDLE='com.cainluo.miyoyo.tools.mock' ;;
  debug)   BUNDLE='com.cainluo.miyoyo.tools.debug' ;;
  release) BUNDLE='com.cainluo.miyoyo.tools' ;;
  *)
    echo "✗ 未知环境：$ENV（可选：mock / debug / release）"
    exit 1
    ;;
esac

REMOTE_DIR="/data/app/el2/100/base/$BUNDLE/haps/entry/files/logs"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_DIR="$SCRIPT_DIR/logs"

# ── 检查模拟器连接 ────────────────────────────────────────────
if ! "$HDC" list targets 2>/dev/null | grep -q "$TARGET"; then
  echo "✗ 模拟器未连接（$TARGET），请先启动模拟器"
  exit 1
fi

# ── 拉取日志目录 ──────────────────────────────────────────────
echo "▶ 拉取 [$ENV] 日志..."
echo "  远端：$REMOTE_DIR"
echo "  本地：$LOCAL_DIR"

mkdir -p "$LOCAL_DIR"
"$HDC" -t "$TARGET" file recv "$REMOTE_DIR" "$LOCAL_DIR"

# hdc file recv 会把远端目录名带过来，把内层 logs/ 的文件移到外层
if [ -d "$LOCAL_DIR/logs" ]; then
  PULL_TIME=$(date '+%H%M%S')
  for f in "$LOCAL_DIR/logs/"*.txt; do
    [ -f "$f" ] || continue
    BASENAME=$(basename "$f" .txt)
    mv "$f" "$LOCAL_DIR/${BASENAME}_pulled-${PULL_TIME}.txt"
  done
  rmdir "$LOCAL_DIR/logs" 2>/dev/null
fi

# ── 统计结果 ──────────────────────────────────────────────────
FILE_COUNT=$(find "$LOCAL_DIR" -name "*.txt" | wc -l | tr -d ' ')
if [ "$FILE_COUNT" -eq 0 ]; then
  echo "⚠️  没有找到日志文件（App 可能还没产生日志）"
  exit 0
fi

TOTAL_SIZE=$(du -sh "$LOCAL_DIR" | cut -f1)
echo "✅ 完成：$FILE_COUNT 个文件，共 $TOTAL_SIZE"
echo "   保存位置：$LOCAL_DIR"

# ── 用 Finder 打开目录 ────────────────────────────────────────
open "$LOCAL_DIR"
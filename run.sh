#!/bin/bash
# 构建 release product（正式发布）并安装到模拟器
# 支持通过 Proxyman Local Rewrite 拦截流量
#
# 用法：
#   bash run.sh                            # 直接连真实 API
#   bash run.sh --proxy 192.168.1.x:9090   # 流量走 Proxyman 代理
#   bash run.sh --clear-proxy              # 清除模拟器代理设置
#
# Proxyman 使用步骤：
#   1. Proxyman → Tools → Local Rewrite，添加规则拦截目标 URL
#   2. 查看 Mac IP：System Settings → Wi-Fi → Details → IP Address
#   3. bash run.sh --proxy <Mac IP>:9090

set -e

EMULATOR='/Applications/DevEco-Studio.app/Contents/tools/emulator/Emulator'
HDC='/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc'
HVIGOR='/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw'
export DEVECO_SDK_HOME='/Applications/DevEco-Studio.app/Contents/sdk'

BUNDLE='com.cainluo.miyoyo.tools'
TARGET='127.0.0.1:5555'
AVD="${AVD:-Mate 80 Pro Max}"
AVD_PATH="$HOME/.Huawei/Emulator/deployed/$AVD"
IMAGE_ROOT="$HOME/Library/Huawei/Sdk"
HAP='entry/build/default/outputs/default/entry-default-unsigned.hap'

PROXY_HOST=''
CLEAR_PROXY=false

# 解析参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    --proxy)
      PROXY_HOST="$2"
      shift 2
      ;;
    --clear-proxy)
      CLEAR_PROXY=true
      shift
      ;;
    *)
      AVD="$1"
      shift
      ;;
  esac
done

# ── 1. 启动模拟器（如果还没运行）──────────────────────────────
if "$HDC" list targets 2>/dev/null | grep -q "$TARGET"; then
  echo "✓ 模拟器已在运行"
else
  echo "▶ 启动模拟器：$AVD"
  "$EMULATOR" -hvd "$AVD" -path "$AVD_PATH" -imageRoot "$IMAGE_ROOT" &
  echo "⏳ 等待模拟器就绪（最多 30 秒）..."
  for i in $(seq 1 30); do
    sleep 1
    if "$HDC" list targets 2>/dev/null | grep -q "$TARGET"; then
      echo "✓ 模拟器已连接"
      break
    fi
    if [ "$i" -eq 30 ]; then
      echo "✗ 模拟器启动超时"
      exit 1
    fi
  done
fi

# ── 2. 代理设置 ───────────────────────────────────────────────
if [ "$CLEAR_PROXY" = true ]; then
  echo "▶ 清除模拟器代理..."
  "$HDC" -t "$TARGET" shell param set persist.netmanager.http_proxy ""
  echo "✓ 代理已清除"
  exit 0
fi

if [ -n "$PROXY_HOST" ]; then
  echo "▶ 设置模拟器代理 → $PROXY_HOST"
  "$HDC" -t "$TARGET" shell param set persist.netmanager.http_proxy "$PROXY_HOST"
  echo "✓ 代理已设置，流量将经过 Proxyman"
fi

# ── 3. Clean ──────────────────────────────────────────────────
echo "▶ Clean..."
"$HVIGOR" clean

# ── 4. Build (default/release product) ───────────────────────
echo "▶ Build (release)..."
"$HVIGOR" assembleHap -p product=default

# ── 5. 安装 ──────────────────────────────────────────────────
echo "▶ 安装..."
"$HDC" -t "$TARGET" install "$HAP"

# ── 6. 启动 ──────────────────────────────────────────────────
echo "▶ 启动..."
"$HDC" -t "$TARGET" shell aa start -b "$BUNDLE" -a EntryAbility

if [ -n "$PROXY_HOST" ]; then
  echo "✅ 完成（release，流量经过 Proxyman: $PROXY_HOST）"
  echo "   清除代理：bash run.sh --clear-proxy"
else
  echo "✅ 完成（release）"
fi

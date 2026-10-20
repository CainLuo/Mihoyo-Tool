#!/bin/bash
# 构建并安装到模拟器
#
# 用法：
#   bash run.sh                            # 交互选择（5 秒无输入默认 debug）
#   bash run.sh debug                      # 直接指定 product
#   bash run.sh mock                       # 独立 mock 包（APP_ENV=mock，bundle .mock）
#   bash run.sh internal
#   bash run.sh release
#   bash run.sh release --proxy 192.168.1.x:9090   # release + Proxyman 代理
#   bash run.sh --clear-proxy              # 清除模拟器代理设置

set -e

EMULATOR='/Applications/DevEco-Studio.app/Contents/tools/emulator/Emulator'
HDC='/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc'
HVIGOR='/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw'
export DEVECO_SDK_HOME='/Applications/DevEco-Studio.app/Contents/sdk'

TARGET='127.0.0.1:5555'
AVD="${AVD:-Mate 80 Pro Max}"
AVD_PATH="$HOME/.Huawei/Emulator/deployed/$AVD"
IMAGE_ROOT="$HOME/Library/Huawei/Sdk"

PRODUCT=''
BUILD_PRODUCT=''
PROXY_HOST=''
CLEAR_PROXY=false

# ── 解析参数 ──────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    mock|debug|internal|release)
      PRODUCT="$arg"
      ;;
    --proxy)
      # 下一个参数是代理地址，用 shift 处理
      ;;
    --clear-proxy)
      CLEAR_PROXY=true
      ;;
  esac
done

# 单独处理 --proxy 的值（需要位置参数）
while [[ $# -gt 0 ]]; do
  case "$1" in
    --proxy)
      PROXY_HOST="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# ── 清除代理（快速退出）──────────────────────────────────────
if [ "$CLEAR_PROXY" = true ]; then
  echo "▶ 清除模拟器代理..."
  "$HDC" -t "$TARGET" shell param set persist.netmanager.http_proxy ""
  echo "✓ 代理已清除"
  exit 0
fi

# ── 交互选择 product（未通过参数指定时）──────────────────────
if [ -z "$PRODUCT" ]; then
  echo ""
  echo "  选择构建目标（5 秒无输入默认 debug）："
  echo "  [1] debug    — 真实 API，手机号登录，可抓包"
  echo "  [2] mock     — 独立 mock 包（APP_ENV=mock）"
  echo "  [3] internal — 真实 API，手机号登录，正式签名"
  echo "  [4] release  — 上架包，无手机号登录"
  echo ""

  # read -t 5 在 bash 中支持超时
  if read -t 5 -p "  输入 1/2/3/4 或直接回车：" choice 2>/dev/null; then
    case "$choice" in
      2) PRODUCT='mock' ;;
      3) PRODUCT='internal' ;;
      4) PRODUCT='release' ;;
      *) PRODUCT='debug' ;;
    esac
  else
    echo ""
    echo "  ⏱ 超时，使用默认：debug"
    PRODUCT='debug'
  fi
fi

# ── 根据 product 设置 bundle 和 HAP 路径 ─────────────────────
case "$PRODUCT" in
  mock)
    BUILD_PRODUCT='mock'
    BUNDLE='com.cainluo.miyoyo.tools.mock'
    HAP='entry/build/mock/outputs/mock/entry-mock-unsigned.hap'
    ;;
  debug)
    BUILD_PRODUCT='debug'
    BUNDLE='com.cainluo.miyoyo.tools.debug'
    HAP='entry/build/debug/outputs/debug/entry-debug-unsigned.hap'
    ;;
  internal)
    BUILD_PRODUCT='internal'
    BUNDLE='com.cainluo.miyoyo.tools'
    HAP='entry/build/internal/outputs/internal/entry-internal-signed.hap'
    ;;
  release)
    BUILD_PRODUCT='default'
    BUNDLE='com.cainluo.miyoyo.tools'
    HAP='entry/build/default/outputs/default/entry-default-signed.hap'
    ;;
esac

echo ""
if [ "$PRODUCT" = "mock" ]; then
  echo "▶ 构建目标：mock（独立 .mock 包，APP_ENV=mock）"
else
  echo "▶ 构建目标：$PRODUCT"
fi

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

# ── 2. 代理设置（仅 release/debug 有意义）────────────────────
if [ -n "$PROXY_HOST" ]; then
  echo "▶ 设置模拟器代理 → $PROXY_HOST"
  "$HDC" -t "$TARGET" shell param set persist.netmanager.http_proxy "$PROXY_HOST"
  echo "✓ 代理已设置"
fi

# ── 3. Clean ──────────────────────────────────────────────────
echo "▶ Clean..."
"$HVIGOR" clean

# ── 4. Build ──────────────────────────────────────────────────
echo "▶ Build ($PRODUCT)..."
"$HVIGOR" assembleHap -p product="$BUILD_PRODUCT"

# ── 5. 安装 ──────────────────────────────────────────────────
echo "▶ 安装..."
"$HDC" -t "$TARGET" install "$HAP"

# ── 6. 启动 ──────────────────────────────────────────────────
echo "▶ 启动..."
"$HDC" -t "$TARGET" shell aa start -b "$BUNDLE" -a EntryAbility

if [ -n "$PROXY_HOST" ]; then
  echo "✅ 完成（$PRODUCT，代理：$PROXY_HOST）"
  echo "   清除代理：bash run.sh --clear-proxy"
else
  echo "✅ 完成（$PRODUCT）"
fi

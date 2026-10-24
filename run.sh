#!/bin/bash
# 构建并安装到模拟器
#
# 用法：
#   bash run.sh                            # 交互选择（5 秒无输入默认 uat）
#   bash run.sh uat                        # UAT：官方 API，Debug 能力，bundle .uat
#   bash run.sh mock                       # Mock：本机 local-service，bundle .mock
#   bash run.sh release                    # Release：官方 API，bundle 正式包名
#   bash run.sh uat --proxy 192.168.1.x:9090
#   bash run.sh --clear-proxy

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
BUILD_MODE=''
PROXY_HOST=''
CLEAR_PROXY=false

# ── 解析参数 ──────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    mock|uat|release)
      PRODUCT="$1"
      shift
      ;;
    --proxy)
      PROXY_HOST="$2"
      shift 2
      ;;
    --clear-proxy)
      CLEAR_PROXY=true
      shift
      ;;
    *)
      echo "未知参数：$1"
      exit 1
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
  echo "  选择构建目标（5 秒无输入默认 uat）："
  echo "  [1] uat      — 官方 API，手机号登录，Debug 能力"
  echo "  [2] mock     — 本机 local-service（127.0.0.1:8787）"
  echo "  [3] release  — 上架包，官方 API"
  echo ""

  if read -t 5 -p "  输入 1/2/3 或直接回车：" choice 2>/dev/null; then
    case "$choice" in
      2) PRODUCT='mock' ;;
      3) PRODUCT='release' ;;
      *) PRODUCT='uat' ;;
    esac
  else
    echo ""
    echo "  ⏱ 超时，使用默认：uat"
    PRODUCT='uat'
  fi
fi

# ── 根据 product 设置 bundle、buildMode 和 HAP 路径 ───────────
case "$PRODUCT" in
  mock)
    BUILD_PRODUCT='mock'
    BUILD_MODE='debug'
    BUNDLE='com.cainluo.miyoyo.tools.mock'
    HAP_SIGNED='entry/build/mock/outputs/mock/entry-mock-signed.hap'
    HAP_UNSIGNED='entry/build/mock/outputs/mock/entry-mock-unsigned.hap'
    ALLOW_UNSIGNED=1
    ;;
  uat)
    BUILD_PRODUCT='uat'
    BUILD_MODE='debug'
    BUNDLE='com.cainluo.miyoyo.tools.uat'
    HAP_SIGNED='entry/build/uat/outputs/uat/entry-uat-signed.hap'
    HAP_UNSIGNED='entry/build/uat/outputs/uat/entry-uat-unsigned.hap'
    ALLOW_UNSIGNED=1
    ;;
  release)
    BUILD_PRODUCT='release'
    BUILD_MODE='release'
    BUNDLE='com.cainluo.miyoyo.tools'
    HAP_SIGNED='entry/build/release/outputs/release/entry-release-signed.hap'
    HAP_UNSIGNED=''
    ALLOW_UNSIGNED=0
    ;;
esac
HAP="$HAP_SIGNED"

# UAT / Mock 在模拟器上允许安装 unsigned HAP；release 必须使用签名 HAP。


echo ""
echo "▶ 构建目标: $PRODUCT (bundle=$BUNDLE, buildMode=$BUILD_MODE)"

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
"$HVIGOR" assembleHap -p product="$BUILD_PRODUCT" -p buildMode="$BUILD_MODE"

# ── 5. 安装 ──────────────────────────────────────────────────
if [ ! -f "$HAP" ] && [ "$ALLOW_UNSIGNED" = "1" ] && [ -f "$HAP_UNSIGNED" ]; then
  HAP="$HAP_UNSIGNED"
  echo "⚠ 未生成签名 HAP，使用 unsigned HAP（模拟器可安装）"
fi

if [ ! -f "$HAP" ]; then
  echo "✗ 未找到 HAP：$HAP"
  echo "  release 需要签名 HAP；uat / mock 允许 unsigned HAP。"
  exit 1
fi

echo "▶ 安装..."
"$HDC" -t "$TARGET" install "$HAP"

# ── 6. 启动 ──────────────────────────────────────────────────
echo "▶ 启动..."
"$HDC" -t "$TARGET" shell aa start -b "$BUNDLE" -a EntryAbility

if [ -n "$PROXY_HOST" ]; then
  echo "✅ 完成 ($PRODUCT, 代理: $PROXY_HOST)"
  echo "   清除代理：bash run.sh --clear-proxy"
else
  echo "✅ 完成 ($PRODUCT)"
fi

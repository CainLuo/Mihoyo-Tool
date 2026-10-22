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
    HAP='entry/build/mock/outputs/mock/entry-mock-signed.hap'
    SIGNING_DIR='Certificates/mock'
    ;;
  uat)
    BUILD_PRODUCT='uat'
    BUILD_MODE='debug'
    BUNDLE='com.cainluo.miyoyo.tools.uat'
    HAP='entry/build/uat/outputs/uat/entry-uat-signed.hap'
    SIGNING_DIR='Certificates/uat'
    ;;
  release)
    BUILD_PRODUCT='release'
    BUILD_MODE='release'
    BUNDLE='com.cainluo.miyoyo.tools'
    HAP='entry/build/release/outputs/release/entry-release-signed.hap'
    SIGNING_DIR='Certificates/release'
    ;;
esac

# ── 签名材料预检 ──────────────────────────────────────────────
# release 已有可用材料；uat / mock 需在 AGC 为对应包名创建调试证书和调试 Profile。
if [ "$PRODUCT" != "release" ]; then
  if [ ! -d "$SIGNING_DIR" ]; then
    echo "✗ 缺少 $PRODUCT 签名材料目录：$SIGNING_DIR"
    echo "  不能复用 release 签名。请先为 $BUNDLE 创建独立调试证书和 Profile。"
    echo "  步骤见 Certificates/README.md。"
    exit 1
  fi
  if ! find "$SIGNING_DIR" -maxdepth 1 -name '*.cer' -print -quit | grep -q . \
     || ! find "$SIGNING_DIR" -maxdepth 1 -name '*.p7b' -print -quit | grep -q .; then
    echo "✗ $SIGNING_DIR 缺少 .cer 或 .p7b"
    echo "  步骤见 Certificates/README.md。"
    exit 1
  fi
  if ! sed -n '/signingConfigs:/,/^[[:space:]]*],/p' build-profile.json5 | grep -q "name: \"$PRODUCT\""; then
    echo "✗ build-profile.json5 缺少 signingConfigs: $PRODUCT"
    echo "  仅放文件不够，还必须填写 signingConfigs；不能复用 release。"
    echo "  步骤见 Certificates/README.md。"
    exit 1
  fi
fi

echo ""
echo "▶ 构建目标：$PRODUCT（bundle=$BUNDLE，buildMode=$BUILD_MODE）"

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
if [ ! -f "$HAP" ]; then
  echo "✗ 未找到签名 HAP：$HAP"
  echo "  如果只生成了 *-unsigned.hap，说明 $PRODUCT 的 signingConfig 尚未配置。"
  exit 1
fi

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

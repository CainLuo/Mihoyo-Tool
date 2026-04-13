#!/bin/bash
# 启动模拟器 + Clean + Build(mock) + 安装 + 运行
# 用法：bash run.sh [emulator_name]
#   emulator_name 默认 "Mate 80 Pro Max"，可传 "Mate X7"

set -e

EMULATOR='/Applications/DevEco-Studio.app/Contents/tools/emulator/Emulator'
HDC='/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc'
HVIGOR='/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw'
export DEVECO_SDK_HOME='/Applications/DevEco-Studio.app/Contents/sdk'

BUNDLE='com.cainluo.mihoyo.tools'
TARGET='127.0.0.1:5555'
AVD="${1:-Mate 80 Pro Max}"
AVD_PATH="$HOME/.Huawei/Emulator/deployed/$AVD"
IMAGE_ROOT="$HOME/Library/Huawei/Sdk"
HAP='entry/build/default/outputs/default/entry-default-unsigned.hap'

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

# ── 2. Clean ──────────────────────────────────────────────────
echo "▶ Clean..."
"$HVIGOR" clean

# ── 3. Build (mock buildMode) ─────────────────────────────────
echo "▶ Build (mock)..."
"$HVIGOR" assembleHap -p product=default -p buildMode=mock

# ── 4. 安装 ──────────────────────────────────────────────────
echo "▶ 安装..."
"$HDC" -t "$TARGET" install "$HAP"

# ── 5. 启动 ──────────────────────────────────────────────────
echo "▶ 启动..."
"$HDC" -t "$TARGET" shell aa start -b "$BUNDLE" -a EntryAbility

echo "✅ 完成"

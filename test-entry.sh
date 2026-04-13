#!/bin/bash
# 构建 entry@ohosTest HAP（entry + core 所有单元测试）
# 构建成功 = 所有测试文件编译通过

set -e

HVIGOR='/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw'
export DEVECO_SDK_HOME='/Applications/DevEco-Studio.app/Contents/sdk'

echo "▶ 构建 entry@ohosTest HAP..."
"$HVIGOR" --mode module -p module=entry@ohosTest assembleHap -p buildMode=mock --parallel --incremental

echo "✅ 完成，HAP 位于 entry/build/default/outputs/ohosTest/"

#!/bin/bash
# 构建 entry@ohosTest HAP（仅 entry 的 Ability / UI 冒烟测试）
# core 的纯逻辑用例在 core/src/test，用 test-core.sh 运行
# 构建成功 = 所有测试文件编译通过

set -e

HVIGOR='/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw'
export DEVECO_SDK_HOME='/Applications/DevEco-Studio.app/Contents/sdk'

echo "▶ 构建 entry@ohosTest HAP..."
"$HVIGOR" --mode module -p module=entry@ohosTest assembleHap -p buildMode=debug --parallel --incremental

echo "✅ 完成，HAP 位于 entry/build/default/outputs/ohosTest/"

#!/bin/bash
# 构建 entry@ohosTest HAP，包含 core 单元测试（Parser、DSUtil、MockServiceBase、RowModels 等）
# 构建成功 = 所有测试文件编译通过
# 安装到设备后可运行测试：hdc install + aa test

set -e

HVIGOR='/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw'
export DEVECO_SDK_HOME='/Applications/DevEco-Studio.app/Contents/sdk'

echo "▶ 构建 entry@ohosTest（含 core 单元测试）..."
"$HVIGOR" --mode module -p module=entry@ohosTest assembleHap -p buildMode=mock --parallel --incremental

echo "✅ 完成，HAP 位于 entry/build/default/outputs/ohosTest/"

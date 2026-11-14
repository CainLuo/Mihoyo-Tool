#!/bin/bash
# 运行 core 本地单元测试（Parser、DSUtil、RowModels 等）
# Mock 路由测试已迁移到 mock-service/tests（Node），运行：cd mock-service && npm test
# 成功 = 所有用例通过（Local Test，宿主机运行）

set -e

HVIGOR='/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw'
export DEVECO_SDK_HOME='/Applications/DevEco-Studio.app/Contents/sdk'

echo "▶ 运行 core@default 本地单测..."
"$HVIGOR" --mode module -p module=core@default -p product=default test

echo "✅ 完成，结果见 core/.test/default/intermediates/test/coverage_data/test_result.txt"

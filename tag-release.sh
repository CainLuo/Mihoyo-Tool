#!/bin/bash
# 本地发布脚本：构建 App 包 → 提交 → 打 Tag → Push → 触发 GitHub Action 自动发布 Release
#
# 用法：bash tag-release.sh v1.0.0

set -e

TAG="$1"

if [ -z "$TAG" ]; then
  echo "用法：bash tag-release.sh <版本号>"
  echo "示例：bash tag-release.sh v1.0.0"
  exit 1
fi

# 验证版本号格式
if ! echo "$TAG" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "✗ 版本号格式错误，应为 vX.Y.Z（如 v1.0.0）"
  exit 1
fi

HVIGOR='/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw'
export DEVECO_SDK_HOME='/Applications/DevEco-Studio.app/Contents/sdk'
APP_PATH='build/outputs/default/Mihoyo-Tool-default-unsigned.app'

echo ""
echo "▶ 准备发布 $TAG"
echo ""

# ── 1. 检查 CHANGELOG.md 包含该版本 ─────────────────────────────
if ! grep -q "^## $TAG" CHANGELOG.md; then
  echo "✗ CHANGELOG.md 中未找到 $TAG 的记录"
  echo "  请先在 CHANGELOG.md 中添加该版本的变更内容，再运行此脚本"
  exit 1
fi
echo "✓ CHANGELOG.md 包含 $TAG 的记录"

# ── 2. 构建 App 包 ───────────────────────────────────────────────
echo "▶ 构建 App 包（product=default）..."
"$HVIGOR" clean
"$HVIGOR" assembleApp -p product=default

if [ ! -f "$APP_PATH" ]; then
  echo "✗ 构建失败，未找到 App 包：$APP_PATH"
  exit 1
fi
echo "✓ 构建完成：$APP_PATH"

# ── 3. 把 App 包复制到临时位置，供 Action 上传 ──────────────────
# App 包不提交到 Git，通过 GitHub Release 的 upload-artifact 机制上传
# 这里把路径写入一个临时文件，供后续步骤读取
echo "$APP_PATH" > .release-app-path

# ── 4. Git commit & tag ──────────────────────────────────────────
echo ""
echo "▶ 提交并打 Tag..."
git add -A
git diff --cached --quiet || git commit -m "chore: release $TAG"
git tag -a "$TAG" -m "Release $TAG"

# ── 5. Push ──────────────────────────────────────────────────────
echo "▶ Push 到 GitHub..."
git push origin HEAD
git push origin "$TAG"

# ── 6. 提示手动上传 App 包 ───────────────────────────────────────
REPO_URL=$(git remote get-url origin | sed 's/.*github.com[:/]//' | sed 's/\.git$//')
echo ""
echo "✅ Tag 已推送，GitHub Action 正在创建 Release"
echo ""
echo "📦 App 包路径：$APP_PATH"
echo ""
echo "⚠️  App 包需要手动上传到 Release（不提交到 Git）："
echo "   1. 等待 Action 完成：https://github.com/$REPO_URL/actions"
echo "   2. 打开 Release 页面：https://github.com/$REPO_URL/releases/tag/$TAG"
echo "   3. 点击 Edit，将 $APP_PATH 拖入 Assets 区域上传"

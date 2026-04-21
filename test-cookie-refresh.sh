#!/bin/bash
# Cookie 刷新手动测试脚本（交互式菜单）
# 直接运行：bash test-cookie-refresh.sh

HDC='/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc'
TARGET='127.0.0.1:5555'

# ── 检查模拟器连接 ────────────────────────────────────────────
if ! "$HDC" list targets 2>/dev/null | grep -q "$TARGET"; then
  echo "✗ 模拟器未连接（$TARGET），请先启动模拟器"
  exit 1
fi

# ── 菜单 ─────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║          Cookie 刷新手动测试脚本                     ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  T1：update_time 超 7 天，有 stoken → 触发冷启动刷新 ║"
echo "║  T3：update_time 超 7 天，无 stoken → 静默跳过       ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  1) T1 场景 (Mock)                                   ║"
echo "║  2) T1 场景 (Debug)                                  ║"
echo "║  3) T1 场景 (Release)                                ║"
echo "║  4) T3 场景 (Mock)                                   ║"
echo "║  5) T3 场景 (Debug)                                  ║"
echo "║  6) T3 场景 (Release)                                ║"
echo "║  0) 退出                                             ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
printf "请选择 [0-6]："
read -r CHOICE

# ── 根据选择确定场景和环境 ────────────────────────────────────
case "$CHOICE" in
  1) SCENARIO="t1"; ENV="mock" ;;
  2) SCENARIO="t1"; ENV="debug" ;;
  3) SCENARIO="t1"; ENV="release" ;;
  4) SCENARIO="t3"; ENV="mock" ;;
  5) SCENARIO="t3"; ENV="debug" ;;
  6) SCENARIO="t3"; ENV="release" ;;
  0) echo "已退出"; exit 0 ;;
  *)
    echo "✗ 无效选项：$CHOICE"
    exit 1
    ;;
esac

# ── 根据 env 确定 bundle id ───────────────────────────────────
case "$ENV" in
  mock)    BUNDLE='com.cainluo.miyoyo.tools.mock' ;;
  debug)   BUNDLE='com.cainluo.miyoyo.tools.debug' ;;
  release) BUNDLE='com.cainluo.miyoyo.tools' ;;
esac

DB_PATH="/data/app/el2/100/base/$BUNDLE/haps/entry/databases/mihoyo_tool_v2.db"

echo ""
echo "▶ 环境：$ENV（$BUNDLE）"

# ── 执行场景 ─────────────────────────────────────────────────
case "$SCENARIO" in
  t1)
    echo "▶ 场景 T1：update_time 改成 8 天前（保留 stoken，触发冷启动刷新）"
    "$HDC" -t "$TARGET" shell \
      "sqlite3 '$DB_PATH' \"UPDATE account_table SET update_time = strftime('%s','now') - 691200;\""
    echo ""
    echo "✅ 完成"
    echo "预期：重启 App 后，首屏渲染完成后静默刷新，无任何 Dialog"
    echo "验证：查看 update_time 是否已更新为当前时间戳"
    ;;

  t3)
    echo "▶ 场景 T3：update_time 改成 8 天前，cookie 改为不含 stoken（跳过刷新）"
    "$HDC" -t "$TARGET" shell \
      "sqlite3 '$DB_PATH' \"UPDATE account_table SET update_time = strftime('%s','now') - 691200, cookie = 'account_id=123; cookie_token=abc; ltoken=xyz; ltuid=123';\""
    echo ""
    echo "✅ 完成"
    echo "预期：重启 App 后，首屏正常渲染，无任何 Dialog 或通知"
    echo "验证：查看 update_time 是否未变化（未触发刷新）"
    ;;
esac

# ── 显示当前 DB 状态 ──────────────────────────────────────────
echo ""
echo "── 当前 DB 状态 ─────────────────────────────────────────"
"$HDC" -t "$TARGET" shell \
  "sqlite3 '$DB_PATH' \"SELECT id, username, update_time, strftime('%s','now') as now FROM account_table;\""
echo "─────────────────────────────────────────────────────────"
echo ""
echo "现在请重启 App 验证效果："
echo "  重启命令：$HDC -t $TARGET shell aa start -b $BUNDLE -a EntryAbility"

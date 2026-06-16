/**
 * wr-2x2.js — Widget 重设计：2×2 标准卡片
 *
 * 实测尺寸（X7）：内容区域 121.9 × 121.9 vp，含 padding 约 146 × 146 vp
 * 官方字号规范：主标题 14fp、18fp，副标题/辅助信息 12fp、14fp，数字 32fp、40fp
 *
 * 布局约束（单游戏）：
 * - 头部(游戏名+UID) + 体力区块(数字+恢复时间) + 数据行
 * - 星铁特殊：后备开拓力放在体力行右侧，避免内容过多
 * - 体力数字 24px（保证上下 padding 一致）
 *
 * 字号适配：
 * - 游戏名 12px，UID 10px
 * - 体力数字 24px，/max 14px
 * - 恢复时间 11px，数据行 11px
 */
function wrRender2x2(cardW, cardH, games) {
  var pad = 12;

  // ── 单游戏 ──────────────────────────────────────────────────────
  if (games.length === 1) {
    var gid = games[0];
    var d = WR.stamina[gid];
    var color = WR.colors[gid];
    var ratio = d.cur / d.max;

    // 当前体力颜色：0-30% 红色，30-70% 橙色，70-100% 游戏主题色
    var staminaColor;
    if (ratio <= 0.3) {
      staminaColor = "#ef5350";
    } else if (ratio <= 0.7) {
      staminaColor = "#ffca28";
    } else {
      staminaColor = color;
    }

    // 头部：游戏名（不换行）+ UID（换行显示）
    var header =
      '<div style="margin-bottom:6px;flex-shrink:0">' +
      '<div style="font-size:12px;font-weight:600;color:rgba(255,255,255,.8);overflow:hidden;text-overflow:ellipsis;white-space:nowrap">' +
      WR.names[gid] +
      "</div>" +
      '<div style="font-size:10px;color:rgba(255,255,255,.35);margin-top:1px">UID 123456789</div>' +
      "</div>";

    // 体力区块：当前/最大 + 恢复时间
    // 星铁特殊：后备开拓力放在右侧
    var staminaBlock;
    if (gid === "starrail") {
      staminaBlock =
        '<div style="display:flex;align-items:flex-start;justify-content:space-between;margin-bottom:8px;flex-shrink:0">' +
        '<div style="display:flex;flex-direction:column;gap:2px">' +
        '<div style="display:flex;align-items:baseline;gap:3px">' +
        '<span style="font-size:24px;font-weight:700;color:' +
        staminaColor +
        ';line-height:1">' +
        d.cur +
        "</span>" +
        '<span style="font-size:14px;color:rgba(255,255,255,.4)">/' +
        d.max +
        "</span>" +
        "</div>" +
        '<span style="font-size:11px;color:rgba(255,255,255,.5)">' +
        d.rec +
        "</span>" +
        "</div>" +
        '<div style="display:flex;flex-direction:column;align-items:flex-end;gap:1px">' +
        '<span style="font-size:9px;color:rgba(255,255,255,.4)">后备</span>' +
        '<span style="font-size:12px;font-weight:600;color:' +
        color +
        '">2400</span>' +
        "</div>" +
        "</div>";
    } else {
      staminaBlock =
        '<div style="display:flex;flex-direction:column;gap:2px;margin-bottom:8px;flex-shrink:0">' +
        '<div style="display:flex;align-items:baseline;gap:3px">' +
        '<span style="font-size:24px;font-weight:700;color:' +
        staminaColor +
        ';line-height:1">' +
        d.cur +
        "</span>" +
        '<span style="font-size:14px;color:rgba(255,255,255,.4)">/' +
        d.max +
        "</span>" +
        "</div>" +
        '<span style="font-size:11px;color:rgba(255,255,255,.5)">' +
        d.rec +
        "</span>" +
        "</div>";
    }

    // 额外数据行（最多 2 行）
    var extras = (WR.extra[gid] || []).slice(0, 2);
    if (gid === "starrail") extras = (WR.extra[gid] || []).slice(1, 3);
    var extraHtml = "";
    for (var i = 0; i < extras.length; i++) {
      extraHtml += WR.row(extras[i].label, extras[i].val, extras[i].color, 11);
    }

    var inner =
      '<div style="width:100%;height:100%;display:flex;flex-direction:column">' +
      header +
      staminaBlock +
      '<div style="flex:1;display:flex;flex-direction:column;justify-content:center;gap:5px">' +
      extraHtml +
      "</div>" +
      "</div>";
    return WR.card(cardW, cardH, inner, gid);
  }

  // ── 多游戏（最多 2 个）：游戏色竖线 + 体力大字 ───────────────────────────────
  var gameCount = Math.min(games.length, 2);  // 2x2 最多只显示 2 个游戏
  var headerH = 18;
  var availH = cardH - pad * 2 - headerH;
  var rowH = Math.floor(availH / gameCount);

  var header =
    '<div style="font-size:11px;font-weight:600;color:rgba(255,255,255,.7);margin-bottom:4px;flex-shrink:0">旅行者</div>';
  var rows = "";

  for (var gi = 0; gi < gameCount; gi++) {
    var gid2 = games[gi];
    var d2 = WR.stamina[gid2];
    var color2 = WR.colors[gid2];
    var ratio2 = d2.cur / d2.max;

    // 当前体力颜色
    var curColor2;
    if (ratio2 <= 0.3) {
      curColor2 = "#ef5350";
    } else if (ratio2 <= 0.7) {
      curColor2 = "#ffca28";
    } else {
      curColor2 = color2;
    }

    // 左侧：游戏色竖线
    var bar =
      '<div style="width:3px;height:' +
      Math.round(rowH * 0.5) +
      "px;border-radius:2px;background:" +
      color2 +
      ';flex-shrink:0"></div>';

    // 中间：游戏名 + 体力 + 恢复时间
    var mid =
      '<div style="flex:1;min-width:0;display:flex;flex-direction:column;justify-content:center;gap:1px">' +
      '<span style="font-size:11px;color:rgba(255,255,255,.5);overflow:hidden;text-overflow:ellipsis;white-space:nowrap">' +
      WR.names[gid2] +
      "</span>" +
      '<div style="display:flex;align-items:baseline;gap:2px">' +
      '<span style="font-size:18px;font-weight:700;color:' +
      curColor2 +
      ';line-height:1.1">' +
      d2.cur +
      "</span>" +
      '<span style="font-size:11px;color:rgba(255,255,255,.35)">/' +
      d2.max +
      "</span>" +
      "</div>" +
      '<span style="font-size:9px;color:rgba(255,255,255,.4)">' +
      d2.rec +
      "</span>" +
      "</div>";

    rows +=
      '<div style="height:' +
      rowH +
      'px;display:flex;align-items:center;gap:8px;overflow:hidden">' +
      bar +
      mid +
      "</div>";

    if (gi < gameCount - 1) {
      rows +=
        '<div style="height:1px;background:rgba(255,255,255,.08);flex-shrink:0"></div>';
    }
  }

  var inner2 =
    '<div style="width:100%;height:100%;display:flex;flex-direction:column">' +
    header +
    rows +
    "</div>";
  return WR.card(cardW, cardH, inner2, games);
}

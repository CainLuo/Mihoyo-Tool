/**
 * wr-2x2.js — Widget 重设计：2×2 标准卡片
 */
function wrRender2x2(cardW, cardH, games) {
  var pad = 12;

  // ── 单游戏 ──────────────────────────────────────────────────────
  if (games.length === 1) {
    var gid = games[0];
    var d = WR.stamina[gid];
    var color = WR.colors[gid];
    var ratio = d.cur / d.max;

    var header =
      '<div style="margin-bottom:8px;flex-shrink:0">' +
      WR.gameHeader(gid, "旅行者", 10, 6) +
      "</div>";

    var ringSize = 64,
      stroke = 6;
    var ring = WR.ringVal(ratio, color, ringSize, stroke, d.cur, d.max, 20, 9);

    var staminaRow =
      '<div style="display:flex;align-items:center;gap:10px;margin-bottom:8px;flex-shrink:0">' +
      ring +
      '<div style="flex:1;min-width:0;display:flex;flex-direction:column;justify-content:center;gap:3px">' +
      '<span style="font-size:11px;color:rgba(255,255,255,.55);overflow:hidden;text-overflow:ellipsis;white-space:nowrap">' +
      d.rec +
      "</span>" +
      (gid === "starrail"
        ? '<div style="display:flex;align-items:center;gap:4px"><span style="font-size:10px;color:rgba(255,255,255,.35)">后备</span><span style="font-size:11px;font-weight:600;color:' +
          color +
          '">2400</span></div>'
        : "") +
      "</div></div>";

    var extras = (WR.extra[gid] || []).slice(0, 2);
    if (gid === "starrail") extras = (WR.extra[gid] || []).slice(1, 3);
    var extraHtml = "";
    for (var i = 0; i < extras.length; i++) {
      extraHtml += WR.row(extras[i].label, extras[i].val, extras[i].color, 11);
    }

    var inner =
      '<div style="width:100%;height:100%;display:flex;flex-direction:column">' +
      header +
      staminaRow +
      '<div style="flex:1;display:flex;flex-direction:column;justify-content:center;gap:5px">' +
      extraHtml +
      "</div>" +
      "</div>";
    return WR.card(cardW, cardH, inner, gid);
  }

  // ── 多游戏：去掉 Progress 圈，改用游戏色竖线 + 体力大字 ──────────
  var gameCount = Math.min(games.length, 3);
  var headerH = 22;
  var availH = cardH - pad * 2 - headerH;
  var rowH = Math.floor(availH / gameCount);

  var header =
    '<div style="font-size:10px;font-weight:600;color:rgba(255,255,255,.7);margin-bottom:4px;flex-shrink:0">旅行者</div>';
  var rows = "";

  for (var gi = 0; gi < gameCount; gi++) {
    var gid2 = games[gi];
    var d2 = WR.stamina[gid2];
    var color2 = WR.colors[gid2];

    // 左侧：游戏色竖线（3px 宽，高度 60% 行高，圆角）
    var bar =
      '<div style="width:3px;height:' +
      Math.round(rowH * 0.6) +
      "px;border-radius:2px;background:" +
      color2 +
      ';flex-shrink:0"></div>';

    // 中间：游戏名（小）+ 体力大字
    var mid =
      '<div style="flex:1;min-width:0;display:flex;flex-direction:column;justify-content:center;gap:1px">' +
      '<span style="font-size:9px;color:rgba(255,255,255,.4);overflow:hidden;text-overflow:ellipsis;white-space:nowrap">' +
      WR.names[gid2] +
      "</span>" +
      '<div style="display:flex;align-items:baseline;gap:2px">' +
      '<span style="font-size:18px;font-weight:700;color:' +
      color2 +
      ';line-height:1.1">' +
      d2.cur +
      "</span>" +
      '<span style="font-size:9px;color:rgba(255,255,255,.3)">/' +
      d2.max +
      "</span>" +
      "</div>" +
      "</div>";

    // 右侧：恢复时间（小字，右对齐）
    var right =
      '<span style="font-size:9px;color:rgba(255,255,255,.35);flex-shrink:0;white-space:nowrap;text-align:right">' +
      d2.rec +
      "</span>";

    rows +=
      '<div style="height:' +
      rowH +
      'px;display:flex;align-items:center;gap:8px;overflow:hidden">' +
      bar +
      mid +
      right +
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

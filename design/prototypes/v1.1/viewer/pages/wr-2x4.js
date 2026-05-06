/**
 * wr-2x4.js — Widget 重设计：2×4 宽幅卡片
 *
 * X7 实测尺寸：290.6 × 121.9 vp（内容区域）
 * 官方字号规范：主标题 14fp，副标题 12fp，数字 32fp/40fp
 */
function wrRender2x4(cardW, cardH, games) {
  var pad = 12;

  // ── 单游戏 ──────────────────────────────────────────────────────
  if (games.length === 1) {
    var gid = games[0];
    var d = WR.stamina[gid];
    var color = WR.colors[gid];
    var ratio = d.cur / d.max;

    var innerH = cardH - pad * 2;
    var ringSize = Math.min(innerH - 16, 80);
    var stroke = 7;

    var ring = WR.ringVal(
      ratio,
      color,
      ringSize,
      stroke,
      d.cur,
      d.max,
      Math.round(ringSize * 0.32),  // 数字 32fp
      Math.round(ringSize * 0.14),  // /max 字号
    );

    var leftCol =
      '<div style="display:flex;flex-direction:column;align-items:center;justify-content:center;gap:4px;flex-shrink:0">' +
      ring +
      '<span style="font-size:10px;color:rgba(255,255,255,.4);text-align:center;max-width:' +
      ringSize +
      'px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">' +
      d.rec +
      "</span>" +
      "</div>";

    var extras = WR.extra[gid] || [];
    var showExtras = gid === "starrail" ? extras.slice(1) : extras;
    var extraHtml = "";
    for (var i = 0; i < Math.min(showExtras.length, 4); i++) {
      extraHtml += WR.row(
        showExtras[i].label,
        showExtras[i].val,
        showExtras[i].color,
        12,  // 副标题 12fp
      );
    }

    var rightCol =
      '<div style="flex:1;min-width:0;display:flex;flex-direction:column;justify-content:center;gap:0">' +
      '<div style="display:flex;align-items:baseline;gap:4px;margin-bottom:6px;flex-shrink:0">' +
      '<span style="font-size:12px;font-weight:500;color:rgba(255,255,255,.7)">' +
      WR.names[gid] +
      "</span>" +
      '<span style="font-size:10px;color:rgba(255,255,255,.35)">UID 123456789</span>' +
      "</div>" +
      (gid === "starrail"
        ? '<div style="display:flex;align-items:center;gap:4px;margin-bottom:4px;flex-shrink:0"><span style="font-size:10px;color:rgba(255,255,255,.4)">后备开拓力</span><span style="font-size:12px;font-weight:600;color:' +
          color +
          '">2400</span></div>'
        : "") +
      '<div style="display:flex;flex-direction:column;gap:4px">' +
      extraHtml +
      "</div>" +
      "</div>";

    var inner =
      '<div style="width:100%;height:100%;display:flex;align-items:center;gap:12px">' +
      leftCol +
      rightCol +
      "</div>";
    return WR.card(cardW, cardH, inner, gid);
  }

  // ── 多游戏：去掉顶部旅行者，每个游戏独立一行 ──────────────────────
  var gameCount = Math.min(games.length, 3);
  var availH = cardH - pad * 2;
  var rowH = Math.floor(availH / gameCount);

  var rows = "";
  for (var gi = 0; gi < gameCount; gi++) {
    var gid2 = games[gi];
    var d2 = WR.stamina[gid2];
    var color2 = WR.colors[gid2];
    var ratio2 = d2.cur / d2.max;
    var extras2 = WR.extra[gid2] || [];

    // 当前体力颜色
    var curColor2;
    if (ratio2 <= 0.3) {
      curColor2 = "#ef5350";
    } else if (ratio2 <= 0.7) {
      curColor2 = "#ffca28";
    } else {
      curColor2 = color2;
    }

    // 左侧：游戏色竖线装饰条
    var bar =
      '<div style="width:3px;height:' +
      Math.round(rowH * 0.5) +
      "px;border-radius:2px;background:" +
      color2 +
      ';flex-shrink:0"></div>';

    if (gameCount === 2) {
      // ── 2 个游戏：空间充裕，显示 UID + 恢复时间 + 2 条额外数据 ─────────
      var exHtml2 = "";
      for (var ei = 0; ei < Math.min(extras2.length, 2); ei++) {
        exHtml2 +=
          '<div style="display:flex;align-items:center;justify-content:space-between">' +
          '<span style="font-size:10px;color:rgba(255,255,255,.4)">' +
          extras2[ei].label +
          "</span>" +
          '<span style="font-size:11px;font-weight:600;color:' +
          extras2[ei].color +
          '">' +
          extras2[ei].val +
          "</span>" +
          "</div>";
      }

      var mid2 =
        '<div style="flex:1;min-width:0;display:flex;flex-direction:column;justify-content:center;gap:2px">' +
        '<div style="display:flex;align-items:center;justify-content:space-between">' +
        '<div style="display:flex;align-items:center;gap:6px">' +
        '<span style="font-size:12px;font-weight:500;color:rgba(255,255,255,.7)">' +
        WR.names[gid2] +
        "</span>" +
        '<span style="font-size:9px;color:rgba(255,255,255,.3)">UID ' +
        (123456789 + gi) +
        "</span>" +
        "</div>" +
        '<span style="font-size:10px;color:rgba(255,255,255,.4)">' +
        d2.rec +
        "</span>" +
        "</div>" +
        '<div style="display:flex;align-items:center;gap:12px">' +
        '<div style="display:flex;align-items:baseline;gap:2px">' +
        '<span style="font-size:20px;font-weight:700;color:' +
        curColor2 +
        ';line-height:1">' +
        d2.cur +
        "</span>" +
        '<span style="font-size:12px;color:rgba(255,255,255,.35)">/' +
        d2.max +
        "</span>" +
        "</div>" +
        '<div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:2px">' +
        exHtml2 +
        "</div>" +
        "</div>" +
        "</div>";

      rows +=
        '<div style="height:' +
        rowH +
        'px;display:flex;align-items:center;gap:10px;overflow:hidden">' +
        bar +
        mid2 +
        "</div>";
    } else {
      // ── 3 个游戏：空间紧凑，只显示游戏名+UID+体力+恢复时间 ─────────
      var mid3 =
        '<div style="flex:1;min-width:0;display:flex;flex-direction:column;justify-content:center;gap:1px">' +
        '<div style="display:flex;align-items:center;gap:4px">' +
        '<span style="font-size:11px;color:rgba(255,255,255,.5)">' +
        WR.names[gid2] +
        "</span>" +
        '<span style="font-size:9px;color:rgba(255,255,255,.3)">UID ' +
        (123456789 + gi) +
        "</span>" +
        "</div>" +
        '<div style="display:flex;align-items:baseline;gap:2px">' +
        '<span style="font-size:16px;font-weight:700;color:' +
        curColor2 +
        ';line-height:1.1">' +
        d2.cur +
        "</span>" +
        '<span style="font-size:11px;color:rgba(255,255,255,.35)">/' +
        d2.max +
        "</span>" +
        '<span style="font-size:10px;color:rgba(255,255,255,.4);margin-left:6px">' +
        d2.rec +
        "</span>" +
        "</div>" +
        "</div>";

      rows +=
        '<div style="height:' +
        rowH +
        'px;display:flex;align-items:center;gap:8px;overflow:hidden">' +
        bar +
        mid3 +
        "</div>";
    }

    if (gi < gameCount - 1) {
      rows +=
        '<div style="height:1px;background:rgba(255,255,255,.08);flex-shrink:0"></div>';
    }
  }

  var inner2 =
    '<div style="width:100%;height:100%;display:flex;flex-direction:column">' +
    rows +
    "</div>";
  return WR.card(cardW, cardH, inner2, games);
}

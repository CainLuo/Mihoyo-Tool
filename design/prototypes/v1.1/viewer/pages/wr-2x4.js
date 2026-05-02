/**
 * wr-2x4.js — Widget 重设计：2×4 宽幅卡片
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
    var ringSize = Math.min(innerH - 18, 88);
    var stroke = 8;

    var ring = WR.ringVal(
      ratio,
      color,
      ringSize,
      stroke,
      d.cur,
      d.max,
      Math.round(ringSize * 0.28),
      Math.round(ringSize * 0.14),
    );

    var leftCol =
      '<div style="display:flex;flex-direction:column;align-items:center;justify-content:center;gap:5px;flex-shrink:0">' +
      ring +
      '<span style="font-size:9px;color:rgba(255,255,255,.4);text-align:center;max-width:' +
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
        11,
      );
    }

    var rightCol =
      '<div style="flex:1;min-width:0;display:flex;flex-direction:column;justify-content:center;gap:0">' +
      '<div style="margin-bottom:8px;flex-shrink:0">' +
      WR.gameHeader(gid, "旅行者", 13, 7) +
      "</div>" +
      (gid === "starrail"
        ? '<div style="display:flex;align-items:center;gap:4px;margin-bottom:6px;flex-shrink:0"><span style="font-size:10px;color:rgba(255,255,255,.4)">后备开拓力</span><span style="font-size:12px;font-weight:600;color:' +
          color +
          '">2400</span></div>'
        : "") +
      '<div style="display:flex;flex-direction:column;gap:5px">' +
      extraHtml +
      "</div>" +
      "</div>";

    var inner =
      '<div style="width:100%;height:100%;display:flex;align-items:center;gap:14px">' +
      leftCol +
      rightCol +
      "</div>";
    return WR.card(cardW, cardH, inner, gid);
  }

  // ── 多游戏 ──────────────────────────────────────────────────────
  var gameCount = Math.min(games.length, 3);
  var headerH = 22;
  var availH = cardH - pad * 2 - headerH;
  var rowH = Math.floor(availH / gameCount);

  var header =
    '<div style="display:flex;align-items:baseline;gap:6px;margin-bottom:4px;flex-shrink:0">' +
    '<span style="font-size:11px;font-weight:600;color:rgba(255,255,255,.8)">旅行者</span>' +
    '<span style="font-size:9px;color:rgba(255,255,255,.3)">182692936</span>' +
    "</div>";

  var rows = "";
  for (var gi = 0; gi < gameCount; gi++) {
    var gid2 = games[gi];
    var d2 = WR.stamina[gid2];
    var color2 = WR.colors[gid2];
    var ratio2 = d2.cur / d2.max;
    var rs = gameCount <= 2 ? Math.min(rowH - 8, 36) : Math.min(rowH - 6, 24);
    var sw = gameCount <= 2 ? 3.5 : 2.5;
    var extras2 = WR.extra[gid2] || [];
    var ex1 = extras2[0];

    var ring2 = WR.ringVal(
      ratio2,
      color2,
      rs,
      sw,
      d2.cur,
      d2.max,
      Math.round(rs * 0.36),
      Math.round(rs * 0.2),
    );

    var mid =
      '<div style="flex:1;min-width:0;display:flex;flex-direction:column;justify-content:center;gap:1px">' +
      '<span style="font-size:9px;color:rgba(255,255,255,.4)">' +
      WR.names[gid2] +
      "</span>" +
      '<div style="display:flex;align-items:baseline;gap:1px">' +
      '<span style="font-size:' +
      (gameCount <= 2 ? 16 : 14) +
      "px;font-weight:700;color:" +
      color2 +
      ';line-height:1.1">' +
      d2.cur +
      "</span>" +
      '<span style="font-size:9px;color:rgba(255,255,255,.3)">/' +
      d2.max +
      "</span>" +
      "</div>" +
      '<span style="font-size:9px;color:rgba(255,255,255,.35);white-space:nowrap;overflow:hidden;text-overflow:ellipsis">' +
      d2.rec +
      "</span>" +
      "</div>";

    var right2 =
      gameCount <= 2 && ex1
        ? '<div style="flex-shrink:0;display:flex;flex-direction:column;align-items:flex-end;justify-content:center;gap:1px">' +
          '<span style="font-size:9px;color:rgba(255,255,255,.4)">' +
          ex1.label +
          "</span>" +
          '<span style="font-size:11px;font-weight:600;color:' +
          ex1.color +
          '">' +
          ex1.val +
          "</span>" +
          "</div>"
        : '<span style="font-size:9px;color:rgba(255,255,255,.35);flex-shrink:0;white-space:nowrap">' +
          d2.rec +
          "</span>";

    rows +=
      '<div style="height:' +
      rowH +
      'px;display:flex;align-items:center;gap:10px;overflow:hidden">' +
      ring2 +
      mid +
      right2 +
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

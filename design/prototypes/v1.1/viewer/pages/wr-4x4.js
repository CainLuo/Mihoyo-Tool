/**
 * wr-4x4.js — Widget 重设计：4×4 大卡片（多区块分组版）
 *
 * 布局：顶部标题 + 体力区块 + 数据区块1 + 数据区块2（或派遣格子）
 * 原神：4条数据行分两组 + 派遣格子（共4个区块）
 * 星铁/绝区零：数据行分两组（共3个区块）
 * 每个区块 flex:1 均分高度，不空旷
 */
function wrRender4x4(cardW, cardH, games) {
  var pad = 12;

  if (games.length === 1) {
    var gid = games[0];
    var d = WR.stamina[gid];
    var color = WR.colors[gid];
    var extras = WR.extra[gid] || [];
    var staminaLabel =
      gid === "starrail" ? "开拓力" : gid === "zzz" ? "电量" : "原粹树脂";

    // 顶部标题行
    var header =
      '<div style="display:flex;align-items:center;gap:6px;flex-shrink:0;padding-bottom:10px;border-bottom:1px solid rgba(255,255,255,.1)">' +
      '<div style="width:8px;height:8px;border-radius:50%;background:' +
      color +
      ';flex-shrink:0"></div>' +
      '<span style="font-size:16px;font-weight:700;color:rgba(255,255,255,.95);flex:1">' +
      WR.names[gid] +
      "</span>" +
      '<span style="font-size:10px;color:rgba(255,255,255,.35)">旅行者</span>' +
      "</div>";

    // 区块1：体力
    var block1 =
      '<div style="flex:1;display:flex;flex-direction:column;justify-content:center;padding:10px 0;border-bottom:1px solid rgba(255,255,255,.1)">' +
      '<div style="font-size:10px;color:rgba(255,255,255,.3);margin-bottom:6px;letter-spacing:0.8px;text-transform:uppercase">' +
      staminaLabel +
      "</div>" +
      '<div style="display:flex;align-items:baseline;gap:4px;margin-bottom:4px">' +
      '<span style="font-size:36px;font-weight:700;color:' +
      color +
      ';line-height:1">' +
      d.cur +
      "</span>" +
      '<span style="font-size:16px;color:rgba(255,255,255,.3)">/ ' +
      d.max +
      "</span>" +
      "</div>" +
      '<div style="font-size:13px;color:rgba(255,255,255,.5)">' +
      d.rec +
      "</div>" +
      (gid === "starrail"
        ? '<div style="display:flex;align-items:center;gap:6px;margin-top:4px">' +
          '<span style="font-size:12px;color:rgba(255,255,255,.35)">后备开拓力</span>' +
          '<span style="font-size:14px;font-weight:600;color:' +
          color +
          '">2400</span>' +
          "</div>"
        : "") +
      "</div>";

    // 数据行分组
    var showExtras = gid === "starrail" ? extras.slice(1) : extras;

    function renderGroup(items, hasBorder) {
      var rows = "";
      for (var i = 0; i < items.length; i++) {
        rows +=
          '<div style="display:flex;align-items:center;justify-content:space-between;flex:1">' +
          '<span style="font-size:13px;color:rgba(255,255,255,.45)">' +
          items[i].label +
          "</span>" +
          '<span style="font-size:13px;font-weight:600;color:' +
          items[i].color +
          '">' +
          items[i].val +
          "</span>" +
          "</div>";
      }
      return (
        '<div style="flex:1;display:flex;flex-direction:column;justify-content:space-evenly;padding:8px 0;' +
        (hasBorder ? "border-bottom:1px solid rgba(255,255,255,.1)" : "") +
        '">' +
        rows +
        "</div>"
      );
    }

    // 派遣格子
    function renderExpeditions() {
      var expColors = ["#5ba3e8", "#9b8eff", "#ef5350", "#ffca28", "#34d399"];
      var expFinished = [false, false, true, false, true];
      var avatars = "";
      for (var ei = 0; ei < 5; ei++) {
        avatars +=
          '<div style="position:relative;flex:1;display:flex;justify-content:center">' +
          '<div style="width:36px;height:36px;border-radius:50%;background:' +
          expColors[ei] +
          "22;border:2px solid " +
          expColors[ei] +
          ';display:flex;align-items:center;justify-content:center;font-size:14px">👤</div>' +
          (expFinished[ei]
            ? '<div style="position:absolute;bottom:0;right:calc(50% - 23px);width:14px;height:14px;border-radius:50%;background:#34d399;display:flex;align-items:center;justify-content:center;font-size:9px;color:#000;font-weight:700">✓</div>'
            : "") +
          "</div>";
      }
      return (
        '<div style="flex:1;display:flex;flex-direction:column;justify-content:center;padding:8px 0">' +
        '<div style="font-size:10px;color:rgba(255,255,255,.3);margin-bottom:8px;letter-spacing:0.8px;text-transform:uppercase">探索派遣</div>' +
        '<div style="display:flex">' +
        avatars +
        "</div>" +
        "</div>"
      );
    }

    var inner = "";
    if (gid === "genshin") {
      // 原神：4条数据行分两组（各2条）+ 派遣格子 = 4个区块
      var half = Math.ceil(showExtras.length / 2);
      var group1 = showExtras.slice(0, half);
      var group2 = showExtras.slice(half);
      inner =
        '<div style="width:100%;height:100%;display:flex;flex-direction:column">' +
        header +
        block1 +
        renderGroup(group1, true) +
        renderGroup(group2, true) +
        renderExpeditions() +
        "</div>";
    } else {
      // 星铁/绝区零：数据行分两组
      var half2 = Math.ceil(showExtras.length / 2);
      var grp1 = showExtras.slice(0, half2);
      var grp2 = showExtras.slice(half2);
      inner =
        '<div style="width:100%;height:100%;display:flex;flex-direction:column">' +
        header +
        block1 +
        renderGroup(grp1, grp2.length > 0) +
        (grp2.length > 0 ? renderGroup(grp2, false) : "") +
        "</div>";
    }

    return WR.card(cardW, cardH, inner, gid);
  }

  // ── 多游戏 ──────────────────────────────────────────────────────
  var gameCount = Math.min(games.length, 3);
  var headerH = 28;
  var availH = cardH - pad * 2 - headerH;
  var rowH = Math.floor(availH / gameCount);
  var maxExtra = gameCount <= 2 ? 3 : 2;

  var header4 =
    '<div style="display:flex;align-items:baseline;gap:6px;margin-bottom:8px;flex-shrink:0">' +
    '<span style="font-size:12px;font-weight:600;color:rgba(255,255,255,.85)">旅行者</span>' +
    '<span style="font-size:10px;color:rgba(255,255,255,.35)">182692936</span>' +
    "</div>";

  var blocks = "";
  for (var gi = 0; gi < gameCount; gi++) {
    var gid2 = games[gi];
    var d2 = WR.stamina[gid2];
    var color2 = WR.colors[gid2];
    var extras2 = WR.extra[gid2] || [];

    var exHtml = "";
    for (var xi = 0; xi < Math.min(extras2.length, maxExtra); xi++) {
      exHtml += WR.row(
        extras2[xi].label,
        extras2[xi].val,
        extras2[xi].color,
        11,
      );
    }

    blocks +=
      (gi > 0
        ? '<div style="height:1px;background:rgba(255,255,255,.08);margin:4px 0;flex-shrink:0"></div>'
        : "") +
      '<div style="height:' +
      rowH +
      'px;display:flex;flex-direction:column;justify-content:center;overflow:hidden">' +
      '<div style="display:flex;align-items:baseline;gap:8px;margin-bottom:4px">' +
      '<span style="font-size:12px;color:rgba(255,255,255,.4)">' +
      WR.names[gid2] +
      "</span>" +
      '<span style="font-size:22px;font-weight:700;color:' +
      color2 +
      ';line-height:1">' +
      d2.cur +
      "</span>" +
      '<span style="font-size:11px;color:rgba(255,255,255,.3)">/ ' +
      d2.max +
      "</span>" +
      '<span style="font-size:11px;color:rgba(255,255,255,.4);margin-left:4px">' +
      d2.rec +
      "</span>" +
      "</div>" +
      '<div style="display:flex;flex-direction:column;gap:3px">' +
      exHtml +
      "</div>" +
      "</div>";
  }

  var inner3 =
    '<div style="width:100%;height:100%;display:flex;flex-direction:column">' +
    header4 +
    blocks +
    "</div>";
  return WR.card(cardW, cardH, inner3, games);
}

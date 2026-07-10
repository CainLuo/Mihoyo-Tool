/**
 * wr-4x4.js — Widget 重设计：4×4 大卡片（多区块分组版）
 *
 * X7 实测尺寸：290.6 × 309.8 vp（内容区域）
 * 官方字号规范：主标题 14fp/18fp，副标题 12fp/14fp，数字 32fp/40fp
 * 布局：顶部标题 + 体力区块 + 数据区块1 + 数据区块2（或派遣格子）
 * 原神：4条数据行分两组 + 派遣格子（共4个区块）
 * 星铁/绝区零：数据行分两组（共3个区块）
 * 每个区块 flex:1 均分高度，不空旷
 *
 * UI/UX 优化：
 * - 字号统一使用 FONT 常量
 * - 文字对比度符合 WCAG 2.2（透明度 ≥ .45）
 * - 图片添加 alt 属性
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

    // 顶部标题行 - 主标题 14fp
    var header =
      '<div style="display:flex;align-items:center;gap:6px;flex-shrink:0;padding-bottom:8px;border-bottom:1px solid rgba(255,255,255,.1)">' +
      '<div style="width:8px;height:8px;border-radius:50%;background:' +
      color +
      ';flex-shrink:0" role="presentation"></div>' +
      '<span style="font-size:' + FONT.sm + ';font-weight:700;color:rgba(255,255,255,.95);flex:1">' +
      WR.names[gid] +
      "</span>" +
      '<span style="font-size:' + FONT.xs + ';color:rgba(255,255,255,.5)">UID 123456789</span>' +
      "</div>";

    // 区块1：体力 - 数字 40fp
    var block1 =
      '<div style="flex:1;display:flex;flex-direction:column;justify-content:center;padding:8px 0;border-bottom:1px solid rgba(255,255,255,.1)">' +
      '<div style="font-size:11px;color:rgba(255,255,255,.45);margin-bottom:4px;letter-spacing:0.8px;text-transform:uppercase">' +
      staminaLabel +
      "</div>" +
      '<div style="display:flex;align-items:baseline;gap:4px;margin-bottom:3px">' +
      '<span style="font-size:' + FONT["5xl"] + ';font-weight:700;color:' +
      color +
      ';line-height:1">' +
      d.cur +
      "</span>" +
      '<span style="font-size:' + FONT.sm + ';color:rgba(255,255,255,.45)">/ ' +
      d.max +
      "</span>" +
      "</div>" +
      '<div style="font-size:' + FONT.xs + ';color:rgba(255,255,255,.6)">' +
      d.rec +
      "</div>" +
      (gid === "starrail"
        ? '<div style="display:flex;align-items:center;gap:6px;margin-top:3px">' +
          '<span style="font-size:11px;color:rgba(255,255,255,.5)">后备开拓力</span>' +
          '<span style="font-size:13px;font-weight:600;color:' +
          color +
          '">2400</span>' +
          "</div>"
        : "") +
      "</div>";

    // 数据行分组 - 副标题 12fp
    // 原神：保留全部（探索派遣也在内）
    // 星铁：保留全部（后备开拓力、每日实训、历战余响、模拟宇宙、货币战争）
    // 绝区零：保留全部
    var showExtras = extras;

    function renderGroup(items, hasBorder) {
      var rows = "";
      for (var i = 0; i < items.length; i++) {
        rows +=
          '<div style="display:flex;align-items:center;justify-content:space-between;flex:1">' +
          '<span style="font-size:' + FONT.xs + ';color:rgba(255,255,255,.55)">' +
          items[i].label +
          "</span>" +
          '<span style="font-size:' + FONT.xs + ';font-weight:600;color:' +
          items[i].color +
          '">' +
          items[i].val +
          "</span>" +
          "</div>";
      }
      return (
        '<div style="flex:1;display:flex;flex-direction:column;justify-content:space-evenly;padding:6px 0;' +
        (hasBorder ? "border-bottom:1px solid rgba(255,255,255,.1)" : "") +
        '">' +
        rows +
        "</div>"
      );
    }

    // 派遣格子 - 纯圆头像图片，无背景色无 border
    function renderExpeditions() {
      var expData = WR.expeditions;
      var avatars = "";
      for (var ei = 0; ei < expData.length; ei++) {
        avatars +=
          '<div style="position:relative;flex:1;display:flex;justify-content:center">' +
          '<img src="' + expData[ei].avatar + '" style="width:32px;height:32px;border-radius:50%;object-fit:cover" alt="派遣角色" />' +
          (expData[ei].finished
            ? '<div style="position:absolute;bottom:-2px;right:calc(50% - 18px);width:12px;height:12px;border-radius:50%;background:#34d399;display:flex;align-items:center;justify-content:center;font-size:8px;color:#000;font-weight:700;box-shadow:0 0 0 2px #111118" aria-label="已完成">✓</div>'
            : "") +
          "</div>";
      }
      return (
        '<div style="flex:1;display:flex;flex-direction:column;justify-content:center;padding:6px 0">' +
        '<div style="font-size:11px;color:rgba(255,255,255,.45);margin-bottom:6px;letter-spacing:0.8px;text-transform:uppercase">探索派遣</div>' +
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

  // ── 多游戏：去掉顶部旅行者，每个游戏独立一行 ──────────────────────
  var gameCount = Math.min(games.length, 3);
  var availH = cardH - pad * 2;
  var rowH = Math.floor(availH / gameCount);

  // 探索派遣头像渲染 - 纯圆头像图片，无背景色无 border
  function renderExpeditionsSmall() {
    var expData = WR.expeditions;
    var avatars = "";
    for (var ei = 0; ei < expData.length; ei++) {
      avatars +=
        '<div style="position:relative;flex-shrink:0">' +
        '<img src="' + expData[ei].avatar + '" style="width:24px;height:24px;border-radius:50%;object-fit:cover" alt="派遣角色" />' +
        (expData[ei].finished
          ? '<div style="position:absolute;bottom:-2px;right:-2px;width:10px;height:10px;border-radius:50%;background:#34d399;display:flex;align-items:center;justify-content:center;font-size:7px;color:#000;font-weight:700;box-shadow:0 0 0 1.5px #111118" aria-label="已完成">✓</div>'
          : "") +
        "</div>";
    }
    return avatars;
  }

  var blocks = "";
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

    if (gameCount === 2) {
      // ── 2 个游戏：左侧体力区块，右侧数据区 ─────────
      // 原神特殊：额外信息 + 探索派遣头像
      var rightContent2 = "";
      if (gid2 === "genshin") {
        // 原神：显示洞天财瓮、每日委托、参量质变仪，下方是派遣头像
        rightContent2 =
          '<div style="flex:1;min-width:0;display:flex;flex-direction:column;justify-content:center;gap:3px">' +
          WR.row(extras2[1].label, extras2[1].val, extras2[1].color, 11) +
          WR.row(extras2[2].label, extras2[2].val, extras2[2].color, 11) +
          WR.row(extras2[3].label, extras2[3].val, extras2[3].color, 11) +
          '<div style="display:flex;align-items:center;gap:4px;margin-top:2px">' +
          '<span style="font-size:11px;color:rgba(255,255,255,.5)">探索派遣</span>' +
          '<span style="font-size:11px;font-weight:600;color:rgba(155,142,255,.9)">4/5</span>' +
          "</div>" +
          '<div style="display:flex;align-items:center;gap:4px">' +
          renderExpeditionsSmall() +
          "</div>" +
          "</div>";
      } else {
        // 其他游戏：显示 3 条额外数据
        var exHtml2 = "";
        for (var xi = 0; xi < Math.min(extras2.length, 3); xi++) {
          exHtml2 += WR.row(
            extras2[xi].label,
            extras2[xi].val,
            extras2[xi].color,
            11,
          );
        }
        rightContent2 =
          '<div style="flex:1;min-width:0;display:flex;flex-direction:column;justify-content:center;gap:3px">' +
          exHtml2 +
          "</div>";
      }

      blocks +=
        (gi > 0
          ? '<div style="height:1px;background:rgba(255,255,255,.08);margin:4px 0;flex-shrink:0" role="separator"></div>'
          : "") +
        '<div style="height:' +
        rowH +
        'px;display:flex;align-items:center;gap:16px;overflow:hidden">' +
        // 左侧：游戏名+UID + 体力区块
        '<div style="flex-shrink:0;min-width:100px;display:flex;flex-direction:column;justify-content:center;gap:2px">' +
        '<div style="display:flex;align-items:center;gap:6px">' +
        '<span style="font-size:13px;font-weight:500;color:rgba(255,255,255,.7)">' +
        WR.names[gid2] +
        "</span>" +
        '<span style="font-size:' + FONT.xs + ';color:rgba(255,255,255,.5)">UID ' +
        (123456789 + gi) +
        "</span>" +
        "</div>" +
        '<div style="display:flex;align-items:baseline;gap:3px">' +
        '<span style="font-size:28px;font-weight:700;color:' +
        curColor2 +
        ';line-height:1">' +
        d2.cur +
        "</span>" +
        '<span style="font-size:13px;color:rgba(255,255,255,.5)">/' +
        d2.max +
        "</span>" +
        "</div>" +
        '<span style="font-size:11px;color:rgba(255,255,255,.55);overflow:hidden;text-overflow:ellipsis;white-space:nowrap">' +
        d2.rec +
        "</span>" +
        "</div>" +
        rightContent2 +
        "</div>";
    } else {
      // ── 3 个游戏：左侧体力区块，右侧4条额外数据 ─────────
      var exHtml3 = "";
      for (var yi = 0; yi < Math.min(extras2.length, 4); yi++) {
        exHtml3 +=
          '<div style="display:flex;align-items:center;justify-content:space-between">' +
          '<span style="font-size:11px;color:rgba(255,255,255,.5)">' +
          extras2[yi].label +
          "</span>" +
          '<span style="font-size:11px;font-weight:600;color:' +
          extras2[yi].color +
          '">' +
          extras2[yi].val +
          "</span>" +
          "</div>";
      }

      blocks +=
        (gi > 0
          ? '<div style="height:1px;background:rgba(255,255,255,.08);margin:3px 0;flex-shrink:0" role="separator"></div>'
          : "") +
        '<div style="height:' +
        rowH +
        'px;display:flex;align-items:center;gap:12px;overflow:hidden">' +
        // 左侧：游戏名+UID + 体力区块
        '<div style="min-width:90px;display:flex;flex-direction:column;justify-content:center;gap:1px">' +
        '<div style="display:flex;align-items:center;gap:6px">' +
        '<span style="font-size:11px;font-weight:500;color:rgba(255,255,255,.65)">' +
        WR.names[gid2] +
        "</span>" +
        '<span style="font-size:11px;color:rgba(255,255,255,.5)">UID ' +
        (123456789 + gi) +
        "</span>" +
        "</div>" +
        '<div style="display:flex;align-items:baseline;gap:2px">' +
        '<span style="font-size:' + FONT.xl + ';font-weight:700;color:' +
        curColor2 +
        ';line-height:1">' +
        d2.cur +
        "</span>" +
        '<span style="font-size:11px;color:rgba(255,255,255,.5)">/' +
        d2.max +
        "</span>" +
        "</div>" +
        '<span style="font-size:11px;color:rgba(255,255,255,.55);overflow:hidden;text-overflow:ellipsis;white-space:nowrap">' +
        d2.rec +
        "</span>" +
        "</div>" +
        // 右侧：4条额外数据
        '<div style="flex:1;min-width:0;display:flex;flex-direction:column;justify-content:center;gap:1px">' +
        exHtml3 +
        "</div>" +
        "</div>";
    }
  }

  var inner3 =
    '<div style="width:100%;height:100%;display:flex;flex-direction:column">' +
    blocks +
    "</div>";
  return WR.card(cardW, cardH, inner3, games);
}

/**
 * wr-2x4.js — Widget 重设计：2×4 宽幅卡片
 *
 * Mate 80 Pro Max 实测：1161×533 px → 387×178 vp（455 ppi，按 3x 计算）
 * 字号规范：主标题 14fp，副标题 12fp，数字 22fp（全部为双数）
 *
 * 布局规则：
 * - 单游戏：左侧（游戏名、角色名、UID、体力、恢复时间）+ 右侧（额外数据行）
 * - 原神特殊：右侧去掉探索派遣，底部显示派遣角色头像（已完成加 mask+勾）
 * - 多游戏：每个游戏一行，左侧游戏色竖线 + 游戏名、角色名、UID、体力、恢复时间
 *
 * UI/UX 优化：
 * - 字号统一使用 FONT 常量
 * - 文字对比度符合 WCAG 2.2（透明度 ≥ .45）
 * - 图片添加 alt 属性
 */
function wrRender2x4(cardW, cardH, games) {
  var pad = 12;

  // ── 单游戏 ──────────────────────────────────────────────────────
  if (games.length === 1) {
    var gid = games[0];
    var d = WR.stamina[gid];
    var color = WR.colors[gid];
    var ratio = d.cur / d.max;

    // 体力颜色：≤30% 红色，≤70% 黄色，否则游戏主题色
    var curColor;
    if (ratio <= 0.3) {
      curColor = "#ef5350";
    } else if (ratio <= 0.7) {
      curColor = "#ffca28";
    } else {
      curColor = color;
    }

    // 左侧列：游戏名 → 角色名 → UID → 体力数值 → 恢复时间
    var leftCol =
      '<div style="display:flex;flex-direction:column;justify-content:center;gap:2px;flex-shrink:0">' +
      // 游戏名 14fp
      '<span style="font-size:' + FONT.sm + ';font-weight:500;color:rgba(255,255,255,.7)">' +
      WR.names[gid] +
      "</span>" +
      // 角色名 12fp
      '<span style="font-size:' + FONT.xs + ';color:rgba(255,255,255,.55)">旅行者 · Lv.60</span>' +
      // UID 12fp
      '<span style="font-size:' + FONT.xs + ';color:rgba(255,255,255,.5)">UID 123456789</span>' +
      // 体力数值 22fp
      '<div style="display:flex;align-items:baseline;gap:2px;margin-top:4px">' +
      '<span style="font-size:22px;font-weight:700;color:' +
      curColor +
      ';line-height:1">' +
      d.cur +
      "</span>" +
      '<span style="font-size:' + FONT.sm + ';color:rgba(255,255,255,.5)">/' +
      d.max +
      "</span>" +
      "</div>" +
      // 恢复时间 12fp
      '<span style="font-size:' + FONT.xs + ';color:rgba(255,255,255,.55)">' +
      d.rec +
      "</span>" +
      "</div>";

    // 右侧列：额外数据行（原神去掉探索派遣）
    var extras = WR.extra[gid] || [];
    var showExtras;
    if (gid === "genshin") {
      // 原神：去掉探索派遣（第一条），只显示洞天财瓮、每日委托、参量质变仪
      showExtras = extras.slice(1);
    } else {
      // 星铁、绝区零：保留全部
      showExtras = extras;
    }
    var extraHtml = "";
    for (var i = 0; i < Math.min(showExtras.length, 3); i++) {
      extraHtml += WR.row(
        showExtras[i].label,
        showExtras[i].val,
        showExtras[i].color,
        12,
      );
    }

    var rightCol =
      '<div style="flex:1;min-width:0;display:flex;flex-direction:column;justify-content:center;gap:2px;padding-left:12px">' +
      extraHtml +
      "</div>";

    // 分隔线
    var divider =
      '<div style="width:1px;height:' +
      Math.round(cardH * 0.5) +
      'px;background:rgba(255,255,255,.08);flex-shrink:0" role="separator"></div>';

    // 原神：底部派遣角色头像
    var bottomExpeditions = "";
    if (gid === "genshin") {
      var expeditions = WR.expeditions || [];
      var avatarSize = 26;
      var avatarHtml = "";
      for (var ei = 0; ei < Math.min(expeditions.length, 5); ei++) {
        var exp = expeditions[ei];
        var finished = exp.finished;
        avatarHtml +=
          '<div style="position:relative;width:' +
          avatarSize +
          "px;height:" +
          avatarSize +
          'px;flex-shrink:0">' +
          // 头像
          '<img src="' +
          exp.avatar +
          '" style="width:100%;height:100%;border-radius:50%;object-fit:cover' +
          (finished ? ";filter:grayscale(0.3)" : "") +
          '" alt="派遣角色" />' +
          // 已完成：mask + 勾
          (finished
            ? '<div style="position:absolute;inset:0;border-radius:50%;background:rgba(0,0,0,.4);display:flex;align-items:center;justify-content:center" aria-label="已完成">' +
              '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#4ade80" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>' +
              "</div>"
            : "") +
          "</div>";
      }
      bottomExpeditions =
        '<div style="display:flex;align-items:center;gap:4px;margin-top:8px;padding-top:8px;border-top:1px solid rgba(255,255,255,.06)">' +
        '<span style="font-size:11px;color:rgba(255,255,255,.5);margin-right:2px">探索派遣</span>' +
        avatarHtml +
        "</div>";
    }

    var inner =
      '<div style="width:100%;height:100%;display:flex;flex-direction:column;justify-content:center">' +
      '<div style="display:flex;align-items:center;gap:12px">' +
      leftCol +
      divider +
      rightCol +
      "</div>" +
      bottomExpeditions +
      "</div>";
    return WR.card(cardW, cardH, inner, gid);
  }

  // ── 多游戏：每个游戏独立一行 ───────────────────────────────────
  var gameCount = Math.min(games.length, 3);
  var availH = cardH - pad * 2;
  var rowH = Math.floor(availH / gameCount);

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

    // 左侧：游戏色竖线装饰条
    var bar =
      '<div style="width:3px;height:' +
      Math.round(rowH * 0.5) +
      "px;border-radius:2px;background:" +
      color2 +
      ';flex-shrink:0" role="presentation"></div>';

    if (gameCount === 2) {
      // ── 2 个游戏：空间充裕，显示角色名 + UID + 体力 + 恢复时间 + 2 条额外数据 ─────────
      var extras2 = WR.extra[gid2] || [];
      // 原神去掉探索派遣，星铁和绝区零保留全部
      var showExtras2 = gid2 === "genshin" ? extras2.slice(1) : extras2;
      var exHtml2 = "";
      for (var ei = 0; ei < Math.min(showExtras2.length, 2); ei++) {
        exHtml2 +=
          '<div style="display:flex;align-items:center;justify-content:space-between">' +
          '<span style="font-size:' + FONT.xs + ';color:rgba(255,255,255,.5)">' +
          showExtras2[ei].label +
          "</span>" +
          '<span style="font-size:' + FONT.xs + ';font-weight:600;color:' +
          showExtras2[ei].color +
          '">' +
          showExtras2[ei].val +
          "</span>" +
          "</div>";
      }

      var mid2 =
        '<div style="flex:1;min-width:0;display:flex;align-items:center;gap:16px">' +
        // 左侧：游戏名 + 角色名 + UID + 体力 + 恢复时间
        '<div style="display:flex;flex-direction:column;justify-content:center;gap:2px;flex-shrink:0">' +
        // 游戏名 14fp
        '<span style="font-size:' + FONT.sm + ';font-weight:500;color:rgba(255,255,255,.7)">' +
        WR.names[gid2] +
        "</span>" +
        // 角色名 10fp
        '<span style="font-size:11px;color:rgba(255,255,255,.55)">旅行者 · Lv.60</span>' +
        // UID
        '<span style="font-size:11px;color:rgba(255,255,255,.5)">UID ' +
        (123456789 + gi) +
        "</span>" +
        // 体力 + 恢复时间
        '<div style="display:flex;align-items:baseline;gap:2px;margin-top:2px">' +
        '<span style="font-size:' + FONT.xl + ';font-weight:700;color:' +
        curColor2 +
        ';line-height:1">' +
        d2.cur +
        "</span>" +
        '<span style="font-size:' + FONT.xs + ';color:rgba(255,255,255,.5)">/' +
        d2.max +
        "</span>" +
        '<span style="font-size:' + FONT.xs + ';color:rgba(255,255,255,.55);margin-left:6px">' +
        d2.rec +
        "</span>" +
        "</div>" +
        "</div>" +
        // 右侧：额外数据行
        '<div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:2px">' +
        exHtml2 +
        "</div>" +
        "</div>";

      rows +=
        '<div style="height:' +
        rowH +
        'px;display:flex;align-items:center;gap:8px;overflow:hidden">' +
        bar +
        mid2 +
        "</div>";
    } else {
      // ── 3 个游戏：空间紧凑，只显示游戏名+角色名+UID+体力+恢复时间 ─────────
      var mid3 =
        '<div style="flex:1;min-width:0;display:flex;align-items:center;gap:12px">' +
        // 左侧：游戏名 + 角色名 + UID
        '<div style="display:flex;flex-direction:column;gap:0;flex-shrink:0">' +
        // 游戏名 12fp
        '<span style="font-size:' + FONT.xs + ';font-weight:500;color:rgba(255,255,255,.55)">' +
        WR.names[gid2] +
        "</span>" +
        // 角色名 10fp
        '<span style="font-size:11px;color:rgba(255,255,255,.5)">旅行者 · Lv.60</span>' +
        // UID
        '<span style="font-size:11px;color:rgba(255,255,255,.5)">UID ' +
        (123456789 + gi) +
        "</span>" +
        "</div>" +
        // 右侧：体力 + 恢复时间
        '<div style="display:flex;align-items:baseline;gap:2px">' +
        '<span style="font-size:' + FONT.lg + ';font-weight:700;color:' +
        curColor2 +
        ';line-height:1.1">' +
        d2.cur +
        "</span>" +
        '<span style="font-size:' + FONT.xs + ';color:rgba(255,255,255,.5)">/' +
        d2.max +
        "</span>" +
        '<span style="font-size:' + FONT.xs + ';color:rgba(255,255,255,.55);margin-left:6px">' +
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
        '<div style="height:1px;background:rgba(255,255,255,.08);flex-shrink:0" role="separator"></div>';
    }
  }

  var inner2 =
    '<div style="width:100%;height:100%;display:flex;flex-direction:column">' +
    rows +
    "</div>";
  return WR.card(cardW, cardH, inner2, games);
}

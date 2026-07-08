/**
 * home.js — 首页渲染逻辑
 * v2：账号 section 支持点击 header 折叠/展开
 */
var homeState = { view: "data" };
// 记录每个账号 section 的折叠状态，key = section id
var homeSectionCollapsed = {};

// 全局函数：直接操作 DOM 实现动画，不走 refresh()
function toggleHomeSection(key) {
  homeSectionCollapsed[key] = !homeSectionCollapsed[key];
  var body = document.getElementById('body-' + key);
  var arrow = document.getElementById('arrow-' + key);
  if (!body) return;
  if (homeSectionCollapsed[key]) {
    body.style.maxHeight = '0';
    body.style.opacity = '0';
    if (arrow) arrow.style.transform = 'rotate(-90deg)';
  } else {
    body.style.maxHeight = '2000px';
    body.style.opacity = '1';
    if (arrow) arrow.style.transform = 'rotate(0deg)';
  }
}

function renderHome(w, h) {
  var c = T();
  var cols = w < 600 ? 1 : w < 840 ? 2 : w < 1200 ? 3 : 4;
  var gridCols = "repeat(" + cols + ",1fr)";

  function ring(ratio, color) {
    var r = 20,
      cx = 22,
      cy = 22;
    var circ = 2 * Math.PI * r;
    var dash = (circ * ratio).toFixed(1);
    var gap = (circ - circ * ratio).toFixed(1);
    return (
      '<svg width="44" height="44" viewBox="0 0 44 44" style="flex-shrink:0">' +
      '<circle cx="' +
      cx +
      '" cy="' +
      cy +
      '" r="' +
      r +
      '" fill="none" stroke="rgba(128,128,128,.15)" stroke-width="4"/>' +
      '<circle cx="' +
      cx +
      '" cy="' +
      cy +
      '" r="' +
      r +
      '" fill="none" stroke="' +
      color +
      '" stroke-width="4"' +
      ' stroke-dasharray="' +
      dash +
      " " +
      gap +
      '" stroke-linecap="round" transform="rotate(-90 ' +
      cx +
      " " +
      cy +
      ')"/>' +
      "</svg>"
    );
  }

  function dataRow(icon, iconBg, label, val, valColor) {
    return (
      '<div style="display:flex;align-items:center;gap:8px" role="listitem">' +
      '<div style="width:28px;height:28px;border-radius:8px;background:' +
      iconBg +
      ';display:flex;align-items:center;justify-content:center;font-size:' + FONT.sm + 'px;flex-shrink:0" aria-hidden="true">' +
      icon +
      "</div>" +
      '<span style="font-size:' + FONT.xs + 'px;color:' +
      c.txt2 +
      ';flex:1;opacity:' + TXT_ALPHA.secondary + '">' +
      label +
      "</span>" +
      '<span style="font-size:' + FONT.sm + 'px;font-weight:600;color:' +
      valColor +
      '">' +
      val +
      "</span>" +
      "</div>"
    );
  }

  function genshinCard(
    nick,
    server,
    resin,
    resinMax,
    isFull,
    expedCur,
    expedMax,
    coin,
    coinMax,
    taskDone,
  ) {
    var resinColor = isFull ? c.danger : c.primary;
    return (
      '<div style="background:' +
      c.surfCard +
      ";border:1px solid " +
      c.border +
      ";border-radius:16px;overflow:hidden;box-shadow:0 2px 8px " +
      c.shadow +
      '">' +
      '<div style="display:flex;align-items:center;gap:8px;padding:10px 12px 8px">' +
      '<img src="../assets/logo_genshin.png" style="width:32px;height:32px;border-radius:7px;object-fit:cover;flex-shrink:0;border:1px solid ' +
      c.border +
      '" alt="原神 Logo"/>' +
      '<div style="flex:1"><div style="font-size:' + FONT.md + 'px;font-weight:500;color:' +
      c.txt +
      '">原神</div>' +
      '<div style="font-size:' + FONT.xs + 'px;color:' +
      c.txt2 +
      ';opacity:' + TXT_ALPHA.secondary + '">' +
      nick +
      " · " +
      server +
      "</div></div>" +
      '<span style="font-size:' + FONT.xs + 'px;color:' +
      c.txt2 +
      ';opacity:' + TXT_ALPHA.muted + '">刚刚</span></div>' +
      cardHeaderDivider() +
      '<div style="padding:10px 12px 12px;display:flex;flex-direction:column;gap:8px">' +
      '<div style="display:flex;align-items:center;gap:10px">' +
      '<div style="width:28px;height:28px;border-radius:8px;background:rgba(77,163,255,.12);display:flex;align-items:center;justify-content:center;font-size:' + FONT.sm + 'px;flex-shrink:0" aria-hidden="true">🌙</div>' +
      '<div style="flex:1"><div style="font-size:' + FONT.xs + 'px;color:' +
      c.txt2 +
      ';margin-bottom:2px;opacity:' + TXT_ALPHA.secondary + '">原粹树脂</div>' +
      '<div style="display:flex;align-items:baseline;gap:3px"><span style="font-size:' + FONT.xl + 'px;font-weight:700;line-height:1;color:' +
      resinColor +
      '">' +
      resin +
      "</span>" +
      '<span style="font-size:' + FONT.sm + 'px;color:' +
      c.txt2 +
      ';opacity:' + TXT_ALPHA.secondary + '">/' +
      resinMax +
      "</span></div>" +
      '<div style="font-size:' + FONT.xs + 'px;color:' +
      (isFull ? c.danger : c.txt2) +
      ';margin-top:2px;opacity:' + (isFull ? '1' : TXT_ALPHA.secondary) + '">' +
      (isFull ? "已全部恢复" : "将于 4 小时后全部恢复") +
      "</div></div>" +
      ring(Math.min(resin / resinMax, 1), resinColor) +
      "</div>" +
      cardDivider() +
      dataRow(
        "🗺️",
        "rgba(155,142,255,.12)",
        "探索派遣",
        expedCur + "/" + expedMax,
        c.starrail,
      ) +
      dataRow(
        "🏡",
        "rgba(255,202,40,.12)",
        "洞天财瓮",
        coin + "/" + coinMax,
        c.gold,
      ) +
      dataRow(
        "📋",
        taskDone ? "rgba(52,211,153,.12)" : "rgba(255,107,107,.12)",
        "每日委托",
        taskDone ? "已全部领取" : "2/4",
        taskDone ? "#34D399" : c.danger,
      ) +
      "</div></div>"
    );
  }

  function starrailCard(
    nick,
    server,
    stamina,
    staminaMax,
    isFull,
    reserve,
    trainScore,
    trainMax,
    cocoonCnt,
    cocoonLimit,
    rogueScore,
    rogueMax,
    tournScore,
    tournMax,
  ) {
    var staminaColor = isFull ? c.danger : c.starrail;
    return (
      '<div style="background:' +
      c.surfCard +
      ";border:1px solid " +
      c.border +
      ";border-radius:16px;overflow:hidden;box-shadow:0 2px 8px " +
      c.shadow +
      '">' +
      '<div style="display:flex;align-items:center;gap:8px;padding:10px 12px 8px">' +
      '<img src="../assets/logo_starrail.png" style="width:32px;height:32px;border-radius:7px;object-fit:cover;flex-shrink:0;border:1px solid ' +
      c.border +
      '" alt="星穹铁道 Logo"/>' +
      '<div style="flex:1"><div style="font-size:' + FONT.md + 'px;font-weight:500;color:' +
      c.txt +
      '">崩坏：星穹铁道</div>' +
      '<div style="font-size:' + FONT.xs + 'px;color:' +
      c.txt2 +
      ';opacity:' + TXT_ALPHA.secondary + '">' +
      nick +
      " · " +
      server +
      "</div></div>" +
      '<span style="font-size:' + FONT.xs + 'px;color:' +
      c.txt2 +
      ';opacity:' + TXT_ALPHA.muted + '">刚刚</span></div>' +
      cardHeaderDivider() +
      '<div style="padding:10px 12px 12px;display:flex;flex-direction:column;gap:6px">' +
      '<div style="display:flex;align-items:center;gap:10px">' +
      '<div style="width:28px;height:28px;border-radius:8px;background:rgba(155,142,255,.12);display:flex;align-items:center;justify-content:center;font-size:' + FONT.sm + 'px;flex-shrink:0" aria-hidden="true">⚡</div>' +
      '<div style="flex:1"><div style="font-size:' + FONT.xs + 'px;color:' +
      c.txt2 +
      ';margin-bottom:2px;opacity:' + TXT_ALPHA.secondary + '">开拓力</div>' +
      '<div style="display:flex;align-items:baseline;gap:3px"><span style="font-size:' + FONT.xl + 'px;font-weight:700;line-height:1;color:' +
      staminaColor +
      '">' +
      stamina +
      "</span>" +
      '<span style="font-size:' + FONT.sm + 'px;color:' +
      c.txt2 +
      ';opacity:' + TXT_ALPHA.secondary + '">/' +
      staminaMax +
      "</span></div>" +
      '<div style="font-size:' + FONT.xs + 'px;color:' +
      (isFull ? c.danger : c.txt2) +
      ';margin-top:2px;opacity:' + (isFull ? '1' : TXT_ALPHA.secondary) + '">' +
      (isFull ? "已全部恢复" : "将于 4 小时后全部恢复") +
      "</div></div>" +
      ring(Math.min(stamina / staminaMax, 1), staminaColor) +
      "</div>" +
      dataRow(
        "🔋",
        "rgba(155,142,255,.08)",
        "后备开拓力",
        reserve.toString(),
        c.txt2,
      ) +
      cardDivider() +
      dataRow(
        "📅",
        "rgba(52,211,153,.12)",
        "每日实训",
        trainScore + "/" + trainMax,
        "#34D399",
      ) +
      dataRow(
        "⚔️",
        "rgba(255,202,40,.12)",
        "历战余响",
        cocoonCnt + "/" + cocoonLimit,
        c.gold,
      ) +
      dataRow(
        "🌌",
        "rgba(77,163,255,.12)",
        "模拟宇宙积分",
        rogueScore + "/" + rogueMax,
        c.primary,
      ) +
      dataRow(
        "💰",
        "rgba(255,107,107,.12)",
        "货币战争积分",
        tournScore + "/" + tournMax,
        c.danger,
      ) +
      "</div></div>"
    );
  }

  function zzzCard(
    nick,
    server,
    energy,
    energyMax,
    isFull,
    vitality,
    vitalityMax,
    cardDone,
    videoState,
  ) {
    var energyColor = isFull ? c.danger : c.zzz;
    var videoLabel =
      videoState === "done"
        ? "已结算"
        : videoState === "open"
          ? "营业中"
          : "未营业";
    var videoColor =
      videoState === "done"
        ? "#34D399"
        : videoState === "open"
          ? c.zzz
          : c.txt2;
    var videoBg =
      videoState === "done" ? "rgba(52,211,153,.12)" : "rgba(247,184,75,.08)";
    return (
      '<div style="background:' +
      c.surfCard +
      ";border:1px solid " +
      c.border +
      ";border-radius:16px;overflow:hidden;box-shadow:0 2px 8px " +
      c.shadow +
      '">' +
      '<div style="display:flex;align-items:center;gap:8px;padding:10px 12px 8px">' +
      '<img src="../assets/logo_zzz.png" style="width:32px;height:32px;border-radius:7px;object-fit:cover;flex-shrink:0;border:1px solid ' +
      c.border +
      '" alt="绝区零 Logo"/>' +
      '<div style="flex:1"><div style="font-size:' + FONT.md + 'px;font-weight:500;color:' +
      c.txt +
      '">绝区零</div>' +
      '<div style="font-size:' + FONT.xs + 'px;color:' +
      c.txt2 +
      ';opacity:' + TXT_ALPHA.secondary + '">' +
      nick +
      " · " +
      server +
      "</div></div>" +
      '<span style="font-size:' + FONT.xs + 'px;color:' +
      c.txt2 +
      ';opacity:' + TXT_ALPHA.muted + '">刚刚</span></div>' +
      cardHeaderDivider() +
      '<div style="padding:10px 12px 12px;display:flex;flex-direction:column;gap:6px">' +
      '<div style="display:flex;align-items:center;gap:10px">' +
      '<div style="width:28px;height:28px;border-radius:8px;background:rgba(247,184,75,.12);display:flex;align-items:center;justify-content:center;font-size:' + FONT.sm + 'px;flex-shrink:0" aria-hidden="true">⚡</div>' +
      '<div style="flex:1"><div style="font-size:' + FONT.xs + 'px;color:' +
      c.txt2 +
      ';margin-bottom:2px;opacity:' + TXT_ALPHA.secondary + '">电量</div>' +
      '<div style="display:flex;align-items:baseline;gap:3px"><span style="font-size:' + FONT.xl + 'px;font-weight:700;line-height:1;color:' +
      energyColor +
      '">' +
      energy +
      "</span>" +
      '<span style="font-size:' + FONT.sm + 'px;color:' +
      c.txt2 +
      ';opacity:' + TXT_ALPHA.secondary + '">/' +
      energyMax +
      "</span></div>" +
      '<div style="font-size:' + FONT.xs + 'px;color:' +
      (isFull ? c.danger : c.txt2) +
      ';margin-top:2px;opacity:' + (isFull ? '1' : TXT_ALPHA.secondary) + '">' +
      (isFull ? "已全部恢复" : "将于 4 小时后全部恢复") +
      "</div></div>" +
      ring(Math.min(energy / energyMax, 1), energyColor) +
      "</div>" +
      cardDivider() +
      dataRow(
        "🎯",
        "rgba(247,184,75,.12)",
        "今日活跃度",
        vitality + "/" + vitalityMax,
        c.zzz,
      ) +
      dataRow(
        "🃏",
        cardDone ? "rgba(52,211,153,.12)" : "rgba(255,107,107,.12)",
        "刮刮卡/占卜",
        cardDone ? "已完成" : "未完成",
        cardDone ? "#34D399" : c.danger,
      ) +
      dataRow("📼", videoBg, "录像店经营", videoLabel, videoColor) +
      "</div></div>"
    );
  }

  function skCard() {
    return (
      '<div style="background:' +
      c.surfCard +
      ";border:1px solid " +
      c.border +
      ";border-radius:16px;padding:12px;box-shadow:0 2px 8px " +
      c.shadow +
      '">' +
      '<div style="display:flex;gap:8px;align-items:center;margin-bottom:10px">' +
      '<div style="width:4px;height:36px;border-radius:2px;background:' +
      c.border +
      ';animation:sk 1.5s ease-in-out infinite"></div>' +
      '<div style="flex:1"><div style="height:14px;width:60%;background:' +
      c.border +
      ';border-radius:4px;margin-bottom:6px;animation:sk 1.5s ease-in-out infinite"></div>' +
      '<div style="height:11px;width:40%;background:' +
      c.border +
      ';border-radius:4px;animation:sk 1.5s ease-in-out infinite"></div></div></div>' +
      '<div style="height:1px;background:' +
      c.div +
      ';margin-bottom:10px"></div>' +
      '<div style="display:flex;gap:8px;align-items:center">' +
      '<div style="flex:1"><div style="height:11px;width:30%;background:' +
      c.border +
      ';border-radius:4px;margin-bottom:6px;animation:sk 1.5s ease-in-out infinite"></div>' +
      '<div style="height:22px;width:50%;background:' +
      c.border +
      ';border-radius:4px;margin-bottom:4px;animation:sk 1.5s ease-in-out infinite"></div>' +
      '<div style="height:11px;width:60%;background:' +
      c.border +
      ';border-radius:4px;animation:sk 1.5s ease-in-out infinite"></div></div>' +
      '<div style="width:52px;height:52px;border-radius:50%;background:' +
      c.border +
      ';animation:sk 1.5s ease-in-out infinite"></div></div></div>'
    );
  }

  // 折叠/展开 section，用 DOM 操作 + CSS transition 实现动画
  function accountSection(key, nickname, avatarUrl, gameCount, cards) {
    var collapsed = !!homeSectionCollapsed[key];
    // 箭头：展开=朝下，折叠=朝右（通过 rotate 实现）
    var arrowRotate = collapsed ? 'rotate(-90deg)' : 'rotate(0deg)';
    var arrow = '<svg id="arrow-' + key + '" width="16" height="16" viewBox="0 0 16 16" fill="none" ' +
      'style="flex-shrink:0;transition:transform .25s;transform:' + arrowRotate + '">' +
      '<path d="M4 6l4 4 4-4" stroke="' + c.txt2 + '" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>';

    var header =
      '<div onclick="toggleHomeSection(\'' + key + '\')" ' +
      'style="display:flex;align-items:center;gap:8px;padding:8px 0 12px;cursor:pointer;user-select:none;-webkit-tap-highlight-color:transparent">' +
      '<img src="' + avatarUrl + '" style="width:28px;height:28px;border-radius:8px;object-fit:cover;flex-shrink:0;border:1px solid ' + c.primary + '55" ' +
      'onerror="this.style.background=\'' + c.primary + '\';this.src=\'\'" />' +
      '<span style="font-size:15px;font-weight:500;color:' + c.txt + ';flex:1">' + nickname + '</span>' +
      '<span style="font-size:12px;color:' + c.txt2 + ';margin-right:4px">' + gameCount + ' 个游戏</span>' +
      arrow + '</div>';

    // body 始终渲染，用 max-height + opacity transition 做动画
    var maxH = collapsed ? '0' : '2000px';
    var opacity = collapsed ? '0' : '1';
    var body = '<div id="body-' + key + '" style="overflow:hidden;transition:max-height .3s ease,opacity .25s ease;max-height:' + maxH + ';opacity:' + opacity + '">' +
      '<div style="display:grid;grid-template-columns:' + gridCols + ';gap:12px;margin-bottom:4px">' +
      cards + '</div></div>';

    return '<div style="margin-bottom:8px">' + header + body + '</div>';
  }

  var content = "";
  if (homeState.view === "loading") {
    var sks = "";
    for (var i = 0; i < cols * 2; i++) sks += skCard();
    content =
      '<div class="sy" style="flex:1;padding:8px 16px 40px">' +
      '<div style="display:flex;align-items:center;gap:8px;padding:8px 0 12px">' +
      '<div style="width:28px;height:28px;border-radius:14px;background:' +
      c.border +
      ';animation:sk 1.5s ease-in-out infinite"></div>' +
      '<div style="height:14px;width:100px;background:' +
      c.border +
      ';border-radius:4px;animation:sk 1.5s ease-in-out infinite"></div></div>' +
      '<div style="display:grid;grid-template-columns:' +
      gridCols +
      ';gap:12px">' +
      sks +
      "</div></div>";
  } else if (homeState.view === "empty") {
    content =
      '<div style="display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;gap:16px;padding:40px">' +
      '<div style="font-size:48px">📋</div>' +
      '<div style="font-size:16px;font-weight:600;color:' +
      c.txt +
      '">暂无账号</div>' +
      '<div style="font-size:13px;color:' +
      c.txt2 +
      ';text-align:center">请先登录米游社账号，即可查看游戏数据</div>' +
      '<div style="padding:10px 24px;background:' +
      c.primary +
      ';border-radius:8px;color:#fff;font-size:14px;font-weight:600;cursor:pointer">登录账号</div>' +
      "</div>";
  } else {
    var sec1 = accountSection(
      "cainluo",
      "CainLuo",
      "https://bbs-static.miyoushe.com/avatar/avatar1.png",
      3,
      genshinCard("旅行者", "天空岛", 140, 200, false, 3, 5, 1800, 2400, true) +
        starrailCard(
          "开拓者",
          "星穹列车",
          200,
          240,
          true,
          1200,
          400,
          500,
          3,
          3,
          8400,
          14000,
          6000,
          8000,
        ) +
        zzzCard("绳匠", "艾利都", 180, 240, false, 400, 500, true, "done"),
    );
    var sec2 = accountSection(
      "another",
      "另一个账号",
      "",
      1,
      genshinCard("钟离", "世界树", 200, 200, true, 5, 5, 2400, 2400, false),
    );
    content =
      '<div class="sy" style="flex:1;padding:8px 16px 40px">' +
      sec1 +
      '<div style="height:1px;background:' +
      c.div +
      ';margin:4px 0 8px"></div>' +
      sec2 +
      "</div>";
  }

  return (
    baseCss(w, h) +
    "<style>@keyframes sk{0%,100%{opacity:.4}50%{opacity:.9}}</style>" +
    '<div style="width:' +
    w +
    "px;height:" +
    h +
    "px;display:flex;flex-direction:column;background:" +
    c.pageBg +
    '">' +
    content +
    tabBar("home") +
    "</div>"
  );
}

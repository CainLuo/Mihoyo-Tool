/**
 * home.js — 首页渲染逻辑
 * 原神卡片：树脂大数字+环形进度、派遣/财瓮/委托小行（方案 A，已确认）
 */
var homeState = { view: "data" };

function renderHome(w, h) {
  var c = T();
  var cols = w < 600 ? 1 : w < 840 ? 2 : w < 1200 ? 3 : 4;
  var gridCols = "repeat(" + cols + ",1fr)";

  // 原神卡片（新设计）
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
    var ratio = Math.min(resin / resinMax, 1);
    var r = 20,
      cx = 22,
      cy = 22;
    var circ = 2 * Math.PI * r;
    var dash = (circ * ratio).toFixed(1);
    var gap = (circ - circ * ratio).toFixed(1);
    var ring =
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
      resinColor +
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
      "</svg>";
    var idiv = cardDivider();
    function row(icon, iconBg, label, val, valColor) {
      return (
        '<div style="display:flex;align-items:center;gap:8px">' +
        '<div style="width:28px;height:28px;border-radius:8px;background:' +
        iconBg +
        ';display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0">' +
        icon +
        "</div>" +
        '<span style="font-size:12px;color:' +
        c.txt2 +
        ';flex:1">' +
        label +
        "</span>" +
        '<span style="font-size:13px;font-weight:600;color:' +
        valColor +
        '">' +
        val +
        "</span>" +
        "</div>"
      );
    }
    return (
      '<div style="background:' +
      c.surfCard +
      ";border:1px solid " +
      c.border +
      ";border-radius:16px;overflow:hidden;box-shadow:0 2px 8px " +
      c.shadow +
      '">' +
      '<div style="display:flex;align-items:center;gap:8px;padding:10px 12px 8px">' +
      '<div style="width:4px;height:36px;border-radius:2px;background:' +
      c.genshin +
      ';flex-shrink:0"></div>' +
      '<div style="flex:1"><div style="font-size:15px;font-weight:500;color:' +
      c.txt +
      '">原神</div>' +
      '<div style="font-size:12px;color:' +
      c.txt2 +
      '">' +
      nick +
      " · " +
      server +
      "</div></div>" +
      '<span style="font-size:11px;color:' +
      c.txt2 +
      '">刚刚</span>' +
      "</div>" +
      cardHeaderDivider() +
      '<div style="padding:10px 12px 12px;display:flex;flex-direction:column;gap:8px">' +
      '<div style="display:flex;align-items:center;gap:10px">' +
      '<div style="width:28px;height:28px;border-radius:8px;background:rgba(77,163,255,.12);display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0">🌙</div>' +
      '<div style="flex:1">' +
      '<div style="font-size:11px;color:' +
      c.txt2 +
      ';margin-bottom:2px">原粹树脂</div>' +
      '<div style="display:flex;align-items:baseline;gap:3px">' +
      '<span style="font-size:24px;font-weight:700;line-height:1;color:' +
      resinColor +
      '">' +
      resin +
      "</span>" +
      '<span style="font-size:13px;color:' +
      c.txt2 +
      '">/' +
      resinMax +
      "</span>" +
      "</div>" +
      '<div style="font-size:11px;color:' +
      (isFull ? c.danger : c.txt2) +
      ';margin-top:2px">' +
      (isFull ? "已全部恢复" : "将于 4 小时后全部恢复") +
      "</div></div>" +
      ring +
      "</div>" +
      idiv +
      row(
        "🗺️",
        "rgba(155,142,255,.12)",
        "探索派遣",
        expedCur + "/" + expedMax,
        c.starrail,
      ) +
      row(
        "🏡",
        "rgba(255,202,40,.12)",
        "洞天财瓮",
        coin + "/" + coinMax,
        c.gold,
      ) +
      row(
        "📋",
        taskDone ? "rgba(52,211,153,.12)" : "rgba(255,107,107,.12)",
        "每日委托",
        taskDone ? "已全部领取" : "2/4",
        taskDone ? "#34D399" : c.danger,
      ) +
      "</div></div>"
    );
  }

  // 崩铁卡片（新设计，已确认）
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
    var ratio = Math.min(stamina / staminaMax, 1);
    var r = 20,
      cx = 22,
      cy = 22;
    var circ = 2 * Math.PI * r;
    var dash = (circ * ratio).toFixed(1);
    var gap = (circ - circ * ratio).toFixed(1);
    var ring =
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
      staminaColor +
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
      "</svg>";
    function row(icon, iconBg, label, val, valColor) {
      return (
        '<div style="display:flex;align-items:center;gap:8px">' +
        '<div style="width:28px;height:28px;border-radius:8px;background:' +
        iconBg +
        ';display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0">' +
        icon +
        "</div>" +
        '<span style="font-size:12px;color:' +
        c.txt2 +
        ';flex:1">' +
        label +
        "</span>" +
        '<span style="font-size:13px;font-weight:600;color:' +
        valColor +
        '">' +
        val +
        "</span>" +
        "</div>"
      );
    }
    return (
      '<div style="background:' +
      c.surfCard +
      ";border:1px solid " +
      c.border +
      ";border-radius:16px;overflow:hidden;box-shadow:0 2px 8px " +
      c.shadow +
      '">' +
      '<div style="display:flex;align-items:center;gap:8px;padding:10px 12px 8px">' +
      '<div style="width:4px;height:36px;border-radius:2px;background:' +
      c.starrail +
      ';flex-shrink:0"></div>' +
      '<div style="flex:1"><div style="font-size:15px;font-weight:500;color:' +
      c.txt +
      '">崩坏：星穹铁道</div>' +
      '<div style="font-size:12px;color:' +
      c.txt2 +
      '">' +
      nick +
      " · " +
      server +
      "</div></div>" +
      '<span style="font-size:11px;color:' +
      c.txt2 +
      '">刚刚</span>' +
      "</div>" +
      cardHeaderDivider() +
      '<div style="padding:10px 12px 12px;display:flex;flex-direction:column;gap:6px">' +
      '<div style="display:flex;align-items:center;gap:10px">' +
      '<div style="width:28px;height:28px;border-radius:8px;background:rgba(155,142,255,.12);display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0">⚡</div>' +
      '<div style="flex:1">' +
      '<div style="font-size:11px;color:' +
      c.txt2 +
      ';margin-bottom:2px">开拓力</div>' +
      '<div style="display:flex;align-items:baseline;gap:3px">' +
      '<span style="font-size:24px;font-weight:700;line-height:1;color:' +
      staminaColor +
      '">' +
      stamina +
      "</span>" +
      '<span style="font-size:13px;color:' +
      c.txt2 +
      '">/' +
      staminaMax +
      "</span>" +
      "</div>" +
      '<div style="font-size:11px;color:' +
      (isFull ? c.danger : c.txt2) +
      ';margin-top:2px">' +
      (isFull ? "已全部恢复" : "将于 4 小时后全部恢复") +
      "</div></div>" +
      ring +
      "</div>" +
      row(
        "🔋",
        "rgba(155,142,255,.08)",
        "后备开拓力",
        reserve.toString(),
        c.txt2,
      ) +
      cardDivider() +
      row(
        "📅",
        "rgba(52,211,153,.12)",
        "每日实训",
        trainScore + "/" + trainMax,
        "#34D399",
      ) +
      row(
        "⚔️",
        "rgba(255,202,40,.12)",
        "历战余响",
        cocoonCnt + "/" + cocoonLimit,
        c.gold,
      ) +
      row(
        "🌌",
        "rgba(77,163,255,.12)",
        "模拟宇宙积分",
        rogueScore + "/" + rogueMax,
        c.primary,
      ) +
      row(
        "💰",
        "rgba(255,107,107,.12)",
        "货币战争积分",
        tournScore + "/" + tournMax,
        c.danger,
      ) +
      "</div></div>"
    );
  }

  // 绝区零卡片（新设计，已确认）
  function zzzCard(nick, server, energy, energyMax, isFull, vitality, vitalityMax, cardDone, videoState) {
    var energyColor = isFull ? c.danger : c.zzz;
    var ratio = Math.min(energy / energyMax, 1);
    var r = 20, cx = 22, cy = 22;
    var circ = 2 * Math.PI * r;
    var dash = (circ * ratio).toFixed(1);
    var gap = (circ - circ * ratio).toFixed(1);
    var ring = '<svg width="44" height="44" viewBox="0 0 44 44" style="flex-shrink:0">'
      + '<circle cx="' + cx + '" cy="' + cy + '" r="' + r + '" fill="none" stroke="rgba(128,128,128,.15)" stroke-width="4"/>'
      + '<circle cx="' + cx + '" cy="' + cy + '" r="' + r + '" fill="none" stroke="' + energyColor + '" stroke-width="4"'
      + ' stroke-dasharray="' + dash + ' ' + gap + '" stroke-linecap="round" transform="rotate(-90 ' + cx + ' ' + cy + ')"/>'
      + '</svg>';
    function row(icon, iconBg, label, val, valColor) {
      return '<div style="display:flex;align-items:center;gap:8px">'
        + '<div style="width:28px;height:28px;border-radius:8px;background:' + iconBg + ';display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0">' + icon + '</div>'
        + '<span style="font-size:12px;color:' + c.txt2 + ';flex:1">' + label + '</span>'
        + '<span style="font-size:13px;font-weight:600;color:' + valColor + '">' + val + '</span>'
        + '</div>';
    }
    var videoLabel = videoState === 'done' ? '已结算' : (videoState === 'open' ? '营业中' : '未营业');
    var videoColor = videoState === 'done' ? '#34D399' : (videoState === 'open' ? c.zzz : c.txt2);
    var videoBg = videoState === 'done' ? 'rgba(52,211,153,.12)' : 'rgba(247,184,75,.08)';
    return '<div style="background:' + c.surfCard + ';border:1px solid ' + c.border + ';border-radius:16px;overflow:hidden;box-shadow:0 2px 8px ' + c.shadow + '">'
      + '<div style="display:flex;align-items:center;gap:8px;padding:10px 12px 8px">'
      + '<div style="width:4px;height:36px;border-radius:2px;background:' + c.zzz + ';flex-shrink:0"></div>'
      + '<div style="flex:1"><div style="font-size:15px;font-weight:500;color:' + c.txt + '">绝区零</div>'
      + '<div style="font-size:12px;color:' + c.txt2 + '">' + nick + ' · ' + server + '</div></div>'
      + '<span style="font-size:11px;color:' + c.txt2 + '">刚刚</span>'
      + '</div>'
      + cardHeaderDivider()
      + '<div style="padding:10px 12px 12px;display:flex;flex-direction:column;gap:6px">'
      + '<div style="display:flex;align-items:center;gap:10px">'
      + '<div style="width:28px;height:28px;border-radius:8px;background:rgba(247,184,75,.12);display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0">⚡</div>'
      + '<div style="flex:1">'
      + '<div style="font-size:11px;color:' + c.txt2 + ';margin-bottom:2px">电量</div>'
      + '<div style="display:flex;align-items:baseline;gap:3px">'
      + '<span style="font-size:24px;font-weight:700;line-height:1;color:' + energyColor + '">' + energy + '</span>'
      + '<span style="font-size:13px;color:' + c.txt2 + '">/' + energyMax + '</span>'
      + '</div>'
      + '<div style="font-size:11px;color:' + (isFull ? c.danger : c.txt2) + ';margin-top:2px">'
      + (isFull ? '已全部恢复' : '将于 4 小时后全部恢复')
      + '</div></div>' + ring + '</div>'
      + cardDivider()
      + row('🎯', 'rgba(247,184,75,.12)', '今日活跃度', vitality + '/' + vitalityMax, c.zzz)
      + row('🃏', cardDone ? 'rgba(52,211,153,.12)' : 'rgba(255,107,107,.12)', '刮刮卡/占卜', cardDone ? '已完成' : '未完成', cardDone ? '#34D399' : c.danger)
      + row('📼', videoBg, '录像店经营', videoLabel, videoColor)
      + '</div></div>';
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

  function accountSection(username, gameCount, cards) {
    return (
      '<div style="margin-bottom:20px">' +
      '<div style="display:flex;align-items:center;gap:8px;padding:8px 0 12px">' +
      '<div style="width:28px;height:28px;border-radius:14px;background:' +
      c.primary +
      ';flex-shrink:0"></div>' +
      '<span style="font-size:15px;font-weight:500;color:' +
      c.txt +
      ';flex:1">' +
      username +
      "</span>" +
      '<span style="font-size:12px;color:' +
      c.txt2 +
      '">' +
      gameCount +
      " 个游戏</span>" +
      "</div>" +
      '<div style="display:grid;grid-template-columns:' +
      gridCols +
      ';gap:12px">' +
      cards +
      "</div>" +
      "</div>"
    );
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
      "182692936",
      3,
      genshinCard("旅行者", "天空岛", 140, 200, false, 3, 5, 1800, 2400, true) +
        starrailCard("开拓者", "星穹列车", 200, 240, true, 1200, 400, 500, 3, 3, 8400, 14000, 6000, 8000) +
        zzzCard("绳匠", "艾利都", 180, 240, false, 400, 500, true, "done"),
    );
    var sec2 = accountSection(
      "另一个账号",
      1,
      genshinCard("钟离", "世界树", 200, 200, true, 5, 5, 2400, 2400, false),
    );
    content =
      '<div class="sy" style="flex:1;padding:8px 16px 40px">' +
      sec1 +
      '<div style="height:1px;background:' +
      c.div +
      ';margin-bottom:20px"></div>' +
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

function homeControls() {
  return [
    {
      id: "view",
      label: "视图",
      options: [
        { value: "data", label: "有数据" },
        { value: "empty", label: "空状态" },
        { value: "loading", label: "加载中" },
      ],
      current: function () {
        return homeState.view;
      },
      onChange: function (v) {
        homeState.view = v;
      },
    },
  ];
}

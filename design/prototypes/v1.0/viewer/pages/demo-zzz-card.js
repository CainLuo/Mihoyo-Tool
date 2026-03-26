/**
 * demo-zzz-card.js — 绝区零战绩卡片 Demo
 * 待确认后合并到 home.js
 */
var demoZzzState = { energy: "normal" };

function zzzCardDemo(c, energyOverride) {
  var state = energyOverride || demoZzzState.energy;
  var isFull = state === "full";
  var energy = isFull ? 240 : 180;
  var energyColor = isFull ? c.danger : c.zzz;
  var ratio = energy / 240;

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
    energyColor +
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

  // 录像店状态
  var videoState =
    state === "video_done"
      ? "已结算"
      : state === "video_open"
        ? "营业中"
        : "未营业";
  var videoColor =
    state === "video_done"
      ? "#34D399"
      : state === "video_open"
        ? c.zzz
        : c.txt2;

  // 刮刮卡状态
  var cardDone = state !== "card_no";
  var cardVal = cardDone ? "已完成" : "未完成";
  var cardColor = cardDone ? "#34D399" : c.danger;

  return (
    '<div style="background:' +
    c.surfCard +
    ";border:1px solid " +
    c.border +
    ";border-radius:16px;overflow:hidden;box-shadow:0 2px 8px " +
    c.shadow +
    '">' +
    // 头部
    '<div style="display:flex;align-items:center;gap:8px;padding:10px 12px 8px">' +
    '<div style="width:4px;height:36px;border-radius:2px;background:' +
    c.zzz +
    ';flex-shrink:0"></div>' +
    '<div style="flex:1"><div style="font-size:15px;font-weight:500;color:' +
    c.txt +
    '">绝区零</div>' +
    '<div style="font-size:12px;color:' +
    c.txt2 +
    '">绳匠 · 艾利都</div></div>' +
    '<span style="font-size:11px;color:' +
    c.txt2 +
    '">刚刚</span>' +
    "</div>" +
    cardHeaderDivider() +
    // 内容区
    '<div style="padding:10px 12px 12px;display:flex;flex-direction:column;gap:6px">' +
    // 体力（大数字 + 环形进度）
    '<div style="display:flex;align-items:center;gap:10px">' +
    '<div style="width:28px;height:28px;border-radius:8px;background:rgba(247,184,75,.12);display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0">⚡</div>' +
    '<div style="flex:1">' +
    '<div style="font-size:11px;color:' +
    c.txt2 +
    ';margin-bottom:2px">电量</div>' +
    '<div style="display:flex;align-items:baseline;gap:3px">' +
    '<span style="font-size:24px;font-weight:700;line-height:1;color:' +
    energyColor +
    '">' +
    energy +
    "</span>" +
    '<span style="font-size:13px;color:' +
    c.txt2 +
    '">/240</span>' +
    "</div>" +
    '<div style="font-size:11px;color:' +
    (isFull ? c.danger : c.txt2) +
    ';margin-top:2px">' +
    (isFull ? "已全部恢复" : "将于 4 小时后全部恢复") +
    "</div></div>" +
    ring +
    "</div>" +
    cardDivider() +
    // 今日活跃度
    row("🎯", "rgba(247,184,75,.12)", "今日活跃度", "400/500", c.zzz) +
    // 刮刮卡/占卜
    row(
      "🃏",
      cardDone ? "rgba(52,211,153,.12)" : "rgba(255,107,107,.12)",
      "刮刮卡/占卜",
      cardVal,
      cardColor,
    ) +
    // 录像店经营
    row(
      "📼",
      state === "video_done" ? "rgba(52,211,153,.12)" : "rgba(247,184,75,.08)",
      "录像店经营",
      videoState,
      videoColor,
    ) +
    "</div></div>"
  );
}

function renderDemoZzzCard(w, h) {
  var c = T();
  var cols = w < 600 ? 1 : w < 840 ? 2 : w < 1200 ? 3 : 4;
  var gridCols = "repeat(" + cols + ",1fr)";

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

  var sec1 = accountSection("182692936", 1, zzzCardDemo(c));

  var content =
    '<div class="sy" style="flex:1;padding:8px 16px 40px">' + sec1 + "</div>";

  return (
    baseCss(w, h) +
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

function demoZzzCardControls() {
  return [
    {
      id: "energy",
      label: "状态",
      options: [
        { value: "normal", label: "正常" },
        { value: "full", label: "电量满" },
        { value: "card_no", label: "刮刮卡未完成" },
        { value: "video_done", label: "录像店已结算" },
        { value: "video_open", label: "录像店营业中" },
      ],
      current: function () {
        return demoZzzState.energy;
      },
      onChange: function (v) {
        demoZzzState.energy = v;
      },
    },
  ];
}

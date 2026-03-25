/**
 * shared.js — 所有原型页面共享的主题、工具函数
 */

var DEVS = {
  pp: { w: 360, h: 780, label: "Phone 竖屏\n360×780" },
  pl: { w: 780, h: 360, label: "Phone 横屏\n780×360" },
  fd: { w: 932, h: 600, label: "Foldable\n932×600" },
  tf: { w: 1200, h: 600, label: "TripleFold\n1200×600" },
  tb: { w: 1024, h: 768, label: "Tablet\n1024×768" },
  pc: { w: 1440, h: 900, label: "2in1/PC\n1440×900" },
};

var THEMES = {
  dark: {
    pageBg: "#000000",
    cardBg: "#000000",
    surfCard: "#1C1C1C",
    border: "#2A2A2A",
    txt: "#E0E0E0",
    txt2: "#999999",
    txtM: "#555555",
    div: "#1A1A1A",
    primary: "#4DA3FF",
    priBg: "rgba(77,163,255,0.12)",
    priRgb: "77,163,255",
    danger: "#FF6B6B",
    dangerBg: "rgba(255,107,107,0.12)",
    warning: "#FFB74D",
    ok: "#34D399",
    okBg: "rgba(52,211,153,0.12)",
    shadow: "rgba(0,0,0,0.4)",
    inputBg: "#111118",
    inputBd: "#333333",
    tabBg: "#1C1C1C",
    tabSel: "#4DA3FF",
    navBg: "rgba(0,0,0,0.92)",
    genshin: "#5BA3E8",
    starrail: "#9B8EFF",
    zzz: "#F7B84B",
    honkai3: "#FF6B9D",
    gold: "#FFCA28",
    cyan: "#4FC3F7",
    hydro: "#4FC3F7",
    pyro: "#FF7043",
    electro: "#CE93D8",
    anemo: "#80CBC4",
    geo: "#FFCA28",
    cryo: "#B3E5FC",
    dendro: "#A5D6A7",
    logoFg0: "#EEF4FF",
    logoFg1: "#D0E4FF",
    logoBg: "#0E0E22",
    bgLight: "#0A1E38",
    bgDark: "#0E0E22",
    bgDeep: "#0D0D18",
    scrollThumb: "rgba(255,255,255,0.15)",
  },
  light: {
    pageBg: "#F5F5F5",
    cardBg: "#FFFFFF",
    surfCard: "#FFFFFF",
    border: "#E8E8E8",
    txt: "#333333",
    txt2: "#666666",
    txtM: "#AAAAAA",
    div: "#EEEEEE",
    primary: "#007DFF",
    priBg: "rgba(0,125,255,0.10)",
    priRgb: "0,125,255",
    danger: "#E8534A",
    dangerBg: "rgba(232,83,74,0.10)",
    warning: "#F57C00",
    ok: "#10B981",
    okBg: "rgba(16,185,129,0.10)",
    shadow: "rgba(0,0,0,0.08)",
    inputBg: "#F8F8F8",
    inputBd: "#DDDDDD",
    tabBg: "#FFFFFF",
    tabSel: "#007DFF",
    navBg: "rgba(245,245,245,0.92)",
    genshin: "#4A90D9",
    starrail: "#7B68EE",
    zzz: "#F5A623",
    honkai3: "#E91E8C",
    gold: "#F5A623",
    cyan: "#4BC3F1",
    hydro: "#4BC3F1",
    pyro: "#E64A19",
    electro: "#9C27B0",
    anemo: "#00897B",
    geo: "#F9A825",
    cryo: "#0288D1",
    dendro: "#388E3C",
    logoFg0: "#FFFFFF",
    logoFg1: "#E8F0FF",
    logoBg: "#FFFFFF",
    bgLight: "#E8F0FF",
    bgDark: "#D0E4FF",
    bgDeep: "#F5F5F5",
    scrollThumb: "rgba(0,0,0,0.15)",
  },
};

/** 当前全局状态（由 index.html 管理） */
var G = {
  dev: "pp",
  theme: "dark",
};

function T() {
  return THEMES[G.theme];
}
function D() {
  return DEVS[G.dev];
}

/** 生成基础 CSS reset + body 尺寸 */
function baseCss(w, h) {
  var c = T();
  var sc = c.scrollThumb;
  return (
    "<style>" +
    "*{box-sizing:border-box;margin:0;padding:0}" +
    "body{width:" +
    w +
    "px;height:" +
    h +
    "px;overflow:hidden;background:" +
    c.pageBg +
    ";color:" +
    c.txt +
    ';font-family:"PingFang SC","Microsoft YaHei",sans-serif}' +
    ".sy{overflow-y:auto;scrollbar-width:thin;scrollbar-color:" +
    sc +
    " transparent}" +
    ".sy::-webkit-scrollbar{width:3px}" +
    ".sy::-webkit-scrollbar-thumb{background:" +
    sc +
    ";border-radius:2px}" +
    "</style>"
  );
}

/** 底部 TabBar（Tab 子页用） */
function tabBar(activeTab) {
  var c = T();
  var tabs = [
    ["首页", "home"],
    ["角色", "characters"],
    ["我的", "my"],
  ];
  var h =
    '<div style="height:56px;flex-shrink:0;display:flex;background:' +
    c.tabBg +
    ";border-top:1px solid " +
    c.div +
    '">';
  for (var i = 0; i < tabs.length; i++) {
    var sel = tabs[i][1] === activeTab;
    h +=
      '<div style="flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px">' +
      '<div style="width:20px;height:3px;border-radius:2px;background:' +
      (sel ? c.tabSel : "transparent") +
      '"></div>' +
      '<span style="font-size:11px;color:' +
      (sel ? c.tabSel : c.txt2) +
      '">' +
      tabs[i][0] +
      "</span>" +
      "</div>";
  }
  return h + "</div>";
}

/** 环形进度 SVG */
function ringProgress(ratio, color, size) {
  var r = size / 2 - 4,
    cx = size / 2,
    cy = size / 2;
  var circ = 2 * Math.PI * r;
  var dash = circ * Math.min(ratio, 1);
  var gap = circ - dash;
  return (
    '<svg width="' +
    size +
    '" height="' +
    size +
    '" viewBox="0 0 ' +
    size +
    " " +
    size +
    '">' +
    '<circle cx="' +
    cx +
    '" cy="' +
    cy +
    '" r="' +
    r +
    '" fill="none" stroke="rgba(128,128,128,.2)" stroke-width="5"/>' +
    '<circle cx="' +
    cx +
    '" cy="' +
    cy +
    '" r="' +
    r +
    '" fill="none" stroke="' +
    color +
    '" stroke-width="5"' +
    ' stroke-dasharray="' +
    dash.toFixed(1) +
    " " +
    gap.toFixed(1) +
    '"' +
    ' stroke-linecap="round" transform="rotate(-90 ' +
    cx +
    " " +
    cy +
    ')"/>' +
    "</svg>"
  );
}

/** 骨架屏色块 */
function sk(w, h, r) {
  var c = T();
  r = r || 6;
  return (
    '<div style="background:' +
    c.border +
    ";border-radius:" +
    r +
    "px;width:" +
    w +
    ";height:" +
    h +
    'px;animation:sk 1.5s ease-in-out infinite"></div>'
  );
}

/** 骨架屏 keyframes（注入到 baseCss 后） */
var SK_ANIM =
  "<style>@keyframes sk{0%,100%{opacity:.4}50%{opacity:.9}}</style>";

/** Logo SVG */
function logoSVG(s) {
  var c = T();
  var gid = "g" + Math.round(Math.random() * 99999);
  var rc = s * 0.22,
    cx = s * 0.5;
  var blueH = s * 0.62,
    headR = s * 0.32,
    headCX = cx,
    headCY = s * 0.72;
  var earW = s * 0.11,
    earH = s * 0.3,
    earR = earW * 0.5;
  var earLX = cx - s * 0.115,
    earRX = cx + s * 0.005,
    earTopY = s * 0.1;
  var iearW = earW * 0.45,
    iearH = earH * 0.55,
    iearR = iearW * 0.5;
  var sw = (s * 0.018).toFixed(2);
  return (
    '<svg width="' +
    s +
    '" height="' +
    s +
    '" viewBox="0 0 ' +
    s +
    " " +
    s +
    '" xmlns="http://www.w3.org/2000/svg">' +
    "<defs>" +
    '<linearGradient id="' +
    gid +
    'b" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="' +
    c.primary +
    '"/><stop offset="100%" stop-color="' +
    c.cyan +
    '"/></linearGradient>' +
    '<radialGradient id="' +
    gid +
    'h" cx="45%" cy="35%" r="65%"><stop offset="0%" stop-color="' +
    c.logoFg0 +
    '"/><stop offset="100%" stop-color="' +
    c.logoFg1 +
    '"/></radialGradient>' +
    '<filter id="' +
    gid +
    's"><feDropShadow dx="0" dy="' +
    (s * 0.01).toFixed(1) +
    '" stdDeviation="' +
    (s * 0.02).toFixed(1) +
    '" flood-color="' +
    c.primary +
    '" flood-opacity="0.4"/></filter>' +
    '<clipPath id="' +
    gid +
    'c"><rect width="' +
    s +
    '" height="' +
    s +
    '" rx="' +
    rc +
    '" ry="' +
    rc +
    '"/></clipPath>' +
    "</defs>" +
    '<g clip-path="url(#' +
    gid +
    'c)">' +
    '<rect width="' +
    s +
    '" height="' +
    s +
    '" fill="' +
    c.logoBg +
    '"/>' +
    '<rect x="0" y="0" width="' +
    s +
    '" height="' +
    blueH +
    '" fill="url(#' +
    gid +
    'b)"/>' +
    '<rect x="' +
    earLX +
    '" y="' +
    earTopY +
    '" width="' +
    earW +
    '" height="' +
    earH +
    '" rx="' +
    earR +
    '" ry="' +
    earR +
    '" fill="url(#' +
    gid +
    'h)" filter="url(#' +
    gid +
    's)"/>' +
    '<rect x="' +
    earRX +
    '" y="' +
    earTopY +
    '" width="' +
    earW +
    '" height="' +
    earH +
    '" rx="' +
    earR +
    '" ry="' +
    earR +
    '" fill="url(#' +
    gid +
    'h)" filter="url(#' +
    gid +
    's)"/>' +
    '<rect x="' +
    earLX +
    '" y="' +
    earTopY +
    '" width="' +
    earW +
    '" height="' +
    earH +
    '" rx="' +
    earR +
    '" ry="' +
    earR +
    '" fill="none" stroke="' +
    c.primary +
    '" stroke-width="' +
    sw +
    '"/>' +
    '<rect x="' +
    earRX +
    '" y="' +
    earTopY +
    '" width="' +
    earW +
    '" height="' +
    earH +
    '" rx="' +
    earR +
    '" ry="' +
    earR +
    '" fill="none" stroke="' +
    c.primary +
    '" stroke-width="' +
    sw +
    '"/>' +
    '<rect x="' +
    (earLX + earW * 0.275) +
    '" y="' +
    (earTopY + earH * 0.1) +
    '" width="' +
    iearW +
    '" height="' +
    iearH +
    '" rx="' +
    iearR +
    '" ry="' +
    iearR +
    '" fill="' +
    c.primary +
    '" opacity="0.55"/>' +
    '<rect x="' +
    (earRX + earW * 0.275) +
    '" y="' +
    (earTopY + earH * 0.1) +
    '" width="' +
    iearW +
    '" height="' +
    iearH +
    '" rx="' +
    iearR +
    '" ry="' +
    iearR +
    '" fill="' +
    c.primary +
    '" opacity="0.55"/>' +
    '<circle cx="' +
    (earLX + earW * 0.5) +
    '" cy="' +
    (earTopY + s * 0.015) +
    '" r="' +
    s * 0.022 +
    '" fill="' +
    c.genshin +
    '" opacity="0.9"/>' +
    '<circle cx="' +
    (earRX + earW * 0.5) +
    '" cy="' +
    (earTopY + s * 0.015) +
    '" r="' +
    s * 0.022 +
    '" fill="' +
    c.starrail +
    '" opacity="0.9"/>' +
    '<circle cx="' +
    headCX +
    '" cy="' +
    headCY +
    '" r="' +
    headR +
    '" fill="url(#' +
    gid +
    'h)" filter="url(#' +
    gid +
    's)"/>' +
    '<circle cx="' +
    headCX +
    '" cy="' +
    headCY +
    '" r="' +
    headR +
    '" fill="none" stroke="' +
    c.primary +
    '" stroke-width="' +
    sw +
    '"/>' +
    '<polygon points="' +
    (headCX - s * 0.09) +
    "," +
    (headCY - s * 0.04) +
    " " +
    (headCX - s * 0.065) +
    "," +
    (headCY - s * 0.015) +
    " " +
    (headCX - s * 0.09) +
    "," +
    (headCY + s * 0.01) +
    " " +
    (headCX - s * 0.115) +
    "," +
    (headCY - s * 0.015) +
    '" fill="' +
    c.primary +
    '"/>' +
    '<polygon points="' +
    (headCX + s * 0.09) +
    "," +
    (headCY - s * 0.04) +
    " " +
    (headCX + s * 0.115) +
    "," +
    (headCY - s * 0.015) +
    " " +
    (headCX + s * 0.09) +
    "," +
    (headCY + s * 0.01) +
    " " +
    (headCX + s * 0.065) +
    "," +
    (headCY - s * 0.015) +
    '" fill="' +
    c.primary +
    '"/>' +
    "</g></svg>"
  );
}

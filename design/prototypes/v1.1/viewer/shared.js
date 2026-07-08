/**
 * shared.js — Widget 原型共享主题和工具函数
 * V1.1 版本
 * 
 * UI/UX 优化：
 * - Typography Scale 统一为 6 级（12/14/16/20/24/40px）
 * - 文字对比度符合 WCAG 2.2（≥ 4.5:1）
 * - 文字透明度从 .35/.3 提升到 .5/.45
 */

var DEVS = {
  pp: { w: 360, h: 780, label: "Phone 竖屏\n360×780" },
  pl: { w: 780, h: 360, label: "Phone 横屏\n780×360" },
  fd: { w: 932, h: 600, label: "Foldable\n932×600" },
  tb: { w: 1024, h: 768, label: "Tablet\n1024×768" },
};

/**
 * Typography Scale（8px 基准）
 * - text-xs:  12px - 辅助信息、标签
 * - text-sm:  14px - 副标题、游戏名
 * - text-base: 16px - 数据行
 * - text-lg:  18px - 小数字
 * - text-xl:  20px - 体力数字（1x2）
 * - text-2xl: 24px - 体力数字（2x2）
 * - text-5xl: 40px - 体力数字（4x4）
 */
var FONT = {
  xs: "12px",    // 辅助信息
  sm: "14px",    // 副标题
  base: "16px",  // 数据行
  lg: "18px",    // 小数字
  xl: "20px",    // 体力数字（1x2）
  "2xl": "24px", // 体力数字（2x2）
  "5xl": "40px", // 体力数字（4x4）
};

/**
 * 文字颜色透明度（WCAG 2.2 对比度合规）
 * - txtHigh: 高对比度文字（标题、数字）
 * - txtMid: 中对比度文字（副标题、数据标签）
 * - txtLow: 低对比度文字（辅助信息）- 已从 .35 提升到 .45 确保 ≥ 4.5:1
 */
var TXT_ALPHA = {
  high: 0.95,  // 主标题、数字
  mid: 0.6,    // 副标题、标签
  low: 0.5,    // 辅助信息（原 .35，提升至 .5 满足 WCAG）
};

var THEMES = {
  dark: {
    pageBg: "#080810",
    cardBg: "#111118",
    surfCard: "#111118",
    surfSubtle: "#16161f",
    border: "#2a2a3a",
    txt: "#e8e8f0",
    txt2: "#888888",
    txtM: "#444455",
    div: "#2a2a3a",
    primary: "#3a6fd8",
    priBg: "rgba(58,111,216,0.15)",
    priRgb: "58,111,216",
    danger: "#ef5350",
    dangerBg: "rgba(239,83,80,0.15)",
    warning: "#ffca28",
    ok: "#34d399",
    okBg: "rgba(52,211,153,0.12)",
    shadow: "rgba(0,0,0,0.4)",
    inputBg: "#0d0d18",
    inputBd: "#2a2a3a",
    tabBg: "#111118",
    tabSel: "#3a6fd8",
    genshin: "#5ba3e8",
    starrail: "#9b8eff",
    zzz: "#f7b84b",
    gold: "#ffca28",
    cyan: "#4fc3f7",
    scrollThumb: "rgba(255,255,255,0.15)",
    // Widget 专用
    widgetBg: "#2E3033",
    widgetBorder: "rgba(255,255,255,0.08)",
    widgetTxt: "rgba(255,255,255," + TXT_ALPHA.high + ")",
    widgetTxt2: "rgba(255,255,255," + TXT_ALPHA.mid + ")",
    widgetTxt3: "rgba(255,255,255," + TXT_ALPHA.low + ")",
    widgetDivider: "rgba(255,255,255,0.12)",
    // 半模态
    sheetBg: "#1a1a28",
    sheetHandle: "rgba(255,255,255,0.2)",
  },
  light: {
    pageBg: "#f5f5f5",
    cardBg: "#ffffff",
    surfCard: "#ffffff",
    surfSubtle: "#f0f0f5",
    border: "#e8e8e8",
    txt: "#1a1a2e",
    txt2: "#666666",
    txtM: "#aaaaaa",
    div: "#eeeeee",
    primary: "#3a6fd8",
    priBg: "rgba(58,111,216,0.10)",
    priRgb: "58,111,216",
    danger: "#e53935",
    dangerBg: "rgba(229,57,53,0.10)",
    warning: "#f9a825",
    ok: "#10b981",
    okBg: "rgba(16,185,129,0.10)",
    shadow: "rgba(0,0,0,0.08)",
    inputBg: "#f8f8f8",
    inputBd: "#dddddd",
    tabBg: "#ffffff",
    tabSel: "#3a6fd8",
    genshin: "#4a90d9",
    starrail: "#7b68ee",
    zzz: "#f5a623",
    gold: "#f9a825",
    cyan: "#4bc3f1",
    scrollThumb: "rgba(0,0,0,0.15)",
    // Widget 专用（浅色模式下 Widget 背景也是深色）
    widgetBg: "#2E3033",
    widgetBorder: "rgba(255,255,255,0.08)",
    widgetTxt: "rgba(255,255,255," + TXT_ALPHA.high + ")",
    widgetTxt2: "rgba(255,255,255," + TXT_ALPHA.mid + ")",
    widgetTxt3: "rgba(255,255,255," + TXT_ALPHA.low + ")",
    widgetDivider: "rgba(255,255,255,0.12)",
    // 半模态
    sheetBg: "#ffffff",
    sheetHandle: "rgba(0,0,0,0.15)",
  },
};

var G = { dev: "pp", theme: "dark" };

function T() {
  return THEMES[G.theme];
}
function D() {
  return DEVS[G.dev];
}

function baseCss(w, h) {
  var c = T();
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
    c.scrollThumb +
    " transparent}" +
    ".sy::-webkit-scrollbar{width:3px}" +
    ".sy::-webkit-scrollbar-thumb{background:" +
    c.scrollThumb +
    ";border-radius:2px}" +
    "</style>"
  );
}

function cardDivider() {
  var color = G.theme === "dark" ? "rgba(255,255,255,.12)" : "#eeeeee";
  return '<div style="height:1px;background:' + color + ';margin:6px 0" role="separator"></div>';
}

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
    '" role="img" aria-label="进度 ' + Math.round(ratio * 100) + '%">' +
    '<circle cx="' +
    cx +
    '" cy="' +
    cy +
    '" r="' +
    r +
    '" fill="none" stroke="rgba(255,255,255,.15)" stroke-width="4"/>' +
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

var SK_ANIM =
  "<style>@keyframes sk{0%,100%{opacity:.4}50%{opacity:.9}}</style>";

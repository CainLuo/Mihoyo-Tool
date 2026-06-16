/**
 * widget-edit.js — HarmonyOS Widget 卡片编辑页原型
 * 方案A：半模态面板（从底部弹出，桌面+卡片预览作为背景）
 * 方案B：App 内配置页（顶部导航栏 + 设置列表）
 */

// ── State ─────────────────────────────────────────────────────────

var widgetEditState = {
  scheme: "A",
  step: "size", // 步骤：size → select → game → done
  selectedSize: "2x2",
  selectedAccounts: [0], // 数组，支持多选
  selectedGames: ["genshin", "starrail", "zzz"],
  displayMode: "single",
};

// ── 常量数据 ──────────────────────────────────────────────────────

var ACCOUNTS = [
  { name: "旅行者", uid: "182692936", games: ["genshin", "starrail", "zzz"] },
  { name: "开拓者", uid: "109050292", games: ["starrail", "zzz"] },
];

var GAME_NAMES = { genshin: "原神", starrail: "崩坏：星穹铁道", zzz: "绝区零" };
var GAME_COLORS = { genshin: "#5ba3e8", starrail: "#9b8eff", zzz: "#f7b84b" };
var GAME_ICONS = { genshin: "🌙", starrail: "⚡", zzz: "⚡" };
var SIZE_LABELS = {
  "1x2": "1×2 迷你",
  "2x2": "2×2 标准",
  "2x4": "2×4 宽幅",
  "4x4": "4×4 大卡片",
};
var SIZE_DESCS = {
  "1x2": "1个账号 · 1款游戏 · 仅体力",
  "2x2": "1个账号 · 最多3款游戏 · 详细模式",
  "2x4": "详细：1账号完整数据 / 精简：2账号体力概览",
  "4x4": "详细：1账号完整数据 / 精简：3账号体力概览",
};

// ── 辅助函数 ──────────────────────────────────────────────────────

function maxAccountsForSize(size) {
  // 每张卡片只绑定 1 个账号（决策 1：多账号通过添加多张卡片实现）
  return 1;
}

/** SVG 环形进度，position:absolute */
function wRingSmall(ratio, color, size) {
  var r = size / 2 - 2.5;
  var cx = size / 2;
  var cy = size / 2;
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
    '" style="position:absolute;top:0;left:0">' +
    '<circle cx="' +
    cx +
    '" cy="' +
    cy +
    '" r="' +
    r +
    '" fill="none" stroke="rgba(255,255,255,.15)" stroke-width="3"/>' +
    '<circle cx="' +
    cx +
    '" cy="' +
    cy +
    '" r="' +
    r +
    '" fill="none" stroke="' +
    color +
    '" stroke-width="3"' +
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

// ── 交互函数（全局，供 onclick 调用）─────────────────────────────

function widgetEditSelectSize(size) {
  widgetEditState.selectedSize = size;
  var maxAcc = maxAccountsForSize(size);
  if (widgetEditState.selectedAccounts.length > maxAcc) {
    widgetEditState.selectedAccounts = widgetEditState.selectedAccounts.slice(
      0,
      maxAcc,
    );
  }
  refresh();
}

function widgetEditToggleAccount(idx) {
  var sel = widgetEditState.selectedAccounts;
  var maxAcc = maxAccountsForSize(widgetEditState.selectedSize);
  var pos = sel.indexOf(idx);
  if (pos >= 0) {
    // 已选中，取消（至少保留1个）
    if (sel.length > 1) {
      widgetEditState.selectedAccounts = sel.filter(function (i) {
        return i !== idx;
      });
    }
  } else {
    if (sel.length < maxAcc) {
      widgetEditState.selectedAccounts = sel.concat([idx]);
    } else {
      // 超出上限，替换最早选的
      var newSel = sel.slice(1).concat([idx]);
      widgetEditState.selectedAccounts = newSel;
    }
  }
  refresh();
}

function widgetEditToggleGame(gid) {
  var sel = widgetEditState.selectedGames;
  var pos = sel.indexOf(gid);
  if (pos >= 0) {
    if (sel.length > 1) {
      widgetEditState.selectedGames = sel.filter(function (g) {
        return g !== gid;
      });
    }
  } else {
    widgetEditState.selectedGames = sel.concat([gid]);
  }
  refresh();
}

function widgetEditNextStep() {
  var steps = ["size", "select", "game", "done"];
  var cur = steps.indexOf(widgetEditState.step);
  if (cur < steps.length - 1) {
    widgetEditState.step = steps[cur + 1];
  }
  refresh();
}

function widgetEditPrevStep() {
  var steps = ["size", "select", "game", "done"];
  var cur = steps.indexOf(widgetEditState.step);
  if (cur > 0) {
    widgetEditState.step = steps[cur - 1];
  }
  refresh();
}

function widgetEditReset() {
  widgetEditState.step = "size";
  refresh();
}

function widgetEditSetDisplayMode(mode) {
  widgetEditState.displayMode = mode;
  refresh();
}

// ── 步骤指示器 ────────────────────────────────────────────────────

function renderStepIndicator(currentStep) {
  var steps = [
    { key: "size", label: "尺寸" },
    { key: "select", label: "账号" },
    { key: "game", label: "游戏" },
    { key: "done", label: "完成" },
  ];
  var c = T();
  var stepIdx = ["size", "select", "game", "done"].indexOf(currentStep);
  var html =
    '<div style="display:flex;align-items:center;justify-content:center;gap:0;margin-bottom:20px">';
  for (var i = 0; i < steps.length; i++) {
    var s = steps[i];
    var isDone = i < stepIdx;
    var isCur = i === stepIdx;
    var dotColor = isDone ? c.primary : isCur ? c.primary : c.border;
    var dotBg = isDone ? c.primary : isCur ? c.primary : "transparent";
    var txtColor = isCur ? c.primary : isDone ? c.primary : c.txt2;
    var dotContent = isDone ? "✓" : i + 1;
    html +=
      '<div style="display:flex;flex-direction:column;align-items:center;gap:4px">' +
      '<div style="width:24px;height:24px;border-radius:50%;border:2px solid ' +
      dotColor +
      ";background:" +
      dotBg +
      ";display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:600;color:" +
      (isDone || isCur ? "#fff" : c.txt2) +
      '">' +
      dotContent +
      "</div>" +
      '<div style="font-size:10px;color:' +
      txtColor +
      ';white-space:nowrap">' +
      s.label +
      "</div>" +
      "</div>";
    if (i < steps.length - 1) {
      var lineColor = i < stepIdx ? c.primary : c.border;
      html +=
        '<div style="width:32px;height:2px;background:' +
        lineColor +
        ';margin-bottom:14px;flex-shrink:0"></div>';
    }
  }
  html += "</div>";
  return html;
}

// ── 步骤内容渲染 ──────────────────────────────────────────────────

function renderStepSize() {
  var c = T();
  var sel = widgetEditState.selectedSize;
  var sizes = ["1x2", "2x2", "2x4", "4x4"];
  var html = '<div style="display:flex;flex-direction:column;gap:10px">';
  for (var i = 0; i < sizes.length; i++) {
    var sz = sizes[i];
    var isSelected = sel === sz;
    var borderColor = isSelected ? c.primary : c.border;
    var bgColor = isSelected ? c.priBg : "transparent";
    html +=
      "<div onclick=\"widgetEditSelectSize('" +
      sz +
      '\')" style="border:2px solid ' +
      borderColor +
      ";border-radius:12px;padding:12px 14px;background:" +
      bgColor +
      ';cursor:pointer;display:flex;align-items:center;gap:12px;transition:all .15s">' +
      // 尺寸示意图
      '<div style="width:40px;height:40px;flex-shrink:0;display:flex;align-items:center;justify-content:center">' +
      renderSizeThumb(sz, isSelected ? c.primary : c.txt2) +
      "</div>" +
      '<div style="flex:1;min-width:0">' +
      '<div style="font-size:14px;font-weight:600;color:' +
      (isSelected ? c.primary : c.txt) +
      ';margin-bottom:2px">' +
      SIZE_LABELS[sz] +
      "</div>" +
      '<div style="font-size:12px;color:' +
      c.txt2 +
      '">' +
      SIZE_DESCS[sz] +
      "</div>" +
      "</div>" +
      (isSelected
        ? '<div style="width:18px;height:18px;border-radius:50%;background:' +
          c.primary +
          ';display:flex;align-items:center;justify-content:center;flex-shrink:0"><span style="color:#fff;font-size:11px">✓</span></div>'
        : "") +
      "</div>";
  }
  html += "</div>";
  return html;
}

function renderSizeThumb(sz, color) {
  var configs = {
    "1x2": { cols: 2, rows: 1 },
    "2x2": { cols: 2, rows: 2 },
    "2x4": { cols: 4, rows: 2 },
    "4x4": { cols: 4, rows: 4 },
  };
  var cfg = configs[sz];
  var cellSize = sz === "4x4" ? 7 : sz === "2x4" ? 8 : 10;
  var gap = 2;
  var totalW = cfg.cols * cellSize + (cfg.cols - 1) * gap;
  var totalH = cfg.rows * cellSize + (cfg.rows - 1) * gap;
  var html =
    '<svg width="' +
    totalW +
    '" height="' +
    totalH +
    '" viewBox="0 0 ' +
    totalW +
    " " +
    totalH +
    '">';
  for (var r = 0; r < cfg.rows; r++) {
    for (var col = 0; col < cfg.cols; col++) {
      var x = col * (cellSize + gap);
      var y = r * (cellSize + gap);
      html +=
        '<rect x="' +
        x +
        '" y="' +
        y +
        '" width="' +
        cellSize +
        '" height="' +
        cellSize +
        '" rx="2" fill="' +
        color +
        '" opacity="0.7"/>';
    }
  }
  html += "</svg>";
  return html;
}

function renderStepSelect() {
  var c = T();
  var sel = widgetEditState.selectedAccounts;
  var maxAcc = maxAccountsForSize(widgetEditState.selectedSize);
  var isMulti = maxAcc > 1;
  var html =
    '<div style="margin-bottom:12px;font-size:12px;color:' +
    c.txt2 +
    '">最多选择 ' +
    maxAcc +
    " 个账号" +
    (isMulti ? "（多选）" : "（单选）") +
    "</div>" +
    '<div style="display:flex;flex-direction:column;gap:10px">';
  for (var i = 0; i < ACCOUNTS.length; i++) {
    var acc = ACCOUNTS[i];
    var isSelected = sel.indexOf(i) >= 0;
    var borderColor = isSelected ? c.primary : c.border;
    var bgColor = isSelected ? c.priBg : "transparent";
    // 指示器：单选用圆形，多选用方形
    var indicator = "";
    if (isMulti) {
      indicator =
        '<div style="width:18px;height:18px;border-radius:4px;border:2px solid ' +
        (isSelected ? c.primary : c.border) +
        ";background:" +
        (isSelected ? c.primary : "transparent") +
        ';display:flex;align-items:center;justify-content:center;flex-shrink:0">' +
        (isSelected ? '<span style="color:#fff;font-size:11px">✓</span>' : "") +
        "</div>";
    } else {
      indicator =
        '<div style="width:18px;height:18px;border-radius:50%;border:2px solid ' +
        (isSelected ? c.primary : c.border) +
        ';background:transparent;display:flex;align-items:center;justify-content:center;flex-shrink:0">' +
        (isSelected
          ? '<div style="width:8px;height:8px;border-radius:50%;background:' +
            c.primary +
            '"></div>'
          : "") +
        "</div>";
    }
    // 游戏标签
    var gameTags = "";
    for (var j = 0; j < acc.games.length; j++) {
      var gid = acc.games[j];
      gameTags +=
        '<span style="font-size:10px;padding:1px 6px;border-radius:4px;background:' +
        GAME_COLORS[gid] +
        "22;color:" +
        GAME_COLORS[gid] +
        ';margin-right:4px">' +
        GAME_ICONS[gid] +
        " " +
        GAME_NAMES[gid] +
        "</span>";
    }
    html +=
      '<div onclick="widgetEditToggleAccount(' +
      i +
      ')" style="border:2px solid ' +
      borderColor +
      ";border-radius:12px;padding:12px 14px;background:" +
      bgColor +
      ';cursor:pointer;display:flex;align-items:center;gap:12px">' +
      '<div style="width:36px;height:36px;border-radius:50%;background:' +
      c.primary +
      '22;display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0">👤</div>' +
      '<div style="flex:1;min-width:0">' +
      '<div style="font-size:14px;font-weight:600;color:' +
      (isSelected ? c.primary : c.txt) +
      ';margin-bottom:4px">' +
      acc.name +
      "</div>" +
      '<div style="font-size:11px;color:' +
      c.txt2 +
      ';margin-bottom:6px">UID ' +
      acc.uid +
      "</div>" +
      "<div>" +
      gameTags +
      "</div>" +
      "</div>" +
      indicator +
      "</div>";
  }
  html += "</div>";
  return html;
}

function renderStepGame() {
  var c = T();
  var sel = widgetEditState.selectedAccounts;
  // 计算所有已选账号的游戏并集
  var availableGames = [];
  for (var i = 0; i < sel.length; i++) {
    var accGames = ACCOUNTS[sel[i]].games;
    for (var j = 0; j < accGames.length; j++) {
      if (availableGames.indexOf(accGames[j]) < 0) {
        availableGames.push(accGames[j]);
      }
    }
  }
  var selGames = widgetEditState.selectedGames;
  var html =
    '<div style="margin-bottom:12px;font-size:12px;color:' +
    c.txt2 +
    '">选择要在卡片上显示的游戏（多选）</div>' +
    '<div style="display:flex;flex-direction:column;gap:10px">';
  for (var k = 0; k < availableGames.length; k++) {
    var gid = availableGames[k];
    var isSelected = selGames.indexOf(gid) >= 0;
    var borderColor = isSelected ? GAME_COLORS[gid] : c.border;
    var bgColor = isSelected ? GAME_COLORS[gid] + "18" : "transparent";
    html +=
      "<div onclick=\"widgetEditToggleGame('" +
      gid +
      '\')" style="border:2px solid ' +
      borderColor +
      ";border-radius:12px;padding:12px 14px;background:" +
      bgColor +
      ';cursor:pointer;display:flex;align-items:center;gap:12px">' +
      '<div style="width:36px;height:36px;border-radius:10px;background:' +
      GAME_COLORS[gid] +
      '22;display:flex;align-items:center;justify-content:center;font-size:20px;flex-shrink:0">' +
      GAME_ICONS[gid] +
      "</div>" +
      '<div style="flex:1;min-width:0">' +
      '<div style="font-size:14px;font-weight:600;color:' +
      (isSelected ? GAME_COLORS[gid] : c.txt) +
      '">' +
      GAME_NAMES[gid] +
      "</div>" +
      "</div>" +
      '<div style="width:18px;height:18px;border-radius:4px;border:2px solid ' +
      (isSelected ? GAME_COLORS[gid] : c.border) +
      ";background:" +
      (isSelected ? GAME_COLORS[gid] : "transparent") +
      ';display:flex;align-items:center;justify-content:center;flex-shrink:0">' +
      (isSelected ? '<span style="color:#fff;font-size:11px">✓</span>' : "") +
      "</div>" +
      "</div>";
  }
  html += "</div>";
  return html;
}

function renderStepDone() {
  var c = T();
  var sel = widgetEditState.selectedAccounts;
  var accNames = sel
    .map(function (i) {
      return ACCOUNTS[i].name;
    })
    .join("、");
  var gameNames = widgetEditState.selectedGames
    .map(function (g) {
      return GAME_NAMES[g];
    })
    .join("、");
  var html =
    '<div style="text-align:center;padding:8px 0 20px">' +
    '<div style="font-size:32px;margin-bottom:12px">🎉</div>' +
    '<div style="font-size:16px;font-weight:600;color:' +
    c.txt +
    ';margin-bottom:6px">配置完成！</div>' +
    '<div style="font-size:12px;color:' +
    c.txt2 +
    '">卡片已准备好添加到桌面</div>' +
    "</div>" +
    '<div style="background:' +
    c.surfSubtle +
    ';border-radius:12px;padding:14px;display:flex;flex-direction:column;gap:10px">' +
    renderSummaryRow("卡片尺寸", SIZE_LABELS[widgetEditState.selectedSize]) +
    renderSummaryRow("显示账号", accNames) +
    renderSummaryRow("显示游戏", gameNames) +
    "</div>";
  return html;
}

function renderSummaryRow(label, value) {
  var c = T();
  return (
    '<div style="display:flex;align-items:center;justify-content:space-between;gap:8px">' +
    '<span style="font-size:13px;color:' +
    c.txt2 +
    '">' +
    label +
    "</span>" +
    '<span style="font-size:13px;font-weight:600;color:' +
    c.txt +
    ';text-align:right;max-width:60%">' +
    value +
    "</span>" +
    "</div>"
  );
}

// ── 通用卡片预览（根据 selectedSize 渲染对应尺寸）────────────────

/**
 * 根据当前选中的尺寸渲染对应的卡片预览。
 * maxW/maxH 是可用区域，卡片会按比例缩放以适应。
 */
function renderWidgetPreview(maxW, maxH) {
  var size = widgetEditState.selectedSize;
  var games = widgetEditState.selectedGames;
  var isDual = widgetEditState.selectedAccounts.length > 1;

  // 各尺寸的格子比例（cols × rows）
  var CELL = 80;
  var GAP = 8;
  var nativeSizes = {
    "1x2": { w: CELL * 2 + GAP, h: CELL },
    "2x2": { w: CELL * 2 + GAP, h: CELL * 2 + GAP },
    "2x4": { w: CELL * 4 + GAP * 3, h: CELL * 2 + GAP },
    "4x4": { w: CELL * 4 + GAP * 3, h: CELL * 4 + GAP * 3 },
  };
  var native = nativeSizes[size] || nativeSizes["2x2"];

  // 按比例缩放，保持宽高比，不超出 maxW/maxH
  var scale = Math.min(maxW / native.w, maxH / native.h, 1);
  var cardW = Math.round(native.w * scale);
  var cardH = Math.round(native.h * scale);

  // 调用对应尺寸的渲染函数（已拆分为独立文件）
  var html = "";
  var accName =
    widgetEditState.selectedAccounts.length > 0
      ? ACCOUNTS[widgetEditState.selectedAccounts[0]].name
      : "旅行者";
  if (size === "1x2") {
    var g = games[0] || "genshin";
    html = wrRender1x2(cardW, cardH, g);
  } else if (size === "2x2") {
    html = wrRender2x2(cardW, cardH, games);
  } else if (size === "2x4") {
    html = wrRender2x4(cardW, cardH, games);
  } else if (size === "4x4") {
    html = wrRender4x4(cardW, cardH, games);
  }

  // 加投影包装
  return (
    '<div style="box-shadow:0 8px 24px rgba(0,0,0,.5);border-radius:16px;overflow:hidden;flex-shrink:0">' +
    html +
    "</div>"
  );
}

// ── 方案A：半模态 ─────────────────────────────────────────────────

function renderSchemeA(w, h) {
  var c = T();
  var step = widgetEditState.step;
  var steps = ["size", "select", "game", "done"];
  var stepIdx = steps.indexOf(step);
  var isFirst = stepIdx === 0;
  var isLast = stepIdx === steps.length - 1;

  // 桌面背景
  var deskBg =
    G.theme === "dark"
      ? "linear-gradient(135deg,#0a0a18 0%,#0d1020 50%,#080810 100%)"
      : "linear-gradient(135deg,#e8eaf6 0%,#e3f2fd 50%,#f3e5f5 100%)";

  // 根据卡片尺寸动态调整半模态高度：
  // 4×4 是正方形，需要更大预览区，半模态压到 58%；其余 72%
  var size = widgetEditState.selectedSize;
  var sheetRatio = size === "4x4" ? 0.58 : size === "2x4" ? 0.65 : 0.72;
  var sheetH = Math.round(h * sheetRatio);
  // 卡片预览区高度 = 屏幕高度 - 半模态高度，留 16px 上下内边距
  var previewAreaH = h - sheetH;
  var previewMaxW = w - 48;
  var previewMaxH = previewAreaH - 24;

  // 步骤内容
  var stepContent = "";
  if (step === "size") stepContent = renderStepSize();
  else if (step === "select") stepContent = renderStepSelect();
  else if (step === "game") stepContent = renderStepGame();
  else if (step === "done") stepContent = renderStepDone();

  // 底部按钮
  var btnPrev = !isFirst
    ? '<button onclick="widgetEditPrevStep()" style="flex:1;height:44px;border-radius:12px;border:1px solid ' +
      c.border +
      ";background:transparent;color:" +
      c.txt +
      ';font-size:14px;cursor:pointer">上一步</button>'
    : "";
  var btnNext = !isLast
    ? '<button onclick="widgetEditNextStep()" style="flex:2;height:44px;border-radius:12px;border:none;background:' +
      c.primary +
      ';color:#fff;font-size:14px;font-weight:600;cursor:pointer">下一步</button>'
    : '<button onclick="widgetEditReset()" style="flex:2;height:44px;border-radius:12px;border:none;background:' +
      c.primary +
      ';color:#fff;font-size:14px;font-weight:600;cursor:pointer">添加到桌面</button>';

  return (
    baseCss(w, h) +
    '<div style="width:' +
    w +
    "px;height:" +
    h +
    'px;position:relative;overflow:hidden">' +
    // 桌面背景
    '<div style="position:absolute;inset:0;background:' +
    deskBg +
    '">' +
    // 卡片预览居中
    '<div style="position:absolute;top:0;left:0;right:0;height:' +
    previewAreaH +
    'px;display:flex;align-items:center;justify-content:center">' +
    renderWidgetPreview(previewMaxW, previewMaxH) +
    "</div>" +
    "</div>" +
    // 半模态遮罩
    '<div style="position:absolute;inset:0;background:rgba(0,0,0,0.4)"></div>' +
    // 半模态面板
    '<div style="position:absolute;left:0;right:0;bottom:0;height:' +
    sheetH +
    "px;background:" +
    c.sheetBg +
    ';border-radius:20px 20px 0 0;display:flex;flex-direction:column;overflow:hidden">' +
    // 拖拽把手
    '<div style="display:flex;justify-content:center;padding:10px 0 6px">' +
    '<div style="width:36px;height:4px;border-radius:2px;background:' +
    c.sheetHandle +
    '"></div>' +
    "</div>" +
    // 标题栏
    '<div style="display:flex;align-items:center;justify-content:space-between;padding:0 16px 12px">' +
    '<div style="font-size:16px;font-weight:600;color:' +
    c.txt +
    '">配置卡片</div>' +
    '<button onclick="widgetEditReset()" style="background:transparent;border:none;color:' +
    c.txt2 +
    ';font-size:14px;cursor:pointer;padding:4px 8px">取消</button>' +
    "</div>" +
    // 内容区（可滚动）
    '<div class="sy" style="flex:1;padding:0 16px;overflow-y:auto;min-height:0">' +
    renderStepIndicator(step) +
    stepContent +
    "</div>" +
    // 底部按钮
    '<div style="padding:12px 16px;padding-bottom:' +
    (h > 700 ? "24px" : "12px") +
    ";display:flex;gap:10px;flex-shrink:0;border-top:1px solid " +
    c.border +
    '">' +
    btnPrev +
    btnNext +
    "</div>" +
    "</div>" +
    "</div>"
  );
}

// ── 方案B：App 内配置页 ───────────────────────────────────────────

function renderSchemeB(w, h) {
  var c = T();
  var sel = widgetEditState.selectedAccounts;
  var accNames = sel
    .map(function (i) {
      return ACCOUNTS[i].name;
    })
    .join("、");
  var gameNames = widgetEditState.selectedGames
    .map(function (g) {
      return GAME_NAMES[g];
    })
    .join("、");

  // 卡片预览（跟随选中尺寸变化）
  var previewMaxW = w - 48;
  var previewMaxH = 180;

  // 设置行
  function settingRow(label, value, onclick) {
    return (
      '<div onclick="' +
      (onclick || "") +
      '" style="display:flex;align-items:center;justify-content:space-between;padding:14px 16px;cursor:' +
      (onclick ? "pointer" : "default") +
      ";border-bottom:1px solid " +
      c.border +
      '">' +
      '<span style="font-size:14px;color:' +
      c.txt +
      '">' +
      label +
      "</span>" +
      '<div style="display:flex;align-items:center;gap:6px">' +
      '<span style="font-size:13px;color:' +
      c.txt2 +
      ';max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;text-align:right">' +
      value +
      "</span>" +
      (onclick
        ? '<span style="color:' + c.txt2 + ';font-size:14px">›</span>'
        : "") +
      "</div>" +
      "</div>"
    );
  }

  // 显示模式选项
  var modes = [
    { value: "single", label: "单游戏" },
    { value: "multi", label: "多游戏" },
  ];
  var modeHtml = '<div style="display:flex;gap:8px">';
  for (var i = 0; i < modes.length; i++) {
    var m = modes[i];
    var isOn = widgetEditState.displayMode === m.value;
    modeHtml +=
      "<button onclick=\"widgetEditSetDisplayMode('" +
      m.value +
      '\')" style="padding:4px 12px;border-radius:8px;border:1px solid ' +
      (isOn ? c.primary : c.border) +
      ";background:" +
      (isOn ? c.priBg : "transparent") +
      ";color:" +
      (isOn ? c.primary : c.txt2) +
      ';font-size:12px;cursor:pointer">' +
      m.label +
      "</button>";
  }
  modeHtml += "</div>";

  return (
    baseCss(w, h) +
    '<div style="width:' +
    w +
    "px;height:" +
    h +
    "px;background:" +
    c.pageBg +
    ';display:flex;flex-direction:column;overflow:hidden">' +
    // 顶部导航栏
    '<div style="height:56px;background:' +
    c.cardBg +
    ";border-bottom:1px solid " +
    c.border +
    ';display:flex;align-items:center;padding:0 16px;flex-shrink:0">' +
    '<button onclick="widgetEditReset()" style="background:transparent;border:none;color:' +
    c.primary +
    ';font-size:14px;cursor:pointer;padding:4px 8px 4px 0;margin-right:4px">‹</button>' +
    '<div style="font-size:16px;font-weight:600;color:' +
    c.txt +
    ';flex:1">Widget 设置</div>' +
    "</div>" +
    // 内容区（可滚动）
    '<div class="sy" style="flex:1;overflow-y:auto">' +
    // 卡片预览区
    '<div style="background:' +
    (G.theme === "dark"
      ? "linear-gradient(135deg,#0a0a18,#0d1020)"
      : "linear-gradient(135deg,#e8eaf6,#e3f2fd)") +
    ';padding:24px;display:flex;justify-content:center;align-items:center;min-height:120px">' +
    renderWidgetPreview(w - 48, 180) +
    "</div>" +
    // 设置列表
    '<div style="padding:16px 16px 8px;font-size:12px;color:' +
    c.txt2 +
    ';letter-spacing:.5px">卡片配置</div>' +
    '<div style="background:' +
    c.cardBg +
    ';border-radius:12px;margin:0 16px;overflow:hidden">' +
    settingRow(
      "卡片尺寸",
      SIZE_LABELS[widgetEditState.selectedSize],
      "widgetEditReset()",
    ) +
    settingRow("显示账号", accNames, "widgetEditReset()") +
    settingRow("显示游戏", gameNames, "widgetEditReset()") +
    '<div style="display:flex;align-items:center;justify-content:space-between;padding:14px 16px">' +
    '<span style="font-size:14px;color:' +
    c.txt +
    '">显示模式</span>' +
    modeHtml +
    "</div>" +
    "</div>" +
    '<div style="height:16px"></div>' +
    "</div>" +
    // 底部按钮
    '<div style="padding:12px 16px;padding-bottom:' +
    (h > 700 ? "24px" : "12px") +
    ";flex-shrink:0;border-top:1px solid " +
    c.border +
    ";background:" +
    c.cardBg +
    '">' +
    '<button style="width:100%;height:48px;border-radius:12px;border:none;background:' +
    c.primary +
    ';color:#fff;font-size:15px;font-weight:600;cursor:pointer">添加到桌面 / 负一屏</button>' +
    "</div>" +
    "</div>"
  );
}

// ── 主渲染函数 ────────────────────────────────────────────────────

function renderWidgetEdit(w, h) {
  if (widgetEditState.scheme === "A") {
    return renderSchemeA(w, h);
  } else {
    return renderSchemeB(w, h);
  }
}

// ── 控制项 ────────────────────────────────────────────────────────

function widgetEditControls() {
  return [
    {
      id: "scheme",
      label: "编辑方案",
      current: function () {
        return widgetEditState.scheme;
      },
      options: [
        { value: "A", label: "方案A 半模态" },
        { value: "B", label: "方案B App内配置页" },
      ],
      onChange: function (v) {
        widgetEditState.scheme = v;
        widgetEditState.step = "size";
      },
    },
  ];
}

/**
 * appearance-settings.js — 外观设置方案对比
 *
 * 对比两种方案：
 *   方案 A：My 页内联 Chip（现状）
 *   方案 B：My 页 SettingRow → 跳转二级页
 *
 * 依赖：device-shell.js、split-layout.js、shared.js
 */

// ── 方案 A：My 页内联 Chip（现状） ──────────────────────────────

/**
 * 渲染方案 A 的 My 页内容（不含外框）。
 * @param {number} w  内容区宽度
 * @param {number} h  内容区高度
 */
function renderMyContentA(w, h) {
  var c = T();
  return (
    baseCss(w, h) +
    apCardCss() +
    '<div style="width:' +
    w +
    "px;height:" +
    h +
    "px;display:flex;flex-direction:column;background:" +
    c.pageBg +
    '">' +
    apNavBar("我的") +
    '<div class="sy" style="flex:1;padding:12px 16px 40px">' +
    apSectionLabel("外观设置") +
    '<div class="ap-card">' +
    '<div class="ap-row">' +
    '<span style="font-size:15px;color:' +
    c.txt +
    ';flex:1;min-width:0;white-space:nowrap">主题</span>' +
    '<div style="display:flex;gap:6px;flex-shrink:0">' +
    '<button class="ap-chip">浅色</button>' +
    '<button class="ap-chip">深色</button>' +
    '<button class="ap-chip ap-chip-on">跟随系统</button>' +
    "</div>" +
    "</div>" +
    "</div>" +
    // 警告提示
    '<div style="margin-top:8px;padding:8px 12px;background:rgba(239,83,80,0.12);border:1px solid rgba(239,83,80,0.3);border-radius:8px;font-size:12px;color:#ef5350;line-height:1.5">' +
    "⚠️ 分栏模式下左侧约 " +
    w +
    'vp，"跟随系统"按钮可能被截断或换行' +
    "</div>" +
    "</div>" +
    apTabBar("my") +
    "</div>"
  );
}

// ── 方案 B：My 页 SettingRow → 二级页 ───────────────────────────

/**
 * 渲染方案 B 的 My 页内容（不含外框）。
 */
function renderMyContentB(w, h) {
  var c = T();
  var selectedLabel = apThemeLabel(G.themeMode || "system");
  return (
    baseCss(w, h) +
    apCardCss() +
    '<div style="width:' +
    w +
    "px;height:" +
    h +
    "px;display:flex;flex-direction:column;background:" +
    c.pageBg +
    '">' +
    apNavBar("我的") +
    '<div class="sy" style="flex:1;padding:12px 16px 40px">' +
    apSectionLabel("外观设置") +
    '<div class="ap-card">' +
    '<div class="ap-row ap-row-tap">' +
    '<span style="font-size:15px;color:' +
    c.txt +
    ';flex:1">主题</span>' +
    '<span style="font-size:14px;color:' +
    c.txt2 +
    ';margin-right:6px">' +
    selectedLabel +
    "</span>" +
    '<span style="color:' +
    c.txt2 +
    ';font-size:16px">›</span>' +
    "</div>" +
    "</div>" +
    '<div style="margin-top:8px;padding:8px 12px;background:rgba(76,175,80,0.12);border:1px solid rgba(76,175,80,0.3);border-radius:8px;font-size:12px;color:#81c784;line-height:1.5">' +
    "✓ 右侧显示当前选中值，点击跳转二级页，任何屏幕宽度下都不拥挤" +
    "</div>" +
    "</div>" +
    apTabBar("my") +
    "</div>"
  );
}

/**
 * 渲染方案 B 的外观设置二级页内容（不含外框）。
 */
function renderAppearanceDetailContent(w, h) {
  var c = T();
  var selectedMode = G.themeMode || "system";
  var modes = [
    { id: "light", label: "浅色", icon: "☀️", desc: "始终使用浅色界面" },
    { id: "dark", label: "深色", icon: "🌙", desc: "始终使用深色界面" },
    {
      id: "system",
      label: "跟随系统",
      icon: "⚙️",
      desc: "跟随系统深色/浅色模式自动切换",
    },
  ];

  var rows = "";
  for (var i = 0; i < modes.length; i++) {
    var m = modes[i];
    var isSelected = m.id === selectedMode;
    rows +=
      '<div class="ap-row ap-row-tap' +
      (isSelected ? " ap-row-selected" : "") +
      '">' +
      '<span style="font-size:20px;flex-shrink:0">' +
      m.icon +
      "</span>" +
      '<div style="flex:1">' +
      '<div style="font-size:15px;color:' +
      c.txt +
      '">' +
      m.label +
      "</div>" +
      '<div style="font-size:12px;color:' +
      c.txt2 +
      ';margin-top:2px">' +
      m.desc +
      "</div>" +
      "</div>" +
      '<div class="ap-check' +
      (isSelected ? " ap-check-on" : "") +
      '">' +
      (isSelected
        ? '<span style="color:#fff;font-size:11px;font-weight:700">✓</span>'
        : "") +
      "</div>" +
      "</div>";
  }

  return (
    baseCss(w, h) +
    apCardCss() +
    '<div style="width:' +
    w +
    "px;height:" +
    h +
    "px;display:flex;flex-direction:column;background:" +
    c.pageBg +
    '">' +
    apNavBar("外观设置", true) +
    '<div class="sy" style="flex:1;padding:16px 20px 40px">' +
    apSectionLabel("主题模式") +
    '<div class="ap-card">' +
    rows +
    "</div>" +
    '<div style="margin-top:12px;padding:0 4px;font-size:12px;color:' +
    c.txt2 +
    ';line-height:1.6">' +
    '选择"跟随系统"时，应用会根据系统设置自动切换深色/浅色模式。' +
    "</div>" +
    "</div>" +
    "</div>"
  );
}

// ── 主渲染函数 ────────────────────────────────────────────────────

function renderAppearanceSettings(w, h) {
  var viewMode = G.apView || "compare";

  // 单页视图：方案B 二级页
  if (viewMode === "detail-b") {
    return renderAppearanceDetailContent(w, h);
  }

  // 单页视图：方案A My页
  if (viewMode === "page-a") {
    return renderMyContentA(w, h);
  }

  // 单页视图：方案B My页
  if (viewMode === "page-b") {
    return renderMyContentB(w, h);
  }

  // 分栏视图：展示方案B 在分栏模式下的效果
  // 直接输出分栏 HTML，不套 renderInShell（#S 容器本身就是外框）
  if (viewMode === "split-b") {
    var leftW = splitLeftWidth(w);
    var rightW = splitRightWidth(w);
    var leftHtml = renderMyContentB(leftW, h);
    var rightHtml = renderAppearanceDetailContent(rightW, h);
    return renderSplitLayout(leftHtml, rightHtml, w, h);
  }

  // 默认：对比视图（左A右B，各占一半，不套外框，直接并排）
  return renderCompareView(w, h);
}

/**
 * 对比视图：左边方案A，右边方案B，各占一半宽度。
 * 不套设备外框，直接并排展示，方便快速对比。
 */
function renderCompareView(w, h) {
  var c = T();
  var halfW = Math.floor(w / 2) - 1;
  var labelH = 32;
  var contentH = h - labelH;

  return (
    "<style>" +
    "*{box-sizing:border-box;margin:0;padding:0}" +
    "body{width:" +
    w +
    "px;height:" +
    h +
    "px;overflow:hidden;background:" +
    c.pageBg +
    ';display:flex;flex-direction:column;font-family:"PingFang SC","Microsoft YaHei",sans-serif}' +
    "</style>" +
    // 顶部标签行
    '<div style="height:' +
    labelH +
    'px;display:flex;flex-shrink:0;border-bottom:1px solid #2a2a3a">' +
    '<div style="flex:1;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;color:#ef5350">方案 A：内联 Chip（现状）</div>' +
    '<div style="width:1px;background:#2a2a3a"></div>' +
    '<div style="flex:1;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;color:#81c784">方案 B：SettingRow → 二级页</div>' +
    "</div>" +
    // 内容区
    '<div style="flex:1;display:flex;overflow:hidden">' +
    '<div style="width:' +
    halfW +
    "px;height:" +
    contentH +
    'px;overflow:hidden;flex-shrink:0">' +
    '<iframe srcdoc="' +
    escHtml(renderMyContentA(halfW, contentH)) +
    '" style="width:' +
    halfW +
    "px;height:" +
    contentH +
    'px;border:none;display:block"></iframe>' +
    "</div>" +
    '<div style="width:1px;background:#2a2a3a;flex-shrink:0"></div>' +
    '<div style="flex:1;height:' +
    contentH +
    'px;overflow:hidden">' +
    '<iframe srcdoc="' +
    escHtml(renderMyContentB(halfW, contentH)) +
    '" style="width:' +
    halfW +
    "px;height:" +
    contentH +
    'px;border:none;display:block"></iframe>' +
    "</div>" +
    "</div>"
  );
}

// ── 共享 UI 片段 ──────────────────────────────────────────────────

/** 卡片 CSS */
function apCardCss() {
  var c = T();
  return (
    "<style>" +
    ".ap-card{background:" +
    c.surfCard +
    ";border:1px solid " +
    c.border +
    ";border-radius:12px;overflow:hidden;box-shadow:0 2px 6px " +
    c.shadow +
    "}" +
    ".ap-row{display:flex;align-items:center;min-height:52px;padding:0 16px;gap:12px;border-bottom:1px solid " +
    c.div +
    "}" +
    ".ap-row:last-child{border-bottom:none}" +
    ".ap-row-tap{cursor:pointer;transition:background 0.15s}" +
    ".ap-row-tap:hover{background:rgba(255,255,255,0.04)}" +
    ".ap-row-selected{background:rgba(58,111,216,0.08)}" +
    ".ap-chip{padding:4px 10px;border-radius:8px;font-size:13px;cursor:pointer;background:" +
    c.div +
    ";color:" +
    c.txt2 +
    ";border:none;font-family:inherit;white-space:nowrap}" +
    ".ap-chip-on{background:" +
    c.primary +
    ";color:#fff}" +
    ".ap-check{width:20px;height:20px;border-radius:50%;border:2px solid " +
    c.border +
    ";display:flex;align-items:center;justify-content:center;flex-shrink:0}" +
    ".ap-check-on{background:" +
    c.primary +
    ";border-color:" +
    c.primary +
    "}" +
    "</style>"
  );
}

/** 顶部导航栏 */
function apNavBar(title, hasBack) {
  var c = T();
  return (
    '<div style="height:56px;display:flex;align-items:center;padding:0 16px;border-bottom:1px solid ' +
    c.div +
    ';flex-shrink:0;gap:10px">' +
    (hasBack
      ? '<span style="font-size:20px;color:' +
        c.txt2 +
        ';cursor:pointer;flex-shrink:0">‹</span>'
      : "") +
    '<span style="font-size:18px;font-weight:700;color:' +
    c.txt +
    '">' +
    title +
    "</span>" +
    "</div>"
  );
}

/** Section 标签 */
function apSectionLabel(text) {
  var c = T();
  return (
    '<div style="font-size:12px;color:' +
    c.txt2 +
    ';padding:0 4px 8px;margin-top:4px">' +
    text +
    "</div>"
  );
}

/** 底部 Tab 栏 */
function apTabBar(active) {
  return tabBar(active);
}

/** 主题模式显示标签 */
function apThemeLabel(mode) {
  if (mode === "light") return "浅色";
  if (mode === "dark") return "深色";
  return "跟随系统";
}

// ── Controls ──────────────────────────────────────────────────────

function appearanceSettingsControls() {
  return [
    {
      id: "apView",
      label: "视图",
      type: "select",
      current: function () {
        return G.apView || "compare";
      },
      onChange: function (v) {
        G.apView = v;
        // 分栏视图需要宽屏设备，自动切换到 Foldable（932×600）
        // 单页视图切回 Phone 竖屏（360×780）
        if (v === "split-b") {
          if (G.dev === "pp" || G.dev === "pl") setDev("fd");
        } else if (
          v === "compare" ||
          v === "page-a" ||
          v === "page-b" ||
          v === "detail-b"
        ) {
          if (
            G.dev === "fd" ||
            G.dev === "tf" ||
            G.dev === "tb" ||
            G.dev === "pc"
          )
            setDev("pp");
        }
      },
      options: [
        { value: "compare", label: "方案对比（并排）" },
        { value: "page-a", label: "方案A：My页（带外框）" },
        { value: "page-b", label: "方案B：My页（带外框）" },
        { value: "detail-b", label: "方案B：外观设置二级页" },
        { value: "split-b", label: "方案B：分栏模式" },
      ],
    },
    {
      id: "themeMode",
      label: "当前主题",
      type: "select",
      current: function () {
        return G.themeMode || "system";
      },
      onChange: function (v) {
        G.themeMode = v;
      },
      options: [
        { value: "light", label: "浅色" },
        { value: "dark", label: "深色" },
        { value: "system", label: "跟随系统" },
      ],
    },
  ];
}

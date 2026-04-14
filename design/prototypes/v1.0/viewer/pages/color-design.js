/**
 * color-design.js — 色彩设计系统展示页
 */

function renderColorDesign(w, h) {
  var c = T();
  var isDark = G.theme === "dark";
  var rowBg = isDark ? "rgba(255,255,255,0.03)" : "rgba(0,0,0,0.03)";
  var divBorder = isDark ? "rgba(255,255,255,0.08)" : "#E8E8E8";

  function swatch(color, size) {
    size = size || 36;
    return (
      '<div style="width:' +
      size +
      "px;height:" +
      size +
      "px;border-radius:6px;background:" +
      color +
      ';border:1px solid rgba(128,128,128,0.15);flex-shrink:0"></div>'
    );
  }

  function row(name, light, dark, desc) {
    var val = isDark ? dark : light;
    return (
      '<div style="display:flex;align-items:center;gap:10px;padding:7px 10px;border-radius:7px;background:' +
      rowBg +
      '">' +
      swatch(val) +
      '<div style="flex:1;min-width:0">' +
      '<div style="font-size:11px;font-family:monospace;color:' +
      c.txt +
      '">' +
      name +
      "</div>" +
      '<div style="font-size:10px;color:' +
      c.txt2 +
      ';margin-top:1px">' +
      desc +
      "</div>" +
      '<div style="font-size:10px;font-family:monospace;color:' +
      c.txt2 +
      ';margin-top:2px;opacity:0.75">' +
      val +
      "</div>" +
      "</div>" +
      '<div style="display:flex;gap:4px;align-items:flex-start;flex-shrink:0">' +
      '<div style="text-align:center"><div style="width:20px;height:20px;border-radius:4px;background:' +
      light +
      ';border:1px solid rgba(128,128,128,0.2)"></div><div style="font-size:8px;color:' +
      c.txt2 +
      ';margin-top:1px">L</div></div>' +
      '<div style="text-align:center"><div style="width:20px;height:20px;border-radius:4px;background:' +
      dark +
      ';border:1px solid rgba(128,128,128,0.2)"></div><div style="font-size:8px;color:' +
      c.txt2 +
      ';margin-top:1px">D</div></div>' +
      "</div>" +
      "</div>"
    );
  }

  function fixedRow(name, val, desc) {
    return (
      '<div style="display:flex;align-items:center;gap:10px;padding:7px 10px;border-radius:7px;background:' +
      rowBg +
      '">' +
      swatch(val) +
      '<div style="flex:1;min-width:0">' +
      '<div style="font-size:11px;font-family:monospace;color:' +
      c.txt +
      '">' +
      name +
      "</div>" +
      '<div style="font-size:10px;color:' +
      c.txt2 +
      ';margin-top:1px">' +
      desc +
      "</div>" +
      '<div style="font-size:10px;font-family:monospace;color:' +
      c.txt2 +
      ';margin-top:2px;opacity:0.75">' +
      val +
      "</div>" +
      "</div>" +
      "</div>"
    );
  }

  function section(title) {
    return (
      '<div style="font-size:11px;font-weight:600;color:' +
      c.txt2 +
      ";letter-spacing:1px;text-transform:uppercase;margin:18px 0 8px;padding-bottom:5px;border-bottom:1px solid " +
      divBorder +
      '">' +
      title +
      "</div>"
    );
  }

  function elementCircles(items) {
    var h = '<div style="display:flex;flex-wrap:wrap;gap:8px">';
    for (var i = 0; i < items.length; i++) {
      var el = items[i];
      h +=
        '<div style="display:flex;flex-direction:column;align-items:center;gap:3px">' +
        '<div style="width:44px;height:44px;border-radius:50%;background:' +
        el.val +
        ";box-shadow:0 2px 8px " +
        el.val +
        '55"></div>' +
        '<div style="font-size:10px;color:' +
        c.txt +
        ';text-align:center">' +
        el.label +
        "</div>" +
        '<div style="font-size:9px;color:' +
        c.txt2 +
        ';font-family:monospace">' +
        el.val +
        "</div>" +
        "</div>";
    }
    return h + "</div>";
  }

  function gradientCards(items) {
    var h =
      '<div style="display:grid;grid-template-columns:repeat(2,1fr);gap:6px">';
    for (var i = 0; i < items.length; i++) {
      var eb = items[i];
      h +=
        '<div style="border-radius:8px;overflow:hidden;background:linear-gradient(135deg,' +
        eb.c1 +
        "," +
        eb.c2 +
        "," +
        eb.c3 +
        ');padding:8px 10px">' +
        '<div style="font-size:11px;color:rgba(255,255,255,0.9);font-weight:600;margin-bottom:4px">' +
        eb.label +
        "</div>" +
        '<div style="font-size:9px;color:rgba(255,255,255,0.5);font-family:monospace;line-height:1.6">' +
        eb.c1 +
        "<br>" +
        eb.c2 +
        "<br>" +
        eb.c3 +
        "</div>" +
        "</div>";
    }
    return h + "</div>";
  }

  var html = baseCss(w, h);
  html +=
    '<div style="width:' +
    w +
    "px;height:" +
    h +
    "px;overflow-y:auto;background:" +
    c.pageBg +
    ';scrollbar-width:thin;scrollbar-color:rgba(128,128,128,0.3) transparent">';
  html += '<div style="padding:16px">';
  html +=
    '<div style="font-size:17px;font-weight:700;color:' +
    c.txt +
    ';margin-bottom:2px">Color Design System</div>';
  html +=
    '<div style="font-size:11px;color:' +
    c.txt2 +
    ';margin-bottom:4px">v1.0 · 当前：' +
    (isDark ? "Dark" : "Light") +
    " 模式</div>";

  // ── 1. 基础语义色
  html += section("基础语义色");
  html += '<div style="display:flex;flex-direction:column;gap:4px">';
  html += row(
    "color_primary",
    "#007DFF",
    "#4DA3FF",
    "主色（米游蓝），按钮/选中态",
  );
  html += row(
    "color_primary_bg",
    "#1A007DFF",
    "#1A4DA3FF",
    "主色背景（轻量高亮）",
  );
  html += row("color_danger", "#E8534A", "#FF6B6B", "危险/错误/低值");
  html += row("color_danger_bg", "#1AE8534A", "#1AFF6B6B", "危险背景");
  html += row("color_warning", "#F0A030", "#F5B942", "警告/中低值");
  html += "</div>";

  // ── 2. 文字色
  html += section("文字色");
  html += '<div style="display:flex;flex-direction:column;gap:4px">';
  html += row("color_text_primary", "#333333", "#E0E0E0", "主文字");
  html += row("color_text_secondary", "#666666", "#999999", "次要文字");
  html += row("color_placeholder", "#999999", "#555555", "占位符文字");
  html += "</div>";

  // ── 3. 背景 / 容器色
  html += section("背景 / 容器色");
  html += '<div style="display:flex;flex-direction:column;gap:4px">';
  html += row(
    "color_page_bg",
    "#F2F2F7",
    "#000000",
    "页面背景 / 卡片背景（合并）",
  );
  html += row("color_surface_card", "#FFFFFF", "#1C1C1C", "卡片表面（次层）");
  html += row(
    "color_divider",
    "#EEEEEE",
    "#2A2A2A",
    "分割线 / 卡片边框（合并）",
  );
  html += row("color_skeleton_bg", "#E0E0E0", "#2E2E2E", "骨架屏占位色");
  html += "</div>";

  // ── 4. 游戏品牌色
  html += section("游戏品牌色");
  html += '<div style="display:flex;flex-direction:column;gap:4px">';
  html += row("game_color_genshin", "#4A90D9", "#5BA3E8", "原神");
  html += row("game_color_starrail", "#7B68EE", "#9B8EFF", "崩坏：星穹铁道");
  html += row("game_color_zzz", "#F5A623", "#F7B84B", "绝区零");
  html += row("game_color_honkai3", "#E8534A", "#FF6B6B", "崩坏3");
  html += "</div>";

  // ── 5. 元素力颜色（跨游戏通用）
  html += section("元素力颜色（跨游戏通用，固定不变）");
  html +=
    '<div style="font-size:10px;color:' +
    c.txt2 +
    ';margin-bottom:8px">相同元素跨游戏共用同一 token。星铁火=原神Pyro，星铁冰=原神Cryo，星铁雷=原神Electro，绝区零同理。</div>';
  html += elementCircles([
    { val: "#EF7A35", label: "火/Pyro" },
    { val: "#4BC3F1", label: "水/Hydro" },
    { val: "#74C2A8", label: "风/Anemo" },
    { val: "#B08FC2", label: "雷/电/Electro" },
    { val: "#A5C83B", label: "草/Dendro" },
    { val: "#98D5E4", label: "冰/Cryo" },
    { val: "#CFA726", label: "岩/Geo" },
    { val: "#9E9E9E", label: "物理/Physical" },
    { val: "#7C4DFF", label: "量子/Quantum" },
    { val: "#FFD54F", label: "虚数/Imaginary" },
    { val: "#E040FB", label: "以太/Ether" },
  ]);

  // ── 6. 稀有度色
  html += section("稀有度色");
  html += '<div style="display:flex;flex-direction:column;gap:4px">';
  html += fixedRow("rarity_5star", "#C8922A", "5星文字色");
  html += fixedRow("rarity_5star_bg", "#6B4C1E", "5星背景色（深金棕）");
  html += fixedRow("rarity_4star_bg", "#4A3060", "4星背景色（深紫）");
  html += "</div>";

  // ── 7. Surface 透明叠加色（合并后）
  html += section("Surface 透明叠加色（暗色系专用）");
  var surfaces = [
    {
      name: "surface_glass",
      val: "#12FFFFFF",
      label: "白色透明叠加（卡片背景/图标背景/分割线）",
    },
    { name: "surface_dark_sm", val: "#1A000000", label: "弱黑叠加" },
    {
      name: "surface_dark_md",
      val: "#40000000",
      label: "中黑叠加（属性网格/命座未激活）",
    },
    {
      name: "surface_dark_lg",
      val: "#80000000",
      label: "强黑叠加（属性面板/技能背景）",
    },
    {
      name: "surface_active_primary",
      val: "#404FC3F7",
      label: "主色激活态（命座激活）",
    },
    { name: "surface_active_border", val: "#CC4FC3F7", label: "主色激活描边" },
    { name: "surface_inactive_border", val: "#33FFFFFF", label: "未激活描边" },
    {
      name: "surface_skill_border_phone",
      val: "#594FC3F7",
      label: "技能边框（Phone）",
    },
    { name: "surface_fetter_bg", val: "#1F4FC3F7", label: "好感度标签背景" },
    {
      name: "surface_fetter_border",
      val: "#334FC3F7",
      label: "好感度标签边框",
    },
  ];
  html += '<div style="display:flex;flex-direction:column;gap:4px">';
  for (var si = 0; si < surfaces.length; si++) {
    html += fixedRow(surfaces[si].name, surfaces[si].val, surfaces[si].label);
  }
  html += "</div>";

  // ── 8. 原神角色详情背景渐变
  html += section("原神角色详情背景渐变（三档 linearGradient）");
  html += gradientCards([
    { label: "水 Hydro", c1: "#0A2A4A", c2: "#0D1E3A", c3: "#081428" },
    { label: "火 Pyro", c1: "#3A1008", c2: "#2A0E0A", c3: "#180808" },
    { label: "雷 Electro", c1: "#2A1040", c2: "#1E0A30", c3: "#100818" },
    { label: "风 Anemo", c1: "#083A2A", c2: "#062A1E", c3: "#041810" },
    { label: "岩 Geo", c1: "#2A1E04", c2: "#1E1604", c3: "#100E02" },
    { label: "冰 Cryo", c1: "#0A1E3A", c2: "#081628", c3: "#040E18" },
    { label: "草 Dendro", c1: "#0A2A08", c2: "#081E06", c3: "#040E02" },
  ]);

  // ── 9. 星铁角色详情背景渐变
  html += section("星铁角色详情背景渐变（共用原神渐变 + 新增）");
  html += gradientCards([
    { label: "物理 Physical", c1: "#1A1A1A", c2: "#111111", c3: "#080808" },
    { label: "火 Fire（同Pyro）", c1: "#3A1008", c2: "#2A0E0A", c3: "#180808" },
    { label: "冰 Ice（同Cryo）", c1: "#0A1E3A", c2: "#081628", c3: "#040E18" },
    {
      label: "雷 Lightning（同Electro）",
      c1: "#2A1040",
      c2: "#1E0A30",
      c3: "#100818",
    },
    {
      label: "风 Wind（同Anemo）",
      c1: "#083A2A",
      c2: "#062A1E",
      c3: "#041810",
    },
    { label: "量子 Quantum", c1: "#1A0A40", c2: "#120830", c3: "#080418" },
    { label: "虚数 Imaginary", c1: "#2A2004", c2: "#1E1804", c3: "#100E02" },
  ]);

  // ── 10. 绝区零角色详情背景渐变
  html += section("绝区零角色详情背景渐变（共用原神渐变 + 新增）");
  html += gradientCards([
    { label: "物理 Physical", c1: "#1A1A1A", c2: "#111111", c3: "#080808" },
    { label: "火 Fire（同Pyro）", c1: "#3A1008", c2: "#2A0E0A", c3: "#180808" },
    { label: "冰 Ice（同Cryo）", c1: "#0A1E3A", c2: "#081628", c3: "#040E18" },
    {
      label: "电 Electric（同Electro）",
      c1: "#2A1040",
      c2: "#1E0A30",
      c3: "#100818",
    },
    { label: "以太 Ether", c1: "#2A0A30", c2: "#1E0820", c3: "#100410" },
  ]);

  html += '<div style="height:24px"></div>';
  html += "</div></div>";
  return html;
}

function colorDesignControls() {
  return [];
}

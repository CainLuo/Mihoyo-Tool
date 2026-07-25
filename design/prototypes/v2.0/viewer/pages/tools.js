/**
 * tools.js — 工具页原型
 *
 * 底部导航新增「工具」Tab，包含 3 个游戏的材料总汇入口
 * 处理空态和无数据场景
 */

var toolsState = {
  view: "normal",      // normal | empty_account | empty_data
  accountCount: 1,
  // 各游戏数据状态
  genshin: { count: 12, computed: 8, hasData: true },
  starrail: { count: 15, computed: 12, hasData: true },
  zzz: { count: 0, computed: 0, hasData: false },  // 无角色数据
};

/**
 * 渲染工具页
 */
function renderTools(w, h) {
  var c = T();
  var isPhone = w < 600;

  // ── 空态：无账号 ───────────────────────────────────────────────────
  if (toolsState.accountCount === 0 || toolsState.view === "empty_account") {
    return baseCss(w, h) + renderEmptyAccount(w, h, c);
  }

  // ── 正常状态：有账号 ───────────────────────────────────────────────
  return baseCss(w, h) + renderNormal(w, h, c, isPhone);
}

/**
 * 空态：无账号
 */
function renderEmptyAccount(w, h, c) {
  return "<div style=\"width:" + w + "px;height:" + h + "px;display:flex;flex-direction:column;background:" + c.pageBg + "\">" +
    // 标题栏
    "<div style=\"padding:12px 16px;border-bottom:1px solid " + c.div + ";flex-shrink:0;background:" + c.cardBg + "\">" +
    "<div style=\"font-size:17px;font-weight:600;color:" + c.txt + "\">工具</div>" +
    "</div>" +
    // 空态内容
    "<div style=\"flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:32px\">" +
    "<div style=\"font-size:48px;margin-bottom:16px\">👤</div>" +
    "<div style=\"font-size:15px;font-weight:600;color:" + c.txt + ";margin-bottom:8px\">请先添加账号</div>" +
    "<div style=\"font-size:13px;color:" + c.txt2 + ";margin-bottom:24px;text-align:center\">登录米游社账号后，即可使用工具功能</div>" +
    "<div onclick=\"alert('跳转到登录页')\" style=\"padding:10px 24px;background:" + c.primary + ";border-radius:8px;font-size:14px;font-weight:600;color:#fff;cursor:pointer\">去登录</div>" +
    "</div>" +
    // 底部 Tab 栏
    renderTabBar(c, "tools") +
    "</div>";
}

/**
 * 正常状态：游戏入口卡片列表
 */
function renderNormal(w, h, c, isPhone) {
  var games = [
    { 
      id: "genshin", 
      name: "原神材料总汇", 
      icon: "🎮", 
      color: "#4A90D9",
      data: toolsState.genshin 
    },
    { 
      id: "starrail", 
      name: "崩坏：星穹铁道材料总汇", 
      icon: "🚂", 
      color: "#7B68EE",
      data: toolsState.starrail 
    },
    { 
      id: "zzz", 
      name: "绝区零材料总汇", 
      icon: "🌆", 
      color: "#F5A623",
      data: toolsState.zzz 
    },
  ];

  var cards = "";
  for (var i = 0; i < games.length; i++) {
    cards += renderGameCard(games[i], c);
  }

  return "<div style=\"width:" + w + "px;height:" + h + "px;display:flex;flex-direction:column;background:" + c.pageBg + "\">" +
    // 标题栏
    "<div style=\"padding:12px 16px;border-bottom:1px solid " + c.div + ";flex-shrink:0;background:" + c.cardBg + "\">" +
    "<div style=\"font-size:17px;font-weight:600;color:" + c.txt + "\">工具</div>" +
    "</div>" +
    // 内容区
    "<div class=\"sy\" style=\"flex:1;padding:12px 16px;display:flex;flex-direction:column;gap:12px\">" +
    cards +
    "</div>" +
    // 底部 Tab 栏
    renderTabBar(c, "tools") +
    "</div>";
}

/**
 * 游戏入口卡片
 */
function renderGameCard(game, c) {
  var hasData = game.data.hasData;
  var count = game.data.count;
  var computed = game.data.computed;
  
  // 无数据时置灰
  var opacity = hasData ? "1" : "0.5";
  var cursor = hasData ? "pointer" : "default";
  var action = hasData ? "alert('跳转到 " + game.name + "')" : "alert('暂无" + game.name.replace('材料总汇', '') + "角色数据')";

  // 状态文字
  var statusText = "";
  if (!hasData) {
    statusText = "暂无角色数据";
  } else if (computed === 0) {
    statusText = count + " 个角色 · 未计算";
  } else if (computed < count) {
    statusText = count + " 个角色 · 已计算 " + computed + " 个";
  } else {
    statusText = count + " 个角色 · 已全部计算";
  }

  return "<div onclick=\"" + action + "\" style=\"background:" + c.surfCard + ";border:1px solid " + c.border + ";border-radius:12px;padding:16px;display:flex;align-items:center;gap:12px;cursor:" + cursor + ";opacity:" + opacity + ";transition:opacity .15s\" onmouseover=\"" + (hasData ? "this.style.background='" + c.primary + "08'" : "") + "\" onmouseout=\"this.style.background='" + c.surfCard + "'\">" +
    // 图标
    "<div style=\"width:48px;height:48px;border-radius:12px;background:" + game.color + "22;display:flex;align-items:center;justify-content:center;font-size:24px;flex-shrink:0\">" + game.icon + "</div>" +
    // 内容
    "<div style=\"flex:1;min-width:0\">" +
    "<div style=\"font-size:15px;font-weight:600;color:" + c.txt + ";margin-bottom:4px\">" + game.name + "</div>" +
    "<div style=\"font-size:12px;color:" + c.txt2 + "\">" + statusText + "</div>" +
    "</div>" +
    // 箭头（有数据时显示）
    (hasData ? "<div style=\"font-size:16px;color:" + c.txt2 + "\">›</div>" : "") +
    "</div>";
}

/**
 * 底部 Tab 栏
 */
function renderTabBar(c, active) {
  var items = [
    { id: "home", icon: "🏠", label: "首页" },
    { id: "characters", icon: "👥", label: "角色" },
    { id: "tools", icon: "🔧", label: "工具" },
    { id: "my", icon: "👤", label: "我的" },
  ];
  var html = "<div style=\"display:flex;justify-content:space-around;padding:8px 0;background:" + c.cardBg + ";border-top:1px solid " + c.div + ";flex-shrink:0\">";
  for (var i = 0; i < items.length; i++) {
    var it = items[i];
    var isActive = active === it.id;
    html += "<div style=\"display:flex;flex-direction:column;align-items:center;gap:2px;cursor:pointer;opacity:" + (isActive ? "1" : "0.55") + "\">" +
      "<span style=\"font-size:20px\">" + it.icon + "</span>" +
      "<span style=\"font-size:10px;color:" + (isActive ? c.primary : c.txt2) + "\">" + it.label + "</span>" +
      "</div>";
  }
  html += "</div>";
  return html;
}

function baseCss(w, h) {
  return "<style>.sy{overflow-y:auto;scrollbar-width:thin;scrollbar-color:rgba(255,255,255,.15) transparent}</style>";
}

/**
 * 控制项
 */
function toolsControls() {
  return [
    {
      id: "view",
      label: "显示状态",
      current: function () { return toolsState.view; },
      onChange: function (v) { toolsState.view = v; },
      options: [
        { value: "normal", label: "正常" },
        { value: "empty_account", label: "无账号" },
      ],
    },
    {
      id: "zzz_hasData",
      label: "绝区零数据",
      current: function () { return toolsState.zzz.hasData ? "yes" : "no"; },
      onChange: function (v) { 
        toolsState.zzz.hasData = v === "yes";
        if (v === "yes") {
          toolsState.zzz.count = 8;
          toolsState.zzz.computed = 5;
        } else {
          toolsState.zzz.count = 0;
          toolsState.zzz.computed = 0;
        }
      },
      options: [
        { value: "yes", label: "有数据" },
        { value: "no", label: "无数据" },
      ],
    },
  ];
}

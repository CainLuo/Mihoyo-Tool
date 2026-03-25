/**
 * my.js — 我的页渲染逻辑
 */

function renderMy(w, h) {
  var c = T();
  var maxW = Math.min(600, w - 40);

  var cardCss =
    "<style>" +
    ".mycard{background:" +
    c.surfCard +
    ";border:1px solid " +
    c.border +
    ";border-radius:12px;overflow:hidden;box-shadow:0 2px 6px " +
    c.shadow +
    ";margin-bottom:4px}" +
    ".myrow{display:flex;align-items:center;min-height:50px;padding:0 16px;gap:12px;border-bottom:1px solid " +
    c.div +
    "}" +
    ".myrow:last-child{border-bottom:none}" +
    ".chip{padding:4px 10px;border-radius:8px;font-size:13px;cursor:pointer;background:" +
    (G.theme === "dark" ? "#2C2C2E" : "#E5E5EA") +
    ";color:" +
    c.txt2 +
    ";border:none;font-family:inherit}" +
    ".chip.on{background:" +
    c.primary +
    ";color:#fff}" +
    "</style>";

  var content =
    '<div class="sy" style="flex:1;padding:12px 20px 40px">' +
    '<div style="max-width:' +
    maxW +
    'px;margin:0 auto">' +
    // 账号管理
    '<div style="font-size:12px;color:' +
    c.txt2 +
    ';padding:0 4px 6px;margin-top:4px">账号管理</div>' +
    '<div class="mycard">' +
    '<div class="myrow"><div style="width:36px;height:36px;border-radius:18px;background:' +
    c.primary +
    ';flex-shrink:0"></div>' +
    '<div style="flex:1"><div style="font-size:15px;color:' +
    c.txt +
    '">182692936</div>' +
    '<div style="font-size:12px;color:' +
    c.txt2 +
    ';margin-top:2px">2 个游戏角色</div></div>' +
    '<span style="color:' +
    c.txt2 +
    ';font-size:14px">›</span></div>' +
    "</div>" +
    '<div style="display:flex;align-items:center;justify-content:center;height:50px;font-size:15px;color:' +
    c.primary +
    ";background:" +
    c.surfCard +
    ";border:1px solid " +
    c.border +
    ";border-radius:12px;cursor:pointer;margin-top:4px;box-shadow:0 2px 6px " +
    c.shadow +
    '">+ 添加账号</div>' +
    // 外观设置
    '<div style="font-size:12px;color:' +
    c.txt2 +
    ';padding:0 4px 6px;margin-top:16px">外观设置</div>' +
    '<div class="mycard">' +
    '<div class="myrow"><span style="font-size:15px;color:' +
    c.txt +
    ';flex:1">主题</span>' +
    '<div style="display:flex;gap:6px">' +
    '<button class="chip">浅色</button>' +
    '<button class="chip">深色</button>' +
    '<button class="chip on">跟随系统</button>' +
    "</div></div>" +
    "</div>" +
    // 关于
    '<div style="font-size:12px;color:' +
    c.txt2 +
    ';padding:0 4px 6px;margin-top:16px">关于</div>' +
    '<div class="mycard">' +
    '<div class="myrow"><span style="font-size:15px;color:' +
    c.txt +
    ';flex:1">版本</span><span style="font-size:15px;color:' +
    c.txt2 +
    '">1.0.0</span></div>' +
    '<div class="myrow"><span style="font-size:15px;color:' +
    c.txt +
    ';flex:1">GitHub</span><span style="font-size:12px;color:' +
    c.primary +
    '">github.com/cainluo/Mihoyo-Tool</span></div>' +
    '<div class="myrow"><span style="font-size:15px;color:' +
    c.txt +
    ';flex:1">许可证</span><span style="font-size:15px;color:' +
    c.txt2 +
    '">MIT License</span></div>' +
    "</div>" +
    "</div></div>";

  return (
    baseCss(w, h) +
    cardCss +
    '<div style="width:' +
    w +
    "px;height:" +
    h +
    "px;display:flex;flex-direction:column;background:" +
    c.pageBg +
    '">' +
    content +
    tabBar("my") +
    "</div>"
  );
}

function myControls() {
  return [];
}

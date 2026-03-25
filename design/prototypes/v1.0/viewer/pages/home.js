/**
 * home.js — 首页渲染逻辑
 * 状态：data / empty / loading
 */
var homeState = { view: "data" };

function renderHome(w, h) {
  var c = T();
  var cols = w < 600 ? 1 : w < 840 ? 2 : w < 1200 ? 3 : 4;
  var gridCols = "repeat(" + cols + ",1fr)";

  var cardCss =
    "<style>" +
    ".hcard{background:" +
    c.surfCard +
    ";border:1px solid " +
    c.border +
    ";border-radius:16px;overflow:hidden;box-shadow:0 2px 8px " +
    c.shadow +
    "}" +
    ".hch{display:flex;align-items:center;gap:8px;padding:10px 12px 8px}" +
    ".hcb{width:4px;height:36px;border-radius:2px;flex-shrink:0}" +
    ".hci{display:flex;flex-direction:column;gap:2px;flex:1}" +
    ".hcdiv{height:1px;background:" +
    c.div +
    ";margin:0 12px}" +
    ".hcb2{padding:10px 12px 12px}" +
    ".sk{background:" +
    c.border +
    ";border-radius:6px;animation:sk 1.5s ease-in-out infinite}" +
    "@keyframes sk{0%,100%{opacity:.4}50%{opacity:.9}}" +
    "</style>";

  function gameCard(
    gameColor,
    gameName,
    nick,
    server,
    cur,
    max,
    label,
    sec,
    secVal,
    isFull,
  ) {
    var color = isFull ? c.danger : gameColor;
    var ratio = Math.min(cur / max, 1);
    return (
      '<div class="hcard">' +
      '<div class="hch"><div class="hcb" style="background:' +
      gameColor +
      '"></div>' +
      '<div class="hci"><div style="font-size:15px;font-weight:500;color:' +
      c.txt +
      '">' +
      gameName +
      "</div>" +
      '<div style="font-size:12px;color:' +
      c.txt2 +
      '">' +
      nick +
      " · " +
      server +
      "</div></div>" +
      '<span style="font-size:11px;color:' +
      c.txt2 +
      '">刚刚</span></div>' +
      '<div class="hcdiv"></div>' +
      '<div class="hcb2"><div style="display:flex;align-items:center;gap:8px">' +
      '<div style="flex:1"><div style="font-size:12px;color:' +
      c.txt2 +
      ';margin-bottom:4px">' +
      label +
      "</div>" +
      '<div style="display:flex;align-items:baseline;gap:4px"><span style="font-size:22px;font-weight:700;color:' +
      color +
      '">' +
      cur +
      '</span><span style="font-size:14px;color:' +
      c.txt2 +
      '">/' +
      max +
      "</span></div>" +
      '<div style="font-size:12px;color:' +
      (isFull ? c.danger : c.txt2) +
      ';margin-top:2px">' +
      (isFull ? "已全部恢复" : "将于4小时后恢复") +
      "</div></div>" +
      '<div style="width:52px;height:52px;flex-shrink:0">' +
      ringProgress(ratio, color, 52) +
      "</div></div>" +
      '<div style="display:flex;justify-content:space-between;font-size:12px;margin-top:6px"><span style="color:' +
      c.txt2 +
      '">' +
      sec +
      '</span><span style="color:' +
      c.txt +
      '">' +
      secVal +
      "</span></div>" +
      "</div></div>"
    );
  }

  function skCard() {
    return (
      '<div class="hcard" style="padding:12px">' +
      '<div style="display:flex;gap:8px;align-items:center;margin-bottom:10px">' +
      '<div class="sk" style="width:4px;height:36px;border-radius:2px"></div>' +
      '<div style="flex:1"><div class="sk" style="height:14px;width:60%;margin-bottom:6px"></div>' +
      '<div class="sk" style="height:11px;width:40%"></div></div></div>' +
      '<div style="height:1px;background:' +
      c.div +
      ';margin-bottom:10px"></div>' +
      '<div style="display:flex;gap:8px;align-items:center">' +
      '<div style="flex:1"><div class="sk" style="height:11px;width:30%;margin-bottom:6px"></div>' +
      '<div class="sk" style="height:22px;width:50%;margin-bottom:4px"></div>' +
      '<div class="sk" style="height:11px;width:60%"></div></div>' +
      '<div class="sk" style="width:52px;height:52px;border-radius:50%"></div></div></div>'
    );
  }

  var content = "";
  if (homeState.view === "loading") {
    var sks = "";
    for (var i = 0; i < cols * 2; i++) sks += skCard();
    content =
      '<div style="padding:8px 16px 40px">' +
      '<div style="display:flex;align-items:center;gap:8px;padding:8px 0 12px">' +
      '<div class="sk" style="width:28px;height:28px;border-radius:14px"></div>' +
      '<div class="sk" style="height:14px;width:100px"></div></div>' +
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
    var c1 = gameCard(
      c.genshin,
      "原神",
      "旅行者",
      "天空岛",
      140,
      200,
      "树脂",
      "每日委托",
      "4/4 已领取",
      false,
    );
    var c2 = gameCard(
      c.starrail,
      "崩坏：星穹铁道",
      "开拓者",
      "星穹列车",
      200,
      240,
      "开拓力",
      "实训",
      "500/500",
      true,
    );
    content =
      '<div class="sy" style="flex:1;padding:8px 16px 40px">' +
      '<div style="display:flex;align-items:center;gap:8px;padding:8px 0 12px">' +
      '<div style="width:28px;height:28px;border-radius:14px;background:' +
      c.primary +
      ';flex-shrink:0"></div>' +
      '<span style="font-size:15px;font-weight:500;color:' +
      c.txt +
      ';flex:1">182692936</span>' +
      '<span style="font-size:12px;color:' +
      c.txt2 +
      '">2 个游戏</span></div>' +
      '<div style="display:grid;grid-template-columns:' +
      gridCols +
      ';gap:12px">' +
      c1 +
      c2 +
      "</div>" +
      "</div>";
  }

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
    (homeState.view === "loading"
      ? '<div class="sy" style="flex:1">' + content + "</div>"
      : content) +
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

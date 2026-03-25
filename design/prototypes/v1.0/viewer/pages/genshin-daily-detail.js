/**
 * genshin-daily-detail.js — 原神便笺详情页渲染逻辑
 */
var dailyState = { view: "normal" };

function renderGenshinDailyDetail(w, h) {
  var c = T();
  var isFull = dailyState.view === "full";
  var resin = isFull ? 200 : 140;
  var resinColor = isFull ? c.danger : resin >= 160 ? c.warning : c.primary;
  var maxW = Math.min(600, w - 32);

  var cardCss =
    "<style>" +
    ".dncard{background:" +
    c.surfCard +
    ";border:1px solid " +
    c.border +
    ";border-radius:12px;padding:14px 16px;margin-bottom:8px;box-shadow:0 2px 6px " +
    c.shadow +
    "}" +
    ".sk{background:" +
    c.border +
    ";border-radius:6px;animation:sk 1.5s ease-in-out infinite}" +
    "@keyframes sk{0%,100%{opacity:.4}50%{opacity:.9}}" +
    "</style>";

  function noteCard(title, sub, val, valColor) {
    return (
      '<div class="dncard">' +
      '<div style="display:flex;align-items:center;justify-content:space-between">' +
      '<div><div style="font-size:14px;font-weight:600;color:' +
      c.txt +
      '">' +
      title +
      "</div>" +
      (sub
        ? '<div style="font-size:12px;color:' +
          c.txt2 +
          ';margin-top:3px">' +
          sub +
          "</div>"
        : "") +
      "</div>" +
      (val
        ? '<div style="font-size:16px;font-weight:700;color:' +
          valColor +
          '">' +
          val +
          "</div>"
        : "") +
      "</div></div>"
    );
  }

  function taskCard() {
    var dots = "";
    for (var i = 0; i < 4; i++) {
      var on = i < 4;
      dots +=
        '<div style="width:20px;height:20px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:700;background:' +
        (on ? c.primary : "transparent") +
        ";border:1.5px solid " +
        (on ? c.primary : c.border) +
        ";color:" +
        (on ? "#fff" : c.txt2) +
        '">' +
        (on ? "✓" : "◇") +
        "</div>";
    }
    return (
      '<div class="dncard">' +
      '<div style="font-size:14px;font-weight:600;color:' +
      c.txt +
      ';margin-bottom:8px">每日委托</div>' +
      '<div style="display:flex;align-items:center;gap:8px"><span style="font-size:12px;color:' +
      c.txt2 +
      '">委托</span><div style="display:flex;gap:6px">' +
      dots +
      '</div><span style="font-size:12px;color:' +
      c.primary +
      ';margin-left:auto">已领取奖励</span></div>' +
      '<div style="display:flex;align-items:center;gap:8px;margin-top:6px"><span style="font-size:12px;color:' +
      c.txt2 +
      '">冒险</span><div style="display:flex;gap:6px">' +
      dots +
      "</div></div>" +
      '<div style="font-size:12px;color:' +
      c.txt2 +
      ';margin-top:6px">储存的冒险 ×2</div>' +
      "</div>"
    );
  }

  function expCard() {
    var exps = [
      { done: false, time: "8小时14分钟" },
      { done: true, time: "" },
      { done: false, time: "2小时30分钟" },
    ];
    var rows = "";
    for (var i = 0; i < exps.length; i++) {
      rows +=
        '<div style="display:flex;align-items:center;gap:10px;padding:8px 0;border-bottom:1px solid ' +
        c.div +
        '">' +
        '<div style="width:40px;height:40px;border-radius:50%;background:' +
        c.border +
        ';flex-shrink:0"></div>' +
        '<div style="flex:1;font-size:13px;color:' +
        c.txt +
        '">派遣中</div>' +
        '<div style="font-size:12px;color:' +
        (exps[i].done ? c.primary : c.txt2) +
        '">' +
        (exps[i].done ? "已完成" : exps[i].time) +
        "</div>" +
        "</div>";
    }
    return (
      '<div class="dncard">' +
      '<div style="font-size:14px;font-weight:600;color:' +
      c.txt +
      ';margin-bottom:8px">探索派遣 (3/5)</div>' +
      rows +
      "</div>"
    );
  }

  function skCards() {
    var h = "";
    for (var i = 0; i < 5; i++) {
      h +=
        '<div class="dncard"><div style="display:flex;justify-content:space-between;align-items:center">' +
        '<div><div class="sk" style="height:14px;width:80px;margin-bottom:6px"></div>' +
        '<div class="sk" style="height:11px;width:120px"></div></div>' +
        '<div class="sk" style="height:18px;width:50px"></div>' +
        "</div></div>";
    }
    return h;
  }

  var content = "";
  if (dailyState.view === "loading") {
    content = skCards();
  } else {
    content =
      noteCard("魔神任务", "第四幕：永恒的终章", null, c.primary) +
      noteCard(
        "原粹树脂",
        isFull ? "已全部恢复" : "将于4小时后全部恢复",
        resin + "/200",
        resinColor,
      ) +
      noteCard("洞天宝钱", "将于12小时后存满", "1800/2400", c.primary) +
      taskCard() +
      noteCard("征讨之花", "本周剩余", "1/3", c.primary) +
      noteCard("参量质变仪", "", "就绪", c.primary) +
      expCard();
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
    '<div class="sy" style="flex:1;padding:12px 16px 40px">' +
    '<div style="max-width:' +
    maxW +
    'px;margin:0 auto">' +
    '<div style="font-size:12px;color:' +
    c.txt2 +
    ';margin-bottom:12px">数据存在约5分钟延迟</div>' +
    content +
    "</div></div></div>"
  );
}

function genshinDailyDetailControls() {
  return [
    {
      id: "view",
      label: "状态",
      options: [
        { value: "normal", label: "正常" },
        { value: "full", label: "树脂满" },
        { value: "loading", label: "加载中" },
      ],
      current: function () {
        return dailyState.view;
      },
      onChange: function (v) {
        dailyState.view = v;
      },
    },
  ];
}

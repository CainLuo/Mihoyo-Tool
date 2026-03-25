/**
 * characters.js — 角色页渲染逻辑
 */
var charactersState = { view: "data" };

var CHARS_DATA = [
  {
    name: "菲林斯",
    lv: 90,
    fetter: 9,
    elem: "雷",
    elemColor: "#CE93D8",
    cons: 0,
    rarity: 5,
  },
  {
    name: "奇偶·女性",
    lv: 1,
    fetter: 0,
    elem: "火",
    elemColor: "#FF7043",
    cons: 0,
    rarity: 4,
  },
  {
    name: "奇偶·男性",
    lv: 50,
    fetter: 0,
    elem: "火",
    elemColor: "#FF7043",
    cons: 0,
    rarity: 4,
  },
  {
    name: "希诺宁",
    lv: 90,
    fetter: 10,
    elem: "岩",
    elemColor: "#FFCA28",
    cons: 0,
    rarity: 5,
  },
  {
    name: "娜维娅",
    lv: 90,
    fetter: 10,
    elem: "岩",
    elemColor: "#FFCA28",
    cons: 0,
    rarity: 5,
  },
  {
    name: "芙宁娜",
    lv: 90,
    fetter: 10,
    elem: "水",
    elemColor: "#4FC3F7",
    cons: 0,
    rarity: 5,
  },
  {
    name: "那维莱特",
    lv: 90,
    fetter: 10,
    elem: "水",
    elemColor: "#4FC3F7",
    cons: 0,
    rarity: 5,
  },
  {
    name: "迪希雅",
    lv: 90,
    fetter: 10,
    elem: "火",
    elemColor: "#FF7043",
    cons: 0,
    rarity: 5,
  },
];

function renderCharacters(w, h) {
  var c = T();
  var cols = w < 600 ? 2 : w < 840 ? 3 : w < 1200 ? 4 : 5;
  var gridCols = "repeat(" + cols + ",1fr)";
  var isPhone = w < 600;

  function charCard(ch) {
    var bg =
      G.theme === "dark"
        ? "linear-gradient(135deg,#1a1a2e,#16213e)"
        : "linear-gradient(135deg,#e8f0ff,#d0e4ff)";
    var nameColor =
      G.theme === "dark" ? "rgba(255,255,255,.9)" : "rgba(0,0,0,.85)";
    return (
      '<div style="background:' +
      c.surfCard +
      ";border:1px solid " +
      c.border +
      ";border-radius:12px;overflow:hidden;box-shadow:0 2px 6px " +
      c.shadow +
      '">' +
      '<div style="position:relative;background:' +
      bg +
      ';aspect-ratio:1/1;overflow:hidden">' +
      '<div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;font-size:32px;opacity:.3">👤</div>' +
      '<div style="position:absolute;top:6px;left:6px;width:22px;height:22px;border-radius:50%;background:' +
      ch.elemColor +
      ';display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:700;color:#fff">' +
      ch.elem +
      "</div>" +
      '<div style="position:absolute;top:6px;right:6px;width:18px;height:18px;border-radius:50%;background:rgba(0,0,0,.6);display:flex;align-items:center;justify-content:center;font-size:10px;font-weight:700;color:#FFD700">' +
      ch.cons +
      "</div>" +
      '<div style="position:absolute;bottom:0;left:0;right:0;background:linear-gradient(to top,rgba(0,0,0,.7),transparent);padding:4px 6px">' +
      '<div style="font-size:' +
      (isPhone ? "11" : "12") +
      "px;font-weight:700;color:" +
      nameColor +
      ';white-space:nowrap;overflow:hidden;text-overflow:ellipsis">' +
      ch.name +
      "</div>" +
      '<div style="font-size:10px;color:rgba(255,255,255,.6)">Lv.' +
      ch.lv +
      ' <span style="color:' +
      c.gold +
      '">R' +
      ch.rarity +
      "</span></div>" +
      "</div></div>" +
      '<div style="padding:6px 8px"><div style="font-size:11px;color:' +
      c.txt2 +
      '">好感 ' +
      ch.fetter +
      "</div></div>" +
      "</div>"
    );
  }

  function skCard() {
    return (
      '<div style="background:' +
      c.surfCard +
      ";border:1px solid " +
      c.border +
      ';border-radius:12px;overflow:hidden">' +
      '<div style="aspect-ratio:1/1;background:' +
      c.border +
      ';animation:sk 1.5s ease-in-out infinite"></div>' +
      '<div style="padding:6px 8px"><div style="height:10px;width:60%;background:' +
      c.border +
      ';border-radius:4px;animation:sk 1.5s ease-in-out infinite"></div></div>' +
      "</div>"
    );
  }

  var gameTabs =
    '<div style="display:flex;gap:8px;padding:10px 16px;border-bottom:1px solid ' +
    c.div +
    ";flex-shrink:0;background:" +
    c.cardBg +
    '">' +
    '<div style="padding:5px 14px;border-radius:16px;font-size:13px;background:' +
    c.primary +
    ';color:#fff;font-weight:600">原神</div>' +
    '<div style="padding:5px 14px;border-radius:16px;font-size:13px;border:1px solid ' +
    c.border +
    ";color:" +
    c.txt2 +
    '">崩坏：星穹铁道</div>' +
    "</div>";

  var content = "";
  if (charactersState.view === "loading") {
    var sks = "";
    for (var i = 0; i < cols * 3; i++) sks += skCard();
    content =
      '<div class="sy" style="flex:1;padding:12px"><style>@keyframes sk{0%,100%{opacity:.4}50%{opacity:.9}}</style>' +
      '<div style="display:grid;grid-template-columns:' +
      gridCols +
      ';gap:10px">' +
      sks +
      "</div></div>";
  } else if (charactersState.view === "empty") {
    content =
      '<div style="flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:16px;padding:40px">' +
      '<div style="font-size:48px">📋</div>' +
      '<div style="font-size:16px;font-weight:600;color:' +
      c.txt +
      '">暂无角色数据</div>' +
      '<div style="font-size:13px;color:' +
      c.txt2 +
      ';text-align:center">请先同步角色数据</div>' +
      '<div style="padding:10px 24px;background:' +
      c.primary +
      ';border-radius:8px;color:#fff;font-size:14px;font-weight:600;cursor:pointer">立即同步</div>' +
      "</div>";
  } else {
    var cards = "";
    for (var i = 0; i < CHARS_DATA.length; i++)
      cards += charCard(CHARS_DATA[i]);
    content =
      '<div class="sy" style="flex:1;padding:12px">' +
      '<div style="display:grid;grid-template-columns:' +
      gridCols +
      ';gap:10px">' +
      cards +
      "</div></div>";
  }

  return (
    baseCss(w, h) +
    "<style>@keyframes sk{0%,100%{opacity:.4}50%{opacity:.9}}</style>" +
    '<div style="width:' +
    w +
    "px;height:" +
    h +
    "px;display:flex;flex-direction:column;background:" +
    c.pageBg +
    '">' +
    gameTabs +
    content +
    tabBar("characters") +
    "</div>"
  );
}

function charactersControls() {
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
        return charactersState.view;
      },
      onChange: function (v) {
        charactersState.view = v;
      },
    },
  ];
}

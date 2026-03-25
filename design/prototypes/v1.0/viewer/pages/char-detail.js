/**
 * char-detail.js — 原神角色详情页渲染逻辑
 * 数据和渲染函数从 char-detail.html 迁移
 */

// ── 元素色映射 ────────────────────────────────────────────────────────
var ELEM_COLORS = {
  hydro: {
    bg: "linear-gradient(135deg,#0a2a4a 0%,#0d1e3a 40%,#081428 100%)",
    accent: "#4fc3f7",
  },
  pyro: {
    bg: "linear-gradient(135deg,#3a1008 0%,#2a0e0a 40%,#180808 100%)",
    accent: "#ff7043",
  },
  electro: {
    bg: "linear-gradient(135deg,#2a1040 0%,#1e0a30 40%,#100818 100%)",
    accent: "#ce93d8",
  },
  anemo: {
    bg: "linear-gradient(135deg,#083a2a 0%,#062a1e 40%,#041810 100%)",
    accent: "#80cbc4",
  },
  geo: {
    bg: "linear-gradient(135deg,#2a1e04 0%,#1e1604 40%,#100e02 100%)",
    accent: "#ffca28",
  },
  cryo: {
    bg: "linear-gradient(135deg,#0a1e3a 0%,#081628 40%,#040e18 100%)",
    accent: "#b3e5fc",
  },
  dendro: {
    bg: "linear-gradient(135deg,#0a2a08 0%,#081e06 40%,#040e02 100%)",
    accent: "#a5d6a7",
  },
};

var CD = {
  name: "那维莱特",
  title: "凡世的公正裁判",
  level: 80,
  maxLevel: 90,
  fetter: 10,
  element: "hydro",
  hp: 36086,
  hpBase: 12491,
  hpBonus: 5436,
  atk: 1454,
  atkBase: 1026,
  atkBonus: 1417,
  def: 723,
  defBase: 809,
  defBonus: 118,
  cr: 18.6,
  cd: 176.0,
  heal: 0.0,
  em: 239,
  er: 100.0,
  img: "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/image_7/22cc7ea21f71c28edafe88c68a63d9aa.png",
  icon: "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f6c8/b30987d539b299dc89004d72274f5e89.png",
  wpn: {
    name: "和璞鸢",
    lv: 90,
    maxLv: 90,
    af: 1,
    atk: 674,
    subLabel: "暴击率",
    subVal: "22.1%",
    stars: 5,
    icon: "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f6c8/a9c72ec4bc54b9acf27362095da7af61.png",
  },
  skills: [
    { i: "⚔️", lv: "0.9/1" },
    { i: "💧", lv: "1.6/6" },
    { i: "🌊", lv: "2.8/6" },
    { i: "🌀", lv: "5.1" },
    { i: "🔮", lv: "6.8" },
    { i: "✨", lv: "9.0" },
    { i: "💫", lv: "11.6" },
  ],
  cons: [0, 0, 0, 0, 0, 0],
  relics: [
    {
      pos: "生之花",
      name: "猎人的胸花",
      lv: 20,
      stars: 5,
      i: "🌸",
      mnLabel: "生命值",
      mv: "4,780",
      s: [
        ["攻击力%", "+29.5%"],
        ["防御力", "+21"],
        ["暴击率", "+3.1%"],
        ["暴击伤害", "+9.3%"],
      ],
    },
    {
      pos: "死之羽",
      name: "杰作的序曲",
      lv: 20,
      stars: 5,
      i: "🪶",
      mnLabel: "攻击力",
      mv: "311",
      s: [
        ["暴击率", "+9.3%"],
        ["防御力", "+16"],
        ["暴击伤害", "+19.4%"],
        ["防御力", "+37"],
      ],
    },
    {
      pos: "时之沙",
      name: "裁判的时刻",
      lv: 20,
      stars: 5,
      i: "⏳",
      mnLabel: "生命值%",
      mv: "46.6%",
      s: [
        ["暴击率", "+3.9%"],
        ["元素精通", "+82"],
        ["暴击伤害", "+19.4%"],
        ["攻击力", "+18"],
      ],
    },
    {
      pos: "空之杯",
      name: "遗忘的容器",
      lv: 20,
      stars: 5,
      i: "🏺",
      mnLabel: "生命值%",
      mv: "46.6%",
      s: [
        ["暴击率", "+10.1%"],
        ["攻击力", "+37"],
        ["暴击伤害", "+21.8%"],
        ["防御力", "+21"],
      ],
    },
    {
      pos: "理之冠",
      name: "老兵的容颜",
      lv: 20,
      stars: 5,
      i: "👑",
      mnLabel: "暴击伤害",
      mv: "62.2%",
      s: [
        ["攻击力%", "+8.6%"],
        ["暴击率", "+5.3%"],
        ["元素精通", "+61"],
        ["防御力", "+39"],
      ],
    },
  ],
};

function cdStars(n) {
  var s = "";
  for (var i = 0; i < n; i++) s += "★";
  return (
    '<span style="color:#ffca28;font-size:11px;letter-spacing:1px">' +
    s +
    "</span>"
  );
}

function cdConsCol() {
  var h = "";
  for (var i = 0; i < CD.cons.length; i++) {
    var on = CD.cons[i];
    h +=
      '<div style="width:28px;height:28px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:700;background:' +
      (on ? "rgba(79,195,247,.25)" : "rgba(0,0,0,.5)") +
      ";border:1.5px solid " +
      (on ? "rgba(79,195,247,.8)" : "rgba(255,255,255,.2)") +
      ";color:" +
      (on ? "#4fc3f7" : "#444") +
      '">' +
      (i + 1) +
      "</div>";
  }
  return h;
}

function cdSklsPhone() {
  var h = "";
  for (var i = 0; i < 3; i++) {
    var s = CD.skills[i];
    h +=
      '<div style="display:flex;flex-direction:column;align-items:center;gap:2px">' +
      '<div style="width:34px;height:34px;border-radius:50%;background:rgba(0,0,0,.5);border:1.5px solid rgba(79,195,247,.35);display:flex;align-items:center;justify-content:center;font-size:15px">' +
      s.i +
      "</div>" +
      '<span style="font-size:11px;color:#4fc3f7;font-weight:700;line-height:1.4">' +
      s.lv +
      "</span>" +
      "</div>";
  }
  return h;
}

function cdApGrid(cols) {
  var d = [
    ["❤️", "生命值", CD.hp.toLocaleString(), 0],
    ["🛡️", "防御力", CD.def, 0],
    ["⚔️", "攻击力", CD.atk.toLocaleString(), 0],
    ["💥", "暴击率", CD.cr + "%", 1],
    ["💢", "暴击伤害", CD.cd + "%", 1],
    ["💚", "治疗加成", CD.heal + "%", 0],
    ["🌿", "元素精通", CD.em, 0],
    ["⚡", "元素充能", CD.er + "%", 0],
  ];
  var h =
    '<div style="display:grid;grid-template-columns:repeat(' +
    cols +
    ',1fr);background:rgba(0,0,0,.25)">';
  for (var i = 0; i < d.length; i++) {
    h +=
      '<div style="display:flex;align-items:center;justify-content:space-between;padding:5px 8px;font-size:11px;border-right:1px solid rgba(255,255,255,.05);border-bottom:1px solid rgba(255,255,255,.05)">' +
      '<span style="color:#888">' +
      d[i][0] +
      " " +
      d[i][1] +
      "</span>" +
      '<span style="color:' +
      (d[i][3] ? "#4fc3f7" : "#e0e0f0") +
      ';font-weight:600">' +
      d[i][2] +
      "</span></div>";
  }
  return h + "</div>";
}

function cdWpnPhone() {
  var w = CD.wpn;
  return (
    '<div style="display:flex;align-items:center;gap:8px;padding:7px 10px;background:rgba(255,255,255,.03);border-bottom:1px solid rgba(255,255,255,.06)">' +
    '<img style="width:36px;height:36px;border-radius:6px;object-fit:contain;background:rgba(255,255,255,.08);flex-shrink:0" src="' +
    w.icon +
    '">' +
    '<div style="flex:1;min-width:0"><div style="font-size:12px;font-weight:600;color:#e0e0f0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">' +
    w.name +
    "</div>" +
    '<div style="font-size:10px;color:#888;margin-top:2px">Lv.' +
    w.lv +
    ' <span style="font-size:10px;color:#ffca28;background:rgba(255,202,40,.15);padding:1px 5px;border-radius:3px">精炼' +
    w.af +
    "</span> · " +
    w.subLabel +
    " " +
    w.subVal +
    "</div></div>" +
    '<div style="font-size:13px;color:#e0e0f0;font-weight:600;flex-shrink:0">' +
    w.atk +
    "</div></div>"
  );
}

function cdRelCardPhone(r) {
  var subs = "";
  for (var i = 0; i < r.s.length; i++) {
    subs +=
      '<div style="display:flex;justify-content:space-between;font-size:10px;padding:1px 0"><span style="color:#999">' +
      r.s[i][0] +
      '</span><span style="color:#ddd">' +
      r.s[i][1] +
      "</span></div>";
  }
  return (
    '<div style="background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.08);border-radius:8px;padding:7px 8px">' +
    '<div style="display:flex;align-items:center;gap:5px;margin-bottom:4px">' +
    '<span style="font-size:15px;flex-shrink:0">' +
    r.i +
    "</span>" +
    '<div style="flex:1;min-width:0"><div style="font-size:11px;font-weight:600;color:#e0e0f0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">' +
    r.name +
    "</div>" +
    '<div style="font-size:9px;color:#888">' +
    r.pos +
    "</div></div>" +
    '<span style="font-size:9px;color:#aaa;background:rgba(255,255,255,.08);padding:1px 4px;border-radius:3px;flex-shrink:0">+' +
    r.lv +
    "</span></div>" +
    '<div style="display:flex;justify-content:space-between;align-items:baseline;padding:2px 0;border-bottom:1px solid rgba(255,255,255,.06);margin-bottom:3px">' +
    '<span style="font-size:10px;color:#4fc3f7">' +
    r.mnLabel +
    "</span>" +
    '<span style="font-size:13px;font-weight:700;color:#fff">' +
    r.mv +
    "</span></div>" +
    subs +
    "</div>"
  );
}

function cdRelRowEnka(r, accent) {
  var subs = "";
  for (var i = 0; i < r.s.length; i++) {
    subs +=
      '<div style="display:flex;justify-content:space-between;align-items:center;padding:2px 6px;gap:4px">' +
      '<span style="font-size:10px;color:rgba(255,255,255,.55);white-space:nowrap">' +
      r.s[i][0] +
      "</span>" +
      '<span style="font-size:11px;font-weight:600;color:#fff;white-space:nowrap">' +
      r.s[i][1] +
      "</span></div>";
  }
  return (
    '<div style="flex:1;display:flex;align-items:stretch;border-bottom:1px solid rgba(255,255,255,.06);background:rgba(0,0,0,.15);min-height:0">' +
    '<div style="width:90px;flex-shrink:0;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:4px 6px;border-right:1px solid rgba(255,255,255,.06)">' +
    '<div style="font-size:24px;line-height:1">' +
    r.i +
    "</div>" +
    '<div style="font-size:9px;color:rgba(255,255,255,.5);margin-top:2px">' +
    r.mnLabel +
    "</div>" +
    '<div style="font-size:16px;font-weight:700;color:#fff;line-height:1.1">' +
    r.mv +
    "</div>" +
    '<div style="margin-top:2px">' +
    cdStars(r.stars) +
    "</div>" +
    '<div style="font-size:9px;color:rgba(255,255,255,.4)">+' +
    r.lv +
    "</div></div>" +
    '<div style="flex:1;display:grid;grid-template-columns:1fr 1fr;align-content:center">' +
    subs +
    "</div></div>"
  );
}

function cdApListEnka(accent) {
  var rows = [
    {
      icon: "💧",
      label: "生命值",
      val: CD.hp.toLocaleString(),
      base: CD.hpBase.toLocaleString(),
      bonus: "+" + CD.hpBonus.toLocaleString(),
    },
    {
      icon: "⚔️",
      label: "攻击力",
      val: CD.atk.toLocaleString(),
      base: CD.atkBase.toLocaleString(),
      bonus: "+" + CD.atkBonus.toLocaleString(),
    },
    {
      icon: "🛡️",
      label: "防御力",
      val: CD.def.toLocaleString(),
      base: CD.defBase.toLocaleString(),
      bonus: "+" + CD.defBonus.toLocaleString(),
    },
    { icon: "🌿", label: "元素精通", val: CD.em, base: null, bonus: null },
    {
      icon: "💥",
      label: "暴击率",
      val: CD.cr + "%",
      base: null,
      bonus: null,
      hi: true,
    },
    {
      icon: "💢",
      label: "暴击伤害",
      val: CD.cd + "%",
      base: null,
      bonus: null,
      hi: true,
    },
    {
      icon: "⚡",
      label: "元素充能",
      val: CD.er + "%",
      base: null,
      bonus: null,
    },
  ];
  var h = "";
  for (var i = 0; i < rows.length; i++) {
    var r = rows[i];
    h +=
      '<div style="display:flex;align-items:center;padding:6px 14px;border-bottom:1px solid rgba(255,255,255,.05)">' +
      '<span style="font-size:14px;margin-right:8px;flex-shrink:0">' +
      r.icon +
      "</span>" +
      '<span style="font-size:12px;color:rgba(255,255,255,.7);flex:1">' +
      r.label +
      "</span>" +
      '<div style="text-align:right"><div style="font-size:14px;font-weight:600;color:' +
      (r.hi ? accent : "#fff") +
      '">' +
      r.val +
      "</div>" +
      (r.base
        ? '<div style="font-size:10px;color:rgba(255,255,255,.4)">' +
          r.base +
          ' <span style="color:rgba(255,255,255,.5)">' +
          r.bonus +
          "</span></div>"
        : "") +
      "</div></div>";
  }
  return h;
}

function cdRenderPP(w, h) {
  var heroH = 260;
  var hero =
    '<div style="height:' +
    heroH +
    'px;flex-shrink:0;position:relative;background:linear-gradient(150deg,#0a1e38,#0e0e22);overflow:hidden">' +
    '<img src="' +
    CD.img +
    '" style="position:absolute;right:0;bottom:0;height:100%;object-fit:cover;opacity:.9" onerror="this.style.display=\'none\'">' +
    '<div style="position:absolute;inset:0;background:linear-gradient(to right,#0c1a30 0%,rgba(12,26,48,.88) 32%,rgba(12,26,48,.4) 55%,transparent 100%)"></div>' +
    '<div style="position:absolute;inset:0;background:linear-gradient(to top,rgba(10,16,30,.9) 0%,transparent 45%)"></div>' +
    '<div style="position:absolute;right:8px;top:50%;transform:translateY(-50%);display:flex;flex-direction:column;gap:5px;z-index:3">' +
    cdConsCol() +
    "</div>" +
    '<div style="position:absolute;left:12px;bottom:10px;z-index:2;max-width:calc(100% - 52px)">' +
    '<div style="font-size:22px;font-weight:700;color:#fff;text-shadow:0 2px 8px rgba(0,0,0,.9);line-height:1.2">' +
    CD.name +
    "</div>" +
    '<div style="font-size:12px;color:#ccc;margin-top:4px;display:flex;align-items:center;gap:6px">Lv.' +
    CD.level +
    ' <span style="font-size:10px;padding:1px 6px;border-radius:4px;background:rgba(79,195,247,.12);color:#4fc3f7;border:1px solid rgba(79,195,247,.2)">好感 ' +
    CD.fetter +
    "</span></div>" +
    '<div style="display:flex;gap:10px;margin-top:8px;padding-bottom:2px">' +
    cdSklsPhone() +
    "</div>" +
    "</div></div>";
  var relHtml = "";
  for (var i = 0; i < CD.relics.length; i++)
    relHtml += cdRelCardPhone(CD.relics[i]);
  var body =
    '<div style="flex:1;min-height:0;overflow-y:auto;scrollbar-width:thin;scrollbar-color:rgba(255,255,255,.2) transparent;padding:10px;display:flex;flex-direction:column;gap:8px">' +
    cdWpnPhone() +
    cdApGrid(2) +
    '<div style="font-size:11px;color:#888;padding-top:2px">圣遗物</div>' +
    '<div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;align-items:start">' +
    relHtml +
    "</div>" +
    '<div style="height:10px;flex-shrink:0"></div></div>';
  return (
    "<style>*{box-sizing:border-box;margin:0;padding:0}body{width:" +
    w +
    "px;height:" +
    h +
    'px;overflow:hidden;font-family:"PingFang SC",sans-serif}</style>' +
    '<div style="display:flex;flex-direction:column;width:' +
    w +
    "px;height:" +
    h +
    'px;background:#0d0d18">' +
    hero +
    body +
    "</div>"
  );
}

function cdRenderPL(w, h) {
  var hero =
    '<div style="width:200px;flex-shrink:0;position:relative;background:linear-gradient(150deg,#0a1e38,#0e0e22);overflow:hidden">' +
    '<img src="' +
    CD.img +
    '" style="position:absolute;top:0;left:0;width:100%;height:100%;object-fit:cover;object-position:center top;opacity:.9" onerror="this.style.display=\'none\'">' +
    '<div style="position:absolute;inset:0;background:linear-gradient(to top,rgba(10,16,30,1) 0%,rgba(10,16,30,.7) 40%,rgba(10,16,30,.1) 65%,transparent 100%)"></div>' +
    '<div style="position:absolute;right:6px;top:50%;transform:translateY(-50%);display:flex;flex-direction:column;gap:4px;z-index:3">' +
    cdConsCol() +
    "</div>" +
    '<div style="position:absolute;left:10px;bottom:8px;z-index:2;max-width:calc(100% - 38px)">' +
    '<div style="font-size:15px;font-weight:700;color:#fff;text-shadow:0 2px 6px rgba(0,0,0,.9)">' +
    CD.name +
    "</div>" +
    '<div style="font-size:10px;color:#ccc;margin-top:3px">Lv.' +
    CD.level +
    "</div>" +
    '<div style="display:flex;gap:8px;margin-top:6px">' +
    cdSklsPhone() +
    "</div>" +
    "</div></div>";
  var relHtml = "";
  for (var i = 0; i < CD.relics.length; i++)
    relHtml += cdRelCardPhone(CD.relics[i]);
  var body =
    '<div style="flex:1;min-width:0;min-height:0;overflow-y:auto;scrollbar-width:thin;scrollbar-color:rgba(255,255,255,.2) transparent;padding:8px;display:flex;flex-direction:column;gap:6px">' +
    cdWpnPhone() +
    cdApGrid(4) +
    '<div style="font-size:11px;color:#888;padding-top:2px">圣遗物</div>' +
    '<div style="display:grid;grid-template-columns:1fr 1fr;gap:5px;align-items:start">' +
    relHtml +
    "</div>" +
    '<div style="height:8px;flex-shrink:0"></div></div>';
  return (
    "<style>*{box-sizing:border-box;margin:0;padding:0}body{width:" +
    w +
    "px;height:" +
    h +
    'px;overflow:hidden;font-family:"PingFang SC",sans-serif}</style>' +
    '<div style="display:flex;flex-direction:column;width:' +
    w +
    "px;height:" +
    h +
    'px;background:#0d0d18">' +
    '<div style="display:flex;flex:1;min-height:0">' +
    hero +
    body +
    "</div></div>"
  );
}

function cdRenderEnka(w, h) {
  var elem = ELEM_COLORS[CD.element] || ELEM_COLORS.hydro;
  var accent = elem.accent;
  var gap = 8;
  var consHtml =
    '<div style="display:flex;flex-direction:column;gap:5px">' +
    cdConsCol() +
    "</div>";
  var sklHtml = '<div style="display:flex;flex-direction:column;gap:6px">';
  for (var si = 0; si < 3; si++) {
    var sk = CD.skills[si];
    sklHtml +=
      '<div style="display:flex;flex-direction:column;align-items:center;gap:2px">' +
      '<div style="width:32px;height:32px;border-radius:50%;background:rgba(0,0,0,.55);border:1.5px solid rgba(255,255,255,.25);display:flex;align-items:center;justify-content:center;font-size:14px">' +
      sk.i +
      "</div>" +
      '<span style="font-size:10px;color:' +
      accent +
      ';font-weight:700">' +
      sk.lv +
      "</span></div>";
  }
  sklHtml += "</div>";
  var left =
    '<div style="flex:1;min-width:0;position:relative;overflow:hidden;border-radius:8px;background:' +
    elem.bg +
    '">' +
    '<img src="' +
    CD.img +
    '" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover;object-position:top center;opacity:.95" onerror="this.style.display=\'none\'">' +
    '<div style="position:absolute;inset:0;background:linear-gradient(to bottom,rgba(0,0,0,.6) 0%,transparent 30%,transparent 55%,rgba(0,0,0,.75) 100%)"></div>' +
    '<div style="position:absolute;left:12px;top:12px;z-index:2">' +
    '<div style="font-size:18px;font-weight:700;color:#fff;text-shadow:0 2px 8px rgba(0,0,0,.9)">' +
    CD.name +
    "</div>" +
    '<div style="font-size:11px;color:rgba(255,255,255,.75);margin-top:4px">Lv.' +
    CD.level +
    "/" +
    CD.maxLevel +
    "</div>" +
    '<div style="font-size:11px;color:' +
    accent +
    ';margin-top:2px">❤ 好感 ' +
    CD.fetter +
    "</div></div>" +
    '<div style="position:absolute;left:12px;bottom:12px;z-index:2">' +
    consHtml +
    "</div>" +
    '<div style="position:absolute;right:12px;bottom:12px;z-index:2">' +
    sklHtml +
    "</div></div>";
  var mid =
    '<div style="flex:1;min-width:0;display:flex;flex-direction:column;border-radius:8px;background:rgba(0,0,0,.35);overflow:hidden">' +
    '<div style="padding:12px 14px;border-bottom:1px solid rgba(255,255,255,.07);flex-shrink:0">' +
    '<div style="display:flex;align-items:center;gap:10px">' +
    '<img style="width:52px;height:52px;object-fit:contain;flex-shrink:0;border-radius:6px;background:rgba(255,255,255,.06)" src="' +
    CD.wpn.icon +
    '">' +
    '<div style="flex:1;min-width:0"><div style="font-size:13px;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">' +
    CD.wpn.name +
    "</div>" +
    '<div style="display:flex;align-items:center;gap:8px;margin-top:3px"><span style="font-size:11px;color:rgba(255,255,255,.6)">⚔️ ' +
    CD.wpn.atk +
    '</span><span style="font-size:11px;color:' +
    accent +
    '">💥 ' +
    CD.wpn.subVal +
    "</span></div>" +
    '<div style="display:flex;align-items:center;gap:6px;margin-top:3px"><span style="font-size:10px;color:#ffca28;background:rgba(255,202,40,.15);padding:1px 5px;border-radius:3px">R' +
    CD.wpn.af +
    '</span><span style="font-size:10px;color:rgba(255,255,255,.5)">Lv.' +
    CD.wpn.lv +
    "/" +
    CD.wpn.maxLv +
    "</span></div>" +
    '</div></div><div style="margin-top:6px">' +
    cdStars(CD.wpn.stars) +
    "</div></div>" +
    '<div style="flex:1;overflow-y:auto;scrollbar-width:thin;scrollbar-color:rgba(255,255,255,.2) transparent">' +
    cdApListEnka(accent) +
    "</div></div>";
  var relics =
    '<div style="flex:1;min-width:0;border-radius:8px;background:rgba(0,0,0,.25);overflow:hidden;display:flex;flex-direction:column">';
  for (var i = 0; i < CD.relics.length; i++)
    relics += cdRelRowEnka(CD.relics[i], accent);
  relics += "</div>";
  return (
    "<style>*{box-sizing:border-box;margin:0;padding:0}body{width:" +
    w +
    "px;height:" +
    h +
    'px;overflow:hidden;font-family:"PingFang SC",sans-serif}</style>' +
    '<div style="display:flex;flex-direction:column;width:' +
    w +
    "px;height:" +
    h +
    "px;background:" +
    elem.bg +
    '">' +
    '<div style="flex:1;min-height:0;display:flex;overflow:hidden;padding:' +
    gap +
    "px;gap:" +
    gap +
    'px">' +
    left +
    mid +
    relics +
    "</div></div>"
  );
}

function renderCharDetail(w, h) {
  if (w <= 400) return cdRenderPP(w, h);
  if (w <= 800) return cdRenderPL(w, h);
  return cdRenderEnka(w, h);
}

function charDetailControls() {
  return [];
}

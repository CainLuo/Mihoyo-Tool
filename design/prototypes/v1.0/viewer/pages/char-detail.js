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
    name: "万世流涌大典",
    lv: 90,
    maxLv: 90,
    af: 1,
    atk: 542,
    subLabel: "暴击伤害",
    subVal: "88.2%",
    stars: 5,
    icon: "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f6c8/a9c72ec4bc54b9acf27362095da7af61.png",
  },
  skills: [
    {
      name: "如水从平",
      lv: 9,
      type: "普攻",
      icon: "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f71a/2c014e6053c4f0d032e1d1ff0c6de0e1.png",
    },
    {
      name: "泪水啊，我必偿还",
      lv: 9,
      type: "元素战技",
      icon: "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f71a/32948454e19c2743c0765c7072934b43.png",
    },
    {
      name: "潮水啊，我已归来",
      lv: 9,
      type: "元素爆发",
      icon: "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f71a/e20c080ec58dbbd58ea632f73dfa4da1.png",
    },
  ],
  cons: [1, 1, 1, 1, 1, 1],
  consIcons: [
    "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f721/ee46811f355b04470301e75887343cf6.png",
    "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f721/c51abfbec3f6066ff3b56cd391132f19.png",
    "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f721/43615c2e302d7d7d4918a47c25a0a112.png",
    "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f721/319854868cf2d73e2b9439e94fb7c3d7.png",
    "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f721/aca9b6bb4b1a6126cb84f0653d6ee621.png",
    "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f721/2f594b03eb9b06dc4715eadcfdd992a3.png",
  ],
  relics: [
    {
      pos: "生之花",
      name: "猎人的胸花",
      lv: 20,
      stars: 5,
      icon: "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f6c8/6951d1c3be4a5a7ed69b0a3509f68b03.png",
      mnLabel: "生命值",
      mv: "4780",
      s: [
        ["暴击伤害", "23.3%"],
        ["暴击率", "10.4%"],
        ["暴击率", "3.1%"],
        ["元素精通", "40"],
      ],
    },
    {
      pos: "死之羽",
      name: "杰作的序曲",
      lv: 20,
      stars: 5,
      icon: "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f6c8/cb025bb6ec2c1a00ee120de2bed4535b.png",
      mnLabel: "攻击力",
      mv: "311",
      s: [
        ["元素精通", "23"],
        ["暴击伤害", "20.2%"],
        ["暴击率", "7.0%"],
        ["防御力%", "11.7%"],
      ],
    },
    {
      pos: "时之沙",
      name: "裁判的时刻",
      lv: 20,
      stars: 5,
      icon: "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f6c8/ae75aea17fa586b710c213b800c4af6f.png",
      mnLabel: "生命值%",
      mv: "46.6%",
      s: [
        ["暴击率", "12.4%"],
        ["暴击伤害", "7.0%"],
        ["攻击力", "19"],
        ["生命值", "478"],
      ],
    },
    {
      pos: "空之杯",
      name: "遗忘的容器",
      lv: 20,
      stars: 5,
      icon: "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f6c8/9b8f2f78608d37db8a0a9ec7d7d10c6e.png",
      mnLabel: "水元素伤害",
      mv: "46.6%",
      s: [
        ["生命值", "777"],
        ["暴击伤害", "20.2%"],
        ["暴击率", "3.9%"],
        ["防御力%", "4.1%"],
      ],
    },
    {
      pos: "理之冠",
      name: "宗室面具",
      lv: 20,
      stars: 5,
      icon: "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f6c8/2e5e66807c6c65eea1918ce6465cdc74.png",
      mnLabel: "暴击率",
      mv: "31.1%",
      s: [
        ["元素充能", "18.2%"],
        ["攻击力", "33"],
        ["暴击伤害", "18.7%"],
        ["生命值%", "9.3%"],
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
  var ec = ELEM_COLORS[CD.element] || ELEM_COLORS.hydro;
  var accent = ec.accent;
  var h = "";
  for (var i = 0; i < CD.cons.length; i++) {
    var on = CD.cons[i];
    var bg = on ? "rgba(79,195,247,.25)" : "rgba(0,0,0,.55)";
    var border = on ? "rgba(79,195,247,.8)" : "rgba(255,255,255,.12)";
    var shadow = on ? "0 0 8px rgba(79,195,247,.4)" : "none";
    h +=
      '<div style="width:30px;height:30px;border-radius:50%;display:flex;align-items:center;justify-content:center;background:' +
      bg +
      ";border:1.5px solid " +
      border +
      ";box-shadow:" +
      shadow +
      ';">' +
      (on
        ? '<span style="font-size:11px;font-weight:800;color:' +
          accent +
          ';">' +
          (i + 1) +
          "</span>"
        : '<svg width="11" height="13" viewBox="0 0 12 14" fill="none"><rect x="2" y="6" width="8" height="7" rx="1.5" fill="rgba(255,255,255,.3)"/><path d="M3.5 6V4.5a2.5 2.5 0 015 0V6" stroke="rgba(255,255,255,.3)" stroke-width="1.5" stroke-linecap="round"/></svg>') +
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
  var heroH = Math.min(320, Math.max(240, h * 0.42));
  var ec = ELEM_COLORS[CD.element] || ELEM_COLORS.hydro;
  var accent = ec.accent;
  var c = {
    card: "#111118",
    border: "#2a2a3a",
    text: "#e8e8f0",
    sub: "#888",
    gold: "#ffca28",
    bg: "#080810",
  };

  // 控制项状态
  var noWpn = window._cdCtrl && window._cdCtrl.cd_no_wpn;
  var noRelics = window._cdCtrl && window._cdCtrl.cd_no_relics;
  var cons0 = window._cdCtrl && window._cdCtrl.cd_cons0;
  var activeCons = cons0 ? [0, 0, 0, 0, 0, 0] : CD.cons;

  // ── 命座列 ──
  function consCol() {
    var html = "";
    for (var i = 0; i < 6; i++) {
      var on = activeCons[i];
      var bg = on ? "rgba(79,195,247,.25)" : "rgba(0,0,0,.55)";
      var border = on ? "rgba(79,195,247,.8)" : "rgba(255,255,255,.12)";
      var shadow = on ? "0 0 8px rgba(79,195,247,.35)" : "none";
      html +=
        '<div style="position:relative;width:30px;height:30px;border-radius:50%;border:1.5px solid ' +
        border +
        ";background:" +
        bg +
        ";display:flex;align-items:center;justify-content:center;overflow:hidden;box-shadow:" +
        shadow +
        ';">' +
        '<img src="' +
        CD.consIcons[i] +
        '" style="width:20px;height:20px;' +
        (on ? "" : "filter:grayscale(1);opacity:.25;") +
        '" onerror="this.style.display=\'none\'">' +
        (on
          ? ""
          : '<div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;"><svg width="11" height="13" viewBox="0 0 12 14" fill="none"><rect x="2" y="6" width="8" height="7" rx="1.5" fill="rgba(255,255,255,.3)"/><path d="M3.5 6V4.5a2.5 2.5 0 015 0V6" stroke="rgba(255,255,255,.3)" stroke-width="1.5" stroke-linecap="round"/></svg></div>') +
        "</div>";
    }
    return html;
  }

  // ── 技能行（3个主技能）──
  function skillsRow() {
    var typeColors = ["#9e9e9e", accent, "#9c27b0"];
    var html = '<div style="display:flex;gap:10px;">';
    for (var i = 0; i < 3; i++) {
      var s = CD.skills[i];
      var tc = typeColors[i];
      html +=
        '<div style="display:flex;flex-direction:column;align-items:center;gap:3px;width:50px;">' +
        '<div style="position:relative;">' +
        '<div style="width:42px;height:42px;border-radius:50%;border:2px solid ' +
        tc +
        ';background:rgba(0,0,0,.5);display:flex;align-items:center;justify-content:center;overflow:hidden;">' +
        '<img src="' +
        s.icon +
        '" style="width:30px;height:30px;" onerror="this.style.display=\'none\'">' +
        "</div>" +
        '<div style="position:absolute;bottom:-3px;right:-3px;background:' +
        tc +
        ';color:#fff;font-size:9px;font-weight:700;border-radius:7px;padding:1px 4px;min-width:16px;text-align:center;">' +
        s.lv +
        "</div>" +
        "</div>" +
        '<div style="font-size:8px;color:rgba(255,255,255,.5);text-align:center;">' +
        s.type +
        "</div>" +
        "</div>";
    }
    return html + "</div>";
  }

  // ── 英雄区 ──
  var hero =
    '<div style="height:' +
    heroH +
    "px;flex-shrink:0;position:relative;overflow:hidden;background:" +
    ec.bg +
    ';">' +
    '<div style="position:absolute;inset:0;background-image:url(' +
    CD.img +
    ');background-size:cover;background-position:center 20%;background-repeat:no-repeat;"></div>' +
    '<div style="position:absolute;inset:0;background:linear-gradient(to right,rgba(8,8,16,1) 0%,rgba(8,8,16,.95) 30%,rgba(8,8,16,.6) 55%,rgba(8,8,16,.1) 80%,transparent 100%)"></div>' +
    '<div style="position:absolute;inset:0;background:linear-gradient(to top,rgba(8,8,16,1) 0%,rgba(8,8,16,.5) 20%,transparent 45%)"></div>' +
    // 命座列：左侧竖排，顶部对齐，和星铁/绝区零一致
    '<div style="position:absolute;left:12px;top:14px;display:flex;flex-direction:column;gap:6px;z-index:3;">' +
    consCol() +
    "</div>" +
    // 角色信息：左下角
    '<div style="position:absolute;left:12px;bottom:12px;z-index:2;max-width:65%;">' +
    '<div style="font-size:24px;font-weight:800;color:#fff;text-shadow:0 2px 12px rgba(0,0,0,.95);letter-spacing:.5px;">' +
    CD.name +
    "</div>" +
    '<div style="margin-top:6px;display:flex;align-items:center;gap:6px;flex-wrap:wrap;justify-content:flex-end;">' +
    '<span style="font-size:12px;color:rgba(255,255,255,.75);background:rgba(0,0,0,.45);padding:2px 8px;border-radius:6px;">Lv.' +
    CD.level +
    "</span>" +
    '<span style="font-size:10px;padding:2px 7px;border-radius:6px;background:rgba(79,195,247,.15);color:' +
    accent +
    ";border:1px solid " +
    accent +
    '44;">好感 ' +
    CD.fetter +
    "</span>" +
    "</div>" +
    "</div>" +
    "</div>";

  // ── 武器 ──
  function wpnSection() {
    if (noWpn) {
      return (
        '<div style="background:' +
        c.card +
        ";border:1px dashed " +
        c.border +
        ';border-radius:10px;padding:14px;display:flex;align-items:center;justify-content:center;gap:8px;">' +
        '<svg width="16" height="18" viewBox="0 0 12 14" fill="none"><rect x="2" y="6" width="8" height="7" rx="1.5" fill="rgba(255,255,255,.3)"/><path d="M3.5 6V4.5a2.5 2.5 0 015 0V6" stroke="rgba(255,255,255,.3)" stroke-width="1.5" stroke-linecap="round"/></svg>' +
        '<span style="font-size:13px;color:' +
        c.sub +
        ';">未装备武器</span>' +
        "</div>"
      );
    }
    var w2 = CD.wpn;
    return (
      '<div style="background:' +
      c.card +
      ";border:1px solid " +
      c.border +
      ';border-radius:10px;padding:10px;display:flex;align-items:center;gap:10px;">' +
      '<img src="' +
      w2.icon +
      '" style="width:52px;height:52px;border-radius:8px;background:#1a1a2e;flex-shrink:0;" onerror="this.style.background=\'#2a2a3a\'">' +
      '<div style="flex:1;">' +
      '<div style="font-size:13px;font-weight:700;color:' +
      c.text +
      ';">' +
      w2.name +
      "</div>" +
      '<div style="font-size:11px;color:' +
      c.sub +
      ';margin-top:2px;">Lv.' +
      w2.lv +
      " · 精炼 " +
      w2.af +
      " · " +
      w2.stars +
      "★</div>" +
      '<div style="font-size:11px;color:' +
      c.gold +
      ';margin-top:2px;">基础攻击力 ' +
      w2.atk +
      " · " +
      w2.subLabel +
      " " +
      w2.subVal +
      "</div>" +
      "</div>" +
      "</div>"
    );
  }

  // ── 属性 ──
  var propsData = [
    { name: "生命值", val: CD.hp.toLocaleString(), hi: false },
    { name: "攻击力", val: CD.atk.toLocaleString(), hi: false },
    { name: "防御力", val: CD.def, hi: false },
    { name: "暴击率", val: CD.cr + "%", hi: true },
    { name: "暴击伤害", val: CD.cd + "%", hi: true },
    { name: "元素精通", val: CD.em, hi: false },
    { name: "元素充能", val: CD.er + "%", hi: false },
    { name: "治疗加成", val: CD.heal + "%", hi: false },
  ];
  var propsHtml = propsData
    .map(function (p) {
      return (
        '<div style="display:flex;justify-content:space-between;align-items:center;padding:5px 0;border-bottom:1px solid ' +
        c.border +
        ';">' +
        '<span style="font-size:12px;color:' +
        c.sub +
        ';">' +
        p.name +
        "</span>" +
        '<span style="font-size:12px;font-weight:600;color:' +
        (p.hi ? accent : c.text) +
        ';">' +
        p.val +
        "</span>" +
        "</div>"
      );
    })
    .join("");

  // ── 圣遗物 ──
  function relicCard(r) {
    var subs = r.s
      .map(function (s) {
        return (
          '<span style="font-size:9px;background:rgba(255,255,255,.06);border-radius:3px;padding:1px 4px;color:' +
          c.sub +
          ';">' +
          s[0] +
          ' <b style="color:' +
          c.text +
          ';">' +
          s[1] +
          "</b></span>"
        );
      })
      .join("");
    return (
      '<div style="background:' +
      c.card +
      ";border:1px solid " +
      c.border +
      ';border-radius:10px;padding:9px;display:flex;flex-direction:column;gap:5px;">' +
      '<div style="display:flex;align-items:center;gap:7px;">' +
      '<div style="width:34px;height:34px;border-radius:6px;background:#1a1a2e;display:flex;align-items:center;justify-content:center;overflow:hidden;flex-shrink:0;">' +
      '<img src="' +
      r.icon +
      '" style="width:30px;height:30px;" onerror="this.style.display=\'none\'">' +
      "</div>" +
      '<div style="flex:1;min-width:0;">' +
      '<div style="font-size:10px;color:' +
      c.text +
      ';font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">' +
      r.name +
      "</div>" +
      '<div style="font-size:10px;color:' +
      accent +
      ';">+' +
      r.lv +
      " · " +
      r.mnLabel +
      " " +
      r.mv +
      "</div>" +
      "</div>" +
      "</div>" +
      '<div style="display:flex;flex-wrap:wrap;gap:2px;">' +
      subs +
      "</div>" +
      "</div>"
    );
  }

  function emptyRelicCard(label) {
    return (
      '<div style="background:' +
      c.card +
      ";border:1px dashed " +
      c.border +
      ';border-radius:10px;padding:9px;display:flex;align-items:center;justify-content:center;gap:6px;min-height:72px;">' +
      '<svg width="14" height="16" viewBox="0 0 12 14" fill="none"><rect x="2" y="6" width="8" height="7" rx="1.5" fill="rgba(255,255,255,.3)"/><path d="M3.5 6V4.5a2.5 2.5 0 015 0V6" stroke="rgba(255,255,255,.3)" stroke-width="1.5" stroke-linecap="round"/></svg>' +
      '<span style="font-size:11px;color:' +
      c.sub +
      ';">' +
      label +
      "</span>" +
      "</div>"
    );
  }

  function relicsSection() {
    if (noRelics) {
      var labels = ["生之花", "死之羽", "时之沙", "空之杯", "理之冠"];
      return (
        '<div style="display:grid;grid-template-columns:1fr 1fr;gap:7px;">' +
        labels
          .map(function (l) {
            return emptyRelicCard(l);
          })
          .join("") +
        "</div>"
      );
    }
    return (
      '<div style="display:grid;grid-template-columns:1fr 1fr;gap:7px;">' +
      CD.relics.map(relicCard).join("") +
      "</div>"
    );
  }

  function section(title, content) {
    return (
      '<div style="margin-bottom:10px;">' +
      '<div style="font-size:11px;font-weight:700;color:' +
      c.sub +
      ';letter-spacing:.5px;margin-bottom:6px;padding-left:2px;">' +
      title +
      "</div>" +
      content +
      "</div>"
    );
  }

  var contentBody =
    '<div style="padding:12px;">' +
    section(
      "技能",
      (function () {
        var typeColors = ["#9e9e9e", accent, "#9c27b0"];
        var html =
          '<div style="background:' +
          c.card +
          ";border:1px solid " +
          c.border +
          ';border-radius:10px;padding:10px 12px;">';
        for (var i = 0; i < 3; i++) {
          var s = CD.skills[i];
          var tc = typeColors[i];
          html +=
            '<div style="display:flex;align-items:center;justify-content:space-between;padding:6px 0;border-bottom:1px solid ' +
            c.border +
            ';">' +
            '<div style="display:flex;align-items:center;gap:8px;min-width:0;flex:1;">' +
            '<img src="' +
            s.icon +
            '" style="width:28px;height:28px;border-radius:50%;border:1.5px solid ' +
            tc +
            '66;background:rgba(0,0,0,.4);flex-shrink:0;" onerror="this.style.display=\'none\'">' +
            '<span style="font-size:12px;color:' +
            c.text +
            ';white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">' +
            s.name +
            "</span>" +
            "</div>" +
            '<span style="font-size:12px;font-weight:700;color:' +
            tc +
            ';background:rgba(255,255,255,.06);border-radius:5px;padding:2px 8px;flex-shrink:0;">Lv.' +
            s.lv +
            "</span>" +
            "</div>";
        }
        return html + "</div>";
      })(),
    ) +
    section("武器", wpnSection()) +
    section(
      "属性",
      '<div style="background:' +
        c.card +
        ";border:1px solid " +
        c.border +
        ';border-radius:10px;padding:10px 12px;">' +
        propsHtml +
        "</div>",
    ) +
    section("圣遗物", relicsSection()) +
    "</div>";

  // 整个页面（英雄区 + 内容区）一起滚动
  return (
    '<div style="width:' +
    w +
    "px;height:" +
    h +
    "px;background:" +
    c.bg +
    ";font-family:'PingFang SC',sans-serif;overflow-y:auto;overflow-x:hidden;scrollbar-width:thin;scrollbar-color:rgba(255,255,255,.15) transparent;\">" +
    hero +
    contentBody +
    "</div>"
  );
}

function cdRenderPL(w, h) {
  var ec = ELEM_COLORS[CD.element] || ELEM_COLORS.hydro;
  var hero =
    '<div style="width:200px;flex-shrink:0;position:relative;overflow:hidden;background:' +
    ec.bg +
    '">' +
    '<div style="position:absolute;inset:0;background-image:url(' +
    CD.img +
    ');background-size:cover;background-position:50% 20%;background-repeat:no-repeat;"></div>' +
    '<div style="position:absolute;inset:0;background:linear-gradient(to top,rgba(8,8,16,1) 0%,rgba(8,8,16,.6) 35%,transparent 65%)"></div>' +
    '<div style="position:absolute;inset:0;background:linear-gradient(to right,rgba(8,8,16,.3) 0%,transparent 50%)"></div>' +
    // 命座列：左侧竖排
    '<div style="position:absolute;left:8px;top:12px;display:flex;flex-direction:column;gap:5px;z-index:3">' +
    cdConsCol() +
    "</div>" +
    '<div style="position:absolute;left:10px;bottom:10px;z-index:2;max-width:calc(100% - 20px)">' +
    '<div style="font-size:15px;font-weight:800;color:#fff;text-shadow:0 2px 8px rgba(0,0,0,.95)">' +
    CD.name +
    "</div>" +
    '<div style="font-size:10px;color:rgba(255,255,255,.7);margin-top:3px;background:rgba(0,0,0,.4);display:inline-block;padding:1px 6px;border-radius:4px;">Lv.' +
    CD.level +
    "</div>" +
    '<div style="display:flex;gap:6px;margin-top:6px">' +
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
    '<div style="position:absolute;inset:0;background-image:url(' +
    CD.img +
    ');background-size:cover;background-position:50% 20%;background-repeat:no-repeat;"></div>' +
    '<div style="position:absolute;inset:0;background:linear-gradient(to bottom,rgba(0,0,0,.55) 0%,transparent 35%,transparent 55%,rgba(0,0,0,.75) 100%)"></div>' +
    // 角色名：左上角
    '<div style="position:absolute;left:12px;top:12px;z-index:2">' +
    '<div style="font-size:18px;font-weight:800;color:#fff;text-shadow:0 2px 8px rgba(0,0,0,.9)">' +
    CD.name +
    "</div>" +
    '<div style="font-size:11px;color:rgba(255,255,255,.7);margin-top:4px;background:rgba(0,0,0,.4);display:inline-block;padding:1px 6px;border-radius:4px;">Lv.' +
    CD.level +
    "/" +
    CD.maxLevel +
    "</div>" +
    '<div style="font-size:11px;color:' +
    accent +
    ';margin-top:4px">好感 ' +
    CD.fetter +
    "</div></div>" +
    // 命座列：左下角竖排
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
  if (!window._cdCtrl)
    window._cdCtrl = { cd_no_wpn: false, cd_no_relics: false, cd_cons0: false };
  return [
    {
      id: "cd_no_wpn",
      label: "武器",
      options: [
        { value: "on", label: "有" },
        { value: "off", label: "无" },
      ],
      current: function () {
        return window._cdCtrl.cd_no_wpn ? "off" : "on";
      },
      onChange: function (v) {
        window._cdCtrl.cd_no_wpn = v === "off";
      },
    },
    {
      id: "cd_no_relics",
      label: "圣遗物",
      options: [
        { value: "on", label: "有" },
        { value: "off", label: "无" },
      ],
      current: function () {
        return window._cdCtrl.cd_no_relics ? "off" : "on";
      },
      onChange: function (v) {
        window._cdCtrl.cd_no_relics = v === "off";
      },
    },
    {
      id: "cd_cons",
      label: "命座",
      options: [
        { value: "6", label: "6命" },
        { value: "0", label: "0命" },
      ],
      current: function () {
        return window._cdCtrl.cd_cons0 ? "0" : "6";
      },
      onChange: function (v) {
        window._cdCtrl.cd_cons0 = v === "0";
      },
    },
  ];
}

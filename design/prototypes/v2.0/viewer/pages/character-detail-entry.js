/**
 * character-detail-entry.js — 角色详情页入口示例（原神）
 * 
 * 复用 v1.0 角色详情页结构，在内容区新增「材料计算」入口卡片
 * 展示如何从角色详情页进入材料计算功能
 */

// ── 元素色映射（与 v1.0 char-detail.js 一致）──
var ELEM_COLORS_ENTRY = {
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

// ── 角色数据（复用 v1.0 CD 数据结构）──
var CD_ENTRY = {
  name: "甘雨",
  title: "循循守月",
  level: 90,
  maxLevel: 90,
  fetter: 10,
  element: "cryo",
  hp: 36086,
  atk: 1454,
  def: 723,
  cr: 18.6,
  cd: 176.0,
  em: 239,
  er: 100.0,
  img: "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/image_7/22cc7ea21f71c28edafe88c68a63d9aa.png",
  icon: "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f6c8/b30987d539b299dc89004d72274f5e89.png",
  wpn: {
    name: "阿莫斯之弓",
    lv: 90,
    af: 1,
    atk: 542,
    subLabel: "攻击力",
    subVal: "49.6%",
    stars: 5,
    icon: "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f6c8/2e5e66807c6c65eea1918ce6465cdc74.png",
  },
  skills: [
    {
      name: "流天射术",
      lv: 10,
      type: "普攻",
      icon: "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f71a/2c014e6053c4f0d032e1d1ff0c6de0e1.png",
    },
    {
      name: "山泽麟迹",
      lv: 10,
      type: "元素战技",
      icon: "https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f71a/32948454e19c2743c0765c7072934b43.png",
    },
    {
      name: "降众天华",
      lv: 10,
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
};

/** 渲染角色详情页（完整版，含材料计算入口） */
function renderCharacterDetailEntry(w, h) {
  var c = T();
  var ec = ELEM_COLORS_ENTRY[CD_ENTRY.element] || ELEM_COLORS_ENTRY.cryo;
  var accent = ec.accent;
  var heroH = Math.min(320, Math.max(240, h * 0.42));

  // ── 命座列 ──
  function consCol() {
    var html = "";
    for (var i = 0; i < CD_ENTRY.cons.length; i++) {
      var on = CD_ENTRY.cons[i];
      var bg = on ? "rgba(179,229,252,.25)" : "rgba(0,0,0,.55)";
      var border = on ? "rgba(179,229,252,.8)" : "rgba(255,255,255,.12)";
      var shadow = on ? "0 0 8px rgba(179,229,252,.35)" : "none";
      html +=
        '<div style="position:relative;width:30px;height:30px;border-radius:50%;border:1.5px solid ' +
        border +
        ";background:" +
        bg +
        ";display:flex;align-items:center;justify-content:center;overflow:hidden;box-shadow:" +
        shadow +
        ';">' +
        '<img src="' +
        CD_ENTRY.consIcons[i] +
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

  // ── 英雄区（立绘 + 命座 + 角色信息）──
  var hero =
    '<div style="height:' +
    heroH +
    "px;flex-shrink:0;position:relative;overflow:hidden;background:" +
    ec.bg +
    ';">' +
    '<div style="position:absolute;inset:0;background-image:url(' +
    CD_ENTRY.img +
    ');background-size:cover;background-position:center 20%;background-repeat:no-repeat;"></div>' +
    '<div style="position:absolute;inset:0;background:linear-gradient(to right,rgba(8,8,16,1) 0%,rgba(8,8,16,.95) 30%,rgba(8,8,16,.6) 55%,rgba(8,8,16,.1) 80%,transparent 100%)"></div>' +
    '<div style="position:absolute;inset:0;background:linear-gradient(to top,rgba(8,8,16,1) 0%,rgba(8,8,16,.5) 20%,transparent 45%)"></div>' +
    // 命座列：左侧竖排
    '<div style="position:absolute;left:12px;top:14px;display:flex;flex-direction:column;gap:6px;z-index:3;">' +
    consCol() +
    "</div>" +
    // 角色信息：左下角
    '<div style="position:absolute;left:12px;bottom:12px;z-index:2;max-width:65%;">' +
    '<div style="font-size:24px;font-weight:800;color:#fff;text-shadow:0 2px 12px rgba(0,0,0,.95);letter-spacing:.5px;">' +
    CD_ENTRY.name +
    "</div>" +
    '<div style="margin-top:6px;display:flex;align-items:center;gap:6px;flex-wrap:wrap;">' +
    '<span style="font-size:12px;color:rgba(255,255,255,.75);background:rgba(0,0,0,.45);padding:2px 8px;border-radius:6px;">Lv.' +
    CD_ENTRY.level +
    "</span>" +
    '<span style="font-size:10px;padding:2px 7px;border-radius:6px;background:rgba(179,229,252,.15);color:' +
    accent +
    ";border:1px solid " +
    accent +
    '44;">好感 ' +
    CD_ENTRY.fetter +
    "</span>" +
    "</div>" +
    "</div>" +
    "</div>";

  // ── 技能区 ──
  function skillsSection() {
    var typeColors = ["#9e9e9e", accent, "#9c27b0"];
    var html =
      '<div style="background:' +
      c.surfCard +
      ";border:1px solid " +
      c.div +
      ';border-radius:10px;padding:10px 12px;">';
    for (var i = 0; i < 3; i++) {
      var s = CD_ENTRY.skills[i];
      var tc = typeColors[i];
      html +=
        '<div style="display:flex;align-items:center;justify-content:space-between;padding:6px 0;border-bottom:1px solid ' +
        c.div +
        ';">' +
        '<div style="display:flex;align-items:center;gap:8px;min-width:0;flex:1;">' +
        '<img src="' +
        s.icon +
        '" style="width:28px;height:28px;border-radius:50%;border:1.5px solid ' +
        tc +
        '66;background:rgba(0,0,0,.4);flex-shrink:0;" onerror="this.style.display=\'none\'">' +
        '<span style="font-size:12px;color:' +
        c.txt +
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
  }

  // ── 武器区 ──
  function wpnSection() {
    var w = CD_ENTRY.wpn;
    return (
      '<div style="background:' +
      c.surfCard +
      ";border:1px solid " +
      c.div +
      ';border-radius:10px;padding:10px;display:flex;align-items:center;gap:10px;">' +
      '<img src="' +
      w.icon +
      '" style="width:52px;height:52px;border-radius:8px;background:#1a1a2e;flex-shrink:0;" onerror="this.style.background=\'#2a2a3a\'">' +
      '<div style="flex:1;">' +
      '<div style="font-size:13px;font-weight:700;color:' +
      c.txt +
      ';">' +
      w.name +
      "</div>" +
      '<div style="font-size:11px;color:' +
      c.txt2 +
      ';margin-top:2px;">Lv.' +
      w.lv +
      " · 精炼 " +
      w.af +
      " · " +
      w.stars +
      "★</div>" +
      '<div style="font-size:11px;color:' +
      c.gold +
      ';margin-top:2px;">基础攻击力 ' +
      w.atk +
      " · " +
      w.subLabel +
      " " +
      w.subVal +
      "</div>" +
      "</div>" +
      "</div>"
    );
  }

  // ── 属性区 ──
  var propsData = [
    { name: "生命值", val: CD_ENTRY.hp.toLocaleString(), hi: false },
    { name: "攻击力", val: CD_ENTRY.atk.toLocaleString(), hi: false },
    { name: "防御力", val: CD_ENTRY.def, hi: false },
    { name: "暴击率", val: CD_ENTRY.cr + "%", hi: true },
    { name: "暴击伤害", val: CD_ENTRY.cd + "%", hi: true },
    { name: "元素精通", val: CD_ENTRY.em, hi: false },
    { name: "元素充能", val: CD_ENTRY.er + "%", hi: false },
  ];
  var propsHtml = propsData
    .map(function (p) {
      return (
        '<div style="display:flex;justify-content:space-between;align-items:center;padding:5px 0;border-bottom:1px solid ' +
        c.div +
        ';">' +
        '<span style="font-size:12px;color:' +
        c.txt2 +
        ';">' +
        p.name +
        "</span>" +
        '<span style="font-size:12px;font-weight:600;color:' +
        (p.hi ? accent : c.txt) +
        ';">' +
        p.val +
        "</span>" +
        "</div>"
      );
    })
    .join("");

  // ── 材料计算入口卡片（新增）──
  function materialCalcEntry() {
    return (
      '<div onclick="alert(\'跳转到材料计算页\')" style="background:' +
      c.surfCard +
      ";border:1px solid " +
      c.div +
      ';border-radius:10px;padding:12px;display:flex;align-items:center;gap:12px;cursor:pointer;transition:transform .15s,box-shadow .15s;" onmouseover="this.style.transform=\'scale(1.02)\';this.style.boxShadow=\'0 4px 20px rgba(77,163,255,.15)\'" onmouseout="this.style.transform=\'scale(1)\';this.style.boxShadow=\'none\'">' +
      '<div style="width:44px;height:44px;border-radius:10px;background:' +
      c.priBg +
      ';display:flex;align-items:center;justify-content:center;font-size:22px;flex-shrink:0;">📊</div>' +
      '<div style="flex:1;">' +
      '<div style="font-size:14px;font-weight:600;color:' +
      c.txt +
      ';">材料计算</div>' +
      '<div style="font-size:12px;color:' +
      c.txt2 +
      ';margin-top:2px;">计算养成所需材料数量</div>' +
      "</div>" +
      '<div style="font-size:18px;color:' +
      c.txtM +
      ';">›</div>' +
      "</div>"
    );
  }

  function section(title, content) {
    return (
      '<div style="margin-bottom:10px;">' +
      '<div style="font-size:11px;font-weight:700;color:' +
      c.txt2 +
      ';letter-spacing:.5px;margin-bottom:6px;padding-left:2px;">' +
      title +
      "</div>" +
      content +
      "</div>"
    );
  }

  var contentBody =
    '<div style="padding:12px;">' +
    section("技能", skillsSection()) +
    section("武器", wpnSection()) +
    section(
      "属性",
      '<div style="background:' +
        c.surfCard +
        ";border:1px solid " +
        c.div +
        ';border-radius:10px;padding:10px 12px;">' +
        propsHtml +
        "</div>"
    ) +
    // 🔑 材料计算入口卡片（新增）
    section("操作", materialCalcEntry()) +
    "</div>";

  return (
    '<div style="width:' + w + 'px;height:' + h + 'px;background:' + c.pageBg + ';font-family:PingFang SC,sans-serif;overflow-y:auto;overflow-x:hidden;scrollbar-width:thin;scrollbar-color:rgba(255,255,255,.15) transparent;">' +
    hero +
    contentBody +
    '</div>'
  );
}

/** 控制项（无） */
function characterDetailEntryControls() {
  return [];
}

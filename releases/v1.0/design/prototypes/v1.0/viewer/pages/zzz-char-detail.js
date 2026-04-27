// ── 绝区零角色详情原型 ──────────────────────────────────────

var zzzCharDetailControls = function () {
  if (!window._zzzCtrl)
    window._zzzCtrl = {
      zzz_no_weapon: false,
      zzz_no_equip: false,
      zzz_rank0: false,
    };
  return [
    {
      id: "zzz_no_weapon",
      label: "音擎",
      options: [
        { value: "on", label: "有" },
        { value: "off", label: "无" },
      ],
      current: function () {
        return window._zzzCtrl.zzz_no_weapon ? "off" : "on";
      },
      onChange: function (v) {
        window._zzzCtrl.zzz_no_weapon = v === "off";
      },
    },
    {
      id: "zzz_no_equip",
      label: "驱动盘",
      options: [
        { value: "on", label: "有" },
        { value: "off", label: "无" },
      ],
      current: function () {
        return window._zzzCtrl.zzz_no_equip ? "off" : "on";
      },
      onChange: function (v) {
        window._zzzCtrl.zzz_no_equip = v === "off";
      },
    },
    {
      id: "zzz_rank",
      label: "影画",
      options: [
        { value: "6", label: "6影" },
        { value: "0", label: "0影" },
      ],
      current: function () {
        return window._zzzCtrl.zzz_rank0 ? "0" : "6";
      },
      onChange: function (v) {
        window._zzzCtrl.zzz_rank0 = v === "0";
      },
    },
  ];
};

var ZZZ_CHAR = {
  id: 1171,
  name: "柏妮思",
  fullName: "柏妮思·怀特",
  rarity: "S",
  level: 60,
  element_type: 201, // 火
  avatar_profession: 3, // 异常
  rank: 6, // 默认展示6影画，控制项可切换到0影
  verticalUrl:
    "https://act-webstatic.mihoyo.com/game_record/zzzv2/role_vertical_painting/role_vertical_painting_1171.png",
  squareUrl:
    "https://act-webstatic.mihoyo.com/game_record/zzzv2/role_square_avatar/role_square_avatar_1171.png",
  color: "#da8837",
  weapon: {
    name: "灼心摇壶",
    level: 60,
    star: 1,
    rarity: "S",
    icon: "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u5efkd/96df0c8f8654e722b940ba9cb36dae15.png",
    talentTitle: "焦油斟注",
    mainProp: { name: "基础攻击力", value: "713" },
    subProp: { name: "攻击力", value: "30%" },
  },
  equip: [
    {
      pos: 1,
      name: "混沌爵士[1]",
      rarity: "S",
      level: 15,
      suitName: "混沌爵士",
      suitOwn: 4,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u5efkd/836682257edea6822bbe06dd5e360779.png",
      main: { name: "生命值", value: "2200" },
      subs: [
        { name: "异常精通", value: "27", valid: true },
        { name: "暴击伤害", value: "4.8%", valid: false },
        { name: "穿透值", value: "9", valid: false },
        { name: "防御力", value: "14.4%", valid: false },
      ],
    },
    {
      pos: 2,
      name: "混沌爵士[2]",
      rarity: "S",
      level: 15,
      suitName: "混沌爵士",
      suitOwn: 4,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u5efkd/836682257edea6822bbe06dd5e360779.png",
      main: { name: "攻击力", value: "316" },
      subs: [
        { name: "暴击伤害", value: "9.6%", valid: false },
        { name: "生命值", value: "224", valid: false },
        { name: "异常精通", value: "9", valid: true },
        { name: "防御力", value: "45", valid: false },
      ],
    },
    {
      pos: 3,
      name: "激素朋克[3]",
      rarity: "S",
      level: 15,
      suitName: "激素朋克",
      suitOwn: 2,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u5efkd/e319a2dbdb455559fcf3d5e97073acb3.png",
      main: { name: "防御力", value: "184" },
      subs: [
        { name: "暴击伤害", value: "4.8%", valid: false },
        { name: "暴击率", value: "7.2%", valid: false },
        { name: "防御力", value: "14.4%", valid: false },
        { name: "攻击力", value: "38", valid: false },
      ],
    },
    {
      pos: 4,
      name: "混沌爵士[4]",
      rarity: "S",
      level: 15,
      suitName: "混沌爵士",
      suitOwn: 4,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u5efkd/836682257edea6822bbe06dd5e360779.png",
      main: { name: "异常精通", value: "92" },
      subs: [
        { name: "防御力", value: "9.6%", valid: false },
        { name: "攻击力%", value: "9%", valid: true },
        { name: "生命值", value: "224", valid: false },
        { name: "穿透值", value: "18", valid: false },
      ],
    },
    {
      pos: 5,
      name: "激素朋克[5]",
      rarity: "S",
      level: 15,
      suitName: "激素朋克",
      suitOwn: 2,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u5efkd/e319a2dbdb455559fcf3d5e97073acb3.png",
      main: { name: "火属性伤害加成", value: "30%" },
      subs: [
        { name: "生命值%", value: "9%", valid: false },
        { name: "异常精通", value: "9", valid: true },
        { name: "攻击力%", value: "9%", valid: true },
        { name: "防御力", value: "4.8%", valid: false },
      ],
    },
    {
      pos: 6,
      name: "混沌爵士[6]",
      rarity: "S",
      level: 15,
      suitName: "混沌爵士",
      suitOwn: 4,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/nap/prod_gf_cn/item_icon_u5efkd/836682257edea6822bbe06dd5e360779.png",
      main: { name: "异常掌控", value: "30%" },
      subs: [
        { name: "生命值%", value: "3%", valid: false },
        { name: "攻击力%", value: "6%", valid: true },
        { name: "防御力", value: "9.6%", valid: false },
        { name: "攻击力", value: "57", valid: false },
      ],
    },
  ],
  skills: [
    { type: 0, name: "普通攻击：炽焰直调式", level: 11 },
    { type: 1, name: "特殊技：灼热熟成法", level: 11 },
    { type: 2, name: "闪避：焰影疾行", level: 11 },
    { type: 3, name: "连携技：燃油熔焰", level: 11 },
    { type: 5, name: "核心被动：燃油特调", level: 6 },
    { type: 6, name: "快速支援：提神特饮", level: 11 },
  ],
  ranks: [
    { pos: 1, name: "热络同心" },
    { pos: 2, name: "加量不加价" },
    { pos: 3, name: "天性乐观" },
    { pos: 4, name: "超绝燃油补给" },
    { pos: 5, name: "火与冰之舞" },
    { pos: 6, name: "盛焰邀约" },
  ],
  properties: [
    { name: "生命值", final: "10901" },
    { name: "攻击力", final: "2954" },
    { name: "防御力", final: "1145" },
    { name: "冲击力", final: "83" },
    { name: "暴击率", final: "12.2%" },
    { name: "暴击伤害", final: "69.2%" },
    { name: "异常掌控", final: "153" },
    { name: "异常精通", final: "287" },
    { name: "穿透率", final: "0.0%" },
    { name: "能量自动回复", final: "1.56" },
    { name: "穿透值", final: "27" },
    { name: "火属性伤害加成", final: "30.0%" },
  ],
};

function renderZzzCharDetail(w, h) {
  var c = {
    bg: "#080810",
    card: "#111118",
    border: "#2a2a3a",
    text: "#e8e8f0",
    sub: "#888",
    primary: "#3a6fd8",
    gold: "#ffca28",
    zzz: "#f7b84b",
  };
  var char = ZZZ_CHAR;
  var accentColor = char.color || "#f7b84b";

  // 元素力背景渐变映射
  var ZZZ_ELEM_BG = {
    200: "linear-gradient(150deg,#1a1a1a,#080808)", // 物理
    201: "linear-gradient(150deg,#3a1008,#180808)", // 火
    202: "linear-gradient(150deg,#0a2a3a,#041018)", // 冰
    203: "linear-gradient(150deg,#2a1040,#100818)", // 电
    205: "linear-gradient(150deg,#2a0a30,#100410)", // 以太
  };
  var elemBg =
    ZZZ_ELEM_BG[char.element_type] || "linear-gradient(150deg,#1a1a2a,#0e0e18)";

  // 控制项状态
  var noWeapon = window._zzzCtrl && window._zzzCtrl.zzz_no_weapon;
  var noEquip = window._zzzCtrl && window._zzzCtrl.zzz_no_equip;
  var rank0 = window._zzzCtrl && window._zzzCtrl.zzz_rank0;
  var activeRank = rank0 ? 0 : char.rank;

  // ── 影画列（左侧竖排）──
  function rankCol() {
    var h = "";
    for (var i = 0; i < char.ranks.length; i++) {
      var unlocked = i < activeRank;
      var bg = unlocked ? "rgba(247,184,75,.25)" : "rgba(0,0,0,.55)";
      var border = unlocked ? "rgba(247,184,75,.8)" : "rgba(255,255,255,.12)";
      var shadow = unlocked ? "0 0 8px rgba(247,184,75,.35)" : "none";
      h +=
        '<div style="width:28px;height:28px;border-radius:6px;border:1.5px solid ' +
        border +
        ";background:" +
        bg +
        ";display:flex;align-items:center;justify-content:center;box-shadow:" +
        shadow +
        ';">' +
        (unlocked
          ? '<span style="font-size:12px;font-weight:800;color:' +
            c.zzz +
            ';">' +
            (i + 1) +
            "</span>"
          : '<svg width="11" height="13" viewBox="0 0 12 14" fill="none"><rect x="2" y="6" width="8" height="7" rx="1.5" fill="rgba(255,255,255,.3)"/><path d="M3.5 6V4.5a2.5 2.5 0 015 0V6" stroke="rgba(255,255,255,.3)" stroke-width="1.5" stroke-linecap="round"/></svg>') +
        "</div>";
    }
    return h;
  }

  // ── 立绘英雄区 ──
  var heroH = Math.min(320, Math.max(240, h * 0.42));
  var heroHtml =
    '<div style="height:' +
    heroH +
    "px;flex-shrink:0;position:relative;overflow:hidden;background:" +
    elemBg +
    ';">' +
    // 立绘独立 div，background-image 不受 shorthand 解析影响
    '<div style="position:absolute;inset:0;background-image:url(' +
    char.verticalUrl +
    ');background-size:cover;background-position:50% 15%;background-repeat:no-repeat;"></div>' +
    // 角色主题色光晕
    '<div style="position:absolute;inset:0;background:radial-gradient(ellipse at 75% 30%,' +
    accentColor +
    '28 0%,transparent 55%);pointer-events:none;"></div>' +
    // 左侧强渐变
    '<div style="position:absolute;inset:0;background:linear-gradient(to right,rgba(8,8,16,1) 0%,rgba(8,8,16,.95) 32%,rgba(8,8,16,.55) 58%,rgba(8,8,16,.05) 80%,transparent 100%);"></div>' +
    // 底部渐变
    '<div style="position:absolute;inset:0;background:linear-gradient(to top,rgba(8,8,16,1) 0%,rgba(8,8,16,.4) 22%,transparent 45%);"></div>' +
    // 影画列：左侧竖排，顶部对齐
    '<div style="position:absolute;left:12px;top:14px;display:flex;flex-direction:column;gap:6px;z-index:3;">' +
    rankCol() +
    "</div>" +
    // 角色信息：左下角
    '<div style="position:absolute;left:12px;bottom:14px;z-index:2;max-width:60%;">' +
    '<div style="font-size:24px;font-weight:800;color:#fff;text-shadow:0 2px 12px rgba(0,0,0,.95);letter-spacing:.5px;">' +
    char.name +
    "</div>" +
    '<div style="font-size:11px;color:rgba(255,255,255,.45);margin-top:2px;letter-spacing:.3px;">' +
    char.fullName +
    "</div>" +
    '<div style="display:flex;align-items:center;gap:6px;margin-top:7px;flex-wrap:wrap;">' +
    '<span style="font-size:12px;color:rgba(255,255,255,.75);background:rgba(0,0,0,.45);padding:2px 8px;border-radius:6px;">Lv.' +
    char.level +
    "</span>" +
    '<span style="font-size:11px;padding:2px 8px;border-radius:6px;background:rgba(247,184,75,.2);color:' +
    c.zzz +
    ';border:1px solid rgba(247,184,75,.4);">' +
    char.rarity +
    "级</span>" +
    '<span style="font-size:11px;padding:2px 8px;border-radius:6px;background:rgba(255,255,255,.08);color:' +
    c.sub +
    ';">' +
    activeRank +
    "影画</span>" +
    "</div>" +
    "</div>" +
    "</div>";

  // ── 音擎 ──
  function weaponSection() {
    if (noWeapon) {
      return (
        '<div style="background:' +
        c.card +
        ";border:1px dashed " +
        c.border +
        ';border-radius:10px;padding:14px;display:flex;align-items:center;justify-content:center;gap:8px;">' +
        '<span style="font-size:20px;">🔒</span>' +
        '<span style="font-size:13px;color:' +
        c.sub +
        ';">未装备音擎</span>' +
        "</div>"
      );
    }
    var wep = char.weapon;
    return (
      '<div style="background:' +
      c.card +
      ";border:1px solid " +
      c.border +
      ';border-radius:10px;padding:10px;">' +
      '<div style="display:flex;align-items:center;gap:10px;">' +
      '<img src="' +
      wep.icon +
      '" style="width:52px;height:52px;border-radius:8px;background:#1a1a2e;flex-shrink:0;" onerror="this.style.background=\'#2a2a3a\'">' +
      '<div style="flex:1;">' +
      '<div style="font-size:13px;font-weight:700;color:' +
      c.text +
      ';">' +
      wep.name +
      "</div>" +
      '<div style="font-size:11px;color:' +
      c.sub +
      ';margin-top:2px;">Lv.' +
      wep.level +
      " · 精炼 " +
      wep.star +
      " · " +
      wep.rarity +
      "级</div>" +
      '<div style="font-size:11px;color:' +
      c.gold +
      ';margin-top:2px;">' +
      wep.mainProp.name +
      " " +
      wep.mainProp.value +
      " · " +
      wep.subProp.name +
      " " +
      wep.subProp.value +
      "</div>" +
      "</div>" +
      "</div>" +
      '<div style="margin-top:8px;padding:7px 8px;background:rgba(255,255,255,.04);border-radius:6px;">' +
      '<span style="font-size:11px;font-weight:600;color:' +
      c.zzz +
      ';">' +
      wep.talentTitle +
      "</span>" +
      "</div>" +
      "</div>"
    );
  }

  // ── 驱动盘卡片（与原神格式统一：图标+名称+强化等级 / 主词条名+值 / 副词条列表）──
  function equipCard(e) {
    var subsHtml = e.subs
      .map(function (s) {
        var nameColor = s.valid ? c.gold : c.sub;
        var valColor = s.valid ? c.gold : c.text;
        return (
          '<div style="display:flex;justify-content:space-between;align-items:center;padding:1px 0;">' +
          '<span style="font-size:10px;color:' +
          nameColor +
          ';">' +
          s.name +
          "</span>" +
          '<span style="font-size:10px;color:' +
          valColor +
          ';">' +
          s.value +
          "</span>" +
          "</div>"
        );
      })
      .join("");
    return (
      '<div style="background:rgba(255,255,255,.04);border:1px solid ' +
      c.border +
      ';border-radius:10px;padding:9px;display:flex;flex-direction:column;gap:5px;">' +
      // 顶部：图标 + 套装名 + 强化等级
      '<div style="display:flex;align-items:center;gap:6px;">' +
      '<img src="' +
      e.icon +
      '" style="width:32px;height:32px;border-radius:6px;background:#1a1a2e;flex-shrink:0;" onerror="this.style.background=\'#2a2a3a\'">' +
      '<span style="font-size:12px;font-weight:700;color:' +
      c.text +
      ';flex:1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">' +
      e.suitName +
      "</span>" +
      '<span style="font-size:10px;color:rgba(255,255,255,.3);background:rgba(255,255,255,.06);border-radius:4px;padding:1px 5px;">+' +
      e.level +
      "</span>" +
      "</div>" +
      // 主词条行
      '<div style="display:flex;justify-content:space-between;align-items:center;padding:2px 0;border-bottom:1px solid rgba(255,255,255,.08);">' +
      '<span style="font-size:10px;color:' +
      accentColor +
      ';">' +
      e.main.name +
      "</span>" +
      '<span style="font-size:13px;font-weight:700;color:' +
      c.text +
      ';">' +
      e.main.value +
      "</span>" +
      "</div>" +
      // 副词条列表（valid=true 金色高亮）
      subsHtml +
      "</div>"
    );
  }

  function emptyEquipCard(label) {
    return (
      '<div style="background:' +
      c.card +
      ";border:1px dashed " +
      c.border +
      ';border-radius:10px;padding:9px;display:flex;align-items:center;justify-content:center;gap:6px;min-height:72px;">' +
      '<span style="font-size:16px;">🔒</span>' +
      '<span style="font-size:11px;color:' +
      c.sub +
      ';">' +
      label +
      "</span>" +
      "</div>"
    );
  }

  function equipSection() {
    if (noEquip) {
      var labels = ["1号位", "2号位", "3号位", "4号位", "5号位", "6号位"];
      return (
        '<div style="display:grid;grid-template-columns:1fr 1fr;gap:7px;">' +
        labels
          .map(function (l) {
            return emptyEquipCard(l);
          })
          .join("") +
        "</div>"
      );
    }
    // 套装摘要
    var suitMap = {};
    char.equip.forEach(function (e) {
      if (!suitMap[e.suitName])
        suitMap[e.suitName] = { name: e.suitName, own: e.suitOwn, count: 0 };
      suitMap[e.suitName].count++;
    });
    var suits = Object.values(suitMap);
    var suitHtml =
      '<div style="background:' +
      c.card +
      ";border:1px solid " +
      c.border +
      ';border-radius:10px;padding:10px 12px;margin-bottom:7px;">' +
      suits
        .map(function (s) {
          var a2 = s.count >= 2,
            a4 = s.count >= 4;
          return (
            '<div style="display:flex;align-items:center;gap:6px;padding:4px 0;border-bottom:1px solid ' +
            c.border +
            ';">' +
            '<span style="font-size:11px;color:' +
            c.text +
            ';flex:1;">' +
            s.name +
            "</span>" +
            '<span style="font-size:10px;padding:1px 6px;border-radius:5px;background:' +
            (a2 ? "rgba(247,184,75,.15)" : "rgba(255,255,255,.04)") +
            ";color:" +
            (a2 ? c.zzz : c.sub) +
            ";border:1px solid " +
            (a2 ? "rgba(247,184,75,.3)" : "transparent") +
            ';">2件</span>' +
            (s.own >= 4
              ? '<span style="font-size:10px;padding:1px 6px;border-radius:5px;background:' +
                (a4 ? "rgba(247,184,75,.15)" : "rgba(255,255,255,.04)") +
                ";color:" +
                (a4 ? c.zzz : c.sub) +
                ";border:1px solid " +
                (a4 ? "rgba(247,184,75,.3)" : "transparent") +
                ';">4件</span>'
              : "") +
            '<span style="font-size:11px;font-weight:700;color:' +
            c.zzz +
            ';">' +
            s.count +
            "/" +
            s.own +
            "</span>" +
            "</div>"
          );
        })
        .join("") +
      "</div>";
    return (
      suitHtml +
      '<div style="display:grid;grid-template-columns:1fr 1fr;gap:7px;">' +
      char.equip.map(equipCard).join("") +
      "</div>"
    );
  }

  // ── 技能 ──
  function skillSection() {
    var typeNames = {
      0: "普攻",
      1: "特殊技",
      2: "闪避",
      3: "连携技",
      5: "核心被动",
      6: "支援技",
    };
    var typeColors = {
      0: "#9e9e9e",
      1: "#ef5350",
      2: "#4caf50",
      3: "#9c27b0",
      5: "#ff9800",
      6: "#3a6fd8",
    };
    return (
      '<div style="background:' +
      c.card +
      ";border:1px solid " +
      c.border +
      ';border-radius:10px;padding:10px 12px;">' +
      char.skills
        .map(function (s) {
          var tc = typeColors[s.type] || c.sub;
          return (
            '<div style="display:flex;align-items:center;justify-content:space-between;padding:6px 0;border-bottom:1px solid ' +
            c.border +
            ';">' +
            '<div style="display:flex;align-items:center;gap:8px;min-width:0;flex:1;">' +
            (s.icon
              ? '<img src="' +
                s.icon +
                '" style="width:28px;height:28px;border-radius:50%;border:1.5px solid ' +
                tc +
                '66;background:rgba(0,0,0,.4);flex-shrink:0;" onerror="this.style.display=\'none\'">'
              : '<div style="width:10px;height:10px;border-radius:50%;background:' +
                tc +
                ';flex-shrink:0;"></div>') +
            '<span style="font-size:12px;color:' +
            c.text +
            ';white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">' +
            s.name +
            "</span>" +
            "</div>" +
            '<span style="font-size:12px;font-weight:700;color:' +
            tc +
            ';background:rgba(255,255,255,.06);border-radius:5px;padding:2px 8px;flex-shrink:0;">Lv.' +
            s.level +
            "</span>" +
            "</div>"
          );
        })
        .join("") +
      "</div>"
    );
  }

  // ── 属性列表 ──
  var propsHtml = char.properties
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
        '<span style="font-size:12px;color:' +
        c.text +
        ';font-weight:600;">' +
        p.final +
        "</span>" +
        "</div>"
      );
    })
    .join("");

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
    section("技能", skillSection()) +
    section("音擎", weaponSection()) +
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
    section("驱动盘", equipSection()) +
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
    heroHtml +
    contentBody +
    "</div>"
  );
}

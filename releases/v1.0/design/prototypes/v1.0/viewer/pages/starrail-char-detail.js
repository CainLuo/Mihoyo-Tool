// ── 星穹铁道角色详情原型 ──────────────────────────────────────

var srCharDetailControls = function () {
  if (!window._srCtrl)
    window._srCtrl = {
      sr_no_equip: false,
      sr_no_relics: false,
      sr_rank0: false,
    };
  return [
    {
      id: "sr_no_equip",
      label: "光锥",
      options: [
        { value: "on", label: "有" },
        { value: "off", label: "无" },
      ],
      current: function () {
        return window._srCtrl.sr_no_equip ? "off" : "on";
      },
      onChange: function (v) {
        window._srCtrl.sr_no_equip = v === "off";
      },
    },
    {
      id: "sr_no_relics",
      label: "遗器",
      options: [
        { value: "on", label: "有" },
        { value: "off", label: "无" },
      ],
      current: function () {
        return window._srCtrl.sr_no_relics ? "off" : "on";
      },
      onChange: function (v) {
        window._srCtrl.sr_no_relics = v === "off";
      },
    },
    {
      id: "sr_rank",
      label: "命座",
      options: [
        { value: "6", label: "6命" },
        { value: "0", label: "0命" },
      ],
      current: function () {
        return window._srCtrl.sr_rank0 ? "0" : "6";
      },
      onChange: function (v) {
        window._srCtrl.sr_rank0 = v === "0";
      },
    },
  ];
};

var SR_CHAR = {
  id: 8008,
  name: "开拓者",
  element: "ice",
  rarity: 5,
  level: 80,
  rank: 6,
  image:
    "https://act-webstatic.mihoyo.com/game_record/hkrpg/custom/avatar_image/8008@2x.png",
  icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/5ab405679e775ea6f02d444a7b2be72a.png",
  equip: {
    name: "飞向粉色的明天",
    level: 80,
    rank: 5,
    rarity: 4,
    icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/5ef1c764c1dc164a14c2343c75ffceef.png",
  },
  relics: [
    {
      pos: 1,
      name: "英豪的冠军桂冠",
      level: 15,
      rarity: 5,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/823d043d0775a36f29436e1817babe84.png",
      main: { name: "生命值", value: "705" },
      subs: [
        { name: "暴击率", value: "7.7%" },
        { name: "暴击伤害", value: "6.9%" },
        { name: "攻击力%", value: "4.3%" },
        { name: "效果命中", value: "11.2%" },
      ],
    },
    {
      pos: 2,
      name: "英豪的鉴金腕铠",
      level: 15,
      rarity: 5,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/82174750224b8e9cfe7a02279b5a4ee7.png",
      main: { name: "攻击力", value: "352" },
      subs: [
        { name: "生命值", value: "118" },
        { name: "攻击力%", value: "9.1%" },
        { name: "速度", value: "2" },
        { name: "暴击率", value: "9.0%" },
      ],
    },
    {
      pos: 3,
      name: "英豪的骁战金甲",
      level: 15,
      rarity: 5,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/33ffeaf8774f1891397d6a67fa96a595.png",
      main: { name: "生命值%", value: "64.8%" },
      subs: [
        { name: "暴击伤害", value: "6.9%" },
        { name: "速度", value: "2" },
        { name: "效果命中", value: "12.0%" },
        { name: "暴击率", value: "11.0%" },
      ],
    },
    {
      pos: 4,
      name: "英豪的赴火护胫",
      level: 15,
      rarity: 5,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/be6efa1cad8196dbc1f74925c18b2964.png",
      main: { name: "速度", value: "25" },
      subs: [
        { name: "暴击伤害", value: "7.7%" },
        { name: "攻击力%", value: "10.8%" },
        { name: "暴击率", value: "8.7%" },
        { name: "效果抵抗", value: "3.4%" },
      ],
    },
  ],
  ornaments: [
    {
      pos: 5,
      name: "露莎卡的水朽苍都",
      level: 15,
      rarity: 5,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/135d674a9fa1b3b2060cd0a354f086c9.png",
      main: { name: "能量恢复效率", value: "38.8%" },
      subs: [
        { name: "生命值", value: "42" },
        { name: "暴击率", value: "12.9%" },
        { name: "暴击伤害", value: "4.3%" },
        { name: "速度", value: "8" },
      ],
    },
    {
      pos: 6,
      name: "露莎卡的双生航道",
      level: 15,
      rarity: 5,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/b13c29f59691de9d71251303422f2148.png",
      main: { name: "暴击伤害", value: "43.2%" },
      subs: [
        { name: "防御力", value: "35" },
        { name: "攻击力%", value: "10.2%" },
        { name: "暴击率", value: "5.5%" },
        { name: "暴击伤害", value: "17.4%" },
      ],
    },
  ],
  ranks: [
    {
      pos: 1,
      name: "现在的记叙者",
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/ba510fba8c4a177ff18519c796e8eed6.png",
    },
    {
      pos: 2,
      name: "过往的拾遗者",
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/a450b1f6a95d97bc4d4894af46a32042.png",
    },
    {
      pos: 3,
      name: "未来的咏唱者",
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/903f07bd39e979e1c65a0854d4d0e4f9.png",
    },
    {
      pos: 4,
      name: "缪斯的新舞伴",
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/ddec60d94f35d7e0cf44e7480670135c.png",
    },
    {
      pos: 5,
      name: "诗篇的裁缝匠",
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/2a9d3a2717ce00f2550d7643a516d97d.png",
    },
    {
      pos: 6,
      name: "神启的转呈者",
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/15ee09aec741a6905c4f03e7d1a34646.png",
    },
  ],
  // 行迹按 point_type 分三组（来自 hkrpgAllAvatar.json 开拓者8008完整数据）
  // point_type=2 主技能
  type2: [
    {
      name: "普攻",
      level: 7,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/fab5ed2134df8ccd352935ab9cee817f.png",
    },
    {
      name: "战技",
      level: 12,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/170cec627564ede3f131cabf0f6d5eb3.png",
    },
    {
      name: "终结技",
      level: 12,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/ca1e802d14b296682289d0832544b790.png",
    },
    {
      name: "天赋",
      level: 12,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/09cd6ff3a7817a1ea560ac3087459f34.png",
    },
    {
      name: "秘技",
      level: 1,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/2268a9c2a619165e85ffc0e61808e75e.png",
    },
  ],
  // point_type=3 额外能力
  type3: [
    {
      activated: true,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/f7d9e198cf0224bab55abece94ae5381.png",
    },
    {
      activated: true,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/7654cd860e51032ed972c748b26fef35.png",
    },
    {
      activated: true,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/321ac2002924c4ed4d4a6ee1c2dc9ffb.png",
    },
  ],
  // point_type=1 属性加成（10个，全部已激活）
  type1: [
    {
      activated: true,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/53c6ec87b2b624efeb7720afb2300e4b.png",
    },
    {
      activated: true,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/53c6ec87b2b624efeb7720afb2300e4b.png",
    },
    {
      activated: true,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/53c6ec87b2b624efeb7720afb2300e4b.png",
    },
    {
      activated: true,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/53c6ec87b2b624efeb7720afb2300e4b.png",
    },
    {
      activated: true,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/53c6ec87b2b624efeb7720afb2300e4b.png",
    },
    {
      activated: true,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/5e7cf0a9cf80cb941f29e1ce38dd44de.png",
    },
    {
      activated: true,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/5e7cf0a9cf80cb941f29e1ce38dd44de.png",
    },
    {
      activated: true,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/5e7cf0a9cf80cb941f29e1ce38dd44de.png",
    },
    {
      activated: true,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/8fb066d87973a4f233bb1991c86af581.png",
    },
    {
      activated: true,
      icon: "https://act-webstatic.mihoyo.com/darkmatter/hkrpg/prod_gf_cn/item_icon_u7f11d/8fb066d87973a4f233bb1991c86af581.png",
    },
  ],
  properties: [
    { name: "生命值", final: "3419" },
    { name: "攻击力", final: "2378" },
    { name: "防御力", final: "1382" },
    { name: "速度", final: "141" },
    { name: "暴击率", final: "28.3%" },
    { name: "暴击伤害", final: "193.5%" },
    { name: "能量恢复效率", final: "38.8%" },
    { name: "效果命中", final: "11.0%" },
  ],
};

var SR_ELEM_COLORS = {
  ice: { bg: "linear-gradient(150deg,#0a1e38,#0e1428)", accent: "#4fc3f7" },
  fire: { bg: "linear-gradient(150deg,#3a1008,#180808)", accent: "#ff7043" },
  wind: { bg: "linear-gradient(150deg,#083a2a,#041810)", accent: "#80cbc4" },
  lightning: {
    bg: "linear-gradient(150deg,#2a1040,#100818)",
    accent: "#ce93d8",
  },
  quantum: { bg: "linear-gradient(150deg,#0a1040,#080818)", accent: "#7986cb" },
  imaginary: {
    bg: "linear-gradient(150deg,#2a1e04,#100e02)",
    accent: "#ffca28",
  },
  physical: {
    bg: "linear-gradient(150deg,#1a1a2a,#0e0e18)",
    accent: "#9e9e9e",
  },
};

function renderSrCharDetail(w, h) {
  var c = {
    bg: "#080810",
    card: "#111118",
    border: "#2a2a3a",
    text: "#e8e8f0",
    sub: "#888",
    primary: "#3a6fd8",
    gold: "#ffca28",
    sr: "#9b8eff",
  };
  var char = SR_CHAR;
  var ec = SR_ELEM_COLORS[char.element] || SR_ELEM_COLORS.physical;
  var accent = ec.accent;

  // 控制项状态
  var noEquip = window._srCtrl && window._srCtrl.sr_no_equip;
  var noRelics = window._srCtrl && window._srCtrl.sr_no_relics;
  var rank0 = window._srCtrl && window._srCtrl.sr_rank0;
  var activeRank = rank0 ? 0 : char.rank;

  // ── 命座列（左侧竖排）──
  function rankCol() {
    var h = "";
    for (var i = 0; i < char.ranks.length; i++) {
      var unlocked = i < activeRank;
      var bg = unlocked ? "rgba(155,142,255,.25)" : "rgba(0,0,0,.55)";
      var border = unlocked ? "rgba(155,142,255,.8)" : "rgba(255,255,255,.12)";
      var shadow = unlocked ? "0 0 8px rgba(155,142,255,.4)" : "none";
      h +=
        '<div style="position:relative;width:30px;height:30px;border-radius:50%;border:1.5px solid ' +
        border +
        ";background:" +
        bg +
        ";display:flex;align-items:center;justify-content:center;overflow:hidden;box-shadow:" +
        shadow +
        ';">' +
        '<img src="' +
        char.ranks[i].icon +
        '" style="width:20px;height:20px;' +
        (unlocked ? "" : "filter:grayscale(1);opacity:.25;") +
        '" onerror="this.style.display=\'none\'">' +
        (unlocked
          ? ""
          : '<div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;"><svg width="12" height="14" viewBox="0 0 12 14" fill="none"><rect x="2" y="6" width="8" height="7" rx="1.5" fill="rgba(255,255,255,.35)"/><path d="M3.5 6V4.5a2.5 2.5 0 015 0V6" stroke="rgba(255,255,255,.35)" stroke-width="1.5" stroke-linecap="round"/></svg></div>') +
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
    ec.bg +
    ';">' +
    // 立绘用独立 div，background-image 不受 shorthand 解析影响
    '<div style="position:absolute;inset:0;background-image:url(' +
    char.image +
    ');background-size:cover;background-position:right 20%;background-repeat:no-repeat;"></div>' +
    // 左侧强渐变
    '<div style="position:absolute;inset:0;background:linear-gradient(to right,rgba(8,8,16,1) 0%,rgba(8,8,16,.95) 30%,rgba(8,8,16,.6) 55%,rgba(8,8,16,.1) 80%,transparent 100%);"></div>' +
    // 底部渐变
    '<div style="position:absolute;inset:0;background:linear-gradient(to top,rgba(8,8,16,1) 0%,rgba(8,8,16,.5) 20%,transparent 45%);"></div>' +
    // 命座列：左侧竖排，顶部对齐
    '<div style="position:absolute;left:12px;top:14px;display:flex;flex-direction:column;gap:6px;z-index:3;">' +
    rankCol() +
    "</div>" +
    // 角色信息：左下角
    '<div style="position:absolute;left:12px;bottom:14px;z-index:2;max-width:60%;">' +
    '<div style="font-size:24px;font-weight:800;color:#fff;text-shadow:0 2px 12px rgba(0,0,0,.95);letter-spacing:.5px;">' +
    char.name +
    "</div>" +
    '<div style="display:flex;align-items:center;gap:6px;margin-top:6px;flex-wrap:wrap;">' +
    '<span style="font-size:12px;color:rgba(255,255,255,.75);background:rgba(0,0,0,.45);padding:2px 8px;border-radius:6px;">Lv.' +
    char.level +
    "</span>" +
    '<span style="font-size:11px;padding:2px 8px;border-radius:6px;background:rgba(155,142,255,.2);color:' +
    c.sr +
    ';border:1px solid rgba(155,142,255,.4);">' +
    activeRank +
    "命</span>" +
    '<span style="font-size:11px;padding:2px 8px;border-radius:6px;background:rgba(255,202,40,.15);color:' +
    c.gold +
    ';border:1px solid rgba(255,202,40,.3);">' +
    char.rarity +
    "★</span>" +
    "</div>" +
    "</div>" +
    "</div>";
  "★</span>" + "</div>" + "</div>" + "</div>";

  // ── 光锥 ──
  function equipSection() {
    if (noEquip) {
      return (
        '<div style="background:' +
        c.card +
        ";border:1px dashed " +
        c.border +
        ';border-radius:10px;padding:14px;display:flex;align-items:center;justify-content:center;gap:8px;">' +
        '<span style="font-size:20px;">🔒</span>' +
        '<span style="font-size:13px;color:' +
        c.sub +
        ';">未装备光锥</span>' +
        "</div>"
      );
    }
    var e = char.equip;
    return (
      '<div style="background:' +
      c.card +
      ";border:1px solid " +
      c.border +
      ';border-radius:10px;padding:10px;display:flex;align-items:center;gap:10px;">' +
      '<img src="' +
      e.icon +
      '" style="width:52px;height:52px;border-radius:8px;background:#1a1a2e;flex-shrink:0;" onerror="this.style.background=\'#2a2a3a\'">' +
      '<div style="flex:1;">' +
      '<div style="font-size:13px;font-weight:700;color:' +
      c.text +
      ';">' +
      e.name +
      "</div>" +
      '<div style="font-size:11px;color:' +
      c.sub +
      ';margin-top:2px;">Lv.' +
      e.level +
      " · 叠影 " +
      e.rank +
      " · " +
      e.rarity +
      "★</div>" +
      "</div>" +
      "</div>"
    );
  }

  // ── 遗器卡片（与原神格式统一：图标+名称+强化等级 / 主词条名+值 / 副词条列表）──
  function relicCard(r) {
    var subsHtml = r.subs
      .map(function (s) {
        return (
          '<div style="display:flex;justify-content:space-between;align-items:center;padding:1px 0;">' +
          '<span style="font-size:10px;color:' +
          c.sub +
          ';">' +
          s.name +
          "</span>" +
          '<span style="font-size:10px;color:' +
          c.text +
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
      // 顶部：图标 + 名称 + 强化等级
      '<div style="display:flex;align-items:center;gap:6px;">' +
      '<img src="' +
      r.icon +
      '" style="width:32px;height:32px;border-radius:6px;background:#1a1a2e;flex-shrink:0;" onerror="this.style.background=\'#2a2a3a\'">' +
      '<span style="font-size:12px;font-weight:700;color:' +
      c.text +
      ';flex:1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">' +
      r.name +
      "</span>" +
      '<span style="font-size:10px;color:rgba(255,255,255,.3);background:rgba(255,255,255,.06);border-radius:4px;padding:1px 5px;">+' +
      r.level +
      "</span>" +
      "</div>" +
      // 主词条行
      '<div style="display:flex;justify-content:space-between;align-items:center;padding:2px 0;border-bottom:1px solid rgba(255,255,255,.08);">' +
      '<span style="font-size:10px;color:' +
      accent +
      ';">' +
      r.main.name +
      "</span>" +
      '<span style="font-size:13px;font-weight:700;color:' +
      c.text +
      ';">' +
      r.main.value +
      "</span>" +
      "</div>" +
      // 副词条列表
      subsHtml +
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
      '<span style="font-size:16px;">🔒</span>' +
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
      var labels = ["头部", "手部", "躯干", "脚部"];
      var ornLabels = ["位面球", "连结绳"];
      return (
        '<div style="display:grid;grid-template-columns:1fr 1fr;gap:7px;">' +
        labels
          .map(function (l) {
            return emptyRelicCard(l);
          })
          .join("") +
        "</div>" +
        '<div style="margin-top:7px;display:grid;grid-template-columns:1fr 1fr;gap:7px;">' +
        ornLabels
          .map(function (l) {
            return emptyRelicCard(l);
          })
          .join("") +
        "</div>"
      );
    }
    return (
      '<div style="display:grid;grid-template-columns:1fr 1fr;gap:7px;">' +
      char.relics.map(relicCard).join("") +
      "</div>" +
      '<div style="margin-top:7px;display:grid;grid-template-columns:1fr 1fr;gap:7px;">' +
      char.ornaments.map(relicCard).join("") +
      "</div>"
    );
  }

  // ── 行迹（三组：主技能/额外能力/属性加成）──
  function traceSection() {
    var lockSvg =
      '<svg width="10" height="12" viewBox="0 0 12 14" fill="none"><rect x="2" y="6" width="8" height="7" rx="1.5" fill="rgba(255,255,255,.4)"/><path d="M3.5 6V4.5a2.5 2.5 0 015 0V6" stroke="rgba(255,255,255,.4)" stroke-width="1.5" stroke-linecap="round"/></svg>';

    // 组1：主技能（point_type=2）大图标 + 等级 + 名称，flex-wrap 自动换行
    var skillSize = 48;
    var group1 =
      '<div style="margin-bottom:10px;">' +
      '<div style="font-size:10px;color:' +
      c.sub +
      ';letter-spacing:.5px;margin-bottom:6px;">主技能</div>' +
      '<div style="display:flex;gap:8px;flex-wrap:wrap;">' +
      char.type2
        .map(function (s) {
          return (
            '<div style="display:flex;flex-direction:column;align-items:center;gap:3px;">' +
            '<div style="position:relative;width:' +
            skillSize +
            "px;height:" +
            skillSize +
            'px;border-radius:50%;background:rgba(0,0,0,.6);border:2px solid rgba(255,255,255,.2);overflow:hidden;">' +
            '<img src="' +
            s.icon +
            '" style="width:100%;height:100%;object-fit:cover;" onerror="this.style.background=\'#2a2a3a\'">' +
            "</div>" +
            '<div style="font-size:11px;font-weight:700;color:' +
            accent +
            ';">' +
            s.level +
            "</div>" +
            '<div style="font-size:9px;color:' +
            c.sub +
            ';text-align:center;max-width:52px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">' +
            s.name +
            "</div>" +
            "</div>"
          );
        })
        .join("") +
      "</div>" +
      "</div>";

    // 组2：额外能力（point_type=3）中图标，激活/未激活
    var extraSize = 36;
    var group2 =
      '<div style="margin-bottom:10px;">' +
      '<div style="font-size:10px;color:' +
      c.sub +
      ';letter-spacing:.5px;margin-bottom:6px;">额外能力</div>' +
      '<div style="display:flex;gap:6px;flex-wrap:wrap;">' +
      char.type3
        .map(function (a) {
          var bg = a.activated ? "rgba(155,142,255,.2)" : "rgba(0,0,0,.5)";
          var border = a.activated
            ? "rgba(155,142,255,.6)"
            : "rgba(255,255,255,.1)";
          var shadow = a.activated ? "0 0 6px rgba(155,142,255,.3)" : "none";
          return (
            '<div style="position:relative;width:' +
            extraSize +
            "px;height:" +
            extraSize +
            "px;border-radius:50%;background:" +
            bg +
            ";border:1.5px solid " +
            border +
            ";box-shadow:" +
            shadow +
            ';display:flex;align-items:center;justify-content:center;overflow:hidden;">' +
            '<img src="' +
            a.icon +
            '" style="width:24px;height:24px;' +
            (a.activated ? "" : "filter:grayscale(1);opacity:.3;") +
            '" onerror="this.style.display=\'none\'">' +
            (a.activated
              ? ""
              : '<div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;">' +
                lockSvg +
                "</div>") +
            "</div>"
          );
        })
        .join("") +
      "</div>" +
      "</div>";

    // 组3：属性加成（point_type=1）小图标，激活/未激活，flex-wrap 自动换行
    var statSize = 28;
    var group3 =
      "<div>" +
      '<div style="font-size:10px;color:' +
      c.sub +
      ';letter-spacing:.5px;margin-bottom:6px;">属性加成</div>' +
      '<div style="display:flex;gap:5px;flex-wrap:wrap;">' +
      char.type1
        .map(function (n) {
          var bg = n.activated ? "rgba(255,255,255,.12)" : "rgba(0,0,0,.4)";
          var border = n.activated
            ? "rgba(255,255,255,.3)"
            : "rgba(255,255,255,.08)";
          return (
            '<div style="position:relative;width:' +
            statSize +
            "px;height:" +
            statSize +
            "px;border-radius:50%;background:" +
            bg +
            ";border:1.5px solid " +
            border +
            ';display:flex;align-items:center;justify-content:center;overflow:hidden;">' +
            '<img src="' +
            n.icon +
            '" style="width:18px;height:18px;' +
            (n.activated ? "" : "filter:grayscale(1);opacity:.25;") +
            '" onerror="this.style.display=\'none\'">' +
            (n.activated
              ? ""
              : '<div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;"><svg width="8" height="10" viewBox="0 0 12 14" fill="none"><rect x="2" y="6" width="8" height="7" rx="1.5" fill="rgba(255,255,255,.4)"/><path d="M3.5 6V4.5a2.5 2.5 0 015 0V6" stroke="rgba(255,255,255,.4)" stroke-width="1.5" stroke-linecap="round"/></svg></div>') +
            "</div>"
          );
        })
        .join("") +
      "</div>" +
      "</div>";

    return (
      '<div style="background:' +
      c.card +
      ";border:1px solid " +
      c.border +
      ';border-radius:10px;padding:12px;">' +
      group1 +
      group2 +
      group3 +
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
    section("行迹", traceSection()) +
    section("光锥", equipSection()) +
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
    section("遗器（头/手/躯/脚）+ 饰品（位面球/连结绳）", relicsSection()) +
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

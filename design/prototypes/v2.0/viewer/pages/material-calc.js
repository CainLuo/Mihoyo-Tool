/**
 * material-calc.js — 单个角色材料计算页面原型
 * 
 * 页面定位：从角色详情页进入，显示当前角色的材料需求
 * 
 * 设计要点：
 * 1. 单个角色，不涉及角色切换
 * 2. 下拉刷新（不用刷新按钮）
 * 3. 等级目标显示在角色信息区
 * 4. 技能目标（普攻/战技/爆发）单独设置
 * 5. 材料分两个 section：角色材料 + 武器材料
 */

/** 页面状态 */
var MC_STATE = {
  // 角色等级目标
  charCurrentLevel: 80,
  charTargetLevel: 90,
  // 武器等级目标
  weaponCurrentLevel: 80,
  weaponTargetLevel: 90,
  // 技能目标
  skillNormal: 10,
  skillSkill: 10,
  skillBurst: 10,
};

/** 单个角色 Mock 数据 */
var MC_CHARACTER = {
  id: 10000122,
  name: "甘雨",
  element: "cryo",
  rarity: 5,
  weapon: {
    name: "阿莫斯之弓",
    icon: "🏹",
    rarity: 5,
    affix: 1,
    level: 80
  }
};

/** 等级选项（角色和武器通用） */
var MC_LEVEL_OPTIONS = [
  { value: 60, label: "60" },
  { value: 70, label: "70" },
  { value: 80, label: "80" },
  { value: 90, label: "90" },
];

/** 角色材料 Mock 数据 */
var MC_MATERIALS_AVATAR = [
  { id: 1, name: "哀叙冰玉", icon: "💎", rarity: 5, have: 12, need: 46 },
  { id: 2, name: "极寒之核", icon: "❄️", rarity: 4, have: 8, need: 46 },
  { id: 3, name: "清心", icon: "🌸", rarity: 3, have: 68, need: 168 },
  { id: 4, name: "骗骗花蜜", icon: "🧪", rarity: 2, have: 36, need: 18 },
  { id: 5, name: "微光花蜜", icon: "🧪", rarity: 3, have: 24, need: 30 },
  { id: 6, name: "原素花蜜", icon: "🧪", rarity: 4, have: 12, need: 36 },
];

/** 武器材料 Mock 数据 */
var MC_MATERIALS_WEAPON = [
  { id: 101, name: "孤云寒冰的神瞳", icon: "⭐", rarity: 5, have: 3, need: 6 },
  { id: 102, name: "北陆弓原胚", icon: "🔨", rarity: 4, have: 1, need: 1 },
  { id: 103, name: "水晶块", icon: "💎", rarity: 3, have: 156, need: 50 },
];

/** 渲染材料计算页面 */
function renderMaterialCalc(w, h) {
  var c = T();
  var char = MC_CHARACTER;
  var weapon = char.weapon;

  // 计算角色材料进度
  var avatarHave = 0, avatarNeed = 0, avatarDeficit = 0;
  for (var i = 0; i < MC_MATERIALS_AVATAR.length; i++) {
    var m = MC_MATERIALS_AVATAR[i];
    avatarHave += Math.min(m.have, m.need);
    avatarNeed += m.need;
    avatarDeficit += Math.max(0, m.need - m.have);
  }
  var avatarPct = avatarNeed > 0 ? Math.round((avatarHave / avatarNeed) * 100) : 0;

  // 计算武器材料进度
  var weaponHave = 0, weaponNeed = 0, weaponDeficit = 0;
  for (var i = 0; i < MC_MATERIALS_WEAPON.length; i++) {
    var m = MC_MATERIALS_WEAPON[i];
    weaponHave += Math.min(m.have, m.need);
    weaponNeed += m.need;
    weaponDeficit += Math.max(0, m.need - m.have);
  }
  var weaponPct = weaponNeed > 0 ? Math.round((weaponHave / weaponNeed) * 100) : 0;

  var html = "";
  html += baseCss(w, h) + SK_ANIM;
  html += "<style>";
  html += ".mc-card:hover{transform:scale(1.01)}";
  html += ".mc-skill:hover{background:" + c.priBg + "}";
  html += ".mc-material:hover{background:" + c.priBg + "}";
  html += "</style>";

  html += "<div style=\"width:" + w + "px;height:" + h + "px;display:flex;flex-direction:column;background:" + c.pageBg + "\">";

  // Header（只有返回按钮和标题）
  html += "<div style=\"height:48px;display:flex;align-items:center;padding:0 16px;border-bottom:1px solid " + c.div + ";flex-shrink:0\">";
  html += "<button onclick=\"alert('返回角色详情页')\" style=\"width:32px;height:32px;display:flex;align-items:center;justify-content:center;border:none;background:transparent;cursor:pointer\">";
  html += "<span style=\"font-size:20px;color:" + c.txt + "\">←</span></button>";
  html += "<h1 style=\"flex:1;margin:0 12px;font-size:17px;font-weight:600;color:" + c.txt + "\">材料计算</h1>";
  html += "</div>";

  // 内容区（支持下拉刷新）
  html += "<div style=\"flex:1;overflow-y:auto;padding:16px\" class=\"sy\">";

  // ── 角色信息卡（含可点击的等级目标）─────────────────────────────
  html += "<div class=\"mc-card\" style=\"display:flex;align-items:center;padding:12px;background:" + c.surfCard + ";border-radius:12px;margin-bottom:16px;border:1px solid " + c.div + "\">";
  // 角色头像
  html += "<div style=\"width:48px;height:48px;border-radius:50%;background:linear-gradient(135deg,#4FC3F7,#3A6FD8);display:flex;align-items:center;justify-content:center;font-size:22px\">👤</div>";
  html += "<div style=\"flex:1;margin-left:12px\">";
  html += "<div style=\"font-size:17px;font-weight:600;color:" + c.txt + "\">" + char.name + "</div>";
  html += "<div style=\"font-size:12px;color:" + c.txt2 + ";margin-top:2px\">" + "★".repeat(char.rarity) + "</div>";
  html += "</div>";
  // 可点击的等级目标（当前 → 目标）
  html += "<button onclick=\"alert('选择角色目标等级')\" style=\"display:flex;align-items:center;gap:6px;padding:8px 12px;background:" + c.priBg + ";border:none;border-radius:8px;cursor:pointer\">";
  html += "<span style=\"font-size:14px;font-weight:600;color:" + c.primary + "\">Lv." + MC_STATE.charCurrentLevel + " → " + MC_STATE.charTargetLevel + "</span>";
  html += "<span style=\"font-size:10px;color:" + c.primary + "\">▼</span>";
  html += "</button>";
  html += "</div>";

  // ── 技能目标设置 ────────────────────────────────────────────────
  html += "<div style=\"margin-bottom:16px\">";
  html += "<div style=\"font-size:13px;color:" + c.txtM + ";margin-bottom:10px\">技能目标</div>";
  html += "<div style=\"display:flex;gap:8px\">";
  
  var skills = [
    { id: "normal", label: "普攻", current: MC_STATE.skillNormal, target: 10 },
    { id: "skill", label: "战技", current: MC_STATE.skillSkill, target: 10 },
    { id: "burst", label: "爆发", current: MC_STATE.skillBurst, target: 10 },
  ];
  
  for (var i = 0; i < skills.length; i++) {
    var s = skills[i];
    var isDone = s.current >= s.target;
    var bgColor = isDone ? c.ok + "18" : c.surfCard;
    var borderColor = isDone ? c.ok + "44" : c.div;
    
    html += "<div class=\"mc-skill\" style=\"flex:1;display:flex;flex-direction:column;align-items:center;padding:10px 8px;background:" + bgColor + ";border-radius:10px;border:1px solid " + borderColor + ";cursor:pointer\">";
    html += "<span style=\"font-size:11px;color:" + c.txtM + "\">" + s.label + "</span>";
    html += "<span style=\"font-size:15px;font-weight:600;color:" + (isDone ? c.ok : c.txt) + ";margin-top:4px\">" + s.current + "/" + s.target + "</span>";
    if (isDone) html += "<span style=\"font-size:12px;color:" + c.ok + "\">✓</span>";
    html += "</div>";
  }
  html += "</div>";
  html += "</div>";

  // ── 角色材料 Section ─────────────────────────────────────────
  html += "<div style=\"margin-bottom:20px\">";
  html += "<div style=\"display:flex;align-items:center;justify-content:space-between;margin-bottom:10px\">";
  html += "<div style=\"display:flex;align-items:center;gap:8px\">";
  html += "<span style=\"font-size:15px;font-weight:600;color:" + c.txt + "\">👤 角色材料</span>";
  html += "<span style=\"font-size:12px;color:" + c.txtM + "\">" + avatarPct + "%</span>";
  html += "</div>";
  html += "<div style=\"font-size:12px;color:" + (avatarDeficit > 0 ? c.danger : c.ok) + "\">";
  html += avatarDeficit > 0 ? "缺少 " + avatarDeficit : "已足够";
  html += "</div>";
  html += "</div>";
  html += renderMaterialItems(MC_MATERIALS_AVATAR, c);
  html += "</div>";

  // ── 武器材料 Section ─────────────────────────────────────────
  html += "<div>";
  html += "<div style=\"display:flex;align-items:center;justify-content:space-between;margin-bottom:10px\">";
  html += "<div style=\"display:flex;align-items:center;gap:8px\">";
  // 武器图标
  html += "<div style=\"width:28px;height:28px;border-radius:6px;background:" + getRarityGradient(weapon.rarity) + ";display:flex;align-items:center;justify-content:center;font-size:14px;flex-shrink:0\">" + weapon.icon + "</div>";
  html += "<span style=\"font-size:15px;font-weight:600;color:" + c.txt + "\">武器材料</span>";
  html += "<span style=\"font-size:12px;color:" + c.txtM + "\">" + weaponPct + "%</span>";
  html += "</div>";
  // 武器等级目标按钮
  html += "<button onclick=\"alert('选择武器目标等级')\" style=\"display:flex;align-items:center;gap:4px;padding:4px 10px;background:" + c.priBg + ";border:none;border-radius:6px;cursor:pointer\">";
  html += "<span style=\"font-size:12px;color:" + c.primary + "\">Lv." + MC_STATE.weaponCurrentLevel + "→" + MC_STATE.weaponTargetLevel + "</span>";
  html += "<span style=\"font-size:9px;color:" + c.primary + "\">▼</span>";
  html += "</button>";
  html += "</div>";
  html += "<div style=\"font-size:12px;color:" + (weaponDeficit > 0 ? c.danger : c.ok) + ";margin-bottom:10px\">";
  html += weaponDeficit > 0 ? "缺少 " + weaponDeficit + " 个材料" : "材料已足够";
  html += "</div>";
  html += renderMaterialItems(MC_MATERIALS_WEAPON, c);
  html += "</div>";

  // 下拉刷新提示
  html += "<div style=\"text-align:center;padding:20px;color:" + c.txtM + ";font-size:12px\">↓ 下拉刷新材料数据</div>";

  html += "</div></div>";
  return html;
}

/** 渲染材料列表项 */
function renderMaterialItems(materials, c) {
  var html = "";
  for (var i = 0; i < materials.length; i++) {
    var m = materials[i];
    var deficit = Math.max(0, m.need - m.have);
    var isEnough = deficit === 0;
    var progress = m.need > 0 ? Math.min(100, Math.round((m.have / m.need) * 100)) : 0;

    html += "<div class=\"mc-material\" style=\"display:flex;align-items:center;padding:10px 12px;background:" + c.surfCard + ";border-radius:10px;margin-bottom:6px;border:1px solid " + c.div + "\">";
    // 图标
    html += "<div style=\"width:36px;height:36px;border-radius:8px;background:" + getRarityGradient(m.rarity) + ";display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0\">" + m.icon + "</div>";
    // 名称和进度条
    html += "<div style=\"flex:1;margin-left:10px;min-width:0\">";
    html += "<div style=\"font-size:14px;color:" + c.txt + ";font-weight:500;white-space:nowrap;overflow:hidden;text-overflow:ellipsis\">" + m.name + "</div>";
    html += "<div style=\"height:3px;background:" + c.div + ";border-radius:2px;margin-top:4px;max-width:80px;overflow:hidden\">";
    html += "<div style=\"height:100%;width:" + progress + "%;background:" + (isEnough ? c.ok : c.primary) + ";border-radius:2px\"></div></div>";
    html += "</div>";
    // 数量
    html += "<div style=\"text-align:right;margin-left:10px;flex-shrink:0\">";
    html += "<div style=\"font-size:14px;font-weight:600;color:" + (isEnough ? c.ok : c.txt) + "\">" + m.have + "/" + m.need + "</div>";
    html += "<div style=\"font-size:11px;color:" + (isEnough ? c.ok : c.danger) + ";margin-top:1px\">";
    html += isEnough ? "✓" : "-" + deficit;
    html += "</div>";
    html += "</div>";
    html += "</div>";
  }
  return html;
}

/** 获取稀有度渐变 */
function getRarityGradient(rarity) {
  switch (rarity) {
    case 5: return "linear-gradient(135deg,#F5A623,#D4880A)";
    case 4: return "linear-gradient(135deg,#9B59B6,#7D3C98)";
    case 3: return "linear-gradient(135deg,#3498DB,#2980B9)";
    case 2: return "linear-gradient(135deg,#27AE60,#1E8449)";
    default: return "linear-gradient(135deg,#7F8C8D,#5D6D7E)";
  }
}

/** 控制项（用于原型演示不同状态） */
function materialCalcControls() {
  return [
    {
      id: "charLevel",
      label: "角色等级",
      current: function () { return MC_STATE.charTargetLevel; },
      onChange: function (val) { MC_STATE.charTargetLevel = parseInt(val); },
      options: [
        { value: 60, label: "→60" },
        { value: 70, label: "→70" },
        { value: 80, label: "→80" },
        { value: 90, label: "→90" },
      ],
    },
    {
      id: "weaponLevel",
      label: "武器等级",
      current: function () { return MC_STATE.weaponTargetLevel; },
      onChange: function (val) { MC_STATE.weaponTargetLevel = parseInt(val); },
      options: [
        { value: 60, label: "→60" },
        { value: 70, label: "→70" },
        { value: 80, label: "→80" },
        { value: 90, label: "→90" },
      ],
    },
    {
      id: "skillLevel",
      label: "技能等级",
      current: function () { return MC_STATE.skillNormal; },
      onChange: function (val) { 
        MC_STATE.skillNormal = parseInt(val);
        MC_STATE.skillSkill = parseInt(val);
        MC_STATE.skillBurst = parseInt(val);
      },
      options: [
        { value: 1, label: "1/10" },
        { value: 6, label: "6/10" },
        { value: 10, label: "10/10" },
      ],
    },
  ];
}

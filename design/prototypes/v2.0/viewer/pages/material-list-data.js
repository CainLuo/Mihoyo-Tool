/**
 * material-list-data.js — 材料汇总 Mock 数据
 */

/** 页面状态 */
var ML_STATE = {
  selectedGame: "genshin",
  viewMode: "character",
  expandedCharacters: {},
};

/** 游戏选项 */
var ML_GAME_OPTIONS = [
  { value: "genshin", label: "原神", color: "#5BA3E8", icon: "🌍" },
  { value: "starrail", label: "星铁", color: "#9B8EFF", icon: "🌟" },
  { value: "zzz", label: "绝区零", color: "#F7B84B", icon: "⚡" },
];

/** 视图模式选项 */
var ML_VIEW_OPTIONS = [
  { value: "character", label: "按角色", icon: "👤" },
  { value: "material", label: "按材料", icon: "📦" },
];

/** 原神角色+武器材料 Mock 数据 */
var ML_GENSHIN_DATA = [
  {
    characterId: 10000122,
    characterName: "甘雨",
    characterIcon: "❄️",
    characterLevel: 90,
    element: "cryo",
    weapon: { id: 15509, name: "阿莫斯之弓", icon: "🏹", rarity: 5, level: 90 },
    skills: [
      { id: 1001221, name: "流天射术", icon: "🏹", level: 10 },
      { id: 1001222, name: "山泽麟迹", icon: "❄️", level: 10 },
      { id: 1001223, name: "降众天华", icon: "💠", level: 10 },
    ],
    avatarMaterials: [
      { id: 1, name: "哀叙冰玉", icon: "💎", rarity: 5, have: 12, need: 46, deficit: 34 },
      { id: 2, name: "极寒之核", icon: "❄️", rarity: 4, have: 8, need: 46, deficit: 38 },
      { id: 3, name: "清心", icon: "🌸", rarity: 3, have: 68, need: 168, deficit: 100 },
    ],
    skillMaterials: [
      { id: 4, name: "「勤劳」的教导", icon: "📖", rarity: 2, have: 24, need: 9, deficit: 0 },
      { id: 5, name: "「勤劳」的指引", icon: "📖", rarity: 3, have: 18, need: 63, deficit: 45 },
    ],
    weaponMaterials: [
      { id: 101, name: "孤云寒冰的神瞳", icon: "⭐", rarity: 5, have: 3, need: 6, deficit: 3 },
    ],
  },
  {
    characterId: 10000003,
    characterName: "琴",
    characterIcon: "🍃",
    characterLevel: 90,
    element: "anemo",
    weapon: { id: 11502, name: "天空之刃", icon: "⚔️", rarity: 5, level: 90 },
    skills: [
      { id: 1000031, name: "西风剑术", icon: "⚔️", level: 10 },
      { id: 1000032, name: "蒲公英之风", icon: "🌀", level: 10 },
    ],
    avatarMaterials: [
      { id: 10, name: "自在松石", icon: "💚", rarity: 5, have: 20, need: 46, deficit: 26 },
      { id: 11, name: "飓风之种", icon: "🌀", rarity: 4, have: 15, need: 46, deficit: 31 },
    ],
    skillMaterials: [
      { id: 12, name: "「抗争」的教导", icon: "📖", rarity: 2, have: 30, need: 9, deficit: 0 },
    ],
    weaponMaterials: [
      { id: 103, name: "凛风奔狼的始龀", icon: "🐺", rarity: 5, have: 5, need: 6, deficit: 1 },
    ],
  },
];

/** 星铁角色材料 Mock 数据 */
var ML_STARRAIL_DATA = [
  {
    characterId: 1001,
    characterName: "希儿",
    characterIcon: "⚡",
    characterLevel: 80,
    element: "quantum",
    lightCone: { id: 23003, name: "于夜色中", icon: "🌙", rarity: 5, level: 80 },
    skills: [
      { id: 10011, name: "强袭", icon: "⚔️", level: 10 },
      { id: 10012, name: "再现", icon: "⚡", level: 10 },
      { id: 10013, name: "乱舞", icon: "💫", level: 10 },
    ],
    avatarMaterials: [
      { id: 201, name: "永寿荣华的天赋", icon: "📜", rarity: 5, have: 5, need: 18, deficit: 13 },
      { id: 202, name: "铁卫军衔勋章", icon: "🎖️", rarity: 4, have: 24, need: 54, deficit: 30 },
    ],
    skillMaterials: [
      { id: 210, name: "毁灭者的寂路", icon: "🔮", rarity: 5, have: 8, need: 12, deficit: 4 },
    ],
    lightConeMaterials: [
      { id: 220, name: "猎兽视界", icon: "🎯", rarity: 4, have: 6, need: 8, deficit: 2 },
    ],
  },
  {
    characterId: 1002,
    characterName: "银狼",
    characterIcon: "🎮",
    characterLevel: 80,
    element: "quantum",
    lightCone: { id: 23004, name: "雨一直下", icon: "🌧️", rarity: 5, level: 80 },
    skills: [
      { id: 10021, name: "系统警告", icon: "⚠️", level: 10 },
      { id: 10022, name: "黑客攻击", icon: "💻", level: 10 },
    ],
    avatarMaterials: [
      { id: 230, name: "永寿荣华的天赋", icon: "📜", rarity: 5, have: 12, need: 18, deficit: 6 },
    ],
    skillMaterials: [
      { id: 240, name: "虚无者的妄想", icon: "🌀", rarity: 5, have: 3, need: 12, deficit: 9 },
    ],
    lightConeMaterials: [
      { id: 250, name: "猎兽视界", icon: "🎯", rarity: 4, have: 8, need: 8, deficit: 0 },
    ],
  },
];

/** 绝区零角色材料 Mock 数据 */
var ML_ZZZ_DATA = [
  {
    characterId: 101,
    characterName: "艾莲",
    characterIcon: "🦈",
    characterLevel: 60,
    element: "ice",
    weapon: { id: 14102, name: "深海访客", icon: "🔱", rarity: 5, level: 60 },
    skills: [
      { id: 1011, name: "霜牙", icon: "🦷", level: 12 },
      { id: 1012, name: "深海猎杀", icon: "🌊", level: 12 },
      { id: 1013, name: "暴风雪", icon: "❄️", level: 12 },
    ],
    avatarMaterials: [
      { id: 301, name: "高维数据：凛冬战役", icon: "💾", rarity: 5, have: 2, need: 5, deficit: 3 },
    ],
    skillMaterials: [
      { id: 310, name: "仓鼠笼乐园", icon: "🐹", rarity: 5, have: 1, need: 5, deficit: 4 },
    ],
    weaponMaterials: [
      { id: 320, name: "炫目机身", icon: "✨", rarity: 4, have: 8, need: 10, deficit: 2 },
    ],
  },
];

/** 获取当前游戏数据 */
function getGameMaterialData() {
  switch (ML_STATE.selectedGame) {
    case "genshin": return ML_GENSHIN_DATA;
    case "starrail": return ML_STARRAIL_DATA;
    case "zzz": return ML_ZZZ_DATA;
    default: return [];
  }
}

/** 合并所有材料（按材料汇总模式） */
function mergeAllMaterials() {
  var data = getGameMaterialData();
  var merged = {};
  
  for (var i = 0; i < data.length; i++) {
    var charData = data[i];
    var charName = charData.characterName;
    
    // 合并角色材料
    if (charData.avatarMaterials) {
      for (var j = 0; j < charData.avatarMaterials.length; j++) {
        var m = charData.avatarMaterials[j];
        if (!merged[m.id]) {
          merged[m.id] = { id: m.id, name: m.name, icon: m.icon, rarity: m.rarity, have: m.have, need: 0, deficit: 0, sources: [] };
        }
        merged[m.id].need += m.need;
        merged[m.id].deficit += m.deficit;
        merged[m.id].sources.push(charName + "(角色)");
      }
    }
    
    // 合并技能材料
    if (charData.skillMaterials) {
      for (var j = 0; j < charData.skillMaterials.length; j++) {
        var m = charData.skillMaterials[j];
        if (!merged[m.id]) {
          merged[m.id] = { id: m.id, name: m.name, icon: m.icon, rarity: m.rarity, have: m.have, need: 0, deficit: 0, sources: [] };
        }
        merged[m.id].need += m.need;
        merged[m.id].deficit += m.deficit;
        merged[m.id].sources.push(charName + "(技能)");
      }
    }
    
    // 合并武器/光锥材料
    var equipMats = ML_STATE.selectedGame === "starrail" ? charData.lightConeMaterials : charData.weaponMaterials;
    if (equipMats) {
      for (var j = 0; j < equipMats.length; j++) {
        var m = equipMats[j];
        if (!merged[m.id]) {
          merged[m.id] = { id: m.id, name: m.name, icon: m.icon, rarity: m.rarity, have: m.have, need: 0, deficit: 0, sources: [] };
        }
        merged[m.id].need += m.need;
        merged[m.id].deficit += m.deficit;
        var equipName = ML_STATE.selectedGame === "starrail" ? charData.lightCone.name : charData.weapon.name;
        merged[m.id].sources.push(charName + "(" + equipName + ")");
      }
    }
  }
  
  // 转为数组并按稀有度排序
  var result = [];
  var keys = Object.keys(merged);
  for (var i = 0; i < keys.length; i++) {
    result.push(merged[keys[i]]);
  }
  result.sort(function (a, b) {
    if (a.rarity !== b.rarity) return b.rarity - a.rarity;
    return a.name.localeCompare(b.name);
  });
  
  return result;
}

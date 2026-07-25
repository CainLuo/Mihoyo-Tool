/**
 * material-list.js — 材料汇总列表页面原型
 * 
 * 支持两种视图模式：
 * 1. 按角色分组：显示每个角色+武器的缺失材料
 * 2. 按材料汇总：合并所有角色的材料需求
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

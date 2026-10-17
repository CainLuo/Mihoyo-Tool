/**
 * material-list-utils.js — 材料汇总工具函数
 */

/** 获取元素渐变 */
function getElementGradient(game, charData) {
  if (game === "genshin") {
    switch (charData.element) {
      case "cryo": return "linear-gradient(135deg,#B3E5FC,#4FC3F7)";
      case "pyro": return "linear-gradient(135deg,#FFCCBC,#FF7043)";
      case "electro": return "linear-gradient(135deg,#E1BEE7,#CE93D8)";
      case "anemo": return "linear-gradient(135deg,#B2DFDB,#80CBC4)";
      case "geo": return "linear-gradient(135deg,#FFF9C4,#FFCA28)";
      case "hydro": return "linear-gradient(135deg,#B3E5FC,#4FC3F7)";
      case "dendro": return "linear-gradient(135deg,#C8E6C9,#A5D6A7)";
      default: return "linear-gradient(135deg,#E0E0E0,#BDBDBD)";
    }
  } else if (game === "starrail") {
    switch (charData.element) {
      case "quantum": return "linear-gradient(135deg,#9575CD,#7E57C2)";
      case "imaginary": return "linear-gradient(135deg,#FFE082,#FFB300)";
      case "fire": return "linear-gradient(135deg,#FFAB91,#FF7043)";
      case "ice": return "linear-gradient(135deg,#B3E5FC,#4FC3F7)";
      case "physical": return "linear-gradient(135deg,#E0E0E0,#BDBDBD)";
      case "wind": return "linear-gradient(135deg,#C8E6C9,#81C784)";
      default: return "linear-gradient(135deg,#E0E0E0,#BDBDBD)";
    }
  } else if (game === "zzz") {
    switch (charData.element) {
      case "ice": return "linear-gradient(135deg,#B3E5FC,#4FC3F7)";
      case "fire": return "linear-gradient(135deg,#FFCCBC,#FF7043)";
      case "electric": return "linear-gradient(135deg,#E1BEE7,#CE93D8)";
      case "physical": return "linear-gradient(135deg,#E0E0E0,#BDBDBD)";
      case "ether": return "linear-gradient(135deg,#CE93D8,#AB47BC)";
      default: return "linear-gradient(135deg,#E0E0E0,#BDBDBD)";
    }
  }
  return "linear-gradient(135deg,#E0E0E0,#BDBDBD)";
}

/** 获取装备标签 */
function getEquipLabel(game) {
  switch (game) {
    case "genshin": return "武器";
    case "starrail": return "光锥";
    case "zzz": return "武器";
    default: return "武器";
  }
}

/** 获取技能标签 */
function getSkillLabel(game) {
  switch (game) {
    case "genshin": return "天赋材料";
    case "starrail": return "行迹材料";
    case "zzz": return "技能材料";
    default: return "技能材料";
  }
}

/** 获取装备材料标签 */
function getEquipMaterialLabel(game) {
  switch (game) {
    case "genshin": return "武器材料";
    case "starrail": return "光锥材料";
    case "zzz": return "武器材料";
    default: return "武器材料";
  }
}

/** 获取稀有度颜色 */
function getRarityColorV2(rarity) {
  switch (rarity) {
    case 5: return "#F5A623";
    case 4: return "#9B59B6";
    case 3: return "#3498DB";
    case 2: return "#27AE60";
    default: return "#7F8C8D";
  }
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

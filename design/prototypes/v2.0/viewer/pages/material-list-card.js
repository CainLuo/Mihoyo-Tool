/**
 * material-list-card.js — 材料汇总卡片渲染
 * 
 * 按材料视图：简化显示，图标 + 数量
 */

/** 渲染材料网格卡片 */
function renderMaterialGridCard(matData, isPhone, c) {
  var html = "";
  
  var cardSize = isPhone ? 48 : 52;
  var iconSize = isPhone ? 48 : 52;
  var fontSize = isPhone ? 13 : 14;
  
  html += "<div style=\"display:flex;flex-direction:column;align-items:center;gap:4px;padding:8px;cursor:pointer\" onclick=\"showMaterialDetail('" + matData.id + "')\">";
  
  // 材料图标（带稀有度背景）
  var iconBg = getRarityGradient(matData.rarity);
  html += "<div style=\"width:" + iconSize + "px;height:" + iconSize + "px;border-radius:12px;background:" + iconBg + ";display:flex;align-items:center;justify-content:center;font-size:24px\">" + matData.icon + "</div>";
  
  // 数量（与图标左、右、下对齐）
  var isEnough = matData.deficit <= 0;
  var quantityColor = isEnough ? c.ok : c.txt;
  html += "<div style=\"width:" + iconSize + "px;text-align:center;font-size:" + fontSize + "px;font-weight:600;color:" + quantityColor + "\">" + matData.have + "/" + matData.need + "</div>";
  
  html += "</div>";
  return html;
}

/** 渲染按材料汇总的网格 */
function renderMaterialGridView(isPhone, c) {
  var materials = mergeAllMaterials();
  
  var html = "";
  var columns = isPhone ? 3 : 4;
  var gutter = 12;
  
  html += "<div style=\"display:grid;grid-template-columns:repeat(" + columns + ",1fr);gap:" + gutter + "px;padding:12px 16px 16px\">";
  
  for (var i = 0; i < materials.length; i++) {
    html += renderMaterialGridCard(materials[i], isPhone, c);
  }
  
  html += "</div>";
  return html;
}

/** 渲染单个角色卡片 */
function renderCharacterCard(charData, isPhone, c, isExpanded) {
  var html = "";
  
  var cardRadius = isPhone ? 12 : 16;
  html += "<div class=\"ml-card\" style=\"background:" + c.surfCard + ";border-radius:" + cardRadius + "px;margin-bottom:16px;border:1px solid " + c.div + ";overflow:hidden\">";
  
  // ─── 卡片主体 ─────────────────────────────────────────
  html += "<div style=\"display:flex;align-items:flex-start;padding:12px 16px;cursor:pointer\" onclick=\"toggleCharacterExpand(" + charData.characterId + ")\">";
  
  // 左侧：头像 + 技能
  var hasSkills = charData.skills && charData.skills.length > 0;
  html += "<div style=\"display:flex;flex-direction:column;align-items:center;gap:8px;flex-shrink:0\">";
  
  // 角色头像
  var avatarSize = isPhone ? 48 : 52;
  var avatarFS = isPhone ? 24 : 26;
  var avatarBg = getElementGradient(ML_STATE.selectedGame, charData);
  html += "<div style=\"width:" + avatarSize + "px;height:" + avatarSize + "px;border-radius:12px;background:" + avatarBg + ";display:flex;align-items:center;justify-content:center;font-size:" + avatarFS + "px\">" + charData.characterIcon + "</div>";
  
  // 技能图标（纵向排列）
  if (hasSkills) {
    var skillIconSize = isPhone ? 28 : 32;
    var skillIconFS = isPhone ? 14 : 16;
    
    for (var i = 0; i < charData.skills.length; i++) {
      var skill = charData.skills[i];
      html += "<div style=\"position:relative;width:" + skillIconSize + "px;height:" + skillIconSize + "px\">";
      
      // 深色背景
      html += "<div style=\"width:100%;height:100%;border-radius:6px;background:" + c.bgDeep + "\"></div>";
      
      // 技能图标
      if (skill.icon) {
        html += "<div style=\"position:absolute;top:0;left:0;width:100%;height:100%;display:flex;align-items:center;justify-content:center;font-size:" + skillIconFS + "px\">" + skill.icon + "</div>";
      }
      
      // 等级标签（右下角）
      html += "<div style=\"position:absolute;right:2px;bottom:2px;background:" + c.primary + ";color:#fff;font-size:9px;padding:1px 4px;border-radius:3px;font-weight:600\">" + skill.level + "</div>";
      html += "</div>";
    }
  }
  
  html += "</div>"; // 左侧结束
  
  // 右侧：名字 + 等级 + 武器
  html += "<div style=\"flex:1;margin-left:12px;display:flex;flex-direction:column;gap:8px;min-width:0\">";
  
  // 名字 + 等级
  var nameSize = isPhone ? 15 : 16;
  html += "<div style=\"display:flex;align-items:baseline;gap:8px\">";
  html += "<span style=\"font-size:" + nameSize + "px;font-weight:600;color:" + c.txt + "\">" + charData.characterName + "</span>";
  html += "<span style=\"font-size:13px;color:" + c.txt2 + "\">Lv." + charData.characterLevel + "</span>";
  html += "</div>";
  
  // 武器/光锥信息
  var equipData = ML_STATE.selectedGame === "starrail" ? charData.lightCone : charData.weapon;
  if (equipData) {
    html += "<div style=\"display:flex;align-items:center;gap:8px\">";
    
    // 武器图标（带稀有度背景）
    var weaponIconSize = isPhone ? 32 : 36;
    var weaponIconFS = isPhone ? 16 : 18;
    var weaponBg = getRarityGradient(equipData.rarity || 5);
    html += "<div style=\"width:" + weaponIconSize + "px;height:" + weaponIconSize + "px;border-radius:6px;background:" + weaponBg + ";display:flex;align-items:center;justify-content:center;font-size:" + weaponIconFS + "px\">" + (equipData.icon || "⚔") + "</div>";
    
    // 武器名 + 等级
    html += "<span style=\"font-size:14px;color:" + c.txt + "\">" + equipData.name + "</span>";
    html += "<span style=\"font-size:13px;font-weight:600;color:" + c.primary + "\">Lv." + equipData.level + "</span>";
    html += "</div>";
  }
  
  html += "</div>"; // 右侧结束
  
  // 展开箭头
  var arrowDeg = isExpanded ? 90 : 0;
  html += "<div style=\"width:24px;height:24px;display:flex;align-items:center;justify-content:center;transform:rotate(" + arrowDeg + "deg);flex-shrink:0;margin-left:8px\">";
  html += "<span style=\"font-size:14px;color:" + c.txtM + "\">›</span></div>";
  
  html += "</div>"; // 卡片主体结束
  
  // ─── 展开区域：材料列表 ─────────────────────────────────────────
  if (isExpanded) {
    html += "<div style=\"border-top:1px solid " + c.div + "\">";
    
    if (charData.avatarMaterials && charData.avatarMaterials.length > 0) {
      html += renderMaterialSection("角色突破材料", charData.avatarMaterials, isPhone, c);
    }
    
    if (charData.skillMaterials && charData.skillMaterials.length > 0) {
      html += renderMaterialSection(getSkillLabel(ML_STATE.selectedGame), charData.skillMaterials, isPhone, c);
    }
    
    var equipMaterials = ML_STATE.selectedGame === "starrail" ? charData.lightConeMaterials : charData.weaponMaterials;
    if (equipMaterials && equipMaterials.length > 0) {
      html += renderMaterialSection(getEquipMaterialLabel(ML_STATE.selectedGame), equipMaterials, isPhone, c);
    }
    
    html += "</div>";
  }
  
  html += "</div>";
  return html;
}

/** 渲染材料区块 */
function renderMaterialSection(title, materials, isPhone, c) {
  var html = "";
  html += "<div style=\"padding:10px 16px 14px\">";
  html += "<div style=\"font-size:12px;color:" + c.txtM + ";margin-bottom:8px;font-weight:500\">" + title + "</div>";
  
  for (var i = 0; i < materials.length; i++) {
    var m = materials[i];
    var isEnough = m.deficit <= 0;
    var progress = m.need > 0 ? Math.min(100, Math.round((m.have / m.need) * 100)) : 0;
    
    html += "<div class=\"ml-material-row\" style=\"display:flex;align-items:center;padding:10px;background:" + c.bgDeep + ";border-radius:8px;margin-bottom:6px\">";
    
    var iconSize = isPhone ? 32 : 36;
    var iconFS = isPhone ? 16 : 18;
    html += "<div style=\"width:" + iconSize + "px;height:" + iconSize + "px;border-radius:8px;background:" + getRarityGradient(m.rarity) + ";display:flex;align-items:center;justify-content:center;font-size:" + iconFS + "px\">" + m.icon + "</div>";
    
    html += "<div style=\"flex:1;margin-left:12px;min-width:0\">";
    var matNameSize = isPhone ? 13 : 14;
    html += "<div style=\"font-size:" + matNameSize + "px;color:" + c.txt + ";font-weight:500;white-space:nowrap;overflow:hidden;text-overflow:ellipsis\">" + m.name + "</div>";
    html += "<div style=\"display:flex;align-items:center;gap:8px;margin-top:4px\">";
    html += "<div style=\"flex:1;height:3px;background:" + c.div + ";border-radius:2px;overflow:hidden;max-width:80px\">";
    var progressColor = isEnough ? c.ok : c.primary;
    html += "<div style=\"height:100%;width:" + progress + "%;background:" + progressColor + ";border-radius:2px\"></div></div>";
    html += "<span style=\"font-size:12px;color:" + c.txt2 + "\">" + m.have + "/" + m.need + "</span></div>";
    html += "</div>";
    
    html += "<div style=\"margin-left:10px;min-width:48px;text-align:right\">";
    if (m.deficit > 0) {
      html += "<span style=\"font-size:13px;font-weight:600;color:" + c.danger + "\">-" + m.deficit + "</span>";
    } else {
      html += "<span style=\"font-size:12px;color:" + c.ok + "\">✓</span>";
    }
    html += "</div></div>";
  }
  
  html += "</div>";
  return html;
}

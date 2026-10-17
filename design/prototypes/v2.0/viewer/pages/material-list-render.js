/**
 * material-list-render.js — 材料汇总渲染函数
 */

/** 渲染材料汇总页面 */
function renderMaterialList(w, h) {
  var c = T();
  var isPhone = w < 520;

  var html = "";
  html += baseCss(w, h) + SK_ANIM;
  html += "<style>";
  html += ".ml-card{transition:transform 0.15s,box-shadow 0.15s}";
  html += ".ml-card:hover{transform:scale(1.01);box-shadow:0 4px 16px rgba(77,163,255,0.1)}";
  html += ".ml-expand{transition:transform 0.2s}";
  html += ".ml-material-row:hover{background:rgba(77,163,255,0.05)}";
  html += ".ml-view-btn{transition:all 0.15s}";
  html += ".ml-view-btn:hover{transform:scale(1.05)}";
  html += "</style>";

  html += "<div style=\"width:" + w + "px;height:" + h + "px;display:flex;flex-direction:column;background:" + c.pageBg + "\">";
  
  // Header
  var headerH = isPhone ? 48 : 56;
  var headerPad = isPhone ? 16 : 24;
  html += "<div style=\"height:" + headerH + "px;display:flex;align-items:center;padding:0 " + headerPad + "px;border-bottom:1px solid " + c.div + ";flex-shrink:0\">";
  html += "<button style=\"width:32px;height:32px;display:flex;align-items:center;justify-content:center;border:none;background:transparent;border-radius:8px;cursor:pointer\">";
  html += "<span style=\"font-size:20px;color:" + c.txt + "\">←</span></button>";
  var titleSize = isPhone ? 16 : 18;
  html += "<h1 style=\"flex:1;margin:0 16px;font-size:" + titleSize + "px;font-weight:600;color:" + c.txt + "\">材料汇总</h1>";
  html += "</div>";

  // 游戏筛选 Tab
  var filterPad = isPhone ? 12 : 16;
  html += "<div style=\"padding:" + filterPad + "px;padding-bottom:8px;display:flex;gap:8px;overflow-x:auto;scrollbar-width:none;border-bottom:1px solid " + c.div + "\">";
  for (var i = 0; i < ML_GAME_OPTIONS.length; i++) {
    var opt = ML_GAME_OPTIONS[i];
    var isActive = ML_STATE.selectedGame === opt.value;
    var btnBg = isActive ? opt.color : c.surfCard;
    var btnColor = isActive ? "#fff" : c.txt2;
    html += "<button class=\"ml-view-btn\" style=\"display:flex;align-items:center;gap:6px;padding:10px 20px;border-radius:20px;border:none;background:" + btnBg + ";color:" + btnColor + ";font-size:14;font-weight:500;cursor:pointer;white-space:nowrap\" onclick=\"setMaterialListGame('" + opt.value + "')\">";
    html += opt.icon + " " + opt.label + "</button>";
  }
  html += "</div>";
  
  // 视图模式切换
  html += "<div style=\"padding:8px " + filterPad + "px;display:flex;align-items:center;gap:8px;border-bottom:1px solid " + c.div + "\">";
  html += "<span style=\"font-size:12px;color:" + c.txtM + "\">视图：</span>";
  for (var i = 0; i < ML_VIEW_OPTIONS.length; i++) {
    var view = ML_VIEW_OPTIONS[i];
    var isActive = ML_STATE.viewMode === view.value;
    var viewBg = isActive ? c.primary : "transparent";
    var viewColor = isActive ? "#fff" : c.txt2;
    var viewBorder = isActive ? "none" : "1px solid " + c.div;
    html += "<button class=\"ml-view-btn\" style=\"display:flex;align-items:center;gap:4px;padding:6px 12px;border-radius:14px;border:" + viewBorder + ";background:" + viewBg + ";color:" + viewColor + ";font-size:12px;font-weight:500;cursor:pointer\" onclick=\"setMaterialListView('" + view.value + "')\">";
    html += view.icon + " " + view.label + "</button>";
  }
  html += "</div>";

  // 内容区
  html += "<div style=\"flex:1;overflow-y:auto;padding:" + (isPhone ? 12 : 16) + "px\" class=\"sy\">";

  if (ML_STATE.viewMode === "character") {
    var data = getGameMaterialData();
    for (var i = 0; i < data.length; i++) {
      var charData = data[i];
      var isExpanded = ML_STATE.expandedCharacters[charData.characterId] !== false;
      html += renderCharacterCard(charData, isPhone, c, isExpanded);
    }
  } else {
    var mergedMaterials = mergeAllMaterials();
    html += renderMaterialSummary(mergedMaterials, isPhone, c);
  }

  html += "</div></div>";
  return html;
}

/** 渲染按材料汇总视图 */
function renderMaterialSummary(materials, isPhone, c) {
  var html = "";
  
  // 只显示有缺口的材料
  var deficitMaterials = [];
  for (var i = 0; i < materials.length; i++) {
    if (materials[i].deficit > 0) {
      deficitMaterials.push(materials[i]);
    }
  }
  
  if (deficitMaterials.length === 0) {
    html += "<div style=\"display:flex;align-items:center;justify-content:center;height:200px\">";
    html += "<div style=\"text-align:center\">";
    html += "<div style=\"font-size:48px;margin-bottom:12px\">✅</div>";
    html += "<div style=\"font-size:14px;color:" + c.txt2 + "\">材料充足，无需补充</div>";
    html += "</div></div>";
    return html;
  }
  
  // 按稀有度分组
  var groups = {};
  for (var i = 0; i < deficitMaterials.length; i++) {
    var m = deficitMaterials[i];
    var key = m.rarity;
    if (!groups[key]) groups[key] = [];
    groups[key].push(m);
  }
  
  var rarities = [5, 4, 3, 2, 1];
  for (var r = 0; r < rarities.length; r++) {
    var rarity = rarities[r];
    if (!groups[rarity]) continue;
    
    var groupMaterials = groups[rarity];
    var rarityColor = getRarityColorV2(rarity);
    
    html += "<div style=\"margin-bottom:20px\">";
    html += "<div style=\"display:flex;align-items:center;gap:8px;margin-bottom:12px\">";
    html += "<div style=\"width:4px;height:16px;background:" + rarityColor + ";border-radius:2px\"></div>";
    html += "<span style=\"font-size:13px;color:" + c.txt + ";font-weight:500\">" + rarity + "星材料</span>";
    html += "<span style=\"font-size:12px;color:" + c.txtM + "\">" + groupMaterials.length + "种</span></div>";
    
    // 紧凑网格布局
    html += "<div style=\"display:flex;flex-wrap:wrap;gap:10px\">";
    
    for (var i = 0; i < groupMaterials.length; i++) {
      var m = groupMaterials[i];
      
      // 紧凑材料卡片
      html += "<div style=\"position:relative;width:" + (isPhone ? 56 : 64) + "px;height:" + (isPhone ? 56 : 64) + "px;border-radius:10px;background:" + getRarityGradient(m.rarity) + ";display:flex;align-items:center;justify-content:center;cursor:pointer;transition:transform 0.15s\" onmouseover=\"this.style.transform='scale(1.08)'\" onmouseout=\"this.style.transform='scale(1)'\">";
      html += "<span style=\"font-size:" + (isPhone ? 24 : 28) + "px\">" + m.icon + "</span>";
      
      // 右下角缺口数量角标
      html += "<div style=\"position:absolute;right:-4px;bottom:-4px;min-width:20px;height:20px;padding:0 6px;background:" + c.danger + ";border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:700;color:#fff;box-shadow:0 2px 4px rgba(0,0,0,0.3)\">" + m.deficit + "</div>";
      
      html += "</div>";
    }
    
    html += "</div></div>";
  }
  
  return html;
}

/**
 * material-target-config.js — 养成目标配置页面原型
 * 
 * 用户在此页面设置：
 * - 点击等级行 → 依次弹出两个单列 Picker（先选当前等级，再选目标等级）
 * - 目标等级 >= 当前等级（联动约束）
 * 
 * 配置后进入材料汇总页面。
 */

/** 页面状态 */
var MTC_STATE = {
  selectedGame: "genshin",
  // 原神配置
  genshinAvatar: { current: 1, target: 90 },
  genshinSkill: { current: 1, target: 10 },
  genshinWeapon: { current: 1, target: 90 },
  // 星铁配置（技能是逐个配置的，这里简化为统一设置）
  starrailAvatar: { current: 1, target: 80 },
  starrailSkill: { current: 1, target: 10 },
  starrailLightCone: { current: 1, target: 80 },
  // 绝区零配置
  zzzAvatar: { current: 1, target: 60 },
  zzzWeapon: { current: 1, target: 60 },  // 音擎等级
  // 绝区零技能（6个独立技能，对应 skill_type）
  zzzSkill0: { current: 1, target: 12, label: "普通攻击" },   // skill_type=0
  zzzSkill1: { current: 1, target: 12, label: "闪避" },       // skill_type=1
  zzzSkill2: { current: 1, target: 12, label: "支援技" },     // skill_type=2
  zzzSkill3: { current: 1, target: 12, label: "特殊技" },     // skill_type=3
  zzzSkill5: { current: 1, target: 12, label: "连携技" },     // skill_type=5
  zzzSkill6: { current: 1, target: 12, label: "核心技" },     // skill_type=6
  // Picker 弹窗状态（官方 TextPickerDialog 只支持单列）
  showPicker: null,       // 当前显示的 picker key
  pickerStep: "current",  // "current" 或 "target"，区分当前等级/目标等级
  pickerValue: 1,         // Picker 当前选中的值
  pickerMaxValue: 90,     // Picker 最大值
  tempCurrentValue: 1,    // 第一步选中的当前等级（用于第二步联动）
};

/** 游戏选项 */
var MTC_GAME_OPTIONS = [
  { value: "genshin", label: "原神", color: "#5BA3E8", icon: "🌍" },
  { value: "starrail", label: "星铁", color: "#9B8EFF", icon: "🌟" },
  { value: "zzz", label: "绝区零", color: "#F7B84B", icon: "⚡" },
];

/** 等级范围配置（max, label）*/
var MTC_LEVEL_RANGES = {
  // 原神
  genshinAvatar: { max: 90, label: "角色等级" },
  genshinSkill: { max: 10, label: "技能等级" },
  genshinWeapon: { max: 90, label: "武器等级" },
  // 星铁
  starrailAvatar: { max: 80, label: "角色等级" },
  starrailSkill: { max: 10, label: "技能等级" },
  starrailLightCone: { max: 80, label: "光锥等级" },
  // 绝区零
  zzzAvatar: { max: 60, label: "角色等级" },
  zzzWeapon: { max: 60, label: "音擎等级" },
  // 绝区零技能（skill_type 对应）
  zzzSkill0: { max: 12, label: "普通攻击" },
  zzzSkill1: { max: 12, label: "闪避" },
  zzzSkill2: { max: 12, label: "支援技" },
  zzzSkill3: { max: 12, label: "特殊技" },
  zzzSkill5: { max: 12, label: "连携技" },
  zzzSkill6: { max: 12, label: "核心技" },
};

/** 渲染养成目标配置页面 */
function renderMaterialTargetConfig(w, h) {
  var c = T();
  var isPhone = w < 520;

  var html = "";
  html += baseCss(w, h);
  html += "<style>";
  html += ".mtc-card{transition:transform 0.15s,box-shadow 0.15s}";
  html += ".mtc-card:hover{transform:translateY(-2px);box-shadow:0 4px 16px rgba(77,163,255,0.15)}";
  html += ".mtc-option{transition:all 0.15s;cursor:pointer}";
  html += ".mtc-option:hover{transform:scale(1.02)}";
  html += ".mtc-option.selected{transform:scale(1);box-shadow:0 0 0 2px " + c.primary + "}";
  html += ".mtc-btn{transition:all 0.15s}";
  html += ".mtc-btn:hover{transform:scale(1.02);box-shadow:0 4px 12px rgba(77,163,255,0.3)}";
  html += ".mtc-level-row{transition:background 0.15s;cursor:pointer}";
  html += ".mtc-level-row:hover{background:rgba(77,163,255,0.08)}";
  // 官方 TextPickerDialog 样式模拟
  html += ".mtc-picker-overlay{position:fixed;inset:0;background:rgba(0,0,0,0.6);display:flex;align-items:flex-end;justify-content:center;z-index:100}";
  html += ".mtc-picker-panel{width:100%;background:" + c.surfCard + ";border-radius:24px 24px 0 0;padding:16px;max-height:60%}";
  html += ".mtc-picker-wheel{height:220px;overflow-y:auto;scroll-snap-type:y mandatory;-webkit-overflow-scrolling:touch}";
  html += ".mtc-picker-item{height:44px;display:flex;align-items:center;justify-content:center;font-size:18px;color:" + c.txt2 + ";scroll-snap-align:center;cursor:pointer;transition:all 0.15s}";
  html += ".mtc-picker-item.selected{color:" + c.primary + ";font-weight:600;font-size:22px;background:rgba(77,163,255,0.1);border-radius:8px}";
  html += ".mtc-picker-item.disabled{color:" + c.div + ";cursor:not-allowed;opacity:0.4}";
  html += "</style>";

  html += "<div style=\"width:" + w + "px;height:" + h + "px;display:flex;flex-direction:column;background:" + c.pageBg + ";position:relative\">";

  // Header
  var headerH = isPhone ? 48 : 56;
  var headerPad = isPhone ? 16 : 24;
  html += "<div style=\"height:" + headerH + "px;display:flex;align-items:center;padding:0 " + headerPad + "px;border-bottom:1px solid " + c.div + ";flex-shrink:0\">";
  html += "<button style=\"width:32px;height:32px;display:flex;align-items:center;justify-content:center;border:none;background:transparent;border-radius:8px;cursor:pointer\" onclick=\"setPage('tools')\">";
  html += "<span style=\"font-size:20px;color:" + c.txt + "\">←</span></button>";
  var titleSize = isPhone ? 16 : 18;
  html += "<h1 style=\"flex:1;margin:0 16px;font-size:" + titleSize + "px;font-weight:600;color:" + c.txt + "\">养成目标配置</h1>";
  html += "</div>";

  // 内容区
  html += "<div style=\"flex:1;overflow-y:auto;padding:" + (isPhone ? 16 : 24) + "px\" class=\"sy\">";

  // 游戏选择
  html += "<div style=\"margin-bottom:" + (isPhone ? 20 : 24) + "px\">";
  html += "<div style=\"font-size:13px;color:" + c.txtM + ";margin-bottom:10px;font-weight:500\">选择游戏</div>";
  html += "<div style=\"display:flex;gap:10px\">";
  for (var i = 0; i < MTC_GAME_OPTIONS.length; i++) {
    var opt = MTC_GAME_OPTIONS[i];
    var isActive = MTC_STATE.selectedGame === opt.value;
    var btnBg = isActive ? opt.color : c.surfCard;
    var btnColor = isActive ? "#fff" : c.txt2;
    var btnBorder = isActive ? "none" : "1px solid " + c.div;
    html += "<button class=\"mtc-option" + (isActive ? " selected" : "") + "\" style=\"display:flex;align-items:center;gap:6px;padding:" + (isPhone ? "10px 16px" : "12px 20px") + ";border-radius:12px;border:" + btnBorder + ";background:" + btnBg + ";color:" + btnColor + ";font-size:14px;font-weight:500\" onclick=\"mtcSetGame('" + opt.value + "')\">";
    html += opt.icon + " " + opt.label + "</button>";
  }
  html += "</div></div>";

  // 原神配置
  if (MTC_STATE.selectedGame === "genshin") {
    html += renderGenshinConfig(isPhone, c);
  }

  // 星铁配置
  if (MTC_STATE.selectedGame === "starrail") {
    html += renderStarRailConfig(isPhone, c);
  }

  // 绝区零配置
  if (MTC_STATE.selectedGame === "zzz") {
    html += renderZZZConfig(isPhone, c);
  }

  html += "</div>";

  // 底部按钮
  html += "<div style=\"padding:" + (isPhone ? 12 : 16) + "px;border-top:1px solid " + c.div + ";flex-shrink:0\">";
  html += "<button class=\"mtc-btn\" style=\"width:100%;height:48px;border-radius:12px;border:none;background:" + c.primary + ";color:#fff;font-size:16px;font-weight:600;cursor:pointer\" onclick=\"setPage('material-list')\">";
  html += "开始计算材料</button>";
  html += "</div>";

  // Picker 弹窗（官方 TextPickerDialog 模拟）
  if (MTC_STATE.showPicker) {
    html += renderSinglePicker(w, h, c, isPhone);
  }

  html += "</div>";
  return html;
}

/** 渲染原神配置 */
function renderGenshinConfig(isPhone, c) {
  var html = "";

  // 说明文字
  html += "<div style=\"margin-bottom:20px;padding:12px;background:" + c.surfCard + ";border-radius:12px;border:1px solid " + c.div + "\">";
  html += "<div style=\"font-size:13px;color:" + c.txt + ";line-height:1.6\">";
  html += "💡 点击等级行设置当前等级和目标等级，系统将计算升级所需的材料。";
  html += "</div></div>";

  // 角色等级
  html += renderLevelRow("角色等级", "genshinAvatar", MTC_STATE.genshinAvatar, isPhone, c);
  
  // 技能等级
  html += renderLevelRow("技能等级", "genshinSkill", MTC_STATE.genshinSkill, isPhone, c);
  
  // 武器等级
  html += renderLevelRow("武器等级", "genshinWeapon", MTC_STATE.genshinWeapon, isPhone, c);

  return html;
}

/** 渲染星铁配置 */
function renderStarRailConfig(isPhone, c) {
  var html = "";

  // 说明文字
  html += "<div style=\"margin-bottom:20px;padding:12px;background:" + c.surfCard + ";border-radius:12px;border:1px solid " + c.div + "\">";
  html += "<div style=\"font-size:13px;color:" + c.txt + ";line-height:1.6\">";
  html += "💡 星穹铁道角色满级为 80 级，光锥满级为 80 级。<br>";
  html += "<span style=\"color:" + c.txtM + ";font-size:12px\">注：技能等级为统一设置，实际计算时会应用到所有行迹。</span>";
  html += "</div></div>";

  // 角色等级
  html += renderLevelRow("角色等级", "starrailAvatar", MTC_STATE.starrailAvatar, isPhone, c);
  
  // 技能等级（星铁的技能叫"行迹"）
  html += renderLevelRow("行迹等级", "starrailSkill", MTC_STATE.starrailSkill, isPhone, c);
  
  // 光锥等级
  html += renderLevelRow("光锥等级", "starrailLightCone", MTC_STATE.starrailLightCone, isPhone, c);

  return html;
}

/** 渲染绝区零配置 */
function renderZZZConfig(isPhone, c) {
  var html = "";

  // 说明文字
  html += "<div style=\"margin-bottom:20px;padding:12px;background:" + c.surfCard + ";border-radius:12px;border:1px solid " + c.div + "\">";
  html += "<div style=\"font-size:13px;color:" + c.txt + ";line-height:1.6\">";
  html += "💡 绝区零角色满级为 60 级，技能满级为 12 级，音擎满级为 60 级。<br>";
  html += "<span style=\"color:" + c.txtM + ";font-size:12px\">注：绝区零有 6 个技能需要逐个配置。</span>";
  html += "</div></div>";

  // 角色等级
  html += renderLevelRow("角色等级", "zzzAvatar", MTC_STATE.zzzAvatar, isPhone, c);
  
  // 音擎等级
  html += renderLevelRow("音擎等级", "zzzWeapon", MTC_STATE.zzzWeapon, isPhone, c);

  // 技能等级标题
  html += "<div style=\"margin-top:16px;margin-bottom:8px;font-size:14px;font-weight:600;color:" + c.txt + "\">技能等级</div>";

  // 6 个技能
  html += renderLevelRow("普通攻击", "zzzSkill0", MTC_STATE.zzzSkill0, isPhone, c);
  html += renderLevelRow("闪避", "zzzSkill1", MTC_STATE.zzzSkill1, isPhone, c);
  html += renderLevelRow("支援技", "zzzSkill2", MTC_STATE.zzzSkill2, isPhone, c);
  html += renderLevelRow("特殊技", "zzzSkill3", MTC_STATE.zzzSkill3, isPhone, c);
  html += renderLevelRow("连携技", "zzzSkill5", MTC_STATE.zzzSkill5, isPhone, c);
  html += renderLevelRow("核心技", "zzzSkill6", MTC_STATE.zzzSkill6, isPhone, c);

  return html;
}

/** 渲染等级选择行（横向布局：左当前等级、右目标等级）*/
function renderLevelRow(label, key, value, isPhone, c) {
  var html = "";
  
  html += "<div style=\"margin-bottom:10px;padding:10px 12px;background:" + c.surfCard + ";border-radius:10px;border:1px solid " + c.div + "\">";
  
  // 标题行
  html += "<div style=\"font-size:12px;color:" + c.txtM + ";margin-bottom:8px;font-weight:500\">" + label + "</div>";
  
  // 横向两列：当前等级 | 目标等级
  html += "<div style=\"display:flex;gap:8px\">";
  
  // 左列：当前等级
  html += "<div class=\"mtc-level-row\" style=\"flex:1;padding:8px;background:" + c.pageBg + ";border-radius:6px;text-align:center;cursor:pointer\" onclick=\"mtcShowPicker('" + key + "', 'current')\">";
  html += "<div style=\"font-size:11px;color:" + c.txtM + ";margin-bottom:2px\">当前</div>";
  html += "<div style=\"font-size:18px;font-weight:600;color:" + c.txt + "\">" + value.current + "</div>";
  html += "</div>";
  
  // 右列：目标等级
  html += "<div class=\"mtc-level-row\" style=\"flex:1;padding:8px;background:" + c.pageBg + ";border-radius:6px;text-align:center;cursor:pointer\" onclick=\"mtcShowPicker('" + key + "', 'target')\">";
  html += "<div style=\"font-size:11px;color:" + c.txtM + ";margin-bottom:2px\">目标</div>";
  html += "<div style=\"font-size:18px;font-weight:600;color:" + c.primary + "\">" + value.target + "</div>";
  html += "</div>";
  
  html += "</div>";
  html += "</div>";
  
  return html;
}

/**
 * 渲染单列 Picker 弹窗（模拟官方 TextPickerDialog）
 * 
 * 分两步：
 * 1. pickerStep="current" → 选择当前等级
 * 2. pickerStep="target" → 选择目标等级（最小值为第一步选中的当前等级）
 */
function renderSinglePicker(w, h, c, isPhone) {
  var key = MTC_STATE.showPicker;
  var config = MTC_LEVEL_RANGES[key];
  if (!config) return "";

  var maxValue = config.max;
  var label = config.label;
  var isCurrentStep = MTC_STATE.pickerStep === "current";
  var minValue = isCurrentStep ? 1 : MTC_STATE.tempCurrentValue;  // 目标等级最小值为当前等级
  var currentValue = MTC_STATE.pickerValue;

  var html = "";
  html += "<div class=\"mtc-picker-overlay\" onclick=\"mtcClosePicker()\">";
  
  html += "<div class=\"mtc-picker-panel\" onclick=\"event.stopPropagation()\">";
  
  // Picker 头部（官方样式）
  html += "<div style=\"display:flex;align-items:center;justify-content:space-between;margin-bottom:12px\">";
  html += "<button style=\"padding:8px 16px;border:none;background:transparent;color:" + c.txtM + ";font-size:14px;cursor:pointer\" onclick=\"mtcClosePicker()\">取消</button>";
  
  // 标题区分当前等级/目标等级
  var titleText = isCurrentStep ? "选择当前等级" : "选择目标等级";
  html += "<span style=\"font-size:16px;font-weight:600;color:" + c.txt + "\">" + titleText + "</span>";
  
  html += "<button style=\"padding:8px 16px;border:none;background:" + c.primary + ";color:#fff;font-size:14px;font-weight:500;border-radius:8px;cursor:pointer\" onclick=\"mtcConfirmPicker()\">确定</button>";
  html += "</div>";
  
  // 步骤提示（仅目标等级时显示约束）
  if (!isCurrentStep) {
    html += "<div style=\"text-align:center;font-size:12px;color:" + c.txtM + ";margin-bottom:8px;padding:6px;background:" + c.pageBg + ";border-radius:8px\">";
    html += "目标等级 ≥ 当前等级（" + MTC_STATE.tempCurrentValue + " 级）";
    html += "</div>";
  }
  
  // 单列滚轮
  html += "<div class=\"mtc-picker-wheel\">";
  for (var i = minValue; i <= maxValue; i++) {
    var isSelected = i === currentValue;
    var itemClass = "mtc-picker-item";
    if (isSelected) itemClass += " selected";
    html += "<div class=\"" + itemClass + "\" onclick=\"mtcSelectValue(" + i + ")\">";
    html += i + " 级";
    html += "</div>";
  }
  html += "</div>";
  
  // 范围提示
  html += "<div style=\"text-align:center;font-size:12px;color:" + c.txtM + ";margin-top:12px\">";
  html += "可选范围：" + minValue + " ~ " + maxValue + " 级";
  html += "</div>";
  
  html += "</div>";
  html += "</div>";
  
  return html;
}

/** 显示 Picker（直接显示对应步骤）*/
function mtcShowPicker(key, step) {
  var config = MTC_LEVEL_RANGES[key];
  var currentValue = MTC_STATE[key];
  
  MTC_STATE.showPicker = key;
  MTC_STATE.pickerStep = step;  // "current" 或 "target"
  MTC_STATE.pickerMaxValue = config.max;
  MTC_STATE.tempCurrentValue = currentValue.current;  // 用于目标等级的最小值约束
  
  if (step === "current") {
    MTC_STATE.pickerValue = currentValue.current;
  } else {
    // 目标等级最小值为当前等级
    MTC_STATE.pickerValue = Math.max(currentValue.current, currentValue.target);
  }
  
  refresh();
}

/** 选择值 */
function mtcSelectValue(value) {
  MTC_STATE.pickerValue = value;
  refresh();
}

/** 确认选择 */
function mtcConfirmPicker() {
  var key = MTC_STATE.showPicker;
  if (!key) return;

  if (MTC_STATE.pickerStep === "current") {
    // 选择当前等级：更新当前等级，如果当前等级 > 目标等级，自动调整目标等级
    var newCurrent = MTC_STATE.pickerValue;
    var currentTarget = MTC_STATE[key].target;
    MTC_STATE[key] = {
      current: newCurrent,
      target: Math.max(newCurrent, currentTarget)
    };
  } else {
    // 选择目标等级：直接更新目标等级
    MTC_STATE[key].target = MTC_STATE.pickerValue;
  }
  
  MTC_STATE.showPicker = null;
  refresh();
}

/** 关闭 Picker */
function mtcClosePicker() {
  MTC_STATE.showPicker = null;
  MTC_STATE.pickerStep = "current";
  refresh();
}

/** 设置游戏 */
function mtcSetGame(game) {
  MTC_STATE.selectedGame = game;
  refresh();
}

/** 控制栏 */
function materialTargetConfigControls() {
  return [];
}

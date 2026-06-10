/**
 * wr-main.js — Widget 重设计：主渲染函数 + 控制项
 * 依赖：wr-data.js, wr-1x2.js, wr-2x2.js, wr-2x4.js, wr-4x4.js
 */

// ─────────────────────────────────────────────────────────────────
// 卡片尺寸说明（重要）
// ─────────────────────────────────────────────────────────────────
// 卡片尺寸（如 2×2）是网格单位，实际渲染尺寸（vp）由系统根据设备屏幕
// 大小和网格配置动态计算。不同设备的相同尺寸卡片，实际 vp 可能不同。
//
// 下面的尺寸值来自 X7 模拟器实测（2026-05-03），测量的是内容组件的实际渲染区域。
// 实际卡片 UI 应使用百分比布局或相对布局，不要硬编码 vp 值。
//
// 官方文档：FormDimension 枚举定义了所有支持的尺寸，但未提供具体 vp 值。
// 参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-formcomponent
// ─────────────────────────────────────────────────────────────────

// X7 模拟器实测尺寸（内容区域，不含外层 padding）
// 测量方法：组件 onAreaChange 回调获取实际渲染区域
var WR_SIZES = {
  "1x2": { w: 146, h: 52 },   // 实测内容 121.9×27.8 + padding 12vp
  "2x2": { w: 146, h: 146 },  // 实测内容 121.9×121.9 + padding 12vp
  "2x4": { w: 315, h: 146 },  // 实测内容 290.6×121.9 + padding 12vp
  "4x4": { w: 315, h: 334 },  // 实测内容 290.6×309.8 + padding 12vp
};

var WR_GAME_MAP = {
  genshin: ["genshin"],
  starrail: ["starrail"],
  zzz: ["zzz"],
  multi2: ["genshin", "starrail"],
  multi3: ["genshin", "starrail", "zzz"],
};

/**
 * 渲染间距标注覆盖层
 * 在卡片上方绘制标注线和数值
 */
function renderSpacingOverlay(size, game) {
  // 1x2 标注
  if (size === "1x2") {
    return '<div style="position:absolute;left:0;top:0;right:0;bottom:0;pointer-events:none">' +
      // padding 12vp 标注
      '<div style="position:absolute;left:0;top:50%;transform:translateY(-50%);display:flex;align-items:center">' +
        '<div style="width:12px;height:1px;background:#4fc3f7"></div>' +
        '<div style="font-size:9px;color:#4fc3f7;margin-left:2px">12vp</div>' +
      '</div>' +
      // 竖线与内容间距 8vp
      '<div style="position:absolute;left:12px;top:50%;transform:translateY(-50%);display:flex;align-items:center">' +
        '<div style="width:8px;height:1px;background:#ffca28"></div>' +
        '<div style="font-size:9px;color:#ffca28;margin-left:2px">8vp</div>' +
      '</div>' +
      // 游戏名与UID间距 4vp
      '<div style="position:absolute;left:23px;top:10px;display:flex;align-items:center">' +
        '<div style="width:4px;height:1px;background:#34d399"></div>' +
        '<div style="font-size:9px;color:#34d399;margin-left:2px">4vp</div>' +
      '</div>' +
      // 体力数字与/max间距 2vp
      '<div style="position:absolute;left:23px;top:28px;display:flex;align-items:center">' +
        '<div style="width:2px;height:1px;background:#f7b84b"></div>' +
        '<div style="font-size:9px;color:#f7b84b;margin-left:2px">2vp</div>' +
      '</div>' +
    '</div>';
  }
  
  // 2x2 单游戏标注
  if (size === "2x2" && (game === "genshin" || game === "starrail" || game === "zzz")) {
    return '<div style="position:absolute;left:0;top:0;right:0;bottom:0;pointer-events:none">' +
      // padding 12vp 标注
      '<div style="position:absolute;left:0;top:12px;display:flex;align-items:center">' +
        '<div style="width:12px;height:1px;background:#4fc3f7"></div>' +
        '<div style="font-size:9px;color:#4fc3f7;margin-left:2px">12vp</div>' +
      '</div>' +
      // 游戏名与UID间距 1vp
      '<div style="position:absolute;left:12px;top:14px;display:flex;align-items:center">' +
        '<div style="width:8px;height:1px;background:#34d399"></div>' +
        '<div style="font-size:9px;color:#34d399;margin-left:2px">1vp</div>' +
      '</div>' +
      // 头部与体力区块间距 6vp
      '<div style="position:absolute;left:60px;top:35px;display:flex;align-items:center">' +
        '<div style="width:6px;height:1px;background:#ffca28"></div>' +
        '<div style="font-size:9px;color:#ffca28;margin-left:2px">6vp</div>' +
      '</div>' +
      // 体力数字与/max间距 3vp
      '<div style="position:absolute;left:24px;top:48px;display:flex;align-items:center">' +
        '<div style="width:3px;height:1px;background:#f7b84b"></div>' +
        '<div style="font-size:9px;color:#f7b84b;margin-left:2px">3vp</div>' +
      '</div>' +
      // 体力行与恢复时间间距 2vp
      '<div style="position:absolute;left:24px;top:72px;display:flex;align-items:center">' +
        '<div style="width:2px;height:1px;background:#ef5350"></div>' +
        '<div style="font-size:9px;color:#ef5350;margin-left:2px">2vp</div>' +
      '</div>' +
      // 体力区块与数据行间距 8vp
      '<div style="position:absolute;left:60px;top:90px;display:flex;align-items:center">' +
        '<div style="width:8px;height:1px;background:#9b8eff"></div>' +
        '<div style="font-size:9px;color:#9b8eff;margin-left:2px">8vp</div>' +
      '</div>' +
      // 数据行之间间距 5vp
      '<div style="position:absolute;left:24px;top:108px;display:flex;align-items:center">' +
        '<div style="width:5px;height:1px;background:#4fc3f7"></div>' +
        '<div style="font-size:9px;color:#4fc3f7;margin-left:2px">5vp</div>' +
      '</div>' +
    '</div>';
  }
  
  // 2x2 多游戏标注
  if (size === "2x2" && (game === "multi2" || game === "multi3")) {
    return '<div style="position:absolute;left:0;top:0;right:0;bottom:0;pointer-events:none">' +
      // padding 12vp
      '<div style="position:absolute;left:0;top:12px;display:flex;align-items:center">' +
        '<div style="width:12px;height:1px;background:#4fc3f7"></div>' +
        '<div style="font-size:9px;color:#4fc3f7;margin-left:2px">12vp</div>' +
      '</div>' +
      // 竖线与内容间距 8vp
      '<div style="position:absolute;left:12px;top:40px;display:flex;align-items:center">' +
        '<div style="width:8px;height:1px;background:#ffca28"></div>' +
        '<div style="font-size:9px;color:#ffca28;margin-left:2px">8vp</div>' +
      '</div>' +
      // 竖线宽度 3vp
      '<div style="position:absolute;left:12px;top:55px;display:flex;flex-direction:column;align-items:center">' +
        '<div style="width:1px;height:3px;background:#34d399"></div>' +
        '<div style="font-size:9px;color:#34d399;margin-top:2px">3vp</div>' +
      '</div>' +
      // 分隔线margin 4vp
      '<div style="position:absolute;right:12px;top:78px;display:flex;align-items:center">' +
        '<div style="width:4px;height:1px;background:#ef5350"></div>' +
        '<div style="font-size:9px;color:#ef5350;margin-left:2px">4vp</div>' +
      '</div>' +
    '</div>';
  }
  
  // 2x4 标注
  if (size === "2x4") {
    return '<div style="position:absolute;left:0;top:0;right:0;bottom:0;pointer-events:none">' +
      // padding 12vp
      '<div style="position:absolute;left:0;top:12px;display:flex;align-items:center">' +
        '<div style="width:12px;height:1px;background:#4fc3f7"></div>' +
        '<div style="font-size:9px;color:#4fc3f7;margin-left:2px">12vp</div>' +
      '</div>' +
      // 左右区块间距 12vp
      '<div style="position:absolute;left:90px;top:50%;transform:translateY(-50%);display:flex;align-items:center">' +
        '<div style="width:12px;height:1px;background:#ffca28"></div>' +
        '<div style="font-size:9px;color:#ffca28;margin-left:2px">12vp</div>' +
      '</div>' +
    '</div>';
  }
  
  // 4x4 标注
  if (size === "4x4") {
    return '<div style="position:absolute;left:0;top:0;right:0;bottom:0;pointer-events:none">' +
      // padding 12vp
      '<div style="position:absolute;left:0;top:12px;display:flex;align-items:center">' +
        '<div style="width:12px;height:1px;background:#4fc3f7"></div>' +
        '<div style="font-size:9px;color:#4fc3f7;margin-left:2px">12vp</div>' +
      '</div>' +
      // 头部与体力区块间距 8vp
      '<div style="position:absolute;left:60px;top:38px;display:flex;align-items:center">' +
        '<div style="width:8px;height:1px;background:#ffca28"></div>' +
        '<div style="font-size:9px;color:#ffca28;margin-left:2px">8vp</div>' +
      '</div>' +
      // 区块间距（border）
      '<div style="position:absolute;right:12px;top:95px;display:flex;align-items:center">' +
        '<div style="width:1px;height:1px;background:#ef5350"></div>' +
        '<div style="font-size:9px;color:#ef5350;margin-left:2px">border</div>' +
      '</div>' +
    '</div>';
  }
  
  return '';
}

function renderWidgetRedesign(w, h) {
  var c = T();
  var size = WR.state.size;
  var game = WR.state.game;
  var sz = WR_SIZES[size] || WR_SIZES["2x2"];
  var games = WR_GAME_MAP[game] || ["genshin"];

  // 渲染新版卡片
  var cardHtml = "";
  if (size === "1x2") {
    var gid = game === "multi2" || game === "multi3" ? "genshin" : game;
    cardHtml = wrRender1x2(sz.w, sz.h, gid);
  } else if (size === "2x2") {
    cardHtml = wrRender2x2(sz.w, sz.h, games);
  } else if (size === "2x4") {
    cardHtml = wrRender2x4(sz.w, sz.h, games);
  } else if (size === "4x4") {
    cardHtml = wrRender4x4(sz.w, sz.h, games);
  }
  
  // 间距标注覆盖层
  var spacingOverlay = renderSpacingOverlay(size, game);
  cardHtml = '<div style="position:relative">' + cardHtml + spacingOverlay + '</div>';

  var sizeLabels = {
    "1x2": "1×2 迷你（X7实测 146×52vp）",
    "2x2": "2×2 标准（X7实测 146×146vp）",
    "2x4": "2×4 宽幅（X7实测 315×146vp）",
    "4x4": "4×4 大卡片（X7实测 315×334vp）",
  };
  var gameLabels = {
    genshin: "原神（单游戏）",
    starrail: "星铁（单游戏）",
    zzz: "绝区零（单游戏）",
    multi2: "原神+星铁（2款）",
    multi3: "三款游戏",
  };

  // 桌面背景模拟
  var deskBg =
    G.theme === "dark"
      ? "linear-gradient(135deg,#0a0a18 0%,#0d1020 50%,#080810 100%)"
      : "linear-gradient(135deg,#e8eaf6 0%,#e3f2fd 50%,#f3e5f5 100%)";

  // 设计说明
  var notes = [
    "✦ 体力环充满内容高度，成为视觉锚点",
    "✦ 去掉 Divider，改用间距和颜色层级区分区域",
    "✦ 游戏主题色只用在体力数值和关键高亮上",
    "✦ 数据行标签 45% 透明度，数值 85% 透明度，形成层级",
    "✦ 四周严格保留 12vp 安全间距（官方规范）",
  ];
  var notesHtml = "";
  for (var i = 0; i < notes.length; i++) {
    notesHtml +=
      '<div style="font-size:11px;color:' +
      c.txt2 +
      ';line-height:1.8">' +
      notes[i] +
      "</div>";
  }
  
  // 间距标注图例
  var spacingLegend = [
    { color: "#4fc3f7", label: "PAD_CARD 12vp" },
    { color: "#ffca28", label: "GAP_SECTION 6vp / 竖线间距 8vp" },
    { color: "#34d399", label: "GAP_NORMAL 4vp / 游戏名↔UID 1vp" },
    { color: "#f7b84b", label: "体力数字间距 2-3vp" },
    { color: "#ef5350", label: "GAP_TIGHT 2vp / 分隔线margin 4vp" },
    { color: "#9b8eff", label: "GAP_BLOCK 8vp" },
  ];
  var legendHtml = '<div style="font-size:11px;font-weight:600;color:' + c.txt + ';margin:16px 0 8px">间距标注图例</div>';
  for (var j = 0; j < spacingLegend.length; j++) {
    legendHtml +=
      '<div style="display:flex;align-items:center;gap:6px;margin-bottom:4px">' +
      '<div style="width:12px;height:2px;background:' + spacingLegend[j].color + ';border-radius:1px"></div>' +
      '<span style="font-size:10px;color:' + c.txt2 + '">' + spacingLegend[j].label + '</span>' +
      '</div>';
  }

  return (
    baseCss(w, h) +
    '<div style="width:' +
    w +
    "px;height:" +
    h +
    'px;display:flex;flex-direction:column;overflow:hidden">' +
    // 标题栏
    '<div style="padding:12px 16px 8px;flex-shrink:0">' +
    '<div style="font-size:13px;font-weight:600;color:' +
    c.txt +
    ';margin-bottom:2px">Widget 卡片预览</div>' +
    '<div style="font-size:11px;color:' +
    c.txt2 +
    '">' +
    (sizeLabels[size] || size) +
    " · " +
    (gameLabels[game] || game) +
    "</div></div>" +
    // 主区域：左侧卡片预览，右侧设计说明
    '<div class="sy" style="flex:1;display:flex;gap:0;min-height:0">' +
    // 卡片预览区（桌面背景）
    '<div style="flex:1;display:flex;align-items:center;justify-content:center;background:' +
    deskBg +
    ';padding:20px">' +
    cardHtml +
    "</div>" +
    // 设计说明侧边栏
    '<div style="width:220px;flex-shrink:0;background:' +
    c.cardBg +
    ";border-left:1px solid " +
    c.border +
    ';padding:16px;overflow-y:auto">' +
    '<div style="font-size:11px;font-weight:600;color:' +
    c.txt +
    ';margin-bottom:10px">设计原则</div>' +
    notesHtml +
    legendHtml +
    "</div>" +
    "</div></div>"
  );
}

function widgetRedesignControls() {
  return [
    {
      id: "size",
      label: "卡片尺寸",
      current: function () {
        return WR.state.size;
      },
      options: [
        { value: "1x2", label: "1×2 迷你" },
        { value: "2x2", label: "2×2 标准" },
        { value: "2x4", label: "2×4 宽幅" },
        { value: "4x4", label: "4×4 大卡片" },
      ],
      onChange: function (v) {
        WR.state.size = v;
      },
    },
    {
      id: "game",
      label: "游戏/数量",
      current: function () {
        return WR.state.game;
      },
      options: [
        { value: "genshin", label: "原神" },
        { value: "starrail", label: "星铁" },
        { value: "zzz", label: "绝区零" },
        { value: "multi2", label: "原神+星铁" },
        { value: "multi3", label: "三款游戏" },
      ],
      onChange: function (v) {
        WR.state.game = v;
      },
    },
  ];
}

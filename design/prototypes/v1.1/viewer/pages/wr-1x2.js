/**
 * wr-1x2.js — Widget 重设计：1×2 迷你卡片（三款游戏）
 *
 * 实测尺寸（X7）：内容区域 121.9 × 27.8 vp，含 padding 约 146 × 52 vp
 * 官方字号规范：主标题 14fp，副标题 12fp，数字 20fp
 *
 * 布局：左侧装饰条 + 三行纵向内容
 * - 第一行：游戏名 + UID（同行，字号小）
 * - 第二行：当前体力 + 最大体力（字号相同，当前体力颜色根据比例从红色到主题色）
 * - 第三行：恢复时间
 */
function wrRender1x2(cardW, cardH, gid) {
  var d = WR.stamina[gid];
  var gameColor = WR.colors[gid];
  var ratio = d.cur / d.max;
  var pad = 12;
  var innerH = cardH - pad * 2;

  // 当前体力颜色：0-30% 红色，30-70% 橙色，70-100% 主题色
  var staminaColor;
  if (ratio <= 0.3) {
    staminaColor = "#ef5350";  // 红色
  } else if (ratio <= 0.7) {
    staminaColor = "#ffca28";  // 橙色
  } else {
    staminaColor = gameColor;  // 游戏主题色
  }

  // 左侧：游戏色竖线装饰条
  var bar =
    '<div style="width:3px;height:' +
    innerH +
    "px;border-radius:2px;background:" +
    gameColor +
    ';flex-shrink:0"></div>';

  var inner;
  if (gid === "starrail") {
    // 星铁特殊布局：左侧游戏信息，右侧体力值上下排列
    // 左侧：游戏名 + UID + 恢复时间
    var leftContent =
      '<div style="flex:1;min-width:0;display:flex;flex-direction:column;justify-content:center;gap:2px">' +
      '<span style="font-size:10px;font-weight:500;color:rgba(255,255,255,.6);line-height:1.2">' +
      WR.names[gid] +
      "</span>" +
      '<span style="font-size:9px;color:rgba(255,255,255,.35);line-height:1.2">UID 123456789</span>' +
      '<span style="font-size:10px;color:rgba(255,255,255,.4);line-height:1">' +
      d.rec +
      "</span>" +
      "</div>";

    // 右侧：当前值 + Divider + 最大值 上下排列
    var rightContent =
      '<div style="display:flex;flex-direction:column;align-items:flex-end;justify-content:center;gap:2px;flex-shrink:0">' +
      '<span style="font-size:16px;font-weight:700;color:' +
      staminaColor +
      ';line-height:1">' +
      d.cur +
      "</span>" +
      '<div style="width:20px;height:1px;background:rgba(255,255,255,.15)"></div>' +
      '<span style="font-size:12px;color:rgba(255,255,255,.4);line-height:1">' +
      d.max +
      "</span>" +
      "</div>";

    inner =
      '<div style="width:100%;height:100%;display:flex;align-items:center;gap:8px">' +
      bar +
      leftContent +
      rightContent +
      "</div>";
  } else {
    // 原神/绝区零：原有布局
    // 第一行：游戏名 + UID
    var row1 =
      '<div style="display:flex;align-items:center;gap:4px;line-height:1.2">' +
      '<span style="font-size:10px;font-weight:500;color:rgba(255,255,255,.6)">' +
      WR.names[gid] +
      "</span>" +
      '<span style="font-size:9px;color:rgba(255,255,255,.35)">UID 123456789</span>' +
      "</div>";

    // 第二行：当前体力/最大体力
    var row2 =
      '<div style="display:flex;align-items:baseline;gap:2px;line-height:1.1">' +
      '<span style="font-size:18px;font-weight:700;color:' +
      staminaColor +
      '">' +
      d.cur +
      "</span>" +
      '<span style="font-size:18px;color:rgba(255,255,255,.4)">/' +
      d.max +
      "</span>" +
      "</div>";

    // 第三行：恢复时间
    var row3 =
      '<span style="font-size:10px;color:rgba(255,255,255,.4);line-height:1">' +
      d.rec +
      "</span>";

    // 内容区
    var content =
      '<div style="flex:1;min-width:0;display:flex;flex-direction:column;justify-content:center;gap:1px">' +
      row1 +
      row2 +
      row3 +
      "</div>";

    inner =
      '<div style="width:100%;height:100%;display:flex;align-items:center;gap:8px">' +
      bar +
      content +
      "</div>";
  }

  return WR.card(cardW, cardH, inner, gid);
}

/**
 * wr-1x2.js — Widget 重设计：1×2 迷你卡片（三款游戏）
 *
 * 设计方案：去掉圆圈，改用竖线标识 + 大数字 + 细进度条
 * - 左侧：游戏色竖线（3px，圆角），作为游戏标识
 * - 右侧：游戏名（9px）+ 体力大字（28px Bold）+ /上限 + 细进度条（4px）+ 恢复时间
 * 进度感通过横条传达，数字大而清晰，无任何重复信息。
 */
function wrRender1x2(cardW, cardH, gid) {
  var d = WR.stamina[gid];
  var color = WR.colors[gid];
  var ratio = Math.min(d.cur / d.max, 1);
  var pad = 12;
  var innerH = cardH - pad * 2;

  // 左侧：游戏色竖线（3px 宽，充满内容高度，圆角）
  var bar =
    '<div style="width:3px;height:' +
    innerH +
    "px;border-radius:2px;background:" +
    color +
    ';flex-shrink:0"></div>';

  // 细进度条（4px 高，游戏色，充满右侧宽度）
  var progressBar =
    '<div style="width:100%;height:4px;border-radius:2px;background:rgba(255,255,255,.12);overflow:hidden;margin-top:4px">' +
    '<div style="width:' +
    Math.round(ratio * 100) +
    "%;height:100%;border-radius:2px;background:" +
    color +
    '"></div>' +
    "</div>";

  // 右侧内容
  var right =
    '<div style="flex:1;min-width:0;display:flex;flex-direction:column;justify-content:center">' +
    '<span style="font-size:9px;color:rgba(255,255,255,.4);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;margin-bottom:1px">' +
    WR.names[gid] +
    "</span>" +
    '<div style="display:flex;align-items:baseline;gap:2px">' +
    '<span style="font-size:28px;font-weight:700;color:' +
    color +
    ';line-height:1">' +
    d.cur +
    "</span>" +
    '<span style="font-size:11px;color:rgba(255,255,255,.35)">/' +
    d.max +
    "</span>" +
    "</div>" +
    progressBar +
    '<span style="font-size:9px;color:rgba(255,255,255,.4);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;margin-top:3px">' +
    d.rec +
    "</span>" +
    (gid === "starrail"
      ? '<div style="display:flex;align-items:center;gap:3px;margin-top:1px"><span style="font-size:9px;color:rgba(255,255,255,.35)">后备</span><span style="font-size:10px;font-weight:600;color:' +
        color +
        '">2400</span></div>'
      : "") +
    "</div>";

  var inner =
    '<div style="width:100%;height:100%;display:flex;align-items:center;gap:10px">' +
    bar +
    right +
    "</div>";
  return WR.card(cardW, cardH, inner, gid);
}

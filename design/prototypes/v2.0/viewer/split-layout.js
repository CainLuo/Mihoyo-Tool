/**
 * split-layout.js — 分栏布局渲染
 * 
 * 从 v1.0 复制，保持一致性
 */

function renderSplitLayout(leftHtml, rightHtml, w, h, opts) {
  opts = opts || {};
  var ratio = opts.leftRatio || 0.4;
  var minLeft = opts.minLeft || 240;
  var maxLeft = opts.maxLeft || 400;
  var divW = opts.dividerW || 1;

  var leftW = Math.max(minLeft, Math.min(maxLeft, Math.round(w * ratio)));
  var rightW = w - leftW - divW;
  var c = T();

  var rightContent = rightHtml
    ? '<iframe srcdoc="' + escHtml(rightHtml) + '" style="width:' + rightW + "px;height:" + h + 'px;border:none;display:block"></iframe>'
    : renderSplitPlaceholder(rightW, h);

  return (
    "<style>" +
    "*{box-sizing:border-box;margin:0;padding:0}" +
    "body{width:" + w + "px;height:" + h + "px;overflow:hidden;background:" + c.pageBg + ";display:flex}" +
    "</style>" +
    '<div style="width:' + leftW + "px;height:" + h + 'px;overflow:hidden;flex-shrink:0">' +
    '<iframe srcdoc="' + escHtml(leftHtml) + '" style="width:' + leftW + "px;height:" + h + 'px;border:none;display:block"></iframe>' +
    "</div>" +
    '<div style="width:' + divW + "px;height:" + h + "px;background:" + c.div + ';flex-shrink:0"></div>' +
    '<div style="width:' + rightW + "px;height:" + h + 'px;overflow:hidden;flex:1">' +
    rightContent +
    "</div>"
  );
}

function renderSplitPlaceholder(w, h) {
  var c = T();
  return (
    baseCss(w, h) +
    '<div style="width:' + w + "px;height:" + h + "px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:12px;background:" + c.pageBg + '">' +
    '<div style="font-size:32px;opacity:0.3">←</div>' +
    '<div style="font-size:14px;color:' + c.txt2 + ';opacity:0.5">从左侧选择内容</div>' +
    "</div>"
  );
}

function splitLeftWidth(totalW, opts) {
  opts = opts || {};
  var ratio = opts.leftRatio || 0.4;
  var minLeft = opts.minLeft || 240;
  var maxLeft = opts.maxLeft || 400;
  return Math.max(minLeft, Math.min(maxLeft, Math.round(totalW * ratio)));
}

function splitRightWidth(totalW, opts) {
  opts = opts || {};
  var divW = opts.dividerW || 1;
  return totalW - splitLeftWidth(totalW, opts) - divW;
}

function isSplitMode() {
  var d = D();
  var w = d.w, h = d.h;
  var isLandscape = w > h * 1.1;
  if (isLandscape) return true;
  return w >= 520;
}

function escHtml(html) {
  return html.replace(/&/g, "&amp;").replace(/"/g, "&quot;");
}

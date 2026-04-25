/**
 * split-layout.js — 分栏布局渲染
 *
 * 提供 renderSplitLayout(leftHtml, rightHtml, w, h, opts) 函数，
 * 渲染 Navigation Split 模式的左右分栏布局。
 *
 * 参数：
 *   leftHtml   — 左侧内容 HTML（Tab 主页面）
 *   rightHtml  — 右侧内容 HTML（详情页，传 null 则显示 SplitPlaceholder）
 *   w          — 总宽度
 *   h          — 总高度
 *   opts       — 可选配置
 *     opts.leftRatio   — 左侧宽度比例，默认 0.4
 *     opts.minLeft     — 左侧最小宽度，默认 240
 *     opts.maxLeft     — 左侧最大宽度，默认 400
 *     opts.dividerW    — 分割线宽度，默认 1
 *
 * 使用方式：
 *   var leftHtml  = renderMyPageContent(leftW, h);
 *   var rightHtml = renderAccountDetailContent(rightW, h);
 *   return renderSplitLayout(leftHtml, rightHtml, w, h);
 */

/**
 * 渲染分栏布局。
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
    ? '<iframe srcdoc="' +
      escHtml(rightHtml) +
      '" style="width:' +
      rightW +
      "px;height:" +
      h +
      'px;border:none;display:block"></iframe>'
    : renderSplitPlaceholder(rightW, h);

  return (
    "<style>" +
    "*{box-sizing:border-box;margin:0;padding:0}" +
    "body{width:" +
    w +
    "px;height:" +
    h +
    "px;overflow:hidden;background:" +
    c.pageBg +
    ";display:flex}" +
    "</style>" +
    '<div style="width:' +
    leftW +
    "px;height:" +
    h +
    'px;overflow:hidden;flex-shrink:0">' +
    '<iframe srcdoc="' +
    escHtml(leftHtml) +
    '" style="width:' +
    leftW +
    "px;height:" +
    h +
    'px;border:none;display:block"></iframe>' +
    "</div>" +
    '<div style="width:' +
    divW +
    "px;height:" +
    h +
    "px;background:" +
    c.div +
    ';flex-shrink:0"></div>' +
    '<div style="width:' +
    rightW +
    "px;height:" +
    h +
    'px;overflow:hidden;flex:1">' +
    rightContent +
    "</div>"
  );
}

/**
 * SplitPlaceholder — 右侧无内容时的占位视图。
 * 对应 entry/src/main/ets/components/SplitPlaceholder.ets
 */
function renderSplitPlaceholder(w, h) {
  var c = T();
  return (
    baseCss(w, h) +
    '<div style="width:' +
    w +
    "px;height:" +
    h +
    "px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:12px;background:" +
    c.pageBg +
    '">' +
    '<div style="font-size:32px;opacity:0.3">←</div>' +
    '<div style="font-size:14px;color:' +
    c.txt2 +
    ';opacity:0.5">从左侧选择内容</div>' +
    "</div>"
  );
}

/**
 * 计算分栏时左侧实际宽度（供各页面渲染函数使用）。
 */
function splitLeftWidth(totalW, opts) {
  opts = opts || {};
  var ratio = opts.leftRatio || 0.4;
  var minLeft = opts.minLeft || 240;
  var maxLeft = opts.maxLeft || 400;
  return Math.max(minLeft, Math.min(maxLeft, Math.round(totalW * ratio)));
}

/**
 * 计算分栏时右侧实际宽度。
 */
function splitRightWidth(totalW, opts) {
  opts = opts || {};
  var divW = opts.dividerW || 1;
  return totalW - splitLeftWidth(totalW, opts) - divW;
}

/**
 * 判断当前设备是否应该显示分栏模式。
 * 对应 Main.ets 的 setCurrentMode() 逻辑：
 *   - 横屏且非分屏 → Split
 *   - 竖屏宽度 >= 520vp → Split
 *   - 其余 → Stack（单栏）
 */
function isSplitMode() {
  var d = D();
  var w = d.w,
    h = d.h;
  var isLandscape = w > h * 1.1;
  if (isLandscape) return true; // 横屏默认分栏（原型不模拟分屏状态）
  return w >= 520;
}

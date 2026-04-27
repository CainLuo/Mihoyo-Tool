/**
 * snackbar.js — Snackbar 操作反馈组件原型
 *
 * 展示三种类型（SUCCESS / ERROR / INFO），水平 padding 固定 value16（16px）
 */

var snackbarState = {
  type: "success",
};

function renderSnackbar(w, h) {
  var c = T();
  var pad = 16;

  var types = {
    success: {
      icon: "✓",
      iconColor: c.primary,
      text: "战绩数据已更新",
      label: "SUCCESS",
    },
    error: {
      icon: "✕",
      iconColor: c.danger,
      text: "刷新失败，请检查网络连接",
      label: "ERROR",
    },
    info: {
      icon: "ℹ",
      iconColor: c.primary,
      text: "已释放 2.3 MB 缓存",
      label: "INFO",
    },
  };

  var t = types[snackbarState.type] || types.success;

  var tabH = 56;
  var snackH = 44;
  var snackBottom = tabH + 12;
  var snackW = w - pad * 2;

  var html = baseCss(w, h);
  html +=
    '<div style="width:' +
    w +
    "px;height:" +
    h +
    "px;position:relative;background:" +
    c.pageBg +
    ';overflow:hidden">';

  // ── 页面内容区 ────────────────────────────────────────────
  html +=
    '<div style="position:absolute;inset:0;bottom:' +
    tabH +
    'px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:12px;padding:20px">';
  html +=
    '<div style="color:' +
    c.txt2 +
    ';font-size:13px;text-align:center">页面内容区域</div>';
  html +=
    '<div style="background:' +
    c.surfCard +
    ';border-radius:10px;padding:12px 16px;width:100%;max-width:280px">';
  html += '<div style="font-size:11px;color:' + c.txt2 + ';line-height:1.8">';
  html +=
    '类型：<span style="color:' + t.iconColor + '">' + t.label + "</span><br>";
  html +=
    '水平 padding：<span style="color:' +
    c.primary +
    '">16px (value16)</span><br>';
  html +=
    'Snackbar 宽度：<span style="color:' +
    c.primary +
    '">' +
    snackW +
    "px</span>";
  html += "</div></div>";
  html += "</div>";

  // ── 底部 Tab 栏 ───────────────────────────────────────────
  html +=
    '<div style="position:absolute;bottom:0;left:0;right:0;height:' +
    tabH +
    "px;background:" +
    c.tabBg +
    ";border-top:1px solid " +
    c.div +
    ';display:flex">';
  var tabs = [
    ["首页", false],
    ["角色", false],
    ["我的", true],
  ];
  for (var i = 0; i < tabs.length; i++) {
    var sel = tabs[i][1];
    html +=
      '<div style="flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:3px">';
    html +=
      '<div style="width:20px;height:3px;border-radius:2px;background:' +
      (sel ? c.tabSel : "transparent") +
      '"></div>';
    html +=
      '<span style="font-size:11px;color:' +
      (sel ? c.tabSel : c.txt2) +
      '">' +
      tabs[i][0] +
      "</span>";
    html += "</div>";
  }
  html += "</div>";

  // ── Snackbar ──────────────────────────────────────────────
  html +=
    '<div style="position:absolute;bottom:' +
    snackBottom +
    "px;left:" +
    pad +
    "px;width:" +
    snackW +
    "px;" +
    "background:" +
    c.surfCard +
    ";border-radius:12px;" +
    "padding:12px 16px;" +
    "display:flex;align-items:center;gap:8px;" +
    'box-shadow:0 4px 20px rgba(0,0,0,0.5)">';
  html +=
    '<span style="font-size:18px;color:' +
    t.iconColor +
    ';flex-shrink:0;line-height:1;font-weight:bold">' +
    t.icon +
    "</span>";
  html +=
    '<span style="font-size:14px;color:' +
    c.txt +
    ';flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">' +
    t.text +
    "</span>";
  html += "</div>";

  // ── padding 标注 ──────────────────────────────────────────
  var annotY = snackBottom - 2;
  var annotH = snackH + 4;
  var annotColor = "rgba(255,200,0,.5)";

  html +=
    '<div style="position:absolute;bottom:' +
    annotY +
    "px;left:0;width:" +
    pad +
    "px;height:" +
    annotH +
    "px;" +
    "border-top:1px dashed " +
    annotColor +
    ";border-bottom:1px dashed " +
    annotColor +
    ";border-left:1px dashed " +
    annotColor +
    '">';
  html +=
    '<span style="position:absolute;top:50%;left:2px;transform:translateY(-50%);font-size:9px;color:' +
    annotColor +
    '">' +
    pad +
    "px</span>";
  html += "</div>";

  html +=
    '<div style="position:absolute;bottom:' +
    annotY +
    "px;right:0;width:" +
    pad +
    "px;height:" +
    annotH +
    "px;" +
    "border-top:1px dashed " +
    annotColor +
    ";border-bottom:1px dashed " +
    annotColor +
    ";border-right:1px dashed " +
    annotColor +
    '">';
  html +=
    '<span style="position:absolute;top:50%;right:2px;transform:translateY(-50%);font-size:9px;color:' +
    annotColor +
    '">' +
    pad +
    "px</span>";
  html += "</div>";

  html += "</div>";
  return html;
}

function snackbarControls() {
  return [
    {
      id: "snack-type",
      label: "类型",
      options: [
        { value: "success", label: "✓ SUCCESS" },
        { value: "error", label: "✕ ERROR" },
        { value: "info", label: "ℹ INFO" },
      ],
      current: function () {
        return snackbarState.type;
      },
      onChange: function (v) {
        snackbarState.type = v;
      },
    },
  ];
}

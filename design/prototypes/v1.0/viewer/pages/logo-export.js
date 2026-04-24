/**
 * logo-export.js — 1024×1024 无圆角 Logo 导出页
 */

function logoSVGNoRadius(s) {
  var c = T();
  var gid = "lx" + Math.round(Math.random() * 99999);
  var cx = s * 0.5;
  var blueH = s * 0.62;
  var headR = s * 0.32,
    headCX = cx,
    headCY = s * 0.72;
  var earW = s * 0.11,
    earH = s * 0.3,
    earR = earW * 0.5;
  var earLX = cx - s * 0.115,
    earRX = cx + s * 0.005,
    earTopY = s * 0.1;
  var iearW = earW * 0.45,
    iearH = earH * 0.55,
    iearR = iearW * 0.5;
  var sw = (s * 0.018).toFixed(2);

  return (
    '<svg width="' +
    s +
    '" height="' +
    s +
    '" viewBox="0 0 ' +
    s +
    " " +
    s +
    '" xmlns="http://www.w3.org/2000/svg">' +
    "<defs>" +
    '<linearGradient id="' +
    gid +
    'b" x1="0%" y1="0%" x2="100%" y2="100%">' +
    '<stop offset="0%" stop-color="' +
    c.primary +
    '"/>' +
    '<stop offset="100%" stop-color="' +
    c.cyan +
    '"/>' +
    "</linearGradient>" +
    '<radialGradient id="' +
    gid +
    'h" cx="45%" cy="35%" r="65%">' +
    '<stop offset="0%" stop-color="' +
    c.logoFg0 +
    '"/>' +
    '<stop offset="100%" stop-color="' +
    c.logoFg1 +
    '"/>' +
    "</radialGradient>" +
    '<filter id="' +
    gid +
    's">' +
    '<feDropShadow dx="0" dy="' +
    (s * 0.01).toFixed(1) +
    '" stdDeviation="' +
    (s * 0.02).toFixed(1) +
    '" flood-color="' +
    c.primary +
    '" flood-opacity="0.4"/>' +
    "</filter>" +
    '<clipPath id="' +
    gid +
    'c"><rect width="' +
    s +
    '" height="' +
    s +
    '" rx="0" ry="0"/></clipPath>' +
    "</defs>" +
    '<g clip-path="url(#' +
    gid +
    'c)">' +
    '<rect width="' +
    s +
    '" height="' +
    s +
    '" fill="' +
    c.logoBg +
    '"/>' +
    '<rect x="0" y="0" width="' +
    s +
    '" height="' +
    blueH +
    '" fill="url(#' +
    gid +
    'b)"/>' +
    '<rect x="' +
    earLX +
    '" y="' +
    earTopY +
    '" width="' +
    earW +
    '" height="' +
    earH +
    '" rx="' +
    earR +
    '" ry="' +
    earR +
    '" fill="url(#' +
    gid +
    'h)" filter="url(#' +
    gid +
    's)"/>' +
    '<rect x="' +
    earRX +
    '" y="' +
    earTopY +
    '" width="' +
    earW +
    '" height="' +
    earH +
    '" rx="' +
    earR +
    '" ry="' +
    earR +
    '" fill="url(#' +
    gid +
    'h)" filter="url(#' +
    gid +
    's)"/>' +
    '<rect x="' +
    earLX +
    '" y="' +
    earTopY +
    '" width="' +
    earW +
    '" height="' +
    earH +
    '" rx="' +
    earR +
    '" ry="' +
    earR +
    '" fill="none" stroke="' +
    c.primary +
    '" stroke-width="' +
    sw +
    '"/>' +
    '<rect x="' +
    earRX +
    '" y="' +
    earTopY +
    '" width="' +
    earW +
    '" height="' +
    earH +
    '" rx="' +
    earR +
    '" ry="' +
    earR +
    '" fill="none" stroke="' +
    c.primary +
    '" stroke-width="' +
    sw +
    '"/>' +
    '<rect x="' +
    (earLX + earW * 0.275) +
    '" y="' +
    (earTopY + earH * 0.1) +
    '" width="' +
    iearW +
    '" height="' +
    iearH +
    '" rx="' +
    iearR +
    '" ry="' +
    iearR +
    '" fill="' +
    c.primary +
    '" opacity="0.55"/>' +
    '<rect x="' +
    (earRX + earW * 0.275) +
    '" y="' +
    (earTopY + earH * 0.1) +
    '" width="' +
    iearW +
    '" height="' +
    iearH +
    '" rx="' +
    iearR +
    '" ry="' +
    iearR +
    '" fill="' +
    c.primary +
    '" opacity="0.55"/>' +
    '<circle cx="' +
    (earLX + earW * 0.5) +
    '" cy="' +
    (earTopY + s * 0.015) +
    '" r="' +
    s * 0.022 +
    '" fill="' +
    c.genshin +
    '" opacity="0.9"/>' +
    '<circle cx="' +
    (earRX + earW * 0.5) +
    '" cy="' +
    (earTopY + s * 0.015) +
    '" r="' +
    s * 0.022 +
    '" fill="' +
    c.starrail +
    '" opacity="0.9"/>' +
    '<circle cx="' +
    headCX +
    '" cy="' +
    headCY +
    '" r="' +
    headR +
    '" fill="url(#' +
    gid +
    'h)" filter="url(#' +
    gid +
    's)"/>' +
    '<circle cx="' +
    headCX +
    '" cy="' +
    headCY +
    '" r="' +
    headR +
    '" fill="none" stroke="' +
    c.primary +
    '" stroke-width="' +
    sw +
    '"/>' +
    '<polygon points="' +
    (headCX - s * 0.09) +
    "," +
    (headCY - s * 0.04) +
    " " +
    (headCX - s * 0.065) +
    "," +
    (headCY - s * 0.015) +
    " " +
    (headCX - s * 0.09) +
    "," +
    (headCY + s * 0.01) +
    " " +
    (headCX - s * 0.115) +
    "," +
    (headCY - s * 0.015) +
    '" fill="' +
    c.primary +
    '"/>' +
    '<polygon points="' +
    (headCX + s * 0.09) +
    "," +
    (headCY - s * 0.04) +
    " " +
    (headCX + s * 0.115) +
    "," +
    (headCY - s * 0.015) +
    " " +
    (headCX + s * 0.09) +
    "," +
    (headCY + s * 0.01) +
    " " +
    (headCX + s * 0.065) +
    "," +
    (headCY - s * 0.015) +
    '" fill="' +
    c.primary +
    '"/>' +
    "</g></svg>"
  );
}

// 导出函数挂在 window 上，供按钮 onclick 调用
window.exportLogoPng = function () {
  var SIZE = 1024;
  var svgStr = logoSVGNoRadius(SIZE);
  var blob = new Blob([svgStr], { type: "image/svg+xml;charset=utf-8" });
  var url = URL.createObjectURL(blob);
  var img = new Image();
  img.onload = function () {
    var canvas = document.createElement("canvas");
    canvas.width = SIZE;
    canvas.height = SIZE;
    var ctx = canvas.getContext("2d");
    ctx.drawImage(img, 0, 0, SIZE, SIZE);
    URL.revokeObjectURL(url);
    canvas.toBlob(function (pngBlob) {
      var a = document.createElement("a");
      a.href = URL.createObjectURL(pngBlob);
      a.download = "miyoyo-icon-1024.png";
      a.click();
      setTimeout(function () {
        URL.revokeObjectURL(a.href);
      }, 1000);
    }, "image/png");
  };
  img.src = url;
};

function renderLogoExport(w, h) {
  var c = T();
  var SIZE = 1024;
  var padding = 80;
  var displaySize = Math.min(Math.floor(Math.min(w, h) - padding), SIZE);
  var bg = G.theme === "dark" ? "#080810" : "#F0F0F0";
  var labelColor = G.theme === "dark" ? "#555" : "#AAA";
  var btnBg = c.primary;

  return (
    "<style>*{box-sizing:border-box;margin:0;padding:0}" +
    "body{width:" +
    w +
    "px;height:" +
    h +
    "px;overflow:hidden;background:" +
    bg +
    ";" +
    'font-family:"PingFang SC","Microsoft YaHei",sans-serif;' +
    "display:flex;flex-direction:column;align-items:center;justify-content:center;gap:16px}" +
    "</style>" +
    '<div style="display:flex;flex-direction:column;align-items:center;gap:14px">' +
    '<div style="width:' +
    displaySize +
    "px;height:" +
    displaySize +
    'px;flex-shrink:0">' +
    logoSVGNoRadius(displaySize) +
    "</div>" +
    '<div style="font-size:11px;color:' +
    labelColor +
    ';letter-spacing:1px">1024 × 1024 · 无圆角</div>' +
    '<button onclick="window.exportLogoPng()" style="' +
    "padding:8px 24px;border-radius:8px;border:none;cursor:pointer;" +
    "background:" +
    btnBg +
    ";color:#fff;font-size:13px;font-weight:600;" +
    "letter-spacing:1px;transition:opacity .15s" +
    '" onmouseover="this.style.opacity=.8" onmouseout="this.style.opacity=1">' +
    "⬇ 导出 PNG" +
    "</button>" +
    "</div>"
  );
}

function logoExportControls() {
  return [];
}

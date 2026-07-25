/**
 * device-shell.js — 设备外框渲染
 * 
 * 从 v1.0 复制，保持一致性
 */

function renderInShell(contentHtml, w, h) {
  var dev = G.dev || "pp";
  if (dev === "pp") return shellPhone(contentHtml, w, h, false);
  if (dev === "pl") return shellPhone(contentHtml, w, h, true);
  if (dev === "fd") return shellFoldable(contentHtml, w, h);
  if (dev === "tf") return shellTripleFold(contentHtml, w, h);
  if (dev === "tb") return shellTablet(contentHtml, w, h);
  if (dev === "pc") return shellPC(contentHtml, w, h);
  return contentHtml;
}

var SHELL_BORDER_RADIUS = {
  pp: 36,
  pl: 36,
  fd: 20,
  tf: 16,
  tb: 24,
  pc: 12,
};

function shellPhone(contentHtml, w, h, isLandscape) {
  var bezel = 10;
  var outerR = 36;
  var innerR = 28;
  var outerW = w + bezel * 2;
  var outerH = h + bezel * 2;
  var c = T();

  var camera = isLandscape
    ? '<div style="position:absolute;right:' + (bezel * 0.5 - 4) + 'px;top:50%;transform:translateY(-50%);width:8px;height:8px;border-radius:50%;background:#1a1a1a;border:1px solid #333"></div>'
    : '<div style="position:absolute;top:' + (bezel * 0.5 - 4) + 'px;left:50%;transform:translateX(-50%);width:8px;height:8px;border-radius:50%;background:#1a1a1a;border:1px solid #333"></div>';

  var sideBtn = isLandscape
    ? '<div style="position:absolute;top:-3px;left:' + Math.round(outerW * 0.3) + 'px;width:40px;height:3px;border-radius:2px 2px 0 0;background:#2a2a2a"></div>' +
      '<div style="position:absolute;top:-3px;left:' + Math.round(outerW * 0.5) + 'px;width:24px;height:3px;border-radius:2px 2px 0 0;background:#2a2a2a"></div>'
    : '<div style="position:absolute;right:-3px;top:' + Math.round(outerH * 0.28) + 'px;width:3px;height:32px;border-radius:0 2px 2px 0;background:#2a2a2a"></div>' +
      '<div style="position:absolute;right:-3px;top:' + Math.round(outerH * 0.42) + 'px;width:3px;height:24px;border-radius:0 2px 2px 0;background:#2a2a2a"></div>' +
      '<div style="position:absolute;left:-3px;top:' + Math.round(outerH * 0.35) + 'px;width:3px;height:40px;border-radius:2px 0 0 2px;background:#2a2a2a"></div>';

  return (
    shellCss() +
    '<div class="shell-wrap" style="width:' + outerW + "px;height:" + outerH + 'px">' +
    '<div class="shell-body" style="width:' + outerW + "px;height:" + outerH + "px;border-radius:" + outerR + 'px">' +
    sideBtn +
    camera +
    '<div class="shell-screen" style="width:' + w + "px;height:" + h + "px;border-radius:" + innerR + "px;top:" + bezel + "px;left:" + bezel + 'px">' +
    '<iframe srcdoc="' + escHtml(contentHtml) + '" style="width:' + w + "px;height:" + h + "px;border:none;border-radius:" + innerR + 'px;display:block"></iframe>' +
    "</div>" +
    "</div>" +
    "</div>"
  );
}

function shellFoldable(contentHtml, w, h) {
  var bezel = 8;
  var outerR = 20;
  var innerR = 14;
  var outerW = w + bezel * 2;
  var outerH = h + bezel * 2;
  var hingeLine =
    '<div style="position:absolute;left:50%;top:' + bezel + "px;width:2px;height:" + h + 'px;background:rgba(0,0,0,0.5);z-index:10;transform:translateX(-50%)"></div>';

  return (
    shellCss() +
    '<div class="shell-wrap" style="width:' + outerW + "px;height:" + outerH + 'px">' +
    '<div class="shell-body" style="width:' + outerW + "px;height:" + outerH + "px;border-radius:" + outerR + 'px">' +
    hingeLine +
    '<div class="shell-screen" style="width:' + w + "px;height:" + h + "px;border-radius:" + innerR + "px;top:" + bezel + "px;left:" + bezel + 'px">' +
    '<iframe srcdoc="' + escHtml(contentHtml) + '" style="width:' + w + "px;height:" + h + "px;border:none;border-radius:" + innerR + 'px;display:block"></iframe>' +
    "</div>" +
    "</div>" +
    "</div>"
  );
}

function shellTripleFold(contentHtml, w, h) {
  var bezel = 8;
  var outerR = 16;
  var innerR = 10;
  var outerW = w + bezel * 2;
  var outerH = h + bezel * 2;
  var third = Math.round(w / 3);
  var hinges =
    '<div style="position:absolute;left:' + (bezel + third) + "px;top:" + bezel + "px;width:2px;height:" + h + 'px;background:rgba(0,0,0,0.5);z-index:10"></div>' +
    '<div style="position:absolute;left:' + (bezel + third * 2) + "px;top:" + bezel + "px;width:2px;height:" + h + 'px;background:rgba(0,0,0,0.5);z-index:10"></div>';

  return (
    shellCss() +
    '<div class="shell-wrap" style="width:' + outerW + "px;height:" + outerH + 'px">' +
    '<div class="shell-body" style="width:' + outerW + "px;height:" + outerH + "px;border-radius:" + outerR + 'px">' +
    hinges +
    '<div class="shell-screen" style="width:' + w + "px;height:" + h + "px;border-radius:" + innerR + "px;top:" + bezel + "px;left:" + bezel + 'px">' +
    '<iframe srcdoc="' + escHtml(contentHtml) + '" style="width:' + w + "px;height:" + h + "px;border:none;border-radius:" + innerR + 'px;display:block"></iframe>' +
    "</div>" +
    "</div>" +
    "</div>"
  );
}

function shellTablet(contentHtml, w, h) {
  var bezel = 12;
  var outerR = 24;
  var innerR = 14;
  var outerW = w + bezel * 2;
  var outerH = h + bezel * 2;
  var camera =
    '<div style="position:absolute;top:' + (bezel * 0.5 - 3) + 'px;left:50%;transform:translateX(-50%);width:6px;height:6px;border-radius:50%;background:#1a1a1a;border:1px solid #333"></div>';

  return (
    shellCss() +
    '<div class="shell-wrap" style="width:' + outerW + "px;height:" + outerH + 'px">' +
    '<div class="shell-body" style="width:' + outerW + "px;height:" + outerH + "px;border-radius:" + outerR + 'px">' +
    camera +
    '<div class="shell-screen" style="width:' + w + "px;height:" + h + "px;border-radius:" + innerR + "px;top:" + bezel + "px;left:" + bezel + 'px">' +
    '<iframe srcdoc="' + escHtml(contentHtml) + '" style="width:' + w + "px;height:" + h + "px;border:none;border-radius:" + innerR + 'px;display:block"></iframe>' +
    "</div>" +
    "</div>" +
    "</div>"
  );
}

function shellPC(contentHtml, w, h) {
  var titleH = 28;
  var bezel = 8;
  var outerR = 12;
  var outerW = w + bezel * 2;
  var outerH = h + titleH + bezel;
  var c = T();

  var titleBar =
    '<div style="height:' + titleH + 'px;display:flex;align-items:center;padding:0 10px;gap:6px;flex-shrink:0">' +
    '<div style="width:10px;height:10px;border-radius:50%;background:#ff5f57"></div>' +
    '<div style="width:10px;height:10px;border-radius:50%;background:#febc2e"></div>' +
    '<div style="width:10px;height:10px;border-radius:50%;background:#28c840"></div>' +
    '<div style="flex:1;text-align:center;font-size:11px;color:' + c.txt2 + ';margin-right:36px">米悠悠</div>' +
    "</div>";

  return (
    shellCss() +
    '<div class="shell-wrap" style="width:' + outerW + "px;height:" + outerH + 'px">' +
    '<div class="shell-body" style="width:' + outerW + "px;height:" + outerH + "px;border-radius:" + outerR + 'px;display:flex;flex-direction:column">' +
    titleBar +
    '<div class="shell-screen" style="width:' + w + "px;height:" + h + 'px;border-radius:0;position:relative;left:' + bezel + 'px">' +
    '<iframe srcdoc="' + escHtml(contentHtml) + '" style="width:' + w + "px;height:" + h + 'px;border:none;display:block"></iframe>' +
    "</div>" +
    "</div>" +
    "</div>"
  );
}

function shellCss() {
  var shellBg = G.theme === "dark" ? "#1a1a1a" : "#d0d0d0";
  var shellBorder = G.theme === "dark" ? "#333" : "#b0b0b0";
  return (
    "<style>" +
    ".shell-wrap{position:relative;display:inline-block}" +
    ".shell-body{position:relative;background:" + shellBg + ";border:1.5px solid " + shellBorder + ";box-shadow:0 8px 32px rgba(0,0,0,0.5),inset 0 1px 0 rgba(255,255,255,0.08)}" +
    ".shell-screen{position:absolute;overflow:hidden;background:#000}" +
    "</style>"
  );
}

function escHtml(html) {
  return html.replace(/&/g, "&amp;").replace(/"/g, "&quot;");
}

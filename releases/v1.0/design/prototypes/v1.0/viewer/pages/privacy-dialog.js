/**
 * privacy-dialog.js — 首屏隐私合规流程原型（全屏 Splash Screen 样式）
 *
 * 场景：
 *   step1-unread  — 步骤一：用户协议（未滑到底部，下一步禁用）
 *   step1-read    — 步骤一：用户协议（已滑到底部，下一步可点击）
 *   step2-unread  — 步骤二：隐私政策（未滑到底部，按钮禁用）
 *   step2-read    — 步骤二：隐私政策（已滑到底部，按钮可点击）
 */

var privacyDialogState = {
  scene: "step1-unread",
};

function renderPrivacyDialog(w, h) {
  var c = T();
  var isWide = w >= 600;

  var css =
    "<style>" +
    ".pc-root{display:flex;flex-direction:column;width:" +
    w +
    "px;height:" +
    h +
    "px;background:" +
    c.pageBg +
    ";overflow:hidden}" +
    // 顶部标题栏
    ".pc-topbar{height:52px;flex-shrink:0;display:flex;align-items:center;padding:0 16px;background:" +
    c.surfCard +
    ";border-bottom:1px solid " +
    c.border +
    ";gap:8px}" +
    ".pc-title{font-size:17px;font-weight:600;color:" +
    c.txt +
    ";flex:1}" +
    ".pc-step-badge{font-size:12px;color:" +
    c.txt2 +
    ";background:" +
    c.border +
    ";padding:2px 8px;border-radius:10px}" +
    // 内容区（模拟 Web 组件）
    ".pc-content{flex:1;overflow-y:auto;padding:20px;scrollbar-width:thin;scrollbar-color:" +
    c.scrollThumb +
    " transparent}" +
    ".pc-content::-webkit-scrollbar{width:3px}" +
    ".pc-content::-webkit-scrollbar-thumb{background:" +
    c.scrollThumb +
    ";border-radius:2px}" +
    // 协议文本样式
    ".pc-doc-title{font-size:18px;font-weight:700;color:" +
    c.txt +
    ";margin-bottom:16px}" +
    ".pc-doc-h2{font-size:14px;font-weight:600;color:" +
    c.txt +
    ";margin:16px 0 8px}" +
    ".pc-doc-p{font-size:13px;color:" +
    c.txt2 +
    ";line-height:1.8;margin-bottom:10px}" +
    // 底部操作区
    ".pc-footer{flex-shrink:0;padding:12px 16px;background:" +
    c.pageBg +
    ";border-top:1px solid " +
    c.border +
    ";display:flex;flex-direction:column;gap:8px}" +
    // 按钮
    ".pc-btn-primary{width:100%;height:46px;border:none;border-radius:8px;font-size:15px;font-weight:600;cursor:pointer;transition:all 0.2s}" +
    ".pc-btn-primary.enabled{background:" +
    c.primary +
    ";color:#fff}" +
    ".pc-btn-primary.disabled{background:" +
    c.border +
    ";color:" +
    c.txt2 +
    ";cursor:not-allowed}" +
    ".pc-btn-secondary{width:100%;height:40px;border:none;background:transparent;font-size:13px;cursor:pointer;transition:all 0.2s}" +
    ".pc-btn-secondary.enabled{color:" +
    c.txt2 +
    "}" +
    ".pc-btn-secondary.enabled:hover{color:" +
    c.txt +
    "}" +
    ".pc-btn-secondary.disabled{color:" +
    c.border +
    ";cursor:not-allowed}" +
    // 滚动提示
    ".pc-scroll-hint{text-align:center;font-size:11px;color:" +
    c.txt2 +
    ";padding:4px 0;opacity:0.7}" +
    "</style>";

  // ── 协议文本内容 ──────────────────────────────────────────
  function termsContent() {
    return (
      '<div class="pc-doc-title">用户协议</div>' +
      '<div class="pc-doc-p">欢迎使用米悠悠（以下简称"本应用"）。在使用本应用前，请您仔细阅读本协议的全部内容。</div>' +
      '<div class="pc-doc-h2">一、服务说明</div>' +
      '<div class="pc-doc-p">本应用为米哈游旗下游戏（原神、崩坏：星穹铁道、绝区零等）提供战绩数据查询服务，数据来源于米游社官方 API。本应用为非官方第三方工具，与米哈游官方无关。</div>' +
      '<div class="pc-doc-h2">二、账号与安全</div>' +
      '<div class="pc-doc-p">您的米游社账号 Cookie 仅存储在本地设备，不会上传至任何第三方服务器。请妥善保管您的账号信息，因账号信息泄露导致的损失由用户自行承担。</div>' +
      '<div class="pc-doc-h2">三、使用规范</div>' +
      '<div class="pc-doc-p">您在使用本应用时，应遵守相关法律法规，不得利用本应用从事任何违法违规活动。本应用保留在您违反本协议时终止服务的权利。</div>' +
      '<div class="pc-doc-h2">四、免责声明</div>' +
      '<div class="pc-doc-p">游戏数据的准确性以官方游戏内数据为准。本应用不对因数据延迟或不准确导致的任何损失承担责任。</div>' +
      '<div class="pc-doc-h2">五、协议变更</div>' +
      '<div class="pc-doc-p">本协议可能随时更新，更新后将在应用内通知。继续使用本应用即表示您接受更新后的协议。</div>' +
      '<div class="pc-doc-h2">六、联系方式</div>' +
      '<div class="pc-doc-p">如您对本协议有任何疑问，请通过 GitHub Issues 联系我们。感谢您阅读完本协议的全部内容。</div>'
    );
  }

  function privacyContent() {
    return (
      '<div class="pc-doc-title">隐私政策</div>' +
      '<div class="pc-doc-p">本应用非常重视您的隐私保护，请您仔细阅读本隐私政策的全部内容。</div>' +
      '<div class="pc-doc-h2">一、收集的信息</div>' +
      '<div class="pc-doc-p">本应用仅收集您主动提供的米游社账号 Cookie，用于查询游戏战绩数据。不收集设备标识符、位置信息或其他个人信息。</div>' +
      '<div class="pc-doc-h2">二、信息使用</div>' +
      '<div class="pc-doc-p">Cookie 信息仅用于向米游社官方 API 发起数据请求，不用于任何其他目的，不会用于广告推送或用户画像分析。</div>' +
      '<div class="pc-doc-h2">三、信息存储</div>' +
      '<div class="pc-doc-p">所有数据仅存储在您的本地设备上，不会上传至任何服务器。卸载应用后，所有本地数据将被清除。</div>' +
      '<div class="pc-doc-h2">四、信息共享</div>' +
      '<div class="pc-doc-p">本应用不会向任何第三方共享、出售或转让您的个人信息。</div>' +
      '<div class="pc-doc-h2">五、您的权利</div>' +
      '<div class="pc-doc-p">您有权随时删除本应用中存储的账号信息。在"我的"页面中，您可以删除任意账号及其关联数据。</div>' +
      '<div class="pc-doc-h2">六、联系我们</div>' +
      '<div class="pc-doc-p">如您对本隐私政策有任何疑问，请通过 GitHub Issues 联系我们。感谢您阅读完本隐私政策的全部内容。</div>'
    );
  }

  // ── 各场景渲染 ────────────────────────────────────────────
  var scene = privacyDialogState.scene;
  var isStep1 = scene === "step1-unread" || scene === "step1-read";
  var isRead = scene === "step1-read" || scene === "step2-read";

  // 顶部标题栏
  var topbar =
    '<div class="pc-topbar">' +
    '<div class="pc-title">' +
    (isStep1 ? "用户协议" : "隐私政策") +
    "</div>" +
    (!isStep1 ? '<div class="pc-step-badge">2/2</div>' : "") +
    "</div>";

  // 内容区
  var scrollHint = !isRead
    ? '<div class="pc-scroll-hint">↓ 请滑动阅读全部内容</div>'
    : '<div class="pc-scroll-hint" style="color:' +
      c.ok +
      '">✓ 已阅读完毕</div>';

  var content =
    '<div class="pc-content">' +
    (isStep1 ? termsContent() : privacyContent()) +
    scrollHint +
    "</div>";

  // 底部操作区
  var footer = "";
  if (isStep1) {
    var nextEnabled = isRead;
    footer =
      '<div class="pc-footer">' +
      '<button class="pc-btn-primary ' +
      (nextEnabled ? "enabled" : "disabled") +
      '"' +
      (nextEnabled
        ? " onclick=\"privacyDialogState.scene='step2-unread';refresh()\""
        : "") +
      ">" +
      "下一步" +
      "</button>" +
      (!nextEnabled
        ? '<div class="pc-scroll-hint">请先阅读完用户协议</div>'
        : "") +
      "</div>";
  } else {
    var agreeEnabled = isRead;
    footer =
      '<div class="pc-footer">' +
      '<button class="pc-btn-primary ' +
      (agreeEnabled ? "enabled" : "disabled") +
      '"' +
      (agreeEnabled ? " onclick=\"alert('已同意，进入主界面')\"" : "") +
      ">" +
      "同意并继续" +
      "</button>" +
      '<button class="pc-btn-secondary ' +
      (agreeEnabled ? "enabled" : "disabled") +
      '"' +
      (agreeEnabled ? " onclick=\"alert('不同意，App 将退出')\"" : "") +
      ">" +
      "不同意，退出" +
      "</button>" +
      (!agreeEnabled
        ? '<div class="pc-scroll-hint">请先阅读完隐私政策</div>'
        : "") +
      "</div>";
  }

  return (
    '<!doctype html><html><head><meta charset="UTF-8">' +
    baseCss(w, h) +
    css +
    "</head><body>" +
    '<div class="pc-root">' +
    topbar +
    content +
    footer +
    "</div>" +
    "</body></html>"
  );
}

function privacyDialogControls() {
  return [
    {
      id: "scene",
      label: "场景",
      options: [
        { label: "步骤一：协议（未读完）", value: "step1-unread" },
        { label: "步骤一：协议（已读完）", value: "step1-read" },
        { label: "步骤二：隐私（未读完）", value: "step2-unread" },
        { label: "步骤二：隐私（已读完）", value: "step2-read" },
      ],
      current: function () {
        return privacyDialogState.scene;
      },
      onChange: function (v) {
        privacyDialogState.scene = v;
      },
    },
  ];
}

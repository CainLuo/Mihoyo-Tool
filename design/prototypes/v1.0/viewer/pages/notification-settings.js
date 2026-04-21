/**
 * notification-settings.js — 通知设置页原型
 *
 * 设计要点：
 *   1. 体力上限值来自 API（maxResin / maxStamina / energyMax），不 hard code
 *   2. 每个账号只显示实际拥有的游戏，可折叠
 *   3. reminderAgentManager 上限 30 个，显示使用量，超限弹 Dialog
 *   4. 通知样式选择纵向排列，附系统通知气泡预览
 */

// ── 模拟数据（来自 DB，体力上限来自 API 响应） ──────────────────
var nsAccounts = [
  {
    id: 182692936,
    nickname: "CainLuo",
    uid: "182692936",
    avatarUrl: "https://bbs-static.miyoushe.com/avatar/avatar1.png",
    isExpanded: true,
    // 该账号实际拥有的游戏（来自 game_role_table）
    // maxStamina 来自 DB 中对应的 DailyNoteRow，0 表示尚未同步
    games: [
      {
        gameId: "genshin",
        gameName: "原神",
        staminaName: "原粹树脂",
        enabled: true,
        threshold: 160,
        maxStamina: 200,
        secondsPerUnit: 480,
      },
      {
        gameId: "starrail",
        gameName: "崩坏：星穹铁道",
        staminaName: "开拓力",
        enabled: true,
        threshold: 230,
        maxStamina: 300,
        secondsPerUnit: 360,
      },
      {
        gameId: "zzz",
        gameName: "绝区零",
        staminaName: "电量",
        enabled: false,
        threshold: 200,
        maxStamina: 240,
        secondsPerUnit: 360,
      },
    ],
  },
  {
    id: 100000001,
    nickname: "旅行者",
    uid: "100000001",
    avatarUrl: "",
    isExpanded: false,
    // 这个账号只有原神（没有星铁和绝区零角色）
    games: [
      {
        gameId: "genshin",
        gameName: "原神",
        staminaName: "原粹树脂",
        enabled: true,
        threshold: 180,
        maxStamina: 200,
        secondsPerUnit: 480,
      },
    ],
  },
];

// ── 全局设置 ────────────────────────────────────────────────────
var nsGlobal = {
  enabled: true,
  permissionDenied: false,
  style: "A",
  reminderUsed: 4, // 当前已注册的代理提醒数（来自 getValidReminders()）
  reminderLimit: 30, // 系统上限
  showLimitDialog: false,
};

// ── 游戏颜色映射 ────────────────────────────────────────────────
function gameColor(gameId) {
  var c = T();
  if (gameId === "genshin") return c.genshin;
  if (gameId === "starrail") return c.starrail;
  if (gameId === "zzz") return c.zzz;
  return c.primary;
}

function notificationSettingsControls() {
  return [
    {
      id: "ns-enabled",
      label: "总开关",
      options: [
        { label: "开启", value: "on" },
        { label: "关闭", value: "off" },
      ],
      current: function () {
        return nsGlobal.enabled ? "on" : "off";
      },
      onChange: function (v) {
        nsGlobal.enabled = v === "on";
        if (!nsGlobal.enabled) nsGlobal.permissionDenied = false;
      },
    },
    {
      id: "ns-perm",
      label: "权限状态",
      options: [
        { label: "已授权", value: "granted" },
        { label: "被拒绝", value: "denied" },
      ],
      current: function () {
        return nsGlobal.permissionDenied ? "denied" : "granted";
      },
      onChange: function (v) {
        nsGlobal.permissionDenied = v === "denied";
      },
    },
    {
      id: "ns-style",
      label: "通知样式",
      options: [
        { label: "样式 A", value: "A" },
        { label: "样式 B", value: "B" },
      ],
      current: function () {
        return nsGlobal.style;
      },
      onChange: function (v) {
        nsGlobal.style = v;
      },
    },
    {
      id: "ns-used",
      label: "已用提醒槽",
      options: [
        { label: "4 / 30", value: "4" },
        { label: "28 / 30", value: "28" },
        { label: "30 / 30（满）", value: "30" },
      ],
      current: function () {
        return String(nsGlobal.reminderUsed);
      },
      onChange: function (v) {
        nsGlobal.reminderUsed = parseInt(v);
      },
    },
    {
      id: "ns-acct2",
      label: "账号 2 折叠",
      options: [
        { label: "折叠", value: "collapsed" },
        { label: "展开", value: "expanded" },
      ],
      current: function () {
        return nsAccounts[1].isExpanded ? "expanded" : "collapsed";
      },
      onChange: function (v) {
        nsAccounts[1].isExpanded = v === "expanded";
      },
    },
  ];
}

function renderNotificationSettings(w, h) {
  var c = T();
  var s = nsGlobal;
  var maxW = Math.min(600, w - 40);
  var sectionDisabled = !s.enabled || s.permissionDenied;

  var css =
    "<style>" +
    ".nc{background:" +
    c.surfCard +
    ";border:1px solid " +
    c.border +
    ";border-radius:12px;overflow:hidden;box-shadow:0 2px 6px " +
    c.shadow +
    ";margin-bottom:4px}" +
    ".nr{display:flex;align-items:center;min-height:50px;padding:0 16px;gap:12px;border-bottom:1px solid " +
    c.div +
    "}" +
    ".nr:last-child{border-bottom:none}" +
    ".nr-dis{opacity:0.4;pointer-events:none}" +
    ".tog{width:44px;height:26px;border-radius:13px;position:relative;flex-shrink:0;transition:background .2s}" +
    ".tog-on{background:" +
    c.primary +
    "}" +
    ".tog-off{background:" +
    (G.theme === "dark" ? "#3a3a3a" : "#ccc") +
    "}" +
    ".tog-k{position:absolute;top:3px;width:20px;height:20px;border-radius:50%;background:#fff;transition:left .2s;box-shadow:0 1px 3px rgba(0,0,0,.3)}" +
    ".tog-on .tog-k{left:21px}" +
    ".tog-off .tog-k{left:3px}" +
    // 样式选择卡片
    ".sc{border:1.5px solid " +
    c.border +
    ";border-radius:10px;padding:14px 16px;margin-bottom:8px}" +
    ".sc:last-child{margin-bottom:0}" +
    ".sc.on{border-color:" +
    c.primary +
    ";background:rgba(77,163,255,0.06)}" +
    ".sc-hd{display:flex;align-items:center;gap:10px;margin-bottom:8px}" +
    ".radio{width:18px;height:18px;border-radius:50%;border:2px solid " +
    c.border +
    ";flex-shrink:0;display:flex;align-items:center;justify-content:center}" +
    ".radio.on{border-color:" +
    c.primary +
    "}" +
    ".radio-dot{width:8px;height:8px;border-radius:50%;background:" +
    c.primary +
    "}" +
    // 通知气泡
    ".nb{background:" +
    (G.theme === "dark" ? "#2a2a3e" : "#fff") +
    ";border:1px solid " +
    (G.theme === "dark" ? "#3a3a50" : "#e0e0e8") +
    ";border-radius:12px;padding:10px 12px;box-shadow:0 2px 8px rgba(0,0,0,.15)}" +
    ".nb-hd{display:flex;align-items:center;gap:6px;margin-bottom:4px}" +
    ".nb-icon{width:16px;height:16px;border-radius:4px;background:linear-gradient(135deg," +
    c.primary +
    "," +
    c.cyan +
    ");flex-shrink:0}" +
    ".nb-app{font-size:11px;color:" +
    c.txt2 +
    ";font-weight:500}" +
    ".nb-time{font-size:10px;color:" +
    c.txt2 +
    ";margin-left:auto;opacity:.6}" +
    ".nb-title{font-size:13px;font-weight:600;color:" +
    c.txt +
    ";margin-bottom:2px}" +
    ".nb-body{font-size:12px;color:" +
    c.txt2 +
    ";line-height:1.5}" +
    ".nb-sub{font-size:11px;color:" +
    c.txt2 +
    ";margin-top:3px;opacity:.7}" +
    ".nb-row{display:flex;align-items:center;gap:6px;padding:3px 0;font-size:12px;color:" +
    c.txt2 +
    "}" +
    ".nb-dot{width:6px;height:6px;border-radius:50%;flex-shrink:0}" +
    ".nb-div{border-top:1px solid " +
    (G.theme === "dark" ? "#3a3a50" : "#e8e8f0") +
    ";margin:6px 0;padding-top:6px}" +
    ".preview-wrap{background:" +
    (G.theme === "dark" ? "#1e1e2e" : "#f0f0f8") +
    ";border:1px solid " +
    c.border +
    ";border-radius:10px;padding:10px 12px;margin-top:10px}" +
    ".preview-lbl{font-size:10px;color:" +
    c.txt2 +
    ";margin-bottom:6px;opacity:.7;letter-spacing:.5px}" +
    ".preview-hint{font-size:11px;color:" +
    c.txt2 +
    ";margin-top:8px;opacity:.7}" +
    // 账号区块
    ".acct-hd{display:flex;align-items:center;gap:10px;padding:12px 16px;cursor:pointer;border-bottom:1px solid " +
    c.div +
    "}" +
    ".acct-avatar{width:32px;height:32px;border-radius:8px;object-fit:cover;flex-shrink:0;border:1px solid " +
    c.border +
    "}" +
    ".acct-avatar-ph{width:32px;height:32px;border-radius:8px;background:" +
    c.primary +
    ";flex-shrink:0;opacity:.5}" +
    ".acct-chevron{font-size:12px;color:" +
    c.txt2 +
    ";transition:transform .2s;margin-left:auto}" +
    // 提醒槽位进度条
    ".slot-bar{height:4px;border-radius:2px;background:" +
    c.border +
    ";overflow:hidden;margin-top:4px}" +
    ".slot-fill{height:100%;border-radius:2px;transition:width .3s}" +
    // 超限 Dialog 遮罩
    ".dialog-mask{position:absolute;inset:0;background:rgba(0,0,0,.6);display:flex;align-items:center;justify-content:center;z-index:100}" +
    ".dialog-box{background:" +
    c.surfCard +
    ";border:1px solid " +
    c.border +
    ";border-radius:16px;padding:20px;max-width:280px;width:calc(100% - 48px)}" +
    ".dialog-title{font-size:16px;font-weight:700;color:" +
    c.txt +
    ";margin-bottom:8px}" +
    ".dialog-body{font-size:13px;color:" +
    c.txt2 +
    ";line-height:1.6;margin-bottom:16px}" +
    ".dialog-btn{width:100%;padding:10px;border-radius:10px;border:none;background:" +
    c.primary +
    ";color:#fff;font-size:14px;font-weight:600;cursor:pointer;font-family:inherit}" +
    ".warn-bar{background:rgba(255,149,0,0.1);border:1px solid rgba(255,149,0,0.3);border-radius:10px;padding:10px 14px;font-size:13px;color:#ff9500;margin-bottom:8px;display:flex;align-items:flex-start;gap:8px}" +
    "</style>";

  // ── 超限 Dialog ─────────────────────────────────────────────
  var limitDialog = "";
  if (s.showLimitDialog) {
    limitDialog =
      '<div class="dialog-mask">' +
      '<div class="dialog-box">' +
      '<div class="dialog-title">⚠️ 代理提醒已达上限</div>' +
      '<div class="dialog-body">系统允许本应用最多注册 30 个代理提醒，当前已使用 ' +
      s.reminderUsed +
      " 个。<br><br>请先关闭部分游戏的通知开关，再开启新的通知。</div>" +
      '<button class="dialog-btn">我知道了</button>' +
      "</div>" +
      "</div>";
  }

  // ── 总开关 ──────────────────────────────────────────────────
  var toggleHtml =
    '<div class="nc">' +
    '<div class="nr">' +
    '<div style="flex:1">' +
    '<div style="font-size:15px;color:' +
    c.txt +
    '">通知提醒</div>' +
    '<div style="font-size:12px;color:' +
    c.txt2 +
    ';margin-top:2px">体力值达到阈值时推送系统提醒，App 关闭后仍有效</div>' +
    "</div>" +
    '<div class="tog ' +
    (s.enabled ? "tog-on" : "tog-off") +
    '"><div class="tog-k"></div></div>' +
    "</div>" +
    "</div>";

  // ── 权限被拒绝提示 ──────────────────────────────────────────
  var permWarn = "";
  if (s.enabled && s.permissionDenied) {
    permWarn =
      '<div class="warn-bar">' +
      '<span style="font-size:16px;flex-shrink:0">⚠️</span>' +
      '<div><div style="font-weight:600;margin-bottom:2px">通知权限未开启</div>' +
      "请前往系统设置 → 应用 → 米悠悠 → 通知，手动开启通知权限</div>" +
      "</div>";
  }

  // ── 代理提醒槽位使用量 ──────────────────────────────────────
  var slotRatio = Math.min(s.reminderUsed / s.reminderLimit, 1);
  var slotColor =
    slotRatio >= 1 ? c.danger : slotRatio >= 0.8 ? "#ff9500" : c.ok;
  var slotHtml =
    '<div class="nc" style="' +
    (sectionDisabled ? "opacity:.4;pointer-events:none" : "") +
    '">' +
    '<div class="nr" style="flex-direction:column;align-items:stretch;padding:12px 16px;gap:6px">' +
    '<div style="display:flex;align-items:center;justify-content:space-between">' +
    '<div style="font-size:13px;color:' +
    c.txt +
    '">代理提醒槽位</div>' +
    '<div style="font-size:13px;font-weight:600;color:' +
    slotColor +
    '">' +
    s.reminderUsed +
    " / " +
    s.reminderLimit +
    "</div>" +
    "</div>" +
    '<div class="slot-bar"><div class="slot-fill" style="width:' +
    (slotRatio * 100).toFixed(0) +
    "%;background:" +
    slotColor +
    '"></div></div>' +
    '<div style="font-size:11px;color:' +
    c.txt2 +
    '">每个「账号 × 游戏」占用 1 个槽位，上限 30 个</div>' +
    "</div>" +
    "</div>";

  // ── 通知样式选择（纵向） ────────────────────────────────────
  // 样式 A 预览
  var previewA =
    '<div class="preview-wrap">' +
    '<div class="preview-lbl">通知预览</div>' +
    '<div class="nb">' +
    '<div class="nb-hd"><div class="nb-icon"></div><span class="nb-app">米悠悠</span><span class="nb-time">刚刚</span></div>' +
    '<div class="nb-title">原神 · CainLuo</div>' +
    '<div class="nb-body">原粹树脂已达 200/200，请及时消耗</div>' +
    '<div class="nb-sub">天空岛 · UID 109050292</div>' +
    "</div>" +
    '<div class="preview-hint">每个「账号 × 游戏」独立一条通知</div>' +
    "</div>";

  // 样式 B 预览（折叠 + 展开）
  var previewB =
    '<div class="preview-wrap">' +
    '<div class="preview-lbl">折叠状态</div>' +
    '<div class="nb">' +
    '<div class="nb-hd"><div class="nb-icon"></div><span class="nb-app">米悠悠</span><span class="nb-time">刚刚</span></div>' +
    '<div class="nb-title">米悠悠 · 3 项体力提醒</div>' +
    '<div class="nb-body">原神、星穹铁道、绝区零体力已达阈值</div>' +
    "</div>" +
    '<div class="preview-lbl" style="margin-top:10px">展开状态（最多 3 行）</div>' +
    '<div class="nb">' +
    '<div class="nb-hd"><div class="nb-icon"></div><span class="nb-app">米悠悠</span><span class="nb-time">刚刚</span></div>' +
    '<div class="nb-title">游戏体力提醒</div>' +
    '<div class="nb-div">' +
    '<div class="nb-row"><div class="nb-dot" style="background:' +
    c.genshin +
    '"></div><span>原神：树脂 200/200 已满</span></div>' +
    '<div class="nb-row"><div class="nb-dot" style="background:' +
    c.starrail +
    '"></div><span>星铁：开拓力 300/300 已满</span></div>' +
    '<div class="nb-row"><div class="nb-dot" style="background:' +
    c.zzz +
    '"></div><span>绝区零：电量 240/240 已满</span></div>' +
    "</div>" +
    "</div>" +
    '<div class="preview-hint">所有游戏合并为一条通知，lines[] 最多 3 行（API 限制）</div>' +
    "</div>";

  var styleSection =
    '<div style="font-size:12px;color:' +
    c.txt2 +
    ';padding:0 4px 6px;margin-top:16px">通知样式</div>' +
    '<div class="nc" style="' +
    (sectionDisabled ? "opacity:.4;pointer-events:none" : "") +
    '">' +
    '<div style="padding:12px 16px">' +
    '<div class="sc' +
    (s.style === "A" ? " on" : "") +
    '">' +
    '<div class="sc-hd">' +
    '<div class="radio' +
    (s.style === "A" ? " on" : "") +
    '">' +
    (s.style === "A" ? '<div class="radio-dot"></div>' : "") +
    "</div>" +
    '<div><div style="font-size:14px;font-weight:600;color:' +
    c.txt +
    '">样式 A · 独立通知</div>' +
    '<div style="font-size:12px;color:' +
    c.txt2 +
    ';margin-top:1px">每个游戏角色独立发送一条通知</div></div>' +
    "</div>" +
    previewA +
    "</div>" +
    '<div class="sc' +
    (s.style === "B" ? " on" : "") +
    '">' +
    '<div class="sc-hd">' +
    '<div class="radio' +
    (s.style === "B" ? " on" : "") +
    '">' +
    (s.style === "B" ? '<div class="radio-dot"></div>' : "") +
    "</div>" +
    '<div><div style="font-size:14px;font-weight:600;color:' +
    c.txt +
    '">样式 B · 合并通知</div>' +
    '<div style="font-size:12px;color:' +
    c.txt2 +
    ';margin-top:1px">多个游戏合并为一条多行通知</div></div>' +
    "</div>" +
    previewB +
    "</div>" +
    "</div>" +
    "</div>";

  // ── 各账号阈值配置（可折叠） ────────────────────────────────
  function renderGameRow(game, acctDisabled) {
    var rowDis = acctDisabled || !game.enabled;
    var maxLabel =
      game.maxStamina > 0
        ? "上限 " +
          game.maxStamina +
          "（来自 API），每点 " +
          game.secondsPerUnit / 60 +
          " 分钟恢复"
        : "上限待同步，每点 " + game.secondsPerUnit / 60 + " 分钟恢复";
    var maxVal = game.maxStamina > 0 ? game.maxStamina : "—";
    return (
      '<div class="nr' +
      (rowDis ? " nr-dis" : "") +
      '">' +
      '<div style="width:3px;height:32px;border-radius:2px;background:' +
      gameColor(game.gameId) +
      ';flex-shrink:0;margin-right:4px"></div>' +
      '<div style="flex:1;min-width:0">' +
      '<div style="font-size:14px;color:' +
      c.txt +
      '">' +
      game.gameName +
      " · " +
      game.staminaName +
      "</div>" +
      '<div style="font-size:11px;color:' +
      c.txt2 +
      ';margin-top:2px">' +
      maxLabel +
      "</div>" +
      "</div>" +
      '<div style="display:flex;align-items:center;gap:8px;flex-shrink:0">' +
      '<div style="background:' +
      (G.theme === "dark" ? "#1a1a2a" : "#f0f0f5") +
      ";border:1px solid " +
      c.border +
      ";border-radius:8px;padding:4px 10px;font-size:14px;color:" +
      c.txt +
      ';width:64px;text-align:center">' +
      game.threshold +
      "</div>" +
      '<div style="font-size:11px;color:' +
      c.txt2 +
      '">/ ' +
      maxVal +
      "</div>" +
      '<div class="tog ' +
      (game.enabled ? "tog-on" : "tog-off") +
      '"><div class="tog-k"></div></div>' +
      "</div>" +
      "</div>"
    );
  }

  var accountsHtml = "";
  for (var i = 0; i < nsAccounts.length; i++) {
    var acct = nsAccounts[i];
    var acctDis = sectionDisabled;
    var avatarHtml = acct.avatarUrl
      ? '<img class="acct-avatar" src="' +
        acct.avatarUrl +
        '" onerror="this.style.background=\'' +
        c.primary +
        "';this.src=''\" />"
      : '<div class="acct-avatar-ph"></div>';

    // 账号头部（可点击折叠）
    var acctHeader =
      '<div class="acct-hd' +
      (acctDis ? " nr-dis" : "") +
      '">' +
      avatarHtml +
      '<div style="flex:1;min-width:0">' +
      '<div style="font-size:14px;font-weight:600;color:' +
      c.txt +
      '">' +
      acct.nickname +
      "</div>" +
      '<div style="font-size:11px;color:' +
      c.txt2 +
      ';margin-top:1px">UID ' +
      acct.uid +
      " · " +
      acct.games.length +
      " 个游戏</div>" +
      "</div>" +
      '<span class="acct-chevron" style="transform:rotate(' +
      (acct.isExpanded ? "90" : "0") +
      'deg)">›</span>' +
      "</div>";

    // 游戏行（折叠时隐藏）
    var gameRows = "";
    if (acct.isExpanded) {
      for (var j = 0; j < acct.games.length; j++) {
        gameRows += renderGameRow(acct.games[j], acctDis);
      }
      // 满值快捷开关
      gameRows +=
        '<div class="nr' +
        (acctDis ? " nr-dis" : "") +
        '" style="background:' +
        (G.theme === "dark"
          ? "rgba(77,163,255,0.04)"
          : "rgba(0,125,255,0.03)") +
        '">' +
        '<div style="flex:1">' +
        '<div style="font-size:13px;color:' +
        c.txt +
        '">满值时通知</div>' +
        '<div style="font-size:11px;color:' +
        c.txt2 +
        ';margin-top:1px">一键将此账号所有游戏阈值设为满值</div>' +
        "</div>" +
        '<div style="font-size:12px;color:' +
        c.primary +
        ";padding:4px 10px;border:1px solid " +
        c.primary +
        ';border-radius:8px;cursor:pointer">设置</div>' +
        "</div>";
    }

    accountsHtml +=
      '<div class="nc" style="margin-bottom:8px">' +
      acctHeader +
      gameRows +
      "</div>";
  }

  var thresholdSection =
    '<div style="font-size:12px;color:' +
    c.txt2 +
    ';padding:0 4px 6px;margin-top:16px">各账号游戏阈值</div>' +
    accountsHtml;

  // ── 说明文字 ────────────────────────────────────────────────
  var hintHtml =
    '<div style="font-size:12px;color:' +
    c.txt2 +
    ';padding:8px 4px 4px;line-height:1.6">' +
    "通知由系统代理管理（reminderAgentManager），关闭 App 后时间到了仍会收到提醒。体力上限值来自便笺 API 响应，不同账号可能不同。" +
    "</div>";

  var content =
    '<div class="sy" style="flex:1;padding:12px 20px 40px">' +
    '<div style="max-width:' +
    maxW +
    'px;margin:0 auto">' +
    '<div style="font-size:20px;font-weight:700;color:' +
    c.txt +
    ';margin-bottom:16px">通知设置</div>' +
    permWarn +
    toggleHtml +
    slotHtml +
    styleSection +
    thresholdSection +
    hintHtml +
    "</div></div>";

  return (
    baseCss(w, h) +
    css +
    '<div style="width:' +
    w +
    "px;height:" +
    h +
    "px;display:flex;flex-direction:column;background:" +
    c.pageBg +
    ';position:relative">' +
    content +
    limitDialog +
    "</div>"
  );
}

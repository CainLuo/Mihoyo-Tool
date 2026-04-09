/**
 * characters.js — 角色页渲染逻辑
 */
var charactersState = {
  view: "data",
  game: "genshin",
  imgRatio: "crop",
  accountCount: "multi", // single | multi
  menuOpen: false,
  selectedAccount: 0,
};

var MOCK_ACCOUNTS = [
  {
    nickname: "CainLuo",
    uid: "100000001",
    avatarUrl: "https://bbs-static.miyoushe.com/avatar/avatar1.png",
  },
  {
    nickname: "旅行者",
    uid: "200000002",
    avatarUrl: "",
  },
  {
    nickname: "钟离",
    uid: "300000003",
    avatarUrl: "",
  },
];

var CHARS_GENSHIN = [
  {
    name: "菲林斯",
    lv: 90,
    fetter: 9,
    elem: "雷",
    elemColor: "#CE93D8",
    cons: 0,
    weaponLv: 90,
    weaponAffix: 1,
  },
  {
    name: "希诺宁",
    lv: 90,
    fetter: 10,
    elem: "岩",
    elemColor: "#FFCA28",
    cons: 0,
    weaponLv: 90,
    weaponAffix: 1,
  },
  {
    name: "娜维娅",
    lv: 90,
    fetter: 10,
    elem: "岩",
    elemColor: "#FFCA28",
    cons: 0,
    weaponLv: 90,
    weaponAffix: 1,
  },
  {
    name: "芙宁娜",
    lv: 90,
    fetter: 10,
    elem: "水",
    elemColor: "#4FC3F7",
    cons: 0,
    weaponLv: 90,
    weaponAffix: 1,
  },
  {
    name: "那维莱特",
    lv: 90,
    fetter: 10,
    elem: "水",
    elemColor: "#4FC3F7",
    cons: 0,
    weaponLv: 90,
    weaponAffix: 1,
  },
  {
    name: "迪希雅",
    lv: 90,
    fetter: 10,
    elem: "火",
    elemColor: "#FF7043",
    cons: 0,
    weaponLv: 90,
    weaponAffix: 1,
  },
  {
    name: "奇偶·女",
    lv: 1,
    fetter: 0,
    elem: "火",
    elemColor: "#FF7043",
    cons: 0,
    weaponLv: 60,
    weaponAffix: 3,
  },
  {
    name: "奇偶·男",
    lv: 50,
    fetter: 0,
    elem: "火",
    elemColor: "#FF7043",
    cons: 0,
    weaponLv: 60,
    weaponAffix: 2,
  },
  {
    name: "无武器角色",
    lv: 70,
    fetter: 5,
    elem: "冰",
    elemColor: "#4FC3F7",
    cons: 2,
    weaponLv: 0,
    weaponAffix: 0,
  },
];

var CHARS_STARRAIL = [
  {
    name: "黄泉",
    lv: 80,
    elem: "雷",
    elemColor: "#CE93D8",
    path: "虚无",
    pathColor: "#9C27B0",
    rank: 0,
    weaponLv: 80,
    weaponAffix: 1,
  },
  {
    name: "镜流",
    lv: 80,
    elem: "冰",
    elemColor: "#4FC3F7",
    path: "毁灭",
    pathColor: "#F44336",
    rank: 0,
    weaponLv: 80,
    weaponAffix: 1,
  },
  {
    name: "白露",
    lv: 80,
    elem: "雷",
    elemColor: "#CE93D8",
    path: "丰饶",
    pathColor: "#4CAF50",
    rank: 0,
    weaponLv: 60,
    weaponAffix: 5,
  },
  {
    name: "克拉拉",
    lv: 80,
    elem: "物理",
    elemColor: "#9E9E9E",
    path: "毁灭",
    pathColor: "#F44336",
    rank: 1,
    weaponLv: 80,
    weaponAffix: 5,
  },
  {
    name: "杰帕德",
    lv: 80,
    elem: "冰",
    elemColor: "#4FC3F7",
    path: "存护",
    pathColor: "#2196F3",
    rank: 0,
    weaponLv: 80,
    weaponAffix: 1,
  },
  {
    name: "希儿",
    lv: 80,
    elem: "量子",
    elemColor: "#7C4DFF",
    path: "巡猎",
    pathColor: "#FF9800",
    rank: 0,
    weaponLv: 70,
    weaponAffix: 4,
  },
  {
    name: "姬子",
    lv: 80,
    elem: "火",
    elemColor: "#FF7043",
    path: "智识",
    pathColor: "#00BCD4",
    rank: 0,
    weaponLv: 70,
    weaponAffix: 1,
  },
  {
    name: "桑博",
    lv: 80,
    elem: "风",
    elemColor: "#69F0AE",
    path: "虚无",
    pathColor: "#9C27B0",
    rank: 3,
    weaponLv: 40,
    weaponAffix: 2,
  },
  {
    name: "无光锥角色",
    lv: 60,
    elem: "冰",
    elemColor: "#4FC3F7",
    path: "存护",
    pathColor: "#2196F3",
    rank: 0,
    weaponLv: 0,
    weaponAffix: 0,
  },
];

var CHARS_ZZZ = [
  {
    name: "柏妮思",
    lv: 60,
    elem: "火",
    elemColor: "#FF7043",
    profession: "支援",
    faction: "卡吕冬之子",
    rank: 0,
    rarity: "S",
    weaponLv: 60,
    weaponAffix: 1,
  },
  {
    name: "朱鸢",
    lv: 60,
    elem: "火",
    elemColor: "#FF7043",
    profession: "支援",
    faction: "维多利亚家政",
    rank: 0,
    rarity: "S",
    weaponLv: 60,
    weaponAffix: 1,
  },
  {
    name: "苍角",
    lv: 60,
    elem: "冰",
    elemColor: "#4FC3F7",
    profession: "强攻",
    faction: "刑侦特别支援队",
    rank: 0,
    rarity: "S",
    weaponLv: 60,
    weaponAffix: 1,
  },
  {
    name: "猫又",
    lv: 60,
    elem: "火",
    elemColor: "#FF7043",
    profession: "异常",
    faction: "狡兔屋",
    rank: 0,
    rarity: "S",
    weaponLv: 60,
    weaponAffix: 1,
  },
  {
    name: "妮可",
    lv: 60,
    elem: "以太",
    elemColor: "#E040FB",
    profession: "辅助",
    faction: "狡兔屋",
    rank: 0,
    rarity: "S",
    weaponLv: 60,
    weaponAffix: 1,
  },
  {
    name: "派派",
    lv: 60,
    elem: "冰",
    elemColor: "#4FC3F7",
    profession: "支援",
    faction: "卡吕冬之子",
    rank: 5,
    rarity: "A",
    weaponLv: 40,
    weaponAffix: 2,
  },
  {
    name: "露西",
    lv: 54,
    elem: "火",
    elemColor: "#FF7043",
    profession: "辅助",
    faction: "卡吕冬之子",
    rank: 5,
    rarity: "A",
    weaponLv: 40,
    weaponAffix: 3,
  },
];

function renderCharacters(w, h) {
  var c = T();
  var cols = w < 600 ? 2 : w < 840 ? 3 : w < 1200 ? 4 : 5;
  var gridCols = "repeat(" + cols + ",1fr)";
  var isPhone = w < 600;
  var game = charactersState.game;
  var nameSz = isPhone ? "11" : "12";
  var imgRatio = charactersState.imgRatio;
  var isMulti = charactersState.accountCount === "multi";
  var menuOpen = charactersState.menuOpen;
  var selectedIdx = charactersState.selectedAccount;
  var accounts = isMulti ? MOCK_ACCOUNTS : [MOCK_ACCOUNTS[0]];
  var currentAccount = accounts[Math.min(selectedIdx, accounts.length - 1)];
  // 星铁图片原始比例 160:188，绝区零 300:368
  var srRatio = imgRatio === "native" ? "160/188" : "1/1";
  var zzzRatio = imgRatio === "native" ? "300/368" : "1/1";

  // ── 账号切换 Menu ─────────────────────────────────────────────
  function accountMenu() {
    if (!menuOpen || !isMulti) return "";
    var items = "";
    for (var i = 0; i < accounts.length; i++) {
      var acc = accounts[i];
      var isSelected = i === selectedIdx;
      var avatarContent = acc.avatarUrl
        ? '<img src="' +
          acc.avatarUrl +
          '" style="width:32px;height:32px;border-radius:8px;object-fit:cover;flex-shrink:0;border:1px solid ' +
          (isSelected ? c.primary : c.border) +
          '" onerror="this.style.background=\'' +
          c.primary +
          "';this.src=''\"/>"
        : '<div style="width:32px;height:32px;border-radius:8px;background:' +
          c.primary +
          "33;border:1px solid " +
          (isSelected ? c.primary : c.border) +
          ';display:flex;align-items:center;justify-content:center;font-size:14px;flex-shrink:0">👤</div>';
      items +=
        '<div onclick="charactersState.selectedAccount=' +
        i +
        ';charactersState.menuOpen=false;refresh()" style="display:flex;align-items:center;gap:10px;padding:10px 14px;cursor:pointer;' +
        (isSelected ? "background:" + c.primary + "18;" : "") +
        'transition:background .15s" onmouseover="this.style.background=\'' +
        c.primary +
        "12'\" onmouseout=\"this.style.background='" +
        (isSelected ? c.primary + "18" : "transparent") +
        "'\">" +
        avatarContent +
        '<div style="flex:1;min-width:0">' +
        '<div style="font-size:13px;font-weight:' +
        (isSelected ? "600" : "400") +
        ";color:" +
        (isSelected ? c.primary : c.txt) +
        ';white-space:nowrap;overflow:hidden;text-overflow:ellipsis">' +
        acc.nickname +
        "</div>" +
        '<div style="font-size:11px;color:' +
        c.txt2 +
        ';margin-top:1px">UID: ' +
        acc.uid +
        "</div>" +
        "</div>" +
        (isSelected
          ? '<div style="font-size:14px;color:' + c.primary + '">✓</div>'
          : "") +
        "</div>";
      if (i < accounts.length - 1) {
        items +=
          '<div style="height:1px;background:' +
          c.div +
          ';margin:0 14px"></div>';
      }
    }
    return (
      '<div style="position:absolute;top:100%;right:0;z-index:100;min-width:220px;' +
      "background:" +
      c.cardBg +
      ";border:1px solid " +
      c.border +
      ";border-radius:12px;" +
      'box-shadow:0 8px 24px rgba(0,0,0,.4);overflow:hidden;margin-top:4px">' +
      '<div style="padding:8px 14px 6px;font-size:11px;color:' +
      c.txt2 +
      ';font-weight:600;letter-spacing:.5px">切换账号</div>' +
      '<div style="height:1px;background:' +
      c.div +
      ';margin-bottom:4px"></div>' +
      items +
      "</div>"
    );
  }

  // ── 标题栏（含账号切换按钮） ──────────────────────────────────
  var currentAvatarContent = currentAccount.avatarUrl
    ? '<img src="' +
      currentAccount.avatarUrl +
      '" style="width:28px;height:28px;border-radius:7px;object-fit:cover;border:1px solid ' +
      c.primary +
      '55" onerror="this.style.background=\'' +
      c.primary +
      "';this.src=''\"/>"
    : '<div style="width:28px;height:28px;border-radius:7px;background:' +
      c.primary +
      "33;border:1px solid " +
      c.primary +
      '55;display:flex;align-items:center;justify-content:center;font-size:13px">👤</div>';

  var titleBar =
    '<div style="display:flex;align-items:center;gap:8px;padding:10px 16px 8px;flex-shrink:0;position:relative">' +
    // 左侧：当前账号头像 + 昵称
    '<div style="flex:1;display:flex;align-items:center;gap:8px">' +
    currentAvatarContent +
    "<div>" +
    '<div style="font-size:14px;font-weight:600;color:' +
    c.txt +
    '">' +
    currentAccount.nickname +
    "</div>" +
    '<div style="font-size:11px;color:' +
    c.txt2 +
    '">UID: ' +
    currentAccount.uid +
    "</div>" +
    "</div>" +
    "</div>" +
    // 右侧按钮组
    '<div style="display:flex;align-items:center;gap:8px;position:relative">' +
    // 账号切换按钮（多账号时才显示）
    (isMulti
      ? '<div onclick="charactersState.menuOpen=!charactersState.menuOpen;refresh()" style="width:32px;height:32px;border-radius:8px;background:' +
        (menuOpen ? c.primary + "22" : c.surfCard) +
        ";border:1px solid " +
        (menuOpen ? c.primary + "66" : c.border) +
        ';display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:16px;transition:all .15s" title="切换账号">👥</div>'
      : "") +
    // 刷新按钮
    '<div style="width:32px;height:32px;border-radius:8px;background:' +
    c.surfCard +
    ";border:1px solid " +
    c.border +
    ';display:flex;align-items:center;justify-content:center;cursor:pointer;font-size:15px" title="刷新">↻</div>' +
    // Menu 下拉
    accountMenu() +
    "</div>" +
    "</div>";

  // 点击空白关闭 menu 的遮罩
  var menuOverlay =
    menuOpen && isMulti
      ? '<div onclick="charactersState.menuOpen=false;refresh()" style="position:fixed;inset:0;z-index:99"></div>'
      : "";

  // 武器浮层：右下角独立区块
  // lv=0 时显示"未装备"占位状态（无等级、无精炼标签）
  function weaponBlock(lv, affix, prefix) {
    if (lv === 0) {
      // 未装备武器：显示禁止图标 + 暗色提示
      return (
        '<div style="position:absolute;bottom:0;right:0;width:56px;height:60px;' +
        "background:rgba(10,10,20,.75);border-top-left-radius:8px;" +
        "border-top:1px solid rgba(255,255,255,.1);border-left:1px solid rgba(255,255,255,.1);" +
        'display:flex;flex-direction:column;overflow:hidden">' +
        // 图标区：禁止符号
        '<div style="flex:1;display:flex;align-items:center;justify-content:center">' +
        '<div style="width:22px;height:22px;border-radius:50%;border:2px solid rgba(255,255,255,.25);' +
        'display:flex;align-items:center;justify-content:center;position:relative;opacity:.5">' +
        // 斜线
        '<div style="position:absolute;width:2px;height:26px;background:rgba(255,255,255,.4);transform:rotate(45deg)"></div>' +
        "</div>" +
        "</div>" +
        // 底部提示文字
        '<div style="display:flex;align-items:center;justify-content:center;height:18px;background:rgba(0,0,0,.5)">' +
        '<span style="font-size:8px;color:rgba(255,255,255,.35);letter-spacing:.3px">未装备</span>' +
        "</div></div>"
      );
    }
    return (
      '<div style="position:absolute;bottom:0;right:0;width:56px;height:60px;' +
      "background:rgba(10,10,20,.75);border-top-left-radius:8px;" +
      "border-top:1px solid rgba(255,255,255,.15);border-left:1px solid rgba(255,255,255,.15);" +
      'display:flex;flex-direction:column;overflow:hidden">' +
      // 图标占位区
      '<div style="flex:1;display:flex;align-items:center;justify-content:center;font-size:20px;opacity:.55">⚔️</div>' +
      // 底部信息行
      '<div style="display:flex;align-items:center;justify-content:space-between;padding:0 4px;height:18px;background:rgba(0,0,0,.5)">' +
      '<span style="font-size:8px;color:rgba(255,255,255,.5)">Lv.' +
      lv +
      "</span>" +
      '<span style="font-size:8px;font-weight:700;color:#4FC3F7;background:rgba(79,195,247,.18);padding:0 3px;border-radius:2px">' +
      prefix +
      affix +
      "</span>" +
      "</div></div>"
    );
  }

  // 底部渐变遮罩 + 角色名（右侧为武器浮层留出空间）
  function nameOverlay(name) {
    return (
      '<div style="position:absolute;bottom:0;left:0;right:0;' +
      "background:linear-gradient(to top,rgba(0,0,0,.75),transparent);" +
      'padding:4px 64px 6px 6px">' +
      '<div style="font-size:' +
      nameSz +
      "px;font-weight:700;color:rgba(255,255,255,.95);" +
      'white-space:nowrap;overflow:hidden;text-overflow:ellipsis">' +
      name +
      "</div>" +
      "</div>"
    );
  }

  // ── 原神卡片 ──────────────────────────────────────────────────
  function genshinCard(ch) {
    return (
      '<div style="background:' +
      c.surfCard +
      ";border:1px solid " +
      c.border +
      ";border-radius:12px;overflow:hidden;box-shadow:0 2px 6px " +
      c.shadow +
      '">' +
      '<div style="position:relative;background:linear-gradient(135deg,#1a1a2e,#16213e);aspect-ratio:1/1;overflow:hidden">' +
      '<div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;font-size:32px;opacity:.25">👤</div>' +
      // 元素（左上，圆形）
      '<div style="position:absolute;top:6px;left:6px;width:24px;height:24px;border-radius:50%;background:' +
      ch.elemColor +
      ';display:flex;align-items:center;justify-content:center;font-size:9px;font-weight:700;color:#fff;box-shadow:0 1px 4px rgba(0,0,0,.4)">' +
      ch.elem +
      "</div>" +
      // 命座（右上）
      '<div style="position:absolute;top:6px;right:6px;width:20px;height:20px;border-radius:50%;background:rgba(0,0,0,.65);border:1px solid rgba(255,255,255,.2);display:flex;align-items:center;justify-content:center;font-size:10px;font-weight:700;color:#FFD700">' +
      ch.cons +
      "</div>" +
      nameOverlay(ch.name) +
      weaponBlock(ch.weaponLv, ch.weaponAffix, "R") +
      "</div>" +
      // 底部信息栏：等级 | 好感
      '<div style="padding:5px 8px;display:flex;align-items:center;gap:6px">' +
      '<span style="font-size:11px;color:' +
      c.txt2 +
      '">Lv.' +
      ch.lv +
      "</span>" +
      '<span style="width:1px;height:10px;background:' +
      c.border +
      '"></span>' +
      '<span style="font-size:10px;color:' +
      c.txt2 +
      '">好感 ' +
      ch.fetter +
      "</span>" +
      "</div></div>"
    );
  }

  // ── 星穹铁道卡片 ──────────────────────────────────────────────
  function starrailCard(ch) {
    // 左上角：属性 + 命途，纵向排列
    var topLeft =
      '<div style="position:absolute;top:6px;left:6px;display:flex;flex-direction:column;gap:3px">' +
      '<div style="padding:1px 5px;border-radius:8px;background:' +
      ch.elemColor +
      "33;border:1px solid " +
      ch.elemColor +
      ";font-size:9px;font-weight:700;color:" +
      ch.elemColor +
      ';white-space:nowrap">' +
      ch.elem +
      "</div>" +
      '<div style="padding:1px 5px;border-radius:8px;background:' +
      ch.pathColor +
      "33;border:1px solid " +
      ch.pathColor +
      ";font-size:9px;font-weight:700;color:" +
      ch.pathColor +
      ';white-space:nowrap">' +
      ch.path +
      "</div>" +
      "</div>";
    return (
      '<div style="background:' +
      c.surfCard +
      ";border:1px solid " +
      c.border +
      ";border-radius:12px;overflow:hidden;box-shadow:0 2px 6px " +
      c.shadow +
      '">' +
      '<div style="position:relative;background:linear-gradient(135deg,#0d1b2a,#1a2744);aspect-ratio:' +
      srRatio +
      ';overflow:hidden">' +
      '<div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;font-size:32px;opacity:.25">👤</div>' +
      topLeft +
      // 星魂（右上）
      '<div style="position:absolute;top:6px;right:6px;width:20px;height:20px;border-radius:50%;background:rgba(0,0,0,.65);border:1px solid rgba(255,255,255,.2);display:flex;align-items:center;justify-content:center;font-size:10px;font-weight:700;color:#FFD700">' +
      ch.rank +
      "</div>" +
      nameOverlay(ch.name) +
      weaponBlock(ch.weaponLv, ch.weaponAffix, "S") +
      "</div>" +
      // 底部信息栏：等级
      '<div style="padding:5px 8px;display:flex;align-items:center">' +
      '<span style="font-size:11px;color:' +
      c.txt2 +
      '">Lv.' +
      ch.lv +
      "</span>" +
      "</div></div>"
    );
  }

  // ── 绝区零卡片 ────────────────────────────────────────────────
  function zzzCard(ch) {
    var rarityColor = ch.rarity === "S" ? "#FFD700" : "#9E9E9E";
    // 左上角：稀有度 + 属性 + 特性，纵向排列
    var topLeft =
      '<div style="position:absolute;top:6px;left:6px;display:flex;flex-direction:column;gap:3px">' +
      '<div style="padding:1px 5px;border-radius:8px;background:rgba(0,0,0,.5);border:1px solid ' +
      rarityColor +
      ";font-size:9px;font-weight:700;color:" +
      rarityColor +
      ';white-space:nowrap">' +
      ch.rarity +
      "</div>" +
      '<div style="padding:1px 5px;border-radius:8px;background:' +
      ch.elemColor +
      "33;border:1px solid " +
      ch.elemColor +
      ";font-size:9px;font-weight:700;color:" +
      ch.elemColor +
      ';white-space:nowrap">' +
      ch.elem +
      "</div>" +
      '<div style="padding:1px 5px;border-radius:8px;background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.2);font-size:9px;color:rgba(255,255,255,.7);white-space:nowrap">' +
      ch.profession +
      "</div>" +
      "</div>";
    return (
      '<div style="background:' +
      c.surfCard +
      ";border:1px solid " +
      c.border +
      ";border-radius:12px;overflow:hidden;box-shadow:0 2px 6px " +
      c.shadow +
      '">' +
      '<div style="position:relative;background:linear-gradient(135deg,#1a0d2e,#2a1a3e);aspect-ratio:' +
      zzzRatio +
      ';overflow:hidden">' +
      '<div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;font-size:32px;opacity:.25">👤</div>' +
      topLeft +
      // 影画（右上）
      '<div style="position:absolute;top:6px;right:6px;width:20px;height:20px;border-radius:50%;background:rgba(0,0,0,.65);border:1px solid rgba(255,255,255,.2);display:flex;align-items:center;justify-content:center;font-size:10px;font-weight:700;color:#FFD700">' +
      ch.rank +
      "</div>" +
      nameOverlay(ch.name) +
      weaponBlock(ch.weaponLv, ch.weaponAffix, "R") +
      "</div>" +
      // 底部信息栏：等级 | 阵营
      '<div style="padding:5px 8px;display:flex;align-items:center;gap:6px">' +
      '<span style="font-size:11px;color:' +
      c.txt2 +
      '">Lv.' +
      ch.lv +
      "</span>" +
      '<span style="width:1px;height:10px;background:' +
      c.border +
      '"></span>' +
      '<span style="font-size:9px;color:' +
      c.txt2 +
      ';white-space:nowrap;overflow:hidden;text-overflow:ellipsis">' +
      ch.faction +
      "</span>" +
      "</div></div>"
    );
  }

  function skCard() {
    return (
      '<div style="background:' +
      c.surfCard +
      ";border:1px solid " +
      c.border +
      ';border-radius:12px;overflow:hidden">' +
      '<div style="aspect-ratio:1/1;background:' +
      c.border +
      ';animation:sk 1.5s ease-in-out infinite"></div>' +
      '<div style="padding:6px 8px"><div style="height:10px;width:60%;background:' +
      c.border +
      ';border-radius:4px;animation:sk 1.5s ease-in-out infinite"></div></div>' +
      "</div>"
    );
  }

  // ── Tab 栏 ────────────────────────────────────────────────────
  var tabs = [
    { id: "genshin", label: "原神" },
    { id: "starrail", label: "崩坏：星穹铁道" },
    { id: "zzz", label: "绝区零" },
  ];
  var gameTabs =
    '<div style="display:flex;gap:8px;padding:10px 16px;border-bottom:1px solid ' +
    c.div +
    ";flex-shrink:0;background:" +
    c.cardBg +
    '">';
  for (var ti = 0; ti < tabs.length; ti++) {
    var t = tabs[ti];
    var isActive = game === t.id;
    gameTabs +=
      '<div data-game="' +
      t.id +
      '" onclick="charactersState.game=this.getAttribute(\'data-game\');refresh()" style="padding:5px 14px;border-radius:16px;font-size:13px;cursor:pointer;' +
      (isActive
        ? "background:" + c.primary + ";color:#fff;font-weight:600"
        : "border:1px solid " + c.border + ";color:" + c.txt2) +
      '">' +
      t.label +
      "</div>";
  }
  gameTabs += "</div>";

  // ── 内容区 ────────────────────────────────────────────────────
  var content = "";
  if (charactersState.view === "loading") {
    var sks = "";
    for (var i = 0; i < cols * 3; i++) sks += skCard();
    content =
      '<div class="sy" style="flex:1;padding:12px">' +
      '<div style="display:grid;grid-template-columns:' +
      gridCols +
      ';gap:10px">' +
      sks +
      "</div></div>";
  } else if (charactersState.view === "empty") {
    content =
      '<div style="flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:16px;padding:40px">' +
      '<div style="font-size:48px">📋</div>' +
      '<div style="font-size:16px;font-weight:600;color:' +
      c.txt +
      '">还没有角色数据</div>' +
      '<div style="font-size:13px;color:' +
      c.txt2 +
      ';text-align:center">绑定账号并同步后，即可查看各游戏的角色列表</div>' +
      '<div style="padding:10px 24px;background:' +
      c.primary +
      ';border-radius:8px;color:#fff;font-size:14px;font-weight:600;cursor:pointer">暂无角色数据，点击刷新同步</div>' +
      "</div>";
  } else {
    var dataList =
      game === "starrail"
        ? CHARS_STARRAIL
        : game === "zzz"
          ? CHARS_ZZZ
          : CHARS_GENSHIN;
    var cards = "";
    for (var i = 0; i < dataList.length; i++) {
      if (game === "starrail") cards += starrailCard(dataList[i]);
      else if (game === "zzz") cards += zzzCard(dataList[i]);
      else cards += genshinCard(dataList[i]);
    }
    content =
      '<div class="sy" style="flex:1;padding:12px">' +
      '<div style="display:grid;grid-template-columns:' +
      gridCols +
      ';gap:10px">' +
      cards +
      "</div></div>";
  }

  return (
    baseCss(w, h) +
    "<style>@keyframes sk{0%,100%{opacity:.4}50%{opacity:.9}}</style>" +
    menuOverlay +
    '<div style="width:' +
    w +
    "px;height:" +
    h +
    "px;display:flex;flex-direction:column;background:" +
    c.pageBg +
    '">' +
    titleBar +
    '<div style="height:1px;background:' +
    c.div +
    ';flex-shrink:0"></div>' +
    gameTabs +
    content +
    tabBar("characters") +
    "</div>"
  );
}

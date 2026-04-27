/**
 * account-detail.js — 账号详情页渲染逻辑
 *
 * 账号数据来自 mihoyo_bbs_account_detail.json：
 *   nickname: CainLuo，uid: 182692936，avatar_url: bbs-static.miyoushe.com/avatar/avatar1.png
 *
 * 游戏卡片数据来自 game_record_app_card_wapi_getGameRecordCard.json
 *
 * 样式与 App 实际 UI 同步：
 *   - 统计格子：rgba(0,0,0,0.45) 深色半透明背景，白色文字
 *   - 服务器/UID：白色文字，rgba(0,0,0,0.4) 标签背景
 */

function renderAccountDetail(w, h) {
  var c = T();
  var maxW = Math.min(600, w - 40);

  // 来自 mihoyo_bbs_account_detail.json
  var bbsUser = {
    uid: "182692936",
    nickname: "CainLuo",
    avatarUrl: "https://bbs-static.miyoushe.com/avatar/avatar1.png",
  };

  var css =
    "<style>" +
    ".ad-game-card{background:" +
    c.surfCard +
    ";border:1px solid " +
    c.border +
    ";border-radius:12px;overflow:hidden;margin-bottom:12px;box-shadow:0 2px 8px " +
    c.shadow +
    "}" +
    ".ad-top-content{display:flex;align-items:center;gap:10px;padding:14px 14px 10px}" +
    ".ad-game-logo{width:32px;height:32px;border-radius:7px;object-fit:cover;flex-shrink:0;border:1px solid " +
    c.border +
    "}" +
    ".ad-game-body{padding:8px 12px 10px;display:grid;grid-template-columns:1fr 1fr 1fr 1fr;gap:6px}" +
    ".ad-stat{background:rgba(0,0,0,0.45);border-radius:6px;padding:6px 8px}" +
    ".ad-stat-val{font-size:14px;font-weight:700;color:#fff;line-height:1.2}" +
    ".ad-stat-name{font-size:10px;color:rgba(255,255,255,0.7);margin-top:1px}" +
    ".ad-meta{display:flex;align-items:center;gap:6px;padding:7px 14px;font-size:12px}" +
    "</style>";

  var games = [
    {
      name: "原神",
      color: c.genshin,
      uid: "109050292",
      nick: "凹凸曼的小怪兽",
      server: "天空岛",
      level: 60,
      bgImg: "../assets/bg_genshin.png",
      logo: "../assets/logo_genshin.png",
      stats: [
        { name: "活跃天数", value: "1314" },
        { name: "成就达成数", value: "1521" },
        { name: "深境螺旋", value: "11-3" },
        { name: "幻想剧诗", value: "-" },
      ],
    },
    {
      name: "崩坏：星穹铁道",
      color: c.starrail,
      uid: "102731382",
      nick: "凹凸曼的小怪兽",
      server: "星穹列车",
      level: 70,
      bgImg: "../assets/bg_starrail.png",
      logo: "../assets/logo_starrail.png",
      stats: [
        { name: "活跃天数", value: "569" },
        { name: "已解锁角色", value: "45" },
        { name: "达成成就数", value: "995" },
        { name: "战利品开启", value: "877" },
      ],
    },
    {
      name: "崩坏3",
      color: c.honkai3,
      uid: "273583184",
      nick: "凹凸曼的小怪兽",
      server: "全平台（桌面）服",
      level: 32,
      bgImg: "../assets/bg_honkai3.png",
      logo: "../assets/logo_honkai3.png",
      stats: [
        { name: "累计登舰", value: "5" },
        { name: "装甲数", value: "5" },
        { name: "服装数", value: "5" },
        { name: "量子流形", value: "原罪" },
      ],
    },
    {
      name: "绝区零",
      color: c.zzz,
      uid: "37716744",
      nick: "凹凸曼的小怪兽",
      server: "新艾利都",
      level: 51,
      bgImg: "../assets/bg_zzz.png",
      logo: "../assets/logo_zzz.png",
      stats: [
        { name: "活跃天数", value: "39" },
        { name: "达成成就数", value: "204" },
        { name: "获得代理人数", value: "14" },
        { name: "获得邦布数", value: "17" },
      ],
    },
  ];

  var gameCards = "";
  for (var i = 0; i < games.length; i++) {
    var g = games[i];

    var statsHtml = "";
    for (var j = 0; j < g.stats.length; j++) {
      statsHtml +=
        '<div class="ad-stat">' +
        '<div class="ad-stat-val">' +
        g.stats[j].value +
        "</div>" +
        '<div class="ad-stat-name">' +
        g.stats[j].name +
        "</div>" +
        "</div>";
    }

    var lvBadge =
      '<div style="background:' +
      g.color +
      "22;border:1px solid " +
      g.color +
      "55;border-radius:6px;padding:3px 10px;font-size:12px;font-weight:600;color:" +
      g.color +
      '">Lv.' +
      g.level +
      "</div>";

    var tagStyle =
      "background:rgba(0,0,0,0.4);color:rgba(255,255,255,0.85);border-radius:4px;padding:2px 7px;font-size:11px";
    var divColor = "rgba(255,255,255,0.15)";
    var uidColor = "rgba(255,255,255,0.7)";

    gameCards +=
      '<div class="ad-game-card">' +
      '<div class="ad-top-content">' +
      '<img class="ad-game-logo" src="' +
      g.logo +
      '"/>' +
      '<div style="flex:1">' +
      '<div style="font-size:15px;font-weight:700;color:' +
      c.txt +
      '">' +
      g.name +
      "</div>" +
      '<div style="font-size:12px;color:' +
      c.txt2 +
      ';margin-top:1px">' +
      g.nick +
      "</div>" +
      "</div>" +
      lvBadge +
      "</div>" +
      '<div style="position:relative;overflow:hidden">' +
      '<div style="position:absolute;inset:0;background-image:url(' +
      g.bgImg +
      ');background-size:cover;background-position:center top;filter:brightness(0.5)"></div>' +
      '<div style="position:relative;z-index:1">' +
      '<div class="ad-meta">' +
      '<span style="' +
      tagStyle +
      '">' +
      g.server +
      "</span>" +
      '<span style="color:' +
      divColor +
      '">·</span>' +
      '<span style="color:' +
      uidColor +
      '">UID ' +
      g.uid +
      "</span>" +
      "</div>" +
      '<div style="height:1px;background:' +
      divColor +
      ';margin:0 12px"></div>' +
      '<div class="ad-game-body">' +
      statsHtml +
      "</div>" +
      "</div></div></div>";
  }

  return (
    baseCss(w, h) +
    css +
    '<div style="width:' +
    w +
    "px;height:" +
    h +
    "px;display:flex;flex-direction:column;background:" +
    c.pageBg +
    '">' +
    '<div class="sy" style="flex:1;padding:16px 20px 40px">' +
    '<div style="max-width:' +
    maxW +
    'px;margin:0 auto">' +
    '<div style="background:' +
    c.surfCard +
    ";border:1px solid " +
    c.border +
    ";border-radius:12px;padding:16px;display:flex;align-items:center;gap:14px;margin-bottom:20px;box-shadow:0 2px 8px " +
    c.shadow +
    '">' +
    '<img src="' +
    bbsUser.avatarUrl +
    '" style="width:52px;height:52px;border-radius:14px;object-fit:cover;flex-shrink:0;border:2px solid ' +
    c.primary +
    '55" onerror="this.style.background=\'' +
    c.primary +
    "33';this.src=''\"/>" +
    '<div style="flex:1">' +
    '<div style="font-size:17px;font-weight:700;color:' +
    c.txt +
    '">' +
    bbsUser.nickname +
    "</div>" +
    '<div style="font-size:12px;color:' +
    c.txt2 +
    ';margin-top:3px">UID ' +
    bbsUser.uid +
    " · 4 个游戏角色</div>" +
    "</div></div>" +
    '<div style="font-size:12px;color:' +
    c.txt2 +
    ';padding:0 4px;margin-bottom:8px;font-weight:500;letter-spacing:0.5px">游戏角色</div>' +
    gameCards +
    '<div style="font-size:12px;color:' +
    c.txt2 +
    ';padding:0 4px;margin-bottom:8px;margin-top:4px;font-weight:500;letter-spacing:0.5px">账号操作</div>' +
    '<div style="display:flex;align-items:center;justify-content:center;height:50px;font-size:15px;color:' +
    c.danger +
    ";background:" +
    c.surfCard +
    ";border:1px solid " +
    c.border +
    ";border-radius:12px;cursor:pointer;box-shadow:0 2px 6px " +
    c.shadow +
    '">删除账号</div>' +
    "</div></div></div>"
  );
}

function accountDetailControls() {
  return [];
}

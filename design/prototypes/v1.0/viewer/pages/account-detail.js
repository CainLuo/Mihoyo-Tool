/**
 * account-detail.js — 账号详情页渲染逻辑
 */

function renderAccountDetail(w, h) {
  var c = T();
  var maxW = Math.min(600, w - 40);

  var cardCss =
    "<style>" +
    ".adcard{background:" +
    c.surfCard +
    ";border:1px solid " +
    c.border +
    ";border-radius:12px;overflow:hidden;box-shadow:0 2px 6px " +
    c.shadow +
    ";margin-bottom:4px}" +
    ".adrow{display:flex;align-items:center;min-height:50px;padding:0 16px;gap:12px;border-bottom:1px solid " +
    c.div +
    "}" +
    ".adrow:last-child{border-bottom:none}" +
    "</style>";

  var roles = [
    {
      game: "原神",
      color: c.genshin,
      uid: "123456789",
      nick: "旅行者",
      server: "天空岛",
    },
    {
      game: "崩坏：星穹铁道",
      color: c.starrail,
      uid: "987654321",
      nick: "开拓者",
      server: "星穹列车",
    },
  ];

  var roleRows = "";
  for (var i = 0; i < roles.length; i++) {
    var r = roles[i];
    roleRows +=
      '<div class="adrow">' +
      '<div style="width:4px;height:32px;border-radius:2px;background:' +
      r.color +
      ';flex-shrink:0"></div>' +
      '<div style="flex:1"><div style="font-size:14px;font-weight:600;color:' +
      c.txt +
      '">' +
      r.game +
      "</div>" +
      '<div style="font-size:12px;color:' +
      c.txt2 +
      ';margin-top:2px">' +
      r.nick +
      " · " +
      r.server +
      " · UID " +
      r.uid +
      "</div>" +
      "</div></div>";
  }

  return (
    baseCss(w, h) +
    cardCss +
    '<div style="width:' +
    w +
    "px;height:" +
    h +
    "px;display:flex;flex-direction:column;background:" +
    c.pageBg +
    '">' +
    '<div class="sy" style="flex:1;padding:12px 20px 40px">' +
    '<div style="max-width:' +
    maxW +
    'px;margin:0 auto">' +
    // 账号头部
    '<div class="adcard" style="padding:16px;display:flex;align-items:center;gap:16px">' +
    '<div style="width:56px;height:56px;border-radius:28px;background:' +
    c.primary +
    ';flex-shrink:0"></div>' +
    '<div><div style="font-size:18px;font-weight:700;color:' +
    c.txt +
    '">182692936</div>' +
    '<div style="font-size:13px;color:' +
    c.txt2 +
    ';margin-top:3px">2 个游戏角色</div></div>' +
    "</div>" +
    // 游戏角色
    '<div style="font-size:12px;color:' +
    c.txt2 +
    ';padding:0 4px 6px;margin-top:12px">游戏角色</div>' +
    '<div class="adcard">' +
    roleRows +
    "</div>" +
    // 操作
    '<div style="font-size:12px;color:' +
    c.txt2 +
    ';padding:0 4px 6px;margin-top:12px">账号操作</div>' +
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

/**
 * starrail-daily-detail.js — 崩坏：星穹铁道便笺详情页
 *
 * 数据来自 mock/182692936/102731382/game_record_app_hkrpg_api_note.json
 *
 * 分组：
 *   第一组（日常）：开拓力 + 恢复倒计时、后备开拓力、委托派遣、每日实训、历战余响
 *   第二组（宇宙）：模拟宇宙积分、差分宇宙（含 exp_is_full）、黄金与机械
 */

var srDailyDetailControls = function () {
  return [];
};

// 完整 mock 数据（与 game_record_app_hkrpg_api_note.json 一致）
var SR_NOTE = {
  current_stamina: 300,
  max_stamina: 300,
  stamina_recover_time: 0,
  stamina_full_ts: 1774676986,
  accepted_epedition_num: 0,
  total_expedition_num: 4,
  expeditions: [],
  current_train_score: 0,
  max_train_score: 500,
  current_rogue_score: 0,
  max_rogue_score: 14000,
  weekly_cocoon_cnt: 3,
  weekly_cocoon_limit: 3,
  current_reserve_stamina: 2400,
  is_reserve_stamina_full: true,
  rogue_tourn_weekly_unlocked: false,
  rogue_tourn_weekly_max: 1000,
  rogue_tourn_weekly_cur: 0,
  current_ts: 1774676986,
  rogue_tourn_exp_is_full: false,
  grid_fight_weekly_cur: 0,
  grid_fight_weekly_max: 0,
};

function formatSeconds(secs) {
  if (!secs || secs <= 0) return "";
  var h = Math.floor(secs / 3600);
  var m = Math.floor((secs % 3600) / 60);
  if (h > 0) return h + "小时" + (m > 0 ? m + "分钟" : "") + "后恢复";
  return m + "分钟后恢复";
}

function renderSrDailyDetail(w, h) {
  var c = T();
  var d = SR_NOTE;
  var isFull = d.current_stamina >= d.max_stamina;
  var staminaColor = isFull
    ? c.danger
    : d.current_stamina >= 200
      ? c.warning
      : c.primary;
  var maxW = Math.min(600, w - 32);

  var css =
    "<style>" +
    ".srcard{background:" +
    c.surfCard +
    ";border:1px solid " +
    c.border +
    ";border-radius:12px;padding:14px 16px;margin-bottom:8px;box-shadow:0 2px 6px " +
    c.shadow +
    "}" +
    ".sr-row{display:flex;align-items:center;justify-content:space-between;padding:7px 0;border-bottom:1px solid " +
    c.div +
    "}" +
    ".sr-row:last-child{border-bottom:none}" +
    ".sr-label{font-size:14px;color:" +
    c.txt2 +
    "}" +
    ".sr-val{font-size:14px;font-weight:600;color:" +
    c.txt +
    "}" +
    ".sr-group-label{font-size:12px;font-weight:600;color:" +
    c.txt2 +
    ";letter-spacing:.5px;margin:16px 0 6px;padding-left:2px}" +
    "</style>";

  // 开拓力（含进度条）
  var ratio = d.max_stamina > 0 ? d.current_stamina / d.max_stamina : 0;
  var recoverDesc = isFull
    ? "已全部恢复"
    : formatSeconds(d.stamina_recover_time) || "恢复中";
  var staminaSection =
    '<div style="margin-bottom:10px">' +
    '<div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px">' +
    "<div>" +
    '<div style="font-size:14px;font-weight:600;color:' +
    c.txt +
    '">开拓力</div>' +
    '<div style="font-size:12px;color:' +
    (isFull ? c.danger : c.txt2) +
    ';margin-top:2px">' +
    recoverDesc +
    "</div>" +
    "</div>" +
    '<div style="font-size:22px;font-weight:800;color:' +
    staminaColor +
    '">' +
    d.current_stamina +
    '<span style="font-size:14px;font-weight:400;color:' +
    c.txt2 +
    '">/' +
    d.max_stamina +
    "</span></div>" +
    "</div>" +
    '<div style="height:5px;background:' +
    c.border +
    ';border-radius:3px;overflow:hidden">' +
    '<div style="height:100%;width:' +
    Math.round(ratio * 100) +
    "%;background:" +
    staminaColor +
    ';border-radius:3px"></div>' +
    "</div>" +
    "</div>";

  // 第一组：日常
  var group1 =
    '<div class="srcard">' +
    staminaSection +
    '<div style="border-top:1px solid ' +
    c.div +
    ';padding-top:8px">' +
    '<div class="sr-row"><span class="sr-label">后备开拓力</span><span class="sr-val" style="color:' +
    (d.is_reserve_stamina_full ? c.danger : c.primary) +
    '">' +
    d.current_reserve_stamina +
    (d.is_reserve_stamina_full ? "（已满）" : "") +
    "</span></div>" +
    '<div class="sr-row"><span class="sr-label">委托派遣</span><span class="sr-val">' +
    d.accepted_epedition_num +
    " / " +
    d.total_expedition_num +
    "</span></div>" +
    '<div class="sr-row"><span class="sr-label">每日实训</span><span class="sr-val">' +
    d.current_train_score +
    " / " +
    d.max_train_score +
    "</span></div>" +
    '<div class="sr-row"><span class="sr-label">历战余响</span><span class="sr-val" style="color:' +
    (d.weekly_cocoon_cnt >= d.weekly_cocoon_limit ? c.primary : c.txt) +
    '">' +
    d.weekly_cocoon_cnt +
    " / " +
    d.weekly_cocoon_limit +
    "</span></div>" +
    "</div>" +
    "</div>";

  // 第二组：宇宙
  var rogueRatio =
    d.max_rogue_score > 0 ? d.current_rogue_score / d.max_rogue_score : 0;
  var rogueSection =
    '<div style="margin-bottom:10px">' +
    '<div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px">' +
    '<div style="font-size:14px;font-weight:600;color:' +
    c.txt +
    '">模拟宇宙积分</div>' +
    '<span style="font-size:14px;font-weight:600;color:' +
    c.txt +
    '">' +
    d.current_rogue_score +
    " / " +
    d.max_rogue_score +
    "</span>" +
    "</div>" +
    '<div style="height:5px;background:' +
    c.border +
    ';border-radius:3px;overflow:hidden">' +
    '<div style="height:100%;width:' +
    Math.round(rogueRatio * 100) +
    "%;background:" +
    c.primary +
    ';border-radius:3px"></div>' +
    "</div>" +
    "</div>";

  // 差分宇宙行（含 exp_is_full 提示）
  var tournRow = d.rogue_tourn_weekly_unlocked
    ? '<div class="sr-row"><span class="sr-label">差分宇宙</span>' +
      '<div style="display:flex;flex-direction:column;align-items:flex-end">' +
      '<span class="sr-val">' +
      d.rogue_tourn_weekly_cur +
      " / " +
      d.rogue_tourn_weekly_max +
      "</span>" +
      (d.rogue_tourn_exp_is_full
        ? '<span style="font-size:11px;color:' +
          c.primary +
          ';margin-top:2px">经验已满</span>'
        : "") +
      "</div></div>"
    : '<div class="sr-row"><span class="sr-label">差分宇宙</span><span class="sr-val" style="color:' +
      c.txt2 +
      '">未解锁</span></div>';

  // 黄金与机械（grid_fight）
  var gridRow =
    d.grid_fight_weekly_max > 0
      ? '<div class="sr-row"><span class="sr-label">黄金与机械</span><span class="sr-val">' +
        d.grid_fight_weekly_cur +
        " / " +
        d.grid_fight_weekly_max +
        "</span></div>"
      : '<div class="sr-row"><span class="sr-label">黄金与机械</span><span class="sr-val" style="color:' +
        c.txt2 +
        '">未解锁</span></div>';

  var group2 =
    '<div class="srcard">' +
    rogueSection +
    '<div style="border-top:1px solid ' +
    c.div +
    ';padding-top:8px">' +
    tournRow +
    gridRow +
    "</div>" +
    "</div>";

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
    '<div class="sy" style="flex:1;padding:12px 16px 40px">' +
    '<div style="max-width:' +
    maxW +
    'px;margin:0 auto">' +
    '<div style="font-size:12px;color:' +
    c.txt2 +
    ';margin-bottom:12px">数据存在约5分钟延迟</div>' +
    '<div class="sr-group-label">日常</div>' +
    group1 +
    '<div class="sr-group-label">宇宙</div>' +
    group2 +
    "</div></div></div>"
  );
}

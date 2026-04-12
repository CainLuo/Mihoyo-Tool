/**
 * zzz-daily-detail.js — 绝区零便笺详情页
 *
 * 数据来自 mock/182692936/37716744/event_game_record_zzz_api_zzz_note.json
 *
 * 分组：
 *   第一组（日常）：电量（含恢复倒计时）、活跃度
 *   第二组（商店）：录像店、刮刮卡
 *   第三组（其他）：式舆防卫战、会员卡、咖啡厅
 *
 * null 字段（bounty_commission / survey_points / coffee / weekly_task）不显示
 */

var zzzDailyDetailControls = function () {
  return [];
};

// 完整 mock 数据（与 event_game_record_zzz_api_zzz_note.json 一致）
var ZZZ_NOTE = {
  energy: {
    progress: { max: 240, current: 240 },
    restore: 0,
    day_type: 0,
    hour: 0,
    minute: 0,
  },
  vitality: { max: 400, current: 0 },
  vhs_sale: { sale_state: "SaleStateDone" },
  card_sign: "CardSignNo",
  bounty_commission: null,
  survey_points: null,
  abyss_refresh: 0,
  coffee: null,
  weekly_task: null,
  member_card: {
    is_open: false,
    member_card_state: "MemberCardStateNo",
    exp_time: "0",
  },
  is_sub: false,
  is_other_sub: false,
  temple_running: {
    expedition_state: "ExpeditionStateUnknown",
    bench_state: "BenchStateUnknown",
    shelve_state: "ShelveStateUnknown",
    level: 0,
    weekly_currency_max: "0",
    currency_next_refresh_ts: "0",
    current_currency: "0",
    auto_work: null,
  },
  cafe_state: "CafeStateNo",
};

function formatZzzSeconds(secs) {
  if (!secs || secs <= 0) return "";
  var h = Math.floor(secs / 3600);
  var m = Math.floor((secs % 3600) / 60);
  if (h > 0) return h + "小时" + (m > 0 ? m + "分钟" : "") + "后恢复";
  return m + "分钟后恢复";
}

function renderZzzDailyDetail(w, h) {
  var c = T();
  var d = ZZZ_NOTE;
  var energyCur = d.energy.progress.current;
  var energyMax = d.energy.progress.max;
  var energyFull = energyCur >= energyMax;
  var energyColor = energyFull
    ? c.danger
    : energyCur >= Math.round(energyMax * 0.8)
      ? c.warning
      : c.primary;
  var vitalityCur = d.vitality.current;
  var vitalityMax = d.vitality.max;
  var vitalityFull = vitalityCur >= vitalityMax;
  var maxW = Math.min(600, w - 32);

  var vhsMap = {
    SaleStateDone: { label: "已结算", color: c.primary },
    SaleStateDoing: { label: "营业中", color: c.warning },
    SaleStateNo: { label: "未开启", color: c.txt2 },
  };
  var vhsInfo = vhsMap[d.vhs_sale.sale_state] || {
    label: d.vhs_sale.sale_state,
    color: c.txt2,
  };

  var cardSignMap = {
    CardSignDone: { label: "已完成", color: c.primary },
    CardSignNo: { label: "未完成", color: c.txt2 },
  };
  var cardSignInfo = cardSignMap[d.card_sign] || {
    label: d.card_sign,
    color: c.txt2,
  };

  // 式舆防卫战状态
  var templeStateMap = {
    ExpeditionStateUnknown: { label: "未知", color: c.txt2 },
    ExpeditionStateRunning: { label: "进行中", color: c.warning },
    ExpeditionStateDone: { label: "已完成", color: c.primary },
    ExpeditionStateIdle: { label: "空闲", color: c.txt2 },
  };
  var templeState = templeStateMap[d.temple_running.expedition_state] || {
    label: d.temple_running.expedition_state,
    color: c.txt2,
  };

  // 会员卡状态
  var memberCardMap = {
    MemberCardStateNo: { label: "未开通", color: c.txt2 },
    MemberCardStateActive: { label: "生效中", color: c.primary },
    MemberCardStateExpired: { label: "已过期", color: c.danger },
  };
  var memberCardInfo = memberCardMap[d.member_card.member_card_state] || {
    label: d.member_card.member_card_state,
    color: c.txt2,
  };

  // 咖啡厅状态
  var cafeMap = {
    CafeStateNo: { label: "未开启", color: c.txt2 },
    CafeStateOpen: { label: "营业中", color: c.warning },
    CafeStateDone: { label: "已结算", color: c.primary },
  };
  var cafeInfo = cafeMap[d.cafe_state] || {
    label: d.cafe_state,
    color: c.txt2,
  };

  var css =
    "<style>" +
    ".zcard{background:" +
    c.surfCard +
    ";border:1px solid " +
    c.border +
    ";border-radius:12px;padding:14px 16px;margin-bottom:8px;box-shadow:0 2px 6px " +
    c.shadow +
    "}" +
    ".z-row{display:flex;align-items:center;justify-content:space-between;padding:7px 0;border-bottom:1px solid " +
    c.div +
    "}" +
    ".z-row:last-child{border-bottom:none}" +
    ".z-label{font-size:14px;color:" +
    c.txt2 +
    "}" +
    ".z-val{font-size:14px;font-weight:600;color:" +
    c.txt +
    "}" +
    ".z-group-label{font-size:12px;font-weight:600;color:" +
    c.txt2 +
    ";letter-spacing:.5px;margin:16px 0 6px;padding-left:2px}" +
    "</style>";

  // 电量（含进度条 + 恢复倒计时）
  var energyRatio = energyMax > 0 ? energyCur / energyMax : 0;
  var energyRecoverDesc = energyFull
    ? "已全部恢复"
    : formatZzzSeconds(d.energy.restore) || "恢复中";
  var energySection =
    '<div style="margin-bottom:10px">' +
    '<div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px">' +
    "<div>" +
    '<div style="font-size:14px;font-weight:600;color:' +
    c.txt +
    '">电量</div>' +
    '<div style="font-size:12px;color:' +
    (energyFull ? c.danger : c.txt2) +
    ';margin-top:2px">' +
    energyRecoverDesc +
    "</div>" +
    "</div>" +
    '<div style="font-size:22px;font-weight:800;color:' +
    energyColor +
    '">' +
    energyCur +
    '<span style="font-size:14px;font-weight:400;color:' +
    c.txt2 +
    '">/' +
    energyMax +
    "</span></div>" +
    "</div>" +
    '<div style="height:5px;background:' +
    c.border +
    ';border-radius:3px;overflow:hidden">' +
    '<div style="height:100%;width:' +
    Math.round(energyRatio * 100) +
    "%;background:" +
    energyColor +
    ';border-radius:3px"></div>' +
    "</div>" +
    "</div>";

  // 活跃度（含进度条）
  var vitalityRatio = vitalityMax > 0 ? vitalityCur / vitalityMax : 0;
  var vitalitySection =
    '<div style="border-top:1px solid ' +
    c.div +
    ';padding-top:10px">' +
    '<div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px">' +
    "<div>" +
    '<div style="font-size:14px;font-weight:600;color:' +
    c.txt +
    '">活跃度</div>' +
    '<div style="font-size:12px;color:' +
    (vitalityFull ? c.primary : c.txt2) +
    ';margin-top:2px">' +
    (vitalityFull ? "本日活跃度已完成" : "完成日常任务可获得活跃度") +
    "</div>" +
    "</div>" +
    '<div style="font-size:22px;font-weight:800;color:' +
    (vitalityFull ? c.primary : c.txt2) +
    '">' +
    vitalityCur +
    '<span style="font-size:14px;font-weight:400;color:' +
    c.txt2 +
    '">/' +
    vitalityMax +
    "</span></div>" +
    "</div>" +
    '<div style="height:5px;background:' +
    c.border +
    ';border-radius:3px;overflow:hidden">' +
    '<div style="height:100%;width:' +
    Math.round(vitalityRatio * 100) +
    "%;background:" +
    c.primary +
    ';border-radius:3px"></div>' +
    "</div>" +
    "</div>";

  // 第一组：日常
  var group1 =
    '<div class="zcard">' + energySection + vitalitySection + "</div>";

  // 第二组：商店
  var group2 =
    '<div class="zcard">' +
    '<div class="z-row"><span class="z-label">录像店</span><span class="z-val" style="color:' +
    vhsInfo.color +
    '">' +
    vhsInfo.label +
    "</span></div>" +
    '<div class="z-row"><span class="z-label">刮刮卡</span><span class="z-val" style="color:' +
    cardSignInfo.color +
    '">' +
    cardSignInfo.label +
    "</span></div>" +
    "</div>";

  // 第三组：其他（式舆防卫战 + 会员卡 + 咖啡厅）
  // 式舆防卫战：显示状态 + 当前货币（如有）
  var templeRow =
    '<div class="z-row"><span class="z-label">式舆防卫战</span>' +
    '<div style="display:flex;flex-direction:column;align-items:flex-end">' +
    '<span class="z-val" style="color:' +
    templeState.color +
    '">' +
    templeState.label +
    "</span>" +
    (parseInt(d.temple_running.current_currency) > 0
      ? '<span style="font-size:11px;color:' +
        c.txt2 +
        ';margin-top:2px">货币：' +
        d.temple_running.current_currency +
        "</span>"
      : "") +
    "</div></div>";

  // 会员卡：显示状态（is_open=false 时显示未开通）
  var memberRow =
    '<div class="z-row"><span class="z-label">会员卡</span><span class="z-val" style="color:' +
    memberCardInfo.color +
    '">' +
    memberCardInfo.label +
    "</span></div>";

  // 咖啡厅
  var cafeRow =
    '<div class="z-row"><span class="z-label">咖啡厅</span><span class="z-val" style="color:' +
    cafeInfo.color +
    '">' +
    cafeInfo.label +
    "</span></div>";

  var group3 =
    '<div class="zcard">' + templeRow + memberRow + cafeRow + "</div>";

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
    '<div class="z-group-label">日常</div>' +
    group1 +
    '<div class="z-group-label">商店</div>' +
    group2 +
    '<div class="z-group-label">其他</div>' +
    group3 +
    "</div></div></div>"
  );
}

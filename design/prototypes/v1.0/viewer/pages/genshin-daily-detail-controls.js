/**
 * genshin-daily-detail-controls.js — 原神便笺详情页控制项
 */
function genshinDailyDetailControls() {
  return [
    {
      id: "view",
      label: "状态",
      options: [
        { value: "normal", label: "正常" },
        { value: "full", label: "树脂满" },
        { value: "loading", label: "加载中" },
      ],
      current: function () {
        return dailyState.view;
      },
      onChange: function (v) {
        dailyState.view = v;
      },
    },
  ];
}

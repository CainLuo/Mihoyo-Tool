/**
 * characters-controls.js — Characters 页面控制项
 */
function charactersControls() {
  return [
    {
      id: "accountCount",
      label: "账号数量",
      options: [
        { value: "single", label: "单账号" },
        { value: "multi", label: "多账号" },
      ],
      current: function () {
        return charactersState.accountCount;
      },
      onChange: function (v) {
        charactersState.accountCount = v;
        charactersState.menuOpen = false;
        charactersState.selectedAccount = 0;
      },
    },
    {
      id: "game",
      label: "游戏",
      options: [
        { value: "genshin", label: "原神" },
        { value: "starrail", label: "崩坏：星穹铁道" },
        { value: "zzz", label: "绝区零" },
      ],
      current: function () {
        return charactersState.game;
      },
      onChange: function (v) {
        charactersState.game = v;
      },
    },
    {
      id: "imgRatio",
      label: "图片比例",
      options: [
        { value: "crop", label: "1:1 裁切" },
        { value: "native", label: "原始比例" },
      ],
      current: function () {
        return charactersState.imgRatio;
      },
      onChange: function (v) {
        charactersState.imgRatio = v;
      },
    },
    {
      id: "view",
      label: "视图",
      options: [
        { value: "data", label: "有数据" },
        { value: "empty", label: "空状态" },
        { value: "loading", label: "加载中" },
      ],
      current: function () {
        return charactersState.view;
      },
      onChange: function (v) {
        charactersState.view = v;
      },
    },
  ];
}

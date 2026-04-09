/**
 * home-controls.js — Home 页面控制项
 * 与 home.js 配合使用，单独拆出避免 home.js 过大
 */
function homeControls() {
  return [
    {
      id: "view",
      label: "视图",
      options: [
        { value: "data", label: "有数据" },
        { value: "empty", label: "空状态" },
        { value: "loading", label: "加载中" },
      ],
      current: function () {
        return homeState.view;
      },
      onChange: function (v) {
        homeState.view = v;
      },
    },
  ];
}

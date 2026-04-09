/**
 * login-controls.js — Login 页面控制项
 */
function loginControls() {
  return [
    {
      id: "tab",
      label: "登录方式",
      options: [
        { value: "phone", label: "手机号" },
        { value: "qrcode", label: "二维码" },
        { value: "cookie", label: "Cookie" },
      ],
      current: function () {
        return loginState.tab;
      },
      onChange: function (v) {
        loginState.tab = v;
      },
    },
    {
      id: "phoneStep",
      label: "手机步骤",
      options: [
        { value: "phone", label: "输入手机" },
        { value: "code", label: "输入验证码" },
      ],
      current: function () {
        return loginState.phoneStep;
      },
      onChange: function (v) {
        loginState.phoneStep = v;
      },
    },
    {
      id: "qr",
      label: "二维码状态",
      options: [
        { value: "loading", label: "加载中" },
        { value: "ready", label: "就绪" },
        { value: "scanned", label: "已扫码" },
        { value: "expired", label: "已过期" },
      ],
      current: function () {
        return loginState.qr;
      },
      onChange: function (v) {
        loginState.qr = v;
      },
    },
  ];
}

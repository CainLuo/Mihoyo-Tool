/**
 * login.js — 登录页渲染逻辑
 */
var loginState = { tab: "phone", phoneStep: "phone", qr: "ready" };

function renderLogin(w, h) {
  var c = T();
  var isWide = w > 480;

  var css =
    "<style>" +
    ".lcard{background:" +
    c.surfCard +
    ";border:1px solid " +
    c.border +
    ";border-radius:12px;padding:20px;box-shadow:0 2px 8px " +
    c.shadow +
    "}" +
    ".ltab{display:flex;gap:3px;background:" +
    (G.theme === "dark" ? "rgba(255,255,255,.04)" : "rgba(0,0,0,.04)") +
    ";border-radius:8px;padding:3px;margin-bottom:18px}" +
    ".lti{flex:1;text-align:center;padding:6px 0;border-radius:6px;font-size:13px;cursor:pointer;color:" +
    c.txt2 +
    ";border:1px solid transparent}" +
    ".lti.on{background:" +
    c.primary +
    ";color:#fff;font-weight:600}" +
    ".lif{width:100%;height:46px;background:" +
    c.inputBg +
    ";border:1px solid " +
    c.inputBd +
    ";border-radius:8px;padding:0 12px;font-size:14px;color:" +
    c.txt +
    ";outline:none}" +
    ".lta{width:100%;height:108px;background:" +
    c.inputBg +
    ";border:1px solid " +
    c.inputBd +
    ";border-radius:8px;padding:10px 12px;font-size:13px;color:" +
    c.txt +
    ";outline:none;resize:none}" +
    ".lbp{width:100%;height:46px;background:" +
    c.primary +
    ";border:none;border-radius:8px;color:#fff;font-size:15px;font-weight:600;cursor:pointer}" +
    "@keyframes spin{to{transform:rotate(360deg)}}" +
    "@keyframes scan{0%{top:6px}100%{top:calc(100% - 6px)}}" +
    "</style>";

  function tabs() {
    var t = [
      ["phone", "手机号"],
      ["qrcode", "二维码"],
      ["cookie", "Cookie"],
    ];
    var h = '<div class="ltab">';
    for (var i = 0; i < t.length; i++) {
      h +=
        '<div class="lti' +
        (loginState.tab === t[i][0] ? " on" : "") +
        '">' +
        t[i][1] +
        "</div>";
    }
    return h + "</div>";
  }

  function phoneContent() {
    if (loginState.phoneStep === "phone") {
      return (
        '<div style="display:flex;flex-direction:column;gap:6px;margin-bottom:12px">' +
        '<div style="font-size:12px;color:' +
        c.txt2 +
        '">手机号</div>' +
        '<input class="lif" type="tel" placeholder="请输入手机号">' +
        '</div><button class="lbp">获取验证码</button>' +
        '<div style="font-size:12px;color:' +
        c.txt2 +
        ';text-align:center;margin-top:10px">仅支持中国大陆手机号</div>'
      );
    }
    return (
      '<div style="text-align:center;margin-bottom:12px">' +
      '<div style="font-size:12px;color:' +
      c.txt2 +
      '">验证码已发送至</div>' +
      '<div style="font-size:15px;font-weight:600;margin-top:4px;color:' +
      c.txt +
      '">138****8888</div></div>' +
      '<div style="display:flex;flex-direction:column;gap:6px;margin-bottom:12px">' +
      '<div style="font-size:12px;color:' +
      c.txt2 +
      '">验证码</div>' +
      '<input class="lif" type="number" placeholder="请输入 6 位验证码">' +
      '</div><button class="lbp">登录</button>' +
      '<div style="display:flex;justify-content:space-between;margin-top:10px">' +
      '<span style="font-size:12px;color:' +
      c.primary +
      ';cursor:pointer">← 重新输入手机号</span>' +
      '<span style="font-size:12px;color:' +
      c.txt2 +
      '">重新发送 45s</span></div>'
    );
  }

  function qrContent() {
    var sz = Math.min(160, w - 80);
    var qrPat = [
      [1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1],
      [1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1],
      [1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1],
      [1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1],
      [1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1],
      [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0],
      [1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1],
    ];
    var qrHtml =
      '<div style="display:grid;grid-template-columns:repeat(17,1fr);gap:1px;padding:8px;background:#fff;width:' +
      sz +
      "px;height:" +
      sz +
      'px">';
    for (var r = 0; r < 7; r++)
      for (var cc = 0; cc < 17; cc++) {
        var on =
          cc < 7
            ? qrPat[r][cc]
            : cc > 9
              ? qrPat[r][cc - 10]
              : Math.random() > 0.5
                ? 1
                : 0;
        qrHtml +=
          '<div style="background:' +
          (on ? "#000" : "#fff") +
          ';border-radius:1px"></div>';
      }
    for (var r = 7; r < 17; r++)
      for (var cc = 0; cc < 17; cc++) {
        qrHtml +=
          '<div style="background:' +
          (Math.random() > 0.5 ? "#000" : "#fff") +
          ';border-radius:1px"></div>';
      }
    qrHtml += "</div>";

    if (loginState.qr === "loading") {
      return (
        '<div style="display:flex;flex-direction:column;align-items:center;gap:12px">' +
        '<div style="width:' +
        sz +
        "px;height:" +
        sz +
        "px;background:" +
        c.inputBg +
        ';border-radius:8px;display:flex;align-items:center;justify-content:center">' +
        '<div style="width:30px;height:30px;border-radius:50%;border:3px solid rgba(' +
        c.priRgb +
        ",.2);border-top-color:" +
        c.primary +
        ';animation:spin .8s linear infinite"></div>' +
        '</div><div style="font-size:12px;color:' +
        c.txt2 +
        '">正在生成二维码…</div></div>'
      );
    }
    if (loginState.qr === "ready") {
      return (
        '<div style="display:flex;flex-direction:column;align-items:center;gap:12px">' +
        '<div style="position:relative;border-radius:8px;overflow:hidden;border:2px solid ' +
        c.border +
        '">' +
        qrHtml +
        '<div style="position:absolute;left:6px;right:6px;height:2px;background:linear-gradient(90deg,transparent,' +
        c.cyan +
        ",transparent);animation:scan 2s ease-in-out infinite alternate;box-shadow:0 0 6px " +
        c.cyan +
        '"></div>' +
        '</div><div style="font-size:12px;color:' +
        c.txt2 +
        ';text-align:center">使用 App 扫码登录<br>二维码有效期 3 分钟</div></div>'
      );
    }
    var mask = G.theme === "dark" ? "rgba(0,0,0,.85)" : "rgba(255,255,255,.85)";
    if (loginState.qr === "scanned") {
      return (
        '<div style="display:flex;flex-direction:column;align-items:center;gap:12px">' +
        '<div style="position:relative;border-radius:8px;overflow:hidden;border:2px solid ' +
        c.border +
        '">' +
        qrHtml +
        '<div style="position:absolute;inset:0;background:' +
        mask +
        ';display:flex;flex-direction:column;align-items:center;justify-content:center;gap:8px">' +
        '<div style="font-size:26px">✅</div>' +
        '<div style="background:' +
        c.okBg +
        ";border:1px solid " +
        c.ok +
        ";border-radius:16px;padding:3px 12px;font-size:12px;color:" +
        c.ok +
        ';font-weight:600">已扫码</div>' +
        '<div style="font-size:12px;color:' +
        c.txt2 +
        '">请在手机上确认登录</div>' +
        "</div></div></div>"
      );
    }
    return (
      '<div style="display:flex;flex-direction:column;align-items:center;gap:12px">' +
      '<div style="position:relative;border-radius:8px;overflow:hidden;border:2px solid ' +
      c.border +
      '">' +
      qrHtml +
      '<div style="position:absolute;inset:0;background:' +
      mask +
      ';display:flex;flex-direction:column;align-items:center;justify-content:center;gap:8px">' +
      '<div style="font-size:22px">⏱</div>' +
      '<div style="font-size:13px;color:' +
      c.txt2 +
      '">二维码已过期</div>' +
      '<button style="padding:6px 14px;background:' +
      c.priBg +
      ";border:1px solid rgba(" +
      c.priRgb +
      ",.3);border-radius:8px;color:" +
      c.primary +
      ';font-size:13px;cursor:pointer">刷新二维码</button>' +
      "</div></div></div>"
    );
  }

  function cookieContent() {
    return (
      '<div style="font-size:12px;color:' +
      c.txt2 +
      ';text-align:center;margin-bottom:12px">在浏览器登录账号后，从开发者工具中复制 Cookie 粘贴到下方</div>' +
      '<div style="display:flex;flex-direction:column;gap:6px;margin-bottom:12px">' +
      '<div style="font-size:12px;color:' +
      c.txt2 +
      '">Cookie</div>' +
      '<textarea class="lta" placeholder="account_id=xxx; cookie_token=xxx; ..."></textarea>' +
      '</div><button class="lbp">确认登录</button>' +
      '<div style="font-size:12px;color:' +
      c.txt2 +
      ';text-align:center;margin-top:10px">Cookie 仅存储在本地设备，不会上传至任何服务器</div>'
    );
  }

  function tabContent() {
    if (loginState.tab === "phone") return phoneContent();
    if (loginState.tab === "qrcode") return qrContent();
    return cookieContent();
  }

  var footer =
    '<div style="margin-top:14px;text-align:center;font-size:12px;color:' +
    c.txt2 +
    '">登录即表示您同意 <span style="color:' +
    c.primary +
    ';cursor:pointer">用户协议</span> 与 <span style="color:' +
    c.primary +
    ';cursor:pointer">隐私政策</span></div>';

  var cardContent = tabs() + tabContent() + footer;

  var body = "";
  if (isWide) {
    body =
      '<div style="flex:1;display:flex;align-items:center;justify-content:center;gap:48px;padding:40px;overflow-y:auto">' +
      '<div style="flex:1;max-width:280px;display:flex;flex-direction:column;gap:14px">' +
      logoSVG(56) +
      '<div style="font-size:24px;font-weight:700;color:' +
      c.txt +
      ';margin-top:8px">米悠悠</div>' +
      '<div style="font-size:13px;color:' +
      c.txt2 +
      ';line-height:1.7">多款游戏数据一站式查看<br>角色 · 便笺</div>' +
      "</div>" +
      '<div style="flex:1;max-width:360px"><div class="lcard"><div style="font-size:17px;font-weight:600;margin-bottom:16px;color:' +
      c.txt +
      '">登录账号</div>' +
      cardContent +
      "</div></div>" +
      "</div>";
  } else {
    body =
      '<div class="sy" style="flex:1;padding:28px 20px 40px;display:flex;flex-direction:column;align-items:center">' +
      '<div style="display:flex;flex-direction:column;align-items:center;gap:8px;margin-bottom:24px">' +
      logoSVG(52) +
      '<div style="font-size:20px;font-weight:700;color:' +
      c.txt +
      '">米悠悠</div>' +
      '<div style="font-size:12px;color:' +
      c.txt2 +
      '">游戏数据助手</div>' +
      "</div>" +
      '<div class="lcard" style="width:100%;max-width:360px">' +
      cardContent +
      "</div>" +
      "</div>";
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
    body +
    "</div>"
  );
}

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

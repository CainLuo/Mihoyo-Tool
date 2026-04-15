var PAGES = {
  launch: { render: renderLaunch, controls: launchControls },
  home: { render: renderHome, controls: homeControls },
  characters: { render: renderCharacters, controls: charactersControls },
  my: { render: renderMy, controls: myControls },
  login: { render: renderLogin, controls: loginControls },
  "genshin-daily-detail": {
    render: renderGenshinDailyDetail,
    controls: genshinDailyDetailControls,
  },
  "starrail-daily-detail": {
    render: renderSrDailyDetail,
    controls: srDailyDetailControls,
  },
  "zzz-daily-detail": {
    render: renderZzzDailyDetail,
    controls: zzzDailyDetailControls,
  },
  "char-detail": { render: renderCharDetail, controls: charDetailControls },
  "starrail-char-detail": {
    render: renderSrCharDetail,
    controls: srCharDetailControls,
  },
  "zzz-char-detail": {
    render: renderZzzCharDetail,
    controls: zzzCharDetailControls,
  },
  "account-detail": {
    render: renderAccountDetail,
    controls: accountDetailControls,
  },
  "tab-icons-demo": {
    render: renderTabIconsDemo,
    controls: tabIconsDemoControls,
  },
  "color-design": {
    render: renderColorDesign,
    controls: colorDesignControls,
  },
};

var curPage = "launch";

function renderPageBar() {
  var pb = document.getElementById("pagebar");
  var page = PAGES[curPage];
  if (!page) {
    pb.innerHTML = "";
    pb.className = "empty";
    return;
  }
  var controls = page.controls();
  if (!controls || !controls.length) {
    pb.innerHTML = "";
    pb.className = "empty";
    return;
  }
  pb.className = "";
  var html = "";
  for (var i = 0; i < controls.length; i++) {
    var ctrl = controls[i];
    if (i > 0) html += '<div class="sep"></div>';
    html += '<span class="lbl">' + ctrl.label + "：</span>";
    for (var j = 0; j < ctrl.options.length; j++) {
      var opt = ctrl.options[j];
      html +=
        '<button class="btn' +
        (ctrl.current() === opt.value ? " on" : "") +
        '" onclick="onCtrl(\'' +
        ctrl.id +
        "','" +
        opt.value +
        "')\">" +
        opt.label +
        "</button>";
    }
  }
  pb.innerHTML = html;
}

function onCtrl(ctrlId, val) {
  var page = PAGES[curPage];
  if (!page) return;
  var controls = page.controls();
  for (var i = 0; i < controls.length; i++) {
    if (controls[i].id === ctrlId) {
      controls[i].onChange(val);
      break;
    }
  }
  refresh();
}

function refresh() {
  var d = D();
  var s = document.getElementById("S");
  s.style.width = d.w + "px";
  s.style.height = d.h + "px";
  var page = PAGES[curPage];
  if (page) {
    try {
      s.innerHTML = page.render(d.w, d.h);
    } catch (e) {
      s.innerHTML =
        '<div style="padding:20px;color:#ff6b6b;font-size:12px">渲染错误：' +
        e.message +
        "</div>";
    }
  }
  renderPageBar();
}

function setDev(dev) {
  G.dev = dev;
  var keys = Object.keys(DEVS);
  for (var i = 0; i < keys.length; i++) {
    var b = document.getElementById("d-" + keys[i]);
    if (b) b.classList.toggle("on", keys[i] === dev);
  }
  refresh();
}

function setTheme(theme) {
  G.theme = theme;
  document.getElementById("t-dark").classList.toggle("on", theme === "dark");
  document.getElementById("t-light").classList.toggle("on", theme === "light");
  refresh();
}

function setPage(page) {
  curPage = page;
  var items = document.querySelectorAll(".nav-item");
  for (var i = 0; i < items.length; i++) {
    items[i].classList.toggle("on", items[i].id === "nav-" + page);
  }
  refresh();
}

// Launch 页渲染
function renderLaunch(w, h) {
  var c = T();
  var isLandscape = w > h * 1.1;
  var logoSz = Math.max(
    80,
    isLandscape ? Math.min(h * 0.42, 180) : Math.min(w * 0.38, 155),
  );
  var nameSize = Math.max(
    18,
    isLandscape ? Math.min(w * 0.024, 30) : Math.min(w * 0.068, 26),
  );
  var subSize = Math.max(10, nameSize * 0.5);
  var textAlign = isLandscape ? "flex-start" : "center";
  var verColor = G.theme === "dark" ? "#2a3a4a" : "#AAAAAA";
  var gameTags =
    '<div style="display:flex;gap:5px;margin-top:2px;flex-wrap:wrap;justify-content:' +
    textAlign +
    '">' +
    '<span style="font-size:10px;padding:2px 8px;border-radius:10px;background:rgba(91,163,232,.15);border:1px solid rgba(91,163,232,.35);color:' +
    c.genshin +
    '">原神</span>' +
    '<span style="font-size:10px;padding:2px 8px;border-radius:10px;background:rgba(155,142,255,.15);border:1px solid rgba(155,142,255,.35);color:' +
    c.starrail +
    '">星穹铁道</span>' +
    '<span style="font-size:10px;padding:2px 8px;border-radius:10px;background:rgba(247,184,75,.15);border:1px solid rgba(247,184,75,.35);color:' +
    c.zzz +
    '">绝区零</span>' +
    "</div>";
  var textBlock =
    '<div style="display:flex;flex-direction:column;align-items:' +
    textAlign +
    ";gap:8px;" +
    (isLandscape ? "margin-left:28px" : "margin-top:20px") +
    '">' +
    '<div style="font-size:' +
    nameSize +
    "px;font-weight:800;letter-spacing:4px;background:linear-gradient(135deg," +
    c.primary +
    "," +
    c.cyan +
    ');-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text">米悠悠</div>' +
    '<div style="font-size:' +
    subSize +
    "px;letter-spacing:4px;color:" +
    c.primary +
    ';font-weight:300;opacity:.8">游戏数据助手</div>' +
    gameTags +
    (isLandscape
      ? '<div style="font-size:11px;color:' +
        verColor +
        ';letter-spacing:2px">v1.0.0</div>'
      : "") +
    "</div>";
  var loadBar = isLandscape
    ? ""
    : '<div style="position:absolute;bottom:48px;left:50%;transform:translateX(-50%);display:flex;flex-direction:column;align-items:center;gap:10px">' +
      '<div style="width:80px;height:1px;background:rgba(255,255,255,.05);overflow:hidden;border-radius:1px"><div style="height:100%;background:linear-gradient(90deg,' +
      c.primary +
      "," +
      c.cyan +
      ');animation:ld 2.2s ease-in-out infinite"></div></div>' +
      '<div style="font-size:10px;color:' +
      verColor +
      ';letter-spacing:2px">v1.0.0</div></div>';
  var bgGrad =
    G.theme === "dark"
      ? "radial-gradient(ellipse at 50% 35%," +
        c.bgLight +
        " 0%," +
        c.bgDark +
        " 45%," +
        c.bgDeep +
        " 100%)"
      : "radial-gradient(ellipse at 50% 35%," +
        c.bgLight +
        " 0%," +
        c.bgDark +
        " 55%," +
        c.pageBg +
        " 100%)";
  return (
    "<style>*{box-sizing:border-box;margin:0;padding:0}body{width:" +
    w +
    "px;height:" +
    h +
    "px;overflow:hidden;background:" +
    c.pageBg +
    ';font-family:"PingFang SC",sans-serif}' +
    "@keyframes ld{0%{width:0;margin-left:0}60%{width:60px;margin-left:0}100%{width:0;margin-left:80px}}" +
    "@keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-7px)}}</style>" +
    '<div style="width:' +
    w +
    "px;height:" +
    h +
    "px;position:relative;background:" +
    bgGrad +
    ';display:flex;align-items:center;justify-content:center">' +
    '<div style="display:flex;flex-direction:' +
    (isLandscape ? "row" : "column") +
    ';align-items:center;justify-content:center;animation:float 4.5s ease-in-out infinite;position:relative;z-index:1">' +
    logoSVG(logoSz) +
    textBlock +
    "</div>" +
    loadBar +
    "</div>"
  );
}
function launchControls() {
  return [];
}

refresh();

/**
 * index-logic.js — 路由和控制逻辑
 * 
 * 遵循 v1.0 框架规范：
 * - PAGES 对象注册所有页面
 * - renderPageBar() 渲染控制栏
 * - refresh() 刷新预览
 * - setDev/setTheme/setPage 切换设备/主题/页面
 */

var PAGES = {
  "tools": {
    render: renderTools,
    controls: toolsControls,
  },
  "char-detail-entry": {
    render: renderCharacterDetailEntry,
    controls: characterDetailEntryControls,
  },

  "material-calc": {
    render: renderMaterialCalc,
    controls: materialCalcControls,
  },
  "material-list": {
    render: renderMaterialList,
    controls: materialListControls,
  },
};

var curPage = "tools";

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

refresh();

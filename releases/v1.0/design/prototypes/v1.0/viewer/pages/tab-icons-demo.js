/**
 * tab-icons-demo.js — Tab 图标规范（正式版）
 * 已确认图标：house / person / gearshape（sys.symbol.*）
 * 选中色：colorPrimary，未选中色：colorTextSecondary
 */

var tabIconsDemoState = {
  activeTab: 'home',
};

function switchDemoTab(tab) {
  tabIconsDemoState.activeTab = tab;
  refresh();
}

function renderTabIconsDemo(w, h) {
  var c = T();
  var active = tabIconsDemoState.activeTab;
  var isWide = w >= 600;

  // ── SVG 图标（与 sys.symbol.* 形状对齐）──────────────────────

  function iconHome(sel) {
    var col = sel ? c.primary : c.txt2;
    return (
      '<svg width="24" height="24" viewBox="0 0 24 24" fill="none">' +
      '<path d="M3 9.5L12 3L21 9.5V20C21 20.5523 20.5523 21 20 21H15V15H9V21H4C3.44772 21 3 20.5523 3 20V9.5Z"' +
      ' stroke="' + col + '" stroke-width="1.8" stroke-linejoin="round"/>' +
      '<path d="M9 21V15H15V21" stroke="' + col + '" stroke-width="1.8" stroke-linejoin="round"/>' +
      '</svg>'
    );
  }

  function iconPerson(sel) {
    var col = sel ? c.primary : c.txt2;
    return (
      '<svg width="24" height="24" viewBox="0 0 24 24" fill="none">' +
      '<circle cx="12" cy="7.5" r="3.5" stroke="' + col + '" stroke-width="1.8"/>' +
      '<path d="M4 20C4 16.134 7.58172 13 12 13C16.4183 13 20 16.134 20 20"' +
      ' stroke="' + col + '" stroke-width="1.8" stroke-linecap="round"/>' +
      '</svg>'
    );
  }

  function iconGear(sel) {
    var col = sel ? c.primary : c.txt2;
    // 标准齿轮：外齿 + 中心圆
    var path = 'M12 15.5A3.5 3.5 0 0 1 8.5 12 3.5 3.5 0 0 1 12 8.5 3.5 3.5 0 0 1 15.5 12 3.5 3.5 0 0 1 12 15.5M19.43 12.97C19.47 12.65 19.5 12.33 19.5 12C19.5 11.67 19.47 11.34 19.43 11L21.54 9.37C21.73 9.22 21.78 8.95 21.66 8.73L19.66 5.27C19.54 5.05 19.27 4.96 19.05 5.05L16.56 6.05C16.04 5.66 15.5 5.32 14.87 5.07L14.5 2.42C14.46 2.18 14.25 2 14 2H10C9.75 2 9.54 2.18 9.5 2.42L9.13 5.07C8.5 5.32 7.96 5.66 7.44 6.05L4.95 5.05C4.73 4.96 4.46 5.05 4.34 5.27L2.34 8.73C2.21 8.95 2.27 9.22 2.46 9.37L4.57 11C4.53 11.34 4.5 11.67 4.5 12C4.5 12.33 4.53 12.65 4.57 13L2.46 14.63C2.27 14.78 2.21 15.05 2.34 15.27L4.34 18.73C4.46 18.95 4.73 19.03 4.95 18.95L7.44 17.94C7.96 18.34 8.5 18.68 9.13 18.93L9.5 21.58C9.54 21.82 9.75 22 10 22H14C14.25 22 14.46 21.82 14.5 21.58L14.87 18.93C15.5 18.67 16.04 18.34 16.56 17.94L19.05 18.95C19.27 19.03 19.54 18.95 19.66 18.73L21.66 15.27C21.78 15.05 21.73 14.78 21.54 14.63L19.43 12.97Z';
    return (
      '<svg width="24" height="24" viewBox="0 0 24 24" fill="none">' +
      '<path d="' + path + '" stroke="' + col + '" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>' +
      '</svg>'
    );
  }

  var tabs = [
    { id: 'home',       label: '首页', icon: iconHome },
    { id: 'characters', label: '角色', icon: iconPerson },
    { id: 'settings',   label: '我的', icon: iconGear },
  ];

  // ── 内容区 ────────────────────────────────────────────────────

  function renderContent() {
    var pad = isWide ? 24 : 16;

    if (active === 'home') {
      return (
        '<div style="padding:' + pad + 'px;display:flex;flex-direction:column;gap:12px">' +
        '<div style="font-size:18px;font-weight:700;color:' + c.txt + ';margin-bottom:4px">首页</div>' +
        '<div style="font-size:13px;color:' + c.txt2 + ';line-height:1.6">展示游戏数据概览，包括树脂、开拓力、电量等实时便笺信息。</div>' +
        renderDemoCard(c, '原神', c.genshin, '🌿', '树脂 140/200', '派遣 4/5 · 委托 4/4') +
        renderDemoCard(c, '星穹铁道', c.starrail, '🚂', '开拓力 180/300', '实训 400/500 · 模拟宇宙') +
        renderDemoCard(c, '绝区零', c.zzz, '⚡', '电量 180/240', '活跃度 300/400') +
        '</div>'
      );
    }
    if (active === 'characters') {
      return (
        '<div style="padding:' + pad + 'px;display:flex;flex-direction:column;gap:12px">' +
        '<div style="font-size:18px;font-weight:700;color:' + c.txt + ';margin-bottom:4px">角色</div>' +
        '<div style="font-size:13px;color:' + c.txt2 + ';line-height:1.6">展示已拥有的游戏角色，支持多账号、多游戏切换。</div>' +
        '<div style="display:grid;grid-template-columns:repeat(' + (isWide ? 5 : 3) + ',1fr);gap:8px">' +
        renderCharCard(c, '纳西妲', 5, c.dendro) +
        renderCharCard(c, '胡桃', 5, c.pyro) +
        renderCharCard(c, '雷电将军', 5, c.electro) +
        renderCharCard(c, '夜兰', 5, c.hydro) +
        renderCharCard(c, '行秋', 4, c.hydro) +
        renderCharCard(c, '香菱', 4, c.pyro) +
        '</div></div>'
      );
    }
    if (active === 'settings') {
      return (
        '<div style="padding:' + pad + 'px;display:flex;flex-direction:column;gap:8px">' +
        '<div style="font-size:18px;font-weight:700;color:' + c.txt + ';margin-bottom:4px">我的</div>' +
        renderSettingSection(c, '账号管理', [
          { label: '已登录账号', value: '2 个' },
          { label: '添加账号', value: '→' },
        ]) +
        renderSettingSection(c, '外观设置', [
          { label: '主题模式', value: '跟随系统' },
        ]) +
        renderSettingSection(c, '关于', [
          { label: '版本', value: 'v1.0.0' },
          { label: 'GitHub', value: '→' },
          { label: '开源许可', value: '→' },
        ]) +
        '</div>'
      );
    }
    return '';
  }

  // ── 辅助渲染 ──────────────────────────────────────────────────

  function renderDemoCard(c, title, accentColor, emoji, line1, line2) {
    return (
      '<div style="background:' + c.surfCard + ';border-radius:12px;padding:14px 16px;border:1px solid ' + c.border + ';margin-bottom:0">' +
      '<div style="display:flex;align-items:center;gap:8px;margin-bottom:8px">' +
      '<span style="font-size:15px">' + emoji + '</span>' +
      '<span style="font-size:14px;font-weight:600;color:' + accentColor + '">' + title + '</span>' +
      '</div>' +
      '<div style="font-size:13px;color:' + c.txt + ';margin-bottom:3px">' + line1 + '</div>' +
      '<div style="font-size:12px;color:' + c.txt2 + '">' + line2 + '</div>' +
      '</div>'
    );
  }

  function renderCharCard(c, name, rarity, elemColor) {
    var bg = rarity === 5
      ? 'linear-gradient(135deg,#3d2a0a,#5c3d10)'
      : 'linear-gradient(135deg,#1a1a3a,#2a2a4a)';
    return (
      '<div style="border-radius:10px;background:' + bg + ';border:1px solid ' + c.border + ';aspect-ratio:3/4;display:flex;flex-direction:column;align-items:center;justify-content:flex-end;padding:6px;position:relative">' +
      '<div style="position:absolute;top:5px;right:5px;font-size:10px;color:' + (rarity === 5 ? c.gold : c.starrail) + ';font-weight:700">' + rarity + '★</div>' +
      '<div style="font-size:11px;color:' + c.txt + ';text-align:center;font-weight:600">' + name + '</div>' +
      '</div>'
    );
  }

  function renderSettingSection(c, title, items) {
    var rows = '';
    for (var i = 0; i < items.length; i++) {
      var item = items[i];
      rows +=
        '<div style="display:flex;align-items:center;justify-content:space-between;padding:12px 16px;' +
        (i < items.length - 1 ? 'border-bottom:1px solid ' + c.border + ';' : '') + '">' +
        '<span style="font-size:14px;color:' + c.txt + '">' + item.label + '</span>' +
        '<span style="font-size:13px;color:' + c.txt2 + '">' + item.value + '</span>' +
        '</div>';
    }
    return (
      '<div style="margin-bottom:8px">' +
      '<div style="font-size:11px;color:' + c.txt2 + ';padding:0 4px 6px;letter-spacing:1px;text-transform:uppercase">' + title + '</div>' +
      '<div style="background:' + c.surfCard + ';border-radius:12px;border:1px solid ' + c.border + ';overflow:hidden">' + rows + '</div>' +
      '</div>'
    );
  }

  // ── 底部 Tab 栏 ───────────────────────────────────────────────

  function renderTabBar() {
    var html =
      '<div style="height:64px;flex-shrink:0;display:flex;flex-direction:column;background:' + c.navBg + ';border-top:1px solid ' + c.border + '">' +
      '<div style="height:56px;display:flex">';
    for (var i = 0; i < tabs.length; i++) {
      var tab = tabs[i];
      var sel = tab.id === active;
      var col = sel ? c.primary : c.txt2;
      html +=
        '<div onclick="switchDemoTab(\'' + tab.id + '\')" ' +
        'style="flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:3px;cursor:pointer">' +
        tab.icon(sel) +
        '<span style="font-size:10px;color:' + col + ';font-weight:' + (sel ? '600' : '400') + '">' + tab.label + '</span>' +
        '</div>';
    }
    html += '</div><div style="height:8px"></div></div>';
    return html;
  }

  // ── 宽屏侧边栏 ────────────────────────────────────────────────

  function renderSidebar() {
    var html =
      '<div style="width:72px;flex-shrink:0;background:' + c.navBg + ';border-right:1px solid ' + c.border + ';display:flex;flex-direction:column;align-items:center;padding:16px 0;gap:4px">';
    for (var i = 0; i < tabs.length; i++) {
      var tab = tabs[i];
      var sel = tab.id === active;
      var col = sel ? c.primary : c.txt2;
      html +=
        '<div onclick="switchDemoTab(\'' + tab.id + '\')" ' +
        'style="width:56px;padding:10px 0;border-radius:12px;display:flex;flex-direction:column;align-items:center;gap:4px;cursor:pointer;' +
        'background:' + (sel ? 'rgba(' + c.priRgb + ',0.12)' : 'transparent') + '">' +
        tab.icon(sel) +
        '<span style="font-size:10px;color:' + col + ';font-weight:' + (sel ? '600' : '400') + '">' + tab.label + '</span>' +
        '</div>';
    }
    html += '</div>';
    return html;
  }

  // ── 主布局 ────────────────────────────────────────────────────

  if (isWide) {
    return (
      baseCss(w, h) +
      '<div style="width:' + w + 'px;height:' + h + 'px;display:flex;overflow:hidden;background:' + c.pageBg + '">' +
      renderSidebar() +
      '<div style="flex:1;display:flex;flex-direction:column;overflow:hidden">' +
      '<div class="sy" style="flex:1;overflow-y:auto">' + renderContent() + '</div>' +
      '</div>' +
      '</div>'
    );
  } else {
    return (
      baseCss(w, h) +
      '<div style="width:' + w + 'px;height:' + h + 'px;display:flex;flex-direction:column;overflow:hidden;background:' + c.pageBg + '">' +
      '<div class="sy" style="flex:1;overflow-y:auto">' + renderContent() + '</div>' +
      renderTabBar() +
      '</div>'
    );
  }
}

function tabIconsDemoControls() {
  return [
    {
      id: 'tab',
      label: '当前 Tab',
      current: function() { return tabIconsDemoState.activeTab; },
      options: [
        { label: '首页', value: 'home' },
        { label: '角色', value: 'characters' },
        { label: '我的', value: 'settings' },
      ],
      onChange: function(v) { tabIconsDemoState.activeTab = v; },
    },
  ];
}

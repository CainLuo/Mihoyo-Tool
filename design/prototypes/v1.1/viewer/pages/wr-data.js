/**
 * wr-data.js — Widget 重设计原型：共享数据和工具函数
 */

var WR = {
  state: { size: "2x2", game: "genshin" },

  colors: { genshin: "#5ba3e8", starrail: "#9b8eff", zzz: "#f7b84b" },
  names: { genshin: "原神", starrail: "星穹铁道", zzz: "绝区零" },

  stamina: {
    genshin: { cur: 140, max: 200, rec: "4小时后回满" },
    starrail: { cur: 200, max: 300, rec: "6小时后回满" },
    zzz: { cur: 180, max: 240, rec: "3小时后回满" },
  },

  extra: {
    genshin: [
      { label: "探索派遣", val: "4/5", color: "rgba(155,142,255,.9)" },
      { label: "洞天财瓮", val: "1800/2400", color: "rgba(255,202,40,.9)" },
      { label: "每日委托", val: "4/4 已领取", color: "rgba(52,211,153,.9)" },
      { label: "参量质变仪", val: "可使用", color: "rgba(79,195,247,.9)" },
    ],
    starrail: [
      { label: "后备开拓力", val: "2400", color: "rgba(155,142,255,.9)" },
      { label: "每日实训", val: "400/500", color: "rgba(255,202,40,.9)" },
      { label: "历战余响", val: "2/3", color: "rgba(79,195,247,.9)" },
      { label: "货币战争", val: "800/1000", color: "rgba(247,184,75,.9)" },
      { label: "模拟宇宙", val: "900/1000", color: "rgba(52,211,153,.9)" },
    ],
    zzz: [
      { label: "今日活跃度", val: "300/400", color: "rgba(247,184,75,.9)" },
      { label: "刮刮卡", val: "已完成", color: "rgba(52,211,153,.9)" },
      { label: "录像店", val: "营业中", color: "rgba(79,195,247,.9)" },
    ],
  },

  // SVG 体力环（无中心数值）
  ring: function (ratio, color, size, stroke) {
    stroke = stroke || 5;
    var r = size / 2 - stroke / 2 - 1;
    var cx = size / 2,
      cy = size / 2;
    var circ = 2 * Math.PI * r;
    var dash = (circ * Math.min(ratio, 1)).toFixed(1);
    var gap = (circ - circ * Math.min(ratio, 1)).toFixed(1);
    return (
      '<svg width="' +
      size +
      '" height="' +
      size +
      '" viewBox="0 0 ' +
      size +
      " " +
      size +
      '" style="display:block;flex-shrink:0">' +
      '<circle cx="' +
      cx +
      '" cy="' +
      cy +
      '" r="' +
      r +
      '" fill="none" stroke="rgba(255,255,255,.12)" stroke-width="' +
      stroke +
      '"/>' +
      '<circle cx="' +
      cx +
      '" cy="' +
      cy +
      '" r="' +
      r +
      '" fill="none" stroke="' +
      color +
      '" stroke-width="' +
      stroke +
      '"' +
      ' stroke-dasharray="' +
      dash +
      " " +
      gap +
      '" stroke-linecap="round" transform="rotate(-90 ' +
      cx +
      " " +
      cy +
      ')"/>' +
      "</svg>"
    );
  },

  // 带中心数值的体力环（Stack 布局）
  ringVal: function (ratio, color, size, stroke, cur, max, valFs, maxFs) {
    return (
      '<div style="position:relative;width:' +
      size +
      "px;height:" +
      size +
      'px;flex-shrink:0">' +
      WR.ring(ratio, color, size, stroke) +
      '<div style="position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center">' +
      '<span style="font-size:' +
      valFs +
      "px;font-weight:700;color:" +
      color +
      ';line-height:1">' +
      cur +
      "</span>" +
      '<span style="font-size:' +
      maxFs +
      'px;color:rgba(255,255,255,.35);line-height:1.3">/' +
      max +
      "</span>" +
      "</div></div>"
    );
  },

  // 数据行：标签左，数值右
  row: function (label, val, valColor, fs) {
    fs = fs || 11;
    return (
      '<div style="display:flex;align-items:center;justify-content:space-between;min-height:' +
      (fs + 6) +
      'px">' +
      '<span style="font-size:' +
      fs +
      'px;color:rgba(255,255,255,.45);flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;margin-right:8px">' +
      label +
      "</span>" +
      '<span style="font-size:' +
      fs +
      "px;font-weight:600;color:" +
      (valColor || "rgba(255,255,255,.85)") +
      ';flex-shrink:0">' +
      val +
      "</span>" +
      "</div>"
    );
  },

  // 游戏色小圆点 + 游戏名 + 账号名
  gameHeader: function (gid, accountName, nameFs, dotSize) {
    nameFs = nameFs || 13;
    dotSize = dotSize || 6;
    var color = WR.colors[gid];
    return (
      '<div style="display:flex;align-items:center;gap:5px;flex-shrink:0">' +
      '<div style="width:' +
      dotSize +
      "px;height:" +
      dotSize +
      "px;border-radius:50%;background:" +
      color +
      ';flex-shrink:0"></div>' +
      '<span style="font-size:' +
      nameFs +
      'px;font-weight:700;color:rgba(255,255,255,.9)">' +
      WR.names[gid] +
      "</span>" +
      '<span style="font-size:' +
      (nameFs - 2) +
      'px;color:rgba(255,255,255,.4);margin-left:2px">' +
      (accountName || "旅行者") +
      "</span>" +
      "</div>"
    );
  },

  // 各游戏渐变背景（单游戏）
  cardBg: {
    genshin: "linear-gradient(135deg, #152030 0%, #1a2d42 50%, #1c3350 100%)",
    starrail: "linear-gradient(135deg, #181828 0%, #201830 50%, #261c40 100%)",
    zzz: "linear-gradient(135deg, #1e1a0e 0%, #2a2010 50%, #342810 100%)",
  },

  // 多游戏：根据包含的游戏列表动态生成多色渐变
  // 各游戏色以极低 opacity 叠加在深色底上，形成「彩虹光谱」感
  multiCardBg: function (games) {
    // 各游戏对应的深色底色（与单游戏背景色系一致）
    var baseColors = {
      genshin: { dark: "#152030", mid: "#1a2d42" },
      starrail: { dark: "#181828", mid: "#201830" },
      zzz: { dark: "#1e1a0e", mid: "#2a2010" },
    };
    var count = Math.min(games.length, 3);
    if (count === 1) {
      var b = baseColors[games[0]] || { dark: "#181820", mid: "#1c1c2c" };
      return "linear-gradient(135deg, " + b.dark + " 0%, " + b.mid + " 100%)";
    }
    if (count === 2) {
      var b0 = baseColors[games[0]] || { dark: "#181820", mid: "#1c1c2c" };
      var b1 = baseColors[games[1]] || { dark: "#181820", mid: "#1c1c2c" };
      // 左上用第一款游戏色系，右下用第二款游戏色系，中间过渡
      return (
        "linear-gradient(135deg, " +
        b0.dark +
        " 0%, " +
        b0.mid +
        " 40%, " +
        b1.mid +
        " 60%, " +
        b1.dark +
        " 100%)"
      );
    }
    // 三款游戏：左上→中→右下，三色渐变
    var b0 = baseColors[games[0]] || { dark: "#181820", mid: "#1c1c2c" };
    var b1 = baseColors[games[1]] || { dark: "#181820", mid: "#1c1c2c" };
    var b2 = baseColors[games[2]] || { dark: "#181820", mid: "#1c1c2c" };
    return (
      "linear-gradient(135deg, " +
      b0.dark +
      " 0%, " +
      b0.mid +
      " 25%, " +
      b1.mid +
      " 50%, " +
      b2.mid +
      " 75%, " +
      b2.dark +
      " 100%)"
    );
  },

  // 多游戏：各游戏色光晕（分散在卡片不同角落）
  multiGlows: function (games, w, h) {
    var positions = [
      { x: "-20px", y: "-20px" }, // 左上
      { x: Math.round(w / 2 - 30) + "px", y: Math.round(h / 2 - 30) + "px" }, // 中间
      { x: w - 20 + "px", y: h - 20 + "px" }, // 右下
    ];
    var count = Math.min(games.length, 3);
    var html = "";
    for (var i = 0; i < count; i++) {
      var color = WR.colors[games[i]];
      var pos = positions[i];
      var size = Math.round(Math.min(w, h) * 0.55);
      html +=
        '<div style="position:absolute;left:' +
        pos.x +
        ";top:" +
        pos.y +
        ";width:" +
        size +
        "px;height:" +
        size +
        "px;" +
        "border-radius:50%;background:" +
        color +
        ';opacity:0.08;pointer-events:none;filter:blur(22px)"></div>';
    }
    return html;
  },

  // 卡片外壳
  // gid: 单游戏传游戏 ID，多游戏传 games 数组
  card: function (w, h, inner, gid) {
    var bg, glows;
    if (Array.isArray(gid)) {
      // 多游戏
      bg = WR.multiCardBg(gid);
      glows = WR.multiGlows(gid, w, h);
    } else if (gid && WR.cardBg[gid]) {
      // 单游戏
      bg = WR.cardBg[gid];
      glows =
        '<div style="position:absolute;bottom:-24px;right:-24px;width:' +
        Math.round(w * 0.65) +
        "px;height:" +
        Math.round(h * 0.65) +
        "px;" +
        "border-radius:50%;background:" +
        WR.colors[gid] +
        ';opacity:0.10;pointer-events:none;filter:blur(24px)"></div>';
    } else {
      bg = "linear-gradient(135deg, #181820 0%, #1c1c2c 100%)";
      glows = "";
    }
    return (
      '<div style="width:' +
      w +
      "px;height:" +
      h +
      "px;background:" +
      bg +
      ";border-radius:16px;" +
      'padding:12px;overflow:hidden;position:relative">' +
      glows +
      '<div style="position:relative;width:100%;height:100%">' +
      inner +
      "</div>" +
      "</div>"
    );
  },
};

/**
 * material-list-controls.js — 材料汇总控制项和交互函数
 */

/** 控制项 */
function materialListControls() {
  return [
    {
      id: "game",
      label: "游戏",
      current: function () { return ML_STATE.selectedGame; },
      onChange: function (val) { ML_STATE.selectedGame = val; },
      options: ML_GAME_OPTIONS.map(function (opt) {
        return { value: opt.value, label: opt.label };
      }),
    },
    {
      id: "view",
      label: "视图",
      current: function () { return ML_STATE.viewMode; },
      onChange: function (val) { ML_STATE.viewMode = val; },
      options: ML_VIEW_OPTIONS.map(function (opt) {
        return { value: opt.value, label: opt.label };
      }),
    },
  ];
}

/** 设置游戏筛选 */
function setMaterialListGame(gameId) {
  ML_STATE.selectedGame = gameId;
  refresh();
}

/** 设置视图模式 */
function setMaterialListView(mode) {
  ML_STATE.viewMode = mode;
  refresh();
}

/** 切换角色展开/收起 */
function toggleCharacterExpand(characterId) {
  if (ML_STATE.expandedCharacters[characterId] === false) {
    ML_STATE.expandedCharacters[characterId] = true;
  } else {
    ML_STATE.expandedCharacters[characterId] = false;
  }
  refresh();
}

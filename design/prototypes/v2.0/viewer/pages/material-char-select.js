/**
 * 材料计算 - 角色选择页
 * 
 * 流程位置：工具页 → 游戏选择弹框 → 角色选择页 → (配置检查) → 材料计算页
 * 
 * 功能：
 * 1. 显示当前选中游戏账号的所有角色
 * 2. 支持勾选最多4个角色
 * 3. 右上角显示切换账号按钮，点击弹出账号列表
 * 4. 点击"下一步"检查配置，无配置则跳转配置页
 */

// === 模拟数据 ===
const MOCK_ACCOUNTS = [
  { id: 1, username: '旅行者', uid: '109050292', game: 'genshin', gameName: '原神' },
  { id: 2, username: '开拓者', uid: '102731382', game: 'starrail', gameName: '星穹铁道' },
  { id: 3, username: '绳匠', uid: '37716744', game: 'zzz', gameName: '绝区零' },
];

const MOCK_GENSHIN_CHARACTERS = [
  { avatarId: '10000133', name: '纳西妲', rarity: 5, level: 90, element: 'Dendro', hasConfig: true },
  { avatarId: '10000131', name: '芙宁娜', rarity: 5, level: 90, element: 'Hydro', hasConfig: true },
  { avatarId: '10000130', name: '那维莱特', rarity: 5, level: 90, element: 'Hydro', hasConfig: false },
  { avatarId: '10000129', name: '林尼', rarity: 5, level: 80, element: 'Pyro', hasConfig: true },
  { avatarId: '10000125', name: '艾尔海森', rarity: 5, level: 90, element: 'Dendro', hasConfig: true },
  { avatarId: '10000123', name: '流浪者', rarity: 5, level: 90, element: 'Anemo', hasConfig: false },
  { avatarId: '10000122', name: '纳西妲', rarity: 5, level: 70, element: 'Dendro', hasConfig: false },
  { avatarId: '10000116', name: '妮露', rarity: 5, level: 90, element: 'Hydro', hasConfig: true },
  { avatarId: '10000114', name: '赛诺', rarity: 5, level: 80, element: 'Electro', hasConfig: true },
  { avatarId: '10000112', name: '提纳里', rarity: 5, level: 60, element: 'Dendro', hasConfig: false },
  { avatarId: '10000097', name: '夜兰', rarity: 5, level: 90, element: 'Hydro', hasConfig: true },
  { avatarId: '10000092', name: '神里绫人', rarity: 5, level: 90, element: 'Hydro', hasConfig: true },
  { avatarId: '10000088', name: '八重神子', rarity: 5, level: 90, element: 'Electro', hasConfig: false },
  { avatarId: '10000077', name: '荒泷一斗', rarity: 5, level: 90, element: 'Geo', hasConfig: true },
  { avatarId: '10000065', name: '雷电将军', rarity: 5, level: 90, element: 'Electro', hasConfig: true },
  { avatarId: '10000056', name: '神里绫华', rarity: 5, level: 90, element: 'Cryo', hasConfig: true },
  { avatarId: '10000055', name: '宵宫', rarity: 5, level: 90, element: 'Pyro', hasConfig: false },
  { avatarId: '10000053', name: '胡桃', rarity: 5, level: 90, element: 'Pyro', hasConfig: true },
  { avatarId: '10000031', name: '甘雨', rarity: 5, level: 90, element: 'Cryo', hasConfig: true },
  { avatarId: '10000002', name: '安柏', rarity: 4, level: 60, element: 'Pyro', hasConfig: false },
];

const MOCK_STARRAIL_CHARACTERS = [
  { avatarId: '1001', name: '开拓者·存护', rarity: 5, level: 70, element: 'Physical', hasConfig: true },
  { avatarId: '1002', name: '开拓者·毁灭', rarity: 5, level: 70, element: 'Physical', hasConfig: false },
  { avatarId: '1008', name: '姬子', rarity: 5, level: 80, element: 'Fire', hasConfig: true },
  { avatarId: '1009', name: '瓦尔特', rarity: 5, level: 80, element: 'Imaginary', hasConfig: true },
  { avatarId: '1013', name: '布洛妮娅', rarity: 5, level: 80, element: 'Wind', hasConfig: false },
];

const MOCK_ZZZ_CHARACTERS = [
  { avatarId: '1021', name: '安比', rarity: 'A', level: 60, element: 'Electric', hasConfig: true },
  { avatarId: '1031', name: '妮可', rarity: 'A', level: 60, element: 'Ether', hasConfig: false },
  { avatarId: '1041', name: '比利', rarity: 'A', level: 50, element: 'Physical', hasConfig: true },
  { avatarId: '1011', name: '莱卡恩', rarity: 'S', level: 60, element: 'Electric', hasConfig: true },
];

// === 游戏配色 ===
const GAME_COLORS = {
  genshin: { primary: '#4A90D9', bg: '#1A2A3A' },
  starrail: { primary: '#7B68EE', bg: '#1A1A2E' },
  zzz: { primary: '#F5A623', bg: '#1A1A1A' },
};

// === 状态 ===
let selectedGame = 'genshin';
let selectedAccountIdx = 0;
let selectedCharacterIds = [];
let showAccountMenu = false;

// === 工具函数 ===
function getCharacters() {
  switch (selectedGame) {
    case 'genshin': return MOCK_GENSHIN_CHARACTERS;
    case 'starrail': return MOCK_STARRAIL_CHARACTERS;
    case 'zzz': return MOCK_ZZZ_CHARACTERS;
    default: return [];
  }
}

function getAccountsForGame() {
  return MOCK_ACCOUNTS.filter(acc => acc.game === selectedGame);
}

function getCurrentAccount() {
  const accounts = getAccountsForGame();
  return accounts[selectedAccountIdx] || accounts[0] || { username: '未知账号', gameName: '未知游戏', uid: '--------' };
}

function toggleCharacter(avatarId) {
  const idx = selectedCharacterIds.indexOf(avatarId);
  if (idx >= 0) {
    selectedCharacterIds.splice(idx, 1);
  } else if (selectedCharacterIds.length < 4) {
    selectedCharacterIds.push(avatarId);
  }
  if (typeof refresh === 'function') refresh();
}

function switchAccount(idx) {
  selectedAccountIdx = idx;
  selectedCharacterIds = [];
  showAccountMenu = false;
  if (typeof refresh === 'function') refresh();
}

function handleNext() {
  if (selectedCharacterIds.length === 0) return;
  
  // 检查配置
  const characters = getCharacters();
  const noConfigChars = selectedCharacterIds.filter(id => {
    const char = characters.find(c => c.avatarId === id);
    return char && !char.hasConfig;
  });
  
  if (noConfigChars.length > 0) {
    // 有角色无配置，跳转配置页
    window.location.hash = 'material-target-config';
  } else {
    // 全部有配置，进入材料计算页
    window.location.hash = 'material-list';
  }
}

// === 渲染函数 ===
function renderCharacterCard(char, idx, color) {
  if (!char) return '';
  
  const isSelected = selectedCharacterIds.includes(char.avatarId);
  const isDisabled = !isSelected && selectedCharacterIds.length >= 4;
  const charName = char.name || '未知';
  const charLevel = char.level || 1;
  const charElement = char.element || '';
  const charRarity = char.rarity || 4;
  const charAvatarId = char.avatarId || '';
  const charHasConfig = char.hasConfig !== undefined ? char.hasConfig : true;
  
  // 元素颜色映射
  const elementColor = 
    charElement === 'Dendro' ? '#4CAF50' :
    charElement === 'Hydro' ? '#2196F3' :
    charElement === 'Pyro' ? '#FF5722' :
    charElement === 'Electro' ? '#9C27B0' :
    charElement === 'Anemo' ? '#00BCD4' :
    charElement === 'Cryo' ? '#03A9F4' :
    charElement === 'Geo' ? '#FFC107' :
    charElement === 'Physical' ? '#9E9E9E' :
    charElement === 'Fire' ? '#FF5722' :
    charElement === 'Wind' ? '#00BCD4' :
    charElement === 'Imaginary' ? '#FFC107' :
    charElement === 'Electric' ? '#9C27B0' :
    charElement === 'Ether' ? '#9C27B0' : '#607D8B';
  
  return `
    <div 
      class="char-card ${isSelected ? 'selected' : ''} ${isDisabled ? 'disabled' : ''}"
      style="
        background: linear-gradient(135deg, ${charRarity === 5 || charRarity === 'S' ? '#2A1A3A' : '#1A2A3A'}, #1A1A2E);
        border-radius: 12px;
        padding: 12px;
        cursor: ${isDisabled ? 'not-allowed' : 'pointer'};
        opacity: ${isDisabled ? '0.5' : '1'};
        transition: all 0.2s;
        position: relative;
      "
      onclick="${!isDisabled ? `toggleCharacter('${charAvatarId}')` : ''}"
    >
      <!-- 角色图标容器（带选中框） -->
      <div style="
        position: relative;
        width: 80px;
        height: 80px;
        margin: 0 auto 8px;
      ">
        <!-- 选中边框 -->
        ${isSelected ? `
          <div style="
            position: absolute;
            top: -4px;
            left: -4px;
            right: -4px;
            bottom: -4px;
            border: 3px solid ${color.primary};
            border-radius: 50%;
            box-shadow: 0 0 8px ${color.primary};
          "></div>
        ` : ''}
        
        <!-- 角色图标 -->
        <div style="
          width: 80px;
          height: 80px;
          background: ${elementColor};
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 32px;
          color: white;
        ">
          ${charName.charAt(0)}
        </div>
        
        <!-- 勾选标记（右上角） -->
        ${isSelected ? `
          <div style="
            position: absolute;
            top: 0;
            right: 0;
            width: 24px;
            height: 24px;
            background: ${color.primary};
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 2px 4px rgba(0,0,0,0.3);
          ">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3">
              <polyline points="20 6 9 17 4 12"></polyline>
            </svg>
          </div>
        ` : ''}
      </div>
      
      <!-- 角色名 -->
      <div style="
        color: white;
        font-size: 14px;
        font-weight: 500;
        margin-bottom: 4px;
        text-align: center;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
      ">${charName}</div>
      
      <!-- 等级 -->
      <div style="
        color: rgba(255,255,255,0.6);
        font-size: 12px;
        text-align: center;
      ">Lv.${charLevel}</div>
      
      <!-- 配置状态 -->
      ${!charHasConfig ? `
        <div style="
          position: absolute;
          bottom: 8px;
          left: 8px;
          right: 8px;
          background: rgba(255,152,0,0.2);
          border-radius: 4px;
          padding: 2px 4px;
          font-size: 10px;
          color: #FFA726;
          text-align: center;
        ">未配置</div>
      ` : ''}
    </div>
  `;
}

function renderAccountMenu(color) {
  const accounts = getAccountsForGame();
  
  if (!showAccountMenu) return '';
  
  return `
    <div 
      style="
        position: absolute;
        top: 100%;
        right: 0;
        margin-top: 8px;
        background: #2A2A3E;
        border-radius: 12px;
        padding: 8px 0;
        min-width: 200px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.5);
        z-index: 100;
      "
    >
      ${accounts.map((acc, idx) => `
        <div 
          class="menu-item"
          style="
            padding: 12px 16px;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 12px;
            background: ${idx === selectedAccountIdx ? 'rgba(74,144,217,0.2)' : 'transparent'};
          "
          onclick="switchAccount(${idx})"
        >
          <!-- 选中标记 -->
          ${idx === selectedAccountIdx ? `
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="${color.primary}" stroke-width="3">
              <polyline points="20 6 9 17 4 12"></polyline>
            </svg>
          ` : `
            <div style="width: 16px; height: 16px;"></div>
          `}
          
          <div>
            <div style="color: white; font-size: 14px;">${acc.username}</div>
            <div style="color: rgba(255,255,255,0.5); font-size: 12px;">UID: ${acc.uid}</div>
          </div>
        </div>
      `).join('')}
    </div>
  `;
}

function renderSelectedBar(color) {
  const selectedCount = selectedCharacterIds.length;
  const chars = getCharacters();
  
  // 元素颜色映射函数
  function getElementColor(element) {
    return element === 'Dendro' ? '#4CAF50' :
           element === 'Hydro' ? '#2196F3' :
           element === 'Pyro' ? '#FF5722' :
           element === 'Electro' ? '#9C27B0' :
           element === 'Anemo' ? '#00BCD4' :
           element === 'Cryo' ? '#03A9F4' :
           element === 'Geo' ? '#FFC107' :
           element === 'Physical' ? '#9E9E9E' :
           element === 'Fire' ? '#FF5722' :
           element === 'Wind' ? '#00BCD4' :
           element === 'Imaginary' ? '#FFC107' :
           element === 'Electric' ? '#9C27B0' :
           element === 'Ether' ? '#9C27B0' : '#607D8B';
  }
  
  return `
    <div style="
      position: fixed;
      bottom: 0;
      left: 0;
      right: 0;
      background: #1A1A2E;
      border-top: 1px solid rgba(255,255,255,0.1);
      padding: 16px;
      display: flex;
      align-items: center;
      gap: 16px;
      z-index: 50;
    ">
      <!-- 已选角色头像 -->
      <div style="display: flex; gap: 8px; flex: 1;">
        ${[0,1,2,3].map(i => {
          if (i < selectedCount) {
            const char = chars.find(c => c.avatarId === selectedCharacterIds[i]);
            if (!char) return `
              <div style="
                width: 56px;
                height: 56px;
                background: #607D8B;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 22px;
                color: white;
              ">?</div>
            `;
            const charName = char.name || '未知';
            const charElement = char.element || '';
            return `
              <div style="
                width: 56px;
                height: 56px;
                background: ${getElementColor(charElement)};
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 22px;
                color: white;
              ">${charName.charAt(0)}</div>
            `;
          } else {
            return `
              <div style="
                width: 56px;
                height: 56px;
                background: rgba(255,255,255,0.1);
                border-radius: 50%;
                border: 2px dashed rgba(255,255,255,0.2);
              "></div>
            `;
          }
        }).join('')}
      </div>
      
      <!-- 已选数量 -->
      <div style="color: rgba(255,255,255,0.7); font-size: 14px;">
        已选 ${selectedCount}/4
      </div>
      
      <!-- 下一步按钮 -->
      <button 
        style="
          background: ${selectedCount > 0 ? color.primary : 'rgba(255,255,255,0.2)'};
          color: white;
          border: none;
          border-radius: 8px;
          padding: 12px 24px;
          font-size: 14px;
          font-weight: 500;
          cursor: ${selectedCount > 0 ? 'pointer' : 'not-allowed'};
        "
        ${selectedCount > 0 ? 'onclick="handleNext()"' : 'disabled'}
      >
        下一步
      </button>
    </div>
  `;
}

window.renderMaterialCharSelect = function(w, h) {
  const color = GAME_COLORS[selectedGame];
  const characters = getCharacters();
  const currentAccount = getCurrentAccount();
  
  return `
    <div style="
      width: ${w}px;
      height: ${h}px;
      background: ${color.bg};
      display: flex;
      flex-direction: column;
      overflow: hidden;
    ">
      <!-- 顶部导航栏 -->
      <div style="
        padding: 16px;
        display: flex;
        align-items: center;
        gap: 16px;
        border-bottom: 1px solid rgba(255,255,255,0.1);
      ">
        <!-- 返回按钮 -->
        <div style="cursor: pointer; padding: 8px;" onclick="window.location.hash='tools'">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2">
            <path d="M19 12H5M12 19l-7-7 7-7"/>
          </svg>
        </div>
        
        <!-- 标题 -->
        <div style="flex: 1;">
          <div style="color: white; font-size: 18px; font-weight: 600;">选择角色</div>
          <div style="color: rgba(255,255,255,0.5); font-size: 12px; margin-top: 2px;">
            ${currentAccount.gameName} · ${currentAccount.username}
          </div>
        </div>
        
        <!-- 切换账号按钮 -->
        <div style="position: relative;">
          <div 
            style="
              background: rgba(255,255,255,0.1);
              border-radius: 8px;
              padding: 8px 12px;
              display: flex;
              align-items: center;
              gap: 6px;
              cursor: pointer;
            "
            onclick="showAccountMenu = !showAccountMenu; if (typeof refresh === 'function') refresh();"
          >
            <span style="font-size: 18px;">👥</span>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2">
              <path d="M6 9l6 6 6-6"/>
            </svg>
          </div>
          ${renderAccountMenu(color)}
        </div>
      </div>
      
      <!-- 提示文字 -->
      <div style="
        padding: 12px 16px;
        background: rgba(255,255,255,0.05);
        color: rgba(255,255,255,0.6);
        font-size: 13px;
      ">
        最多可选择 4 个角色进行材料计算
      </div>
      
      <!-- 角色网格 -->
      <div style="
        flex: 1;
        overflow-y: auto;
        padding: 16px;
        padding-bottom: 100px;
      ">
        <div style="
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 12px;
        ">
          ${characters.map((char, idx) => renderCharacterCard(char, idx, color)).join('')}
        </div>
      </div>
      
      <!-- 底部已选栏 -->
      ${renderSelectedBar(color)}
    </div>
  `;
};

window.materialCharSelectControls = function() {
  return [
    {
      id: 'game',
      label: '游戏',
      options: [
        { value: 'genshin', label: '原神' },
        { value: 'starrail', label: '星穹铁道' },
        { value: 'zzz', label: '绝区零' },
      ],
      current: () => selectedGame,
      onChange: (val) => {
        selectedGame = val;
        selectedAccountIdx = 0;
        selectedCharacterIds = [];
        if (typeof refresh === 'function') refresh();
      }
    }
  ];
};

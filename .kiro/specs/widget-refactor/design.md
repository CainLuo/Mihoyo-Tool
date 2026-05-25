# Widget 模块重构 - 设计文档

## 一、架构设计

### 1.1 分层架构

```
┌─────────────────────────────────────────────────────────┐
│                    FormExtensionAbility                  │
│  - 同步读取 Preferences                                  │
│  - 调用 WidgetViewModel.buildUIState()                  │
│  - 构建 LocalStorage payload                            │
└─────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│                      WidgetViewModel                     │
│  - parsePayload()：解析 JSON                            │
│  - buildUIState()：组装 UIState                         │
│  - calcStaminaColor()：计算体力颜色                     │
│  - buildExtraRows()：组装额外数据行                     │
└─────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│                       Widget Page                        │
│  - @LocalStorageProp 接收 payload                       │
│  - 调用 ViewModel 获取 UIState                          │
│  - 传递 UIState 给 Component                            │
└─────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│                    Widget Component                      │
│  - @Prop 接收 UIState                                   │
│  - 只负责 UI 渲染                                       │
│  - 无业务逻辑                                           │
└─────────────────────────────────────────────────────────┘
```

### 1.2 数据流

```
payload JSON
    │
    ▼
WidgetViewModel.parsePayload()
    │
    ▼
ParsedPayload (内部数据结构)
    │
    ▼
WidgetViewModel.buildUIState()
    │
    ▼
WidgetUIState (渲染数据)
    │
    ▼
Widget Component (渲染)
```

## 二、UIState 类设计

### 2.1 WidgetTheme

Widget 专用主题常量，不依赖 HAR 模块。

```typescript
export class WidgetTheme {
  // 字体大小
  font9: number = 9;
  font10: number = 10;
  font11: number = 11;
  font12: number = 12;
  font13: number = 13;
  font14: number = 14;
  font18: number = 18;
  font24: number = 24;
  
  // 间距
  value0: number = 0;
  value1: number = 1;
  value2: number = 2;
  value3: number = 3;
  value4: number = 4;
  value5: number = 5;
  value8: number = 8;
  value12: number = 12;
  value16: number = 16;
  
  // 圆角
  radius2: number = 2;
  radius16: number = 16;
  
  // 百分比
  full: string = '100%';
  
  private static instance: WidgetTheme;
  
  static get(): WidgetTheme {
    if (!WidgetTheme.instance) {
      WidgetTheme.instance = new WidgetTheme();
    }
    return WidgetTheme.instance;
  }
}
```

### 2.2 WidgetExtraRow

额外数据行，已解析好，Component 直接渲染。

```typescript
export class WidgetExtraRow {
  label: ResourceStr = '';
  value: string = '';
  valueColor: ResourceColor = $r('app.color.text_on_dark_medium');
}
```

### 2.3 WidgetRoleUIState

单角色数据 UIState，包含所有需要渲染的数据。

```typescript
export class WidgetRoleUIState {
  // 头部
  gameName: ResourceStr = '';
  gameColor: ResourceColor = $r('app.color.game_color_genshin');
  roleId: string = '';
  
  // 体力数据
  currentStamina: number = 0;
  maxStamina: number = 160;
  recoverySeconds: number = 0;
  recoveryDesc: ResourceStr = '';
  isFull: boolean = false;
  staminaColor: ResourceColor = $r('app.color.game_color_genshin');
  
  // 星铁专用
  reserveStamina: string = '0';
  
  // 额外数据行
  extraRows: WidgetExtraRow[] = [];
}
```

### 2.4 Widget2x2UIState (Union 模拟)

由于 Widget Form 不支持 union 类型，使用类型标记区分：

```typescript
export class Widget2x2UIState {
  isEmpty: boolean = false;
  isSingleGame: boolean = true;
  
  // 单游戏数据
  singleGameState: WidgetRoleUIState = new WidgetRoleUIState();
  
  // 多游戏数据
  multiGameState: WidgetMultiGameUIState = new WidgetMultiGameUIState();
}

export class WidgetMultiGameUIState {
  accountName: string = '';
  roles: WidgetRoleUIState[] = [];
}
```

## 三、WidgetViewModel 设计

### 3.1 类结构

```typescript
export class WidgetViewModel {
  private theme: WidgetTheme = WidgetTheme.get();
  
  /**
   * 构建 2x2 UIState
   */
  build2x2UIState(payloadJson: string): Widget2x2UIState {
    if (payloadJson.length === 0) {
      return this.buildEmptyState();
    }
    
    const payload = parsePayload(payloadJson);
    const roles = payload.getAllRoles();
    
    if (roles.length === 0) {
      return this.buildEmptyState();
    } else if (roles.length === 1) {
      return this.buildSingleGameState(roles[0]);
    } else {
      return this.buildMultiGameState(roles);
    }
  }
  
  private buildEmptyState(): Widget2x2UIState {
    const state = new Widget2x2UIState();
    state.isEmpty = true;
    return state;
  }
  
  private buildSingleGameState(role: ParsedRole): Widget2x2UIState {
    const state = new Widget2x2UIState();
    state.isSingleGame = true;
    state.singleGameState = this.buildRoleUIState(role);
    return state;
  }
  
  private buildMultiGameState(roles: ParsedRole[]): Widget2x2UIState {
    const state = new Widget2x2UIState();
    state.isSingleGame = false;
    state.multiGameState = new WidgetMultiGameUIState();
    state.multiGameState.accountName = roles.length > 0 ? roles[0].nickname : '';
    
    for (let i = 0; i < roles.length && i < 2; i++) {
      state.multiGameState.roles.push(this.buildRoleUIStateCompact(roles[i]));
    }
    
    return state;
  }
  
  /**
   * 构建完整角色 UIState（包含 extraRows）
   */
  private buildRoleUIState(role: ParsedRole): WidgetRoleUIState {
    const state = new WidgetRoleUIState();
    
    // 游戏信息
    const gameId = this.detectGameId(role);
    state.gameName = this.getGameNameResource(gameId);
    state.gameColor = this.getGameColorResource(gameId);
    state.roleId = role.roleId;
    
    // 体力数据
    state.currentStamina = role.currentStamina;
    state.maxStamina = role.maxStamina;
    state.recoverySeconds = role.recoverySeconds;
    state.recoveryDesc = this.formatRecoveryDesc(role.recoverySeconds);
    state.isFull = role.recoverySeconds <= 0 && role.currentStamina >= role.maxStamina;
    state.staminaColor = this.calcStaminaColor(role.currentStamina, role.maxStamina, state.gameColor);
    
    // 额外数据行
    state.extraRows = this.buildExtraRows(gameId, role.rawJson);
    
    return state;
  }
  
  /**
   * 构建紧凑角色 UIState（不包含 extraRows）
   */
  private buildRoleUIStateCompact(role: ParsedRole): WidgetRoleUIState {
    const state = this.buildRoleUIState(role);
    state.extraRows = []; // 紧凑模式不显示
    return state;
  }
  
  /**
   * 计算体力颜色
   */
  private calcStaminaColor(current: number, max: number, gameColor: ResourceColor): ResourceColor {
    const ratio = max > 0 ? current / max : 0;
    if (ratio <= 0.3) {
      return $r('app.color.color_danger');
    }
    if (ratio <= 0.7) {
      return $r('app.color.color_warning');
    }
    return gameColor;
  }
  
  /**
   * 构建额外数据行
   */
  private buildExtraRows(gameId: string, rawJson: string): WidgetExtraRow[] {
    const rows: WidgetExtraRow[] = [];
    
    if (rawJson.length === 0) {
      return rows;
    }
    
    try {
      const data = JSON.parse(rawJson) as Record<string, Object>;
      
      if (gameId === 'genshin') {
        rows.push(...this.buildGenshinExtraRows(data));
      } else if (gameId === 'starrail') {
        rows.push(...this.buildStarRailExtraRows(data));
      } else if (gameId === 'zzz') {
        rows.push(...this.buildZZZExtraRows(data));
      }
    } catch (_e) {
      // 解析失败返回空数组
    }
    
    return rows.slice(0, 2);
  }
  
  private buildGenshinExtraRows(data: Record<string, Object>): WidgetExtraRow[] {
    const rows: WidgetExtraRow[] = [];
    
    // 探索派遣
    const maxExpedition = data['max_expedition_num'] as number;
    if (maxExpedition > 0) {
      const finished = this.countFinishedExpeditions(data['expeditions']);
      rows.push({
        label: $r('app.string.widget_expedition'),
        value: `${finished}/${maxExpedition}`,
        valueColor: $r('app.color.game_color_starrail')
      });
    }
    
    // 洞天财瓮
    const maxCoin = data['max_home_coin'] as number;
    if (maxCoin > 0) {
      const coin = data['current_home_coin'] as number;
      rows.push({
        label: $r('app.string.widget_home_coin'),
        value: `${coin}/${maxCoin}`,
        valueColor: $r('app.color.color_warning')
      });
    }
    
    return rows;
  }
  
  // ... 其他游戏解析方法
}
```

## 四、Component 设计

### 4.1 Widget2x2SingleGame

```typescript
@Component
export struct Widget2x2SingleGame {
  @Prop theme: WidgetTheme = WidgetTheme.get();
  @Prop role: WidgetRoleUIState = new WidgetRoleUIState();
  
  build() {
    Column() {
      // 头部
      Column({ space: this.theme.value1 }) {
        Text(this.role.gameName)
          .fontSize(this.theme.font12)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_on_dark_high'))
        
        Text('UID ' + this.role.roleId)
          .fontSize(this.theme.font10)
          .fontColor($r('app.color.text_on_dark_muted'))
      }
      .width(this.theme.full)
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: this.theme.value8 })
      
      // 体力区块
      this.buildStaminaBlock()
      
      // 额外数据行
      Column({ space: this.theme.value5 }) {
        ForEach(this.role.extraRows, (row: WidgetExtraRow) => {
          Row() {
            Text(row.label)
              .fontSize(this.theme.font11)
              .fontColor($r('app.color.text_on_dark_tertiary'))
              .layoutWeight(1)
            
            Text(row.value)
              .fontSize(this.theme.font11)
              .fontWeight(FontWeight.Bold)
              .fontColor(row.valueColor)
          }
          .width(this.theme.full)
        })
      }
      .width(this.theme.full)
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .width(this.theme.full)
    .height(this.theme.full)
  }
  
  @Builder
  private buildStaminaBlock(): void {
    Column({ space: this.theme.value2 }) {
      Row({ space: this.theme.value3 }) {
        Text(String(this.role.currentStamina))
          .fontSize(this.theme.font24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.role.staminaColor)
        
        Text('/' + String(this.role.maxStamina))
          .fontSize(this.theme.font14)
          .fontColor($r('app.color.text_on_dark_muted'))
      }
      .alignItems(VerticalAlign.Bottom)
      
      Text(this.role.recoveryDesc)
        .fontSize(this.theme.font11)
        .fontColor($r('app.color.text_on_dark_secondary'))
    }
    .width(this.theme.full)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: this.theme.value8 })
  }
}
```

## 五、资源文件更新

### 5.1 新增字符串资源

在 `entry/src/main/resources/base/element/string.json` 中添加：

```json
{
  "string": [
    { "name": "widget_expedition", "value": "探索派遣" },
    { "name": "widget_home_coin", "value": "洞天财瓮" },
    { "name": "widget_daily_train", "value": "每日实训" },
    { "name": "widget_weekly_cocoon", "value": "历战余响" },
    { "name": "widget_vitality", "value": "今日活跃度" },
    { "name": "widget_card_sign", "value": "刮刮卡" },
    { "name": "widget_reserve_prefix", "value": "后备" }
  ]
}
```

### 5.2 多语言同步

同步更新 `en/element/string.json` 和 `zh_HK/element/string.json`。

## 六、迁移计划

### 6.1 第一阶段：创建新文件

1. 创建 `WidgetUIStates.ets`
2. 创建 `WidgetViewModel.ets`
3. 添加字符串资源

### 6.2 第二阶段：修改 Widget Pages

按顺序修改：
1. `Widget2x2.ets`
2. `Widget2x4.ets`
3. `Widget4x4.ets`
4. `Widget1x2Genshin.ets`
5. `Widget1x2StarRail.ets`
6. `Widget1x2ZZZ.ets`

### 6.3 第三阶段：修改 Widget Components

按顺序修改：
1. `Widget2x2SingleGame.ets`
2. `WidgetSlotRenderer.ets`
3. `WidgetCardContent.ets`
4. 其他组件

### 6.4 第四阶段：清理

1. 删除废弃文件
2. 移除调试代码
3. 验证构建和功能

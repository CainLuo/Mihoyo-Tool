# Widget 模块重构 - 需求文档

## 背景

当前 Widget 模块存在多处违背项目 Rules 的问题：

1. **Hard Code**：组件中硬编码字符串（如 `'探索派遣'`、`'洞天财瓮'`）
2. **Theme 实例化**：每个 page/component 都 `new DefaultTheme()`
3. **数据解析位置错误**：page/component 中直接解析 payload
4. **职责混乱**：Component 包含业务逻辑（数据解析、游戏类型判断）

## 重构目标

按照 MVVM 分层和项目 Rules，重构 Widget 模块：

1. **UIState 模式**：定义 `WidgetUIState` 类，ViewModel 负责组装
2. **Theme 单例传递**：通过 UIState 传递 Theme 实例
3. **数据解析上移**：所有 payload 解析逻辑移到 ViewModel 层
4. **Component 纯净化**：Component 只接收 UIState，只负责渲染

## 详细需求

### 1. WidgetUIState 定义

为每种 Widget 尺寸定义 UIState：

```typescript
// entry/src/main/ets/widget/models/WidgetUIStates.ets

/** Widget 主题常量（单例） */
export class WidgetTheme {
  // 从 DefaultTheme 复制必要字段
  // 避免依赖 DefaultTheme 类（HAR 模块限制）
}

/** 单角色数据 UIState */
export class WidgetRoleUIState {
  gameName: ResourceStr = '';
  gameColor: ResourceColor = $r('app.color.game_color_genshin');
  roleId: string = '';
  
  // 体力数据
  currentStamina: number = 0;
  maxStamina: number = 160;
  recoveryDesc: ResourceStr = '';
  isFull: boolean = false;
  staminaColor: ResourceColor = $r('app.color.color_primary');
  
  // 额外数据行（已解析好，Component 直接渲染）
  extraRows: WidgetExtraRow[] = [];
}

/** 额外数据行 */
export class WidgetExtraRow {
  label: ResourceStr = '';
  value: string = '';
  valueColor: ResourceColor = $r('app.color.text_on_dark_medium');
}

/** 2x2 单游戏 UIState */
export class Widget2x2SingleGameUIState {
  theme: WidgetTheme;
  role: WidgetRoleUIState;
}

/** 2x2 多游戏 UIState */
export class Widget2x2MultiGameUIState {
  theme: WidgetTheme;
  accountName: string = '';
  roles: WidgetRoleUIState[]; // 最多 2 个
}
```

### 2. WidgetViewModel

```typescript
// entry/src/main/ets/widget/viewmodel/WidgetViewModel.ets

export class WidgetViewModel {
  private theme: WidgetTheme = new WidgetTheme();
  
  /**
   * 从 payload JSON 构建 2x2 UIState
   */
  build2x2UIState(payloadJson: string): Widget2x2UIState {
    const payload = parsePayload(payloadJson);
    const roles = payload.getAllRoles();
    
    if (roles.length === 0) {
      return this.buildEmptyUIState();
    } else if (roles.length === 1) {
      return this.buildSingleGameUIState(roles[0]);
    } else {
      return this.buildMultiGameUIState(roles);
    }
  }
  
  private buildSingleGameUIState(role: ParsedRole): Widget2x2SingleGameUIState {
    // 所有解析逻辑在这里完成
    // 包括：游戏类型判断、体力颜色计算、extraRows 组装
  }
}
```

### 3. Page 职责

```typescript
// entry/src/main/ets/widget/pages/Widget2x2.ets

@Entry(storage)
@Component
struct Widget2x2 {
  @LocalStorageProp('payload') payloadJson: string = '';
  
  // UIState 由 ViewModel 构建，page 只负责传递
  private vm: WidgetViewModel = new WidgetViewModel();
  
  private get uiState(): Widget2x2UIState {
    return this.vm.build2x2UIState(this.payloadJson);
  }
  
  build() {
    Stack() {
      // 背景渐变
      Column()
        .linearGradient(this.buildGradient())
        
      // 内容
      this.buildContent()
    }
    .onClick(() => { /* ... */ })
  }
  
  @Builder
  private buildContent(): void {
    if (this.uiState.isEmpty) {
      WidgetEmptyPlaceholder({ theme: this.uiState.theme })
    } else if (this.uiState.isSingleGame) {
      Widget2x2SingleGame({ 
        theme: this.uiState.theme,
        role: (this.uiState as Widget2x2SingleGameUIState).role 
      })
    } else {
      Widget2x2MultiGame({
        theme: this.uiState.theme,
        state: this.uiState as Widget2x2MultiGameUIState
      })
    }
  }
}
```

### 4. Component 职责

```typescript
// entry/src/main/ets/widget/components/Widget2x2SingleGame.ets

@Component
export struct Widget2x2SingleGame {
  @Prop theme: WidgetTheme;      // 从外部传入
  @Prop role: WidgetRoleUIState; // 数据已解析好
  
  build() {
    Column() {
      // 头部
      Text(this.role.gameName)
        .fontSize(this.theme.font12)
        .fontColor($r('app.color.text_on_dark_high'))
      
      Text('UID ' + this.role.roleId)
        .fontSize(this.theme.font10)
        .fontColor($r('app.color.text_on_dark_muted'))
      
      // 体力区块
      Row() {
        Text(String(this.role.currentStamina))
          .fontSize(this.theme.font24)
          .fontColor(this.role.staminaColor)
        
        Text('/' + String(this.role.maxStamina))
          .fontSize(this.theme.font14)
      }
      
      Text(this.role.recoveryDesc)
        .fontSize(this.theme.font11)
      
      // 额外数据行（直接渲染，不再解析）
      ForEach(this.role.extraRows, (row: WidgetExtraRow) => {
        Row() {
          Text(row.label)
            .fontSize(this.theme.font11)
          Text(row.value)
            .fontSize(this.theme.font11)
            .fontColor(row.valueColor)
        }
      })
    }
  }
}
```

## 文件清单

### 新增文件

| 文件 | 职责 |
|-----|------|
| `widget/models/WidgetUIStates.ets` | 所有 UIState 类定义 |
| `widget/viewmodel/WidgetViewModel.ets` | UIState 组装逻辑 |

### 修改文件

| 文件 | 修改内容 |
|-----|---------|
| `widget/pages/Widget2x2.ets` | 移除数据解析，使用 ViewModel |
| `widget/pages/Widget2x4.ets` | 同上 |
| `widget/pages/Widget4x4.ets` | 同上 |
| `widget/pages/Widget1x2Genshin.ets` | 同上 |
| `widget/pages/Widget1x2StarRail.ets` | 同上 |
| `widget/pages/Widget1x2ZZZ.ets` | 同上 |
| `widget/components/Widget2x2SingleGame.ets` | 移除解析逻辑，接收 UIState |
| `widget/components/WidgetSlotRenderer.ets` | 同上 |
| `widget/components/WidgetCardContent.ets` | 同上 |
| `widget/components/WidgetDataRow.ets` | 接收 theme 参数 |
| 其他组件文件 | 移除硬编码，接收 theme 参数 |

### 删除文件

| 文件 | 原因 |
|-----|------|
| `widget/utils/WidgetSlotDataParser.ets` | 解析逻辑移到 ViewModel |
| `widget/utils/WidgetPayloadParser.ets` | 解析逻辑移到 ViewModel（保留部分复用） |
| `widget/utils/WidgetTheme.ets` | 合并到 WidgetUIStates.ets |

## 验收标准

1. 所有 Widget 组件无硬编码字符串
2. 所有 Widget 组件无 `new DefaultTheme()`
3. 所有 page 文件无数据解析逻辑
4. 所有 component 文件无业务逻辑（只有 UI 渲染）
5. 构建通过，Widget 功能正常

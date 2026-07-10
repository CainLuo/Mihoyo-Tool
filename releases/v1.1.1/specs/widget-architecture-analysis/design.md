# Widget 代码架构设计文档

## 一、整体架构

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            主应用进程 (Main Process)                         │
│                                                                             │
│  ┌─────────────────┐    ┌──────────────────┐    ┌───────────────────────┐   │
│  │   core 模块      │    │  EntryAbility    │    │ WidgetDataStoreBuilder │   │
│  │                 │───▶│                  │───▶│                       │   │
│  │ Repository/DB   │    │ CoreInitializer  │    │ buildAndSave()        │   │
│  └─────────────────┘    └──────────────────┘    └───────────┬───────────┘   │
│                                                            │               │
│                                                            ▼               │
│                                              ┌───────────────────────────┐  │
│                                              │    Preferences 存储        │  │
│                                              │                           │  │
│                                              │ - widget_configs (配置)   │  │
│                                              │ - widget_data (数据)      │  │
│                                              └───────────┬───────────────┘  │
└──────────────────────────────────────────────────────────│──────────────────┘
                                                           │
                                            ┌──────────────┴──────────────┐
                                            │   跨进程数据传递              │
                                            │   (Preferences 共享)         │
                                            └──────────────┬──────────────┘
                                                           │
┌──────────────────────────────────────────────────────────│──────────────────┐
│                            FormExtension 进程             │                  │
│                                                          ▼                  │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                     EntryFormAbility                                   │  │
│  │                                                                        │  │
│  │  onAddForm(want) ──────────────────────────────────────────────────── ▶│  │
│  │    │                                                                   │  │
│  │    ├─▶ preferences.removePreferencesFromCacheSync() // 清缓存          │  │
│  │    ├─▶ preferences.getPreferencesSync() // 同步读取                    │  │
│  │    ├─▶ WidgetDataStoreManager.loadSync() // 加载数据                   │  │
│  │    ├─▶ WidgetPayloadBuilder.buildPayload() // 构建 payload             │  │
│  │    └─▶ formBindingData.createFormBindingData() // 返回数据             │  │
│  │                                                                        │  │
│  │  onUpdateForm(formId) ──────────────────────────────────────────────▶  │  │
│  │    └─▶ pushUpdate() // 推送最新数据                                    │  │
│  │                                                                        │  │
│  │  onFormEvent(formId, message) ──────────────────────────────────────▶  │  │
│  │    └─▶ pushUpdate() // 用户点击刷新按钮                                │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                          │                  │
│                                                          ▼                  │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                     Widget 页面组件 (@Entry)                           │  │
│  │                                                                        │  │
│  │  Widget2x2.ets / Widget2x4.ets / Widget4x4.ets                        │  │
│  │    │                                                                   │  │
│  │    ├─▶ @LocalStorageProp('payload') payloadStr: string = ''           │  │
│  │    │                                                                   │  │
│  │    ├─▶ aboutToAppear():                                                │  │
│  │    │     const parsed = WidgetPayloadParser.parse(this.payloadStr)     │  │
│  │    │     this.uiState = Widget2x2ViewModel.buildUIState(parsed)        │  │
│  │    │                                                                   │  │
│  │    └─▶ build(): 根据 uiState 渲染 UI                                   │  │
│  │                                                                        │  │
│  │  ┌────────────────────────────────────────────────────────────────┐   │  │
│  │  │               FormLink (卡片交互)                               │   │  │
│  │  │                                                                 │   │  │
│  │  │  action: 'router' → 跳转到主应用 UIAbility                      │   │  │
│  │  │  action: 'message' → 触发 onFormEvent() 刷新数据                │   │  │
│  │  └────────────────────────────────────────────────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 二、数据模型层次

### 2.1 数据存储层

```
WidgetDataStore (全局数据，v2 扁平结构)
└─ data: Record<accountId, WidgetAccountDataV2>
     └─ slots: Record<roleId, WidgetSlotData>
          ├─ gameId, nickname, server, level
          └─ rawJson (API 原始响应)

WidgetConfig (单个卡片配置)
├─ formId, formName, size
└─ slots: WidgetSlotRef[] (三元组：accountId/gameId/roleId)
```

**设计特点：**
- 扁平化结构，支持 O(1) 查询
- `data.{accountId}.slots.{roleId}` 层级，避免嵌套循环
- 使用 `"accountId/roleId"` 作为全局唯一的 slot 标识

### 2.2 Payload 传输层

```
WidgetPayloadItem (JSON 序列化后存入 LocalStorage)
└─ accounts: WidgetAccountPayloadItem[]
     └─ games: WidgetGamePayloadItem[]
          └─ roles: WidgetRolePayloadItem[]
               └─ roleId, nickname, server, rawJson
```

**设计特点：**
- 单个 JSON 字符串传递，避免多个 LocalStorage key
- Widget 组件通过 `@LocalStorageProp('payload')` 接收

### 2.3 解析层 (ParsedPayload)

```
ParsedPayload (解析后的 Model 对象)
└─ getAllRoles(): ParsedRole[]
     ├─ gameId, roleId, currentStamina, maxStamina, recoverySeconds
     └─ rawJson (保留原始数据，供 ViewModel 解析额外字段)
```

**职责：**
- 将 JSON 字符串解析为类型安全的对象
- 提供便捷的访问方法（`getAllRoles()`、`isSingleGame`）

### 2.4 ViewModel 层 (UI State)

```
Widget2x2ViewModel.buildUIState(parsed) → Widget2x2UIState
Widget2x4ViewModel.buildUIState(parsed) → Widget2x4UIState
Widget4x4ViewModel.buildUIState(parsed) → Widget4x4UIState
```

**UIState 特点：**
- 所有字段都是 View 层直接可用的形式（`Resource`、`string`、`number`）
- 包含计算后的展示字段（`isFull`、`recoveryTime`、`staminaColorType`）
- 多语言资源已转换（`gameNameResource`、`labelResource`）

---

## 三、关键设计约束

### 3.1 FormExtensionAbility 进程隔离

**约束：** FormExtensionAbility 不能导入 HSP 模块（core 是 HSP）。

```typescript
// ❌ 禁止：FormExtensionAbility 导入 core 模块
import { GenshinRepository } from 'core'; // 会 crash

// ✅ 正确：在主应用进程构建数据，通过 Preferences 传递
// EntryAbility 中：
WidgetDataStoreBuilder.buildAndSave(context);

// EntryFormAbility 中：
const dataStore = WidgetDataStoreManager.loadSync(context);
```

### 3.2 同步 API 要求

**约束：** `onAddForm()` 返回后 FormExtension 进程只有 10 秒存活时间。

```typescript
onAddForm(want: Want): formBindingData.FormBindingData {
  // ✅ 同步读取
  this.prefs = preferences.getPreferencesSync(this.context, { name: 'widget_configs' });
  const dataStore = WidgetDataStoreManager.loadSync(this.context);
  
  // 立即构建并返回
  const payload = WidgetPayloadBuilder.buildPayload(config, dataStore);
  return formBindingData.createFormBindingData(payload.toLocalStorageRecord());
}
```

### 3.3 Widget 组件装饰器规则

**约束：** Widget 使用 `@Component`（V1 体系），不能使用 `@ComponentV2`。

```typescript
// ✅ 正确：Widget 使用 @Component（V1 体系）
@Component
export struct Widget2x2 {
  @LocalStorageProp('payload') payloadStr: string = '';
}

// ❌ 错误：Widget 使用 @ComponentV2（Widget 渲染引擎不支持）
@ComponentV2
export struct Widget2x2 { ... }
```

### 3.4 FormLink 事件机制

```typescript
// 卡片刷新按钮
FormLink({
  action: 'message',  // 触发 FormExtensionAbility.onFormEvent()
  params: { 'method': 'refresh' }
}) {
  Image($r('app.media.ic_refresh'))
}

// 卡片点击跳转
FormLink({
  action: 'router',
  abilityName: 'EntryAbility',
  params: { 'target': 'GenshinDailyDetail' }
}) {
  Column() { ... }
}
```

**三种 action 类型：**
| action | 用途 | 触发回调 |
|--------|------|----------|
| `router` | 跳转到指定 UIAbility | UIAbility.onCreate |
| `message` | 自定义消息 | FormExtensionAbility.onFormEvent() |
| `call` | 后台启动 UIAbility | UIAbility.onCreate（不调度到前台） |

---

## 四、数据流完整路径

```
用户添加卡片到桌面
       │
       ▼
EntryFormAbility.onAddForm(want)
       │
       ├─▶ 解析 want.parameters 获取 formId, formName, dimension
       │
       ├─▶ preferences.removePreferencesFromCacheSync() // 清除缓存
       │
       ├─▶ preferences.getPreferencesSync() // 同步读取配置
       │
       ├─▶ loadPendingConfig(formName) // 加载用户在配置页选择的 slots
       │
       ├─▶ WidgetDataStoreManager.loadSync() // 加载全局数据
       │
       ├─▶ WidgetPayloadBuilder.buildPayload(config, dataStore)
       │    │
       │    └─▶ 构建 WidgetPayload
       │         ├─ 从 config.slots 或预配置或 fallback 确定 slotKeys
       │         ├─ 按 accountId 分组
       │         └─ 序列化为 JSON
       │
       ├─▶ WidgetImageDownloader.loadFormImagesSync() // 加载派遣头像
       │
       └─▶ formBindingData.createFormBindingData({ payload, formImages })
            │
            ▼
Widget 页面组件接收数据
       │
       ├─▶ @LocalStorageProp('payload') payloadStr: string
       │
       ├─▶ aboutToAppear():
       │    const parsed = WidgetPayloadParser.parse(this.payloadStr)
       │    this.uiState = Widget2x2ViewModel.buildUIState(parsed)
       │
       └─▶ build(): 根据 uiState 渲染 UI
            ├─ Widget2x2SingleGame (单游戏详细布局)
            └─ Widget1x2ContentView × 2 (多游戏紧凑布局)
```

---

## 五、目录结构

```
entry/src/main/ets/widget/
├── pages/                          # Widget 页面组件 (@Entry)
│   ├── Widget2x2.ets
│   ├── Widget2x4.ets
│   ├── Widget4x4.ets
│   ├── Widget1x2Genshin.ets
│   ├── Widget1x2StarRail.ets
│   └── Widget1x2ZZZ.ets
│
├── components/                     # Widget 组件 (@Component)
│   ├── Widget2x2SingleGame.ets
│   ├── Widget2x4SingleGame.ets
│   ├── Widget4x4SingleGame.ets
│   └── Widget1x2ContentView.ets
│
├── models/                         # 数据模型
│   ├── WidgetUIStates.ets         # UI State 模型
│   ├── WidgetModels.ets           # LocalStorage 数据模型
│   ├── WidgetConfig.ets           # 配置存储模型
│   └── WidgetDataStore.ets        # 全局数据存储模型
│
├── viewmodel/                      # ViewModel 层
│   ├── Widget2x2ViewModel.ets
│   ├── Widget2x4ViewModel.ets
│   └── Widget4x4ViewModel.ets
│
└── utils/                          # 工具函数
    ├── WidgetPayloadParser.ets    # Payload 解析器
    ├── WidgetPayloadBuilder.ets   # Payload 构建器
    ├── WidgetDataHelper.ets       # 数据解析工具
    ├── WidgetDataStoreManager.ets # Preferences 读写
    ├── WidgetConfigStore.ets      # 配置存储
    └── WidgetImageDownloader.ets  # 图片下载管理
```

---

## 六、测试策略

### 6.1 单元测试（entry/src/test/）

**ViewModel 单元测试：**
- Widget2x2ViewModel.buildUIState() 状态转换测试
- WidgetPayloadParser.parse() JSON 解析测试
- WidgetDataHelper 工具函数测试

### 6.2 集成测试（entry/src/ohosTest/）

**EntryFormAbility 生命周期测试：**
- onAddForm() 正确返回 payload
- onUpdateForm() 正确推送更新
- onFormEvent() 正确响应刷新事件

### 6.3 手动测试

**Widget 配置流程：**
1. 长按桌面添加 Widget
2. 选择尺寸 → 选择游戏 → 选择角色
3. 确认配置，验证 Widget 显示正确数据

**Widget 刷新流程：**
1. 等待定时刷新（系统触发 onUpdateForm）
2. 手动点击刷新按钮（触发 onFormEvent）
3. 验证数据更新正确

---

## 七、优化点清单

### 优化点 1：EntryFormAbility 代码复杂度过高

**现状：**
- `onAddForm()` 方法超过 200 行
- 包含大量调试日志
- Mock 数据构建逻辑混在业务代码中

**改进方案：**
- 拆分为多个私有方法
- 移除调试日志，使用 Logger 统一管理
- Mock 数据构建独立为工具函数

### 优化点 2：WidgetPayloadBuilder 逻辑复杂

**现状：**
- `buildPayload()` 方法嵌套循环多
- fallback 逻辑分散在多处

**改进方案：**
- 使用策略模式统一 slot 选择逻辑
- 将 fallback 逻辑抽取为独立方法

### 优化点 3：Widget 页面组件职责不清晰

**现状：**
- `aboutToAppear()` 中包含解析逻辑
- 多个页面组件有重复代码

**改进方案：**
- 抽取公共基类或 mixin
- 将解析逻辑移到 ViewModel 层

### 优化点 4：图片下载机制不够健壮

**现状：**
- 派遣头像下载失败后没有 fallback
- 图片缓存机制不完善

**改进方案：**
- 添加默认占位图
- 实现图片缓存清理机制

### 优化点 5：测试覆盖不足

**现状：**
- Widget 相关测试文件缺失
- ViewModel 没有单元测试

**改进方案：**
- 补充 ViewModel 单元测试
- 补充 PayloadParser 单元测试

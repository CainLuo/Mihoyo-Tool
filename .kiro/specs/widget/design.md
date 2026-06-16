# Widget 多账号混合显示 - 设计文档

## 核心设计原则

1. **单一数据源**：所有 Widget 共享一份数据，数据包含所有账号的所有游戏角色
2. **配置与数据分离**：Widget 配置只存「选择哪几个 slot」，数据存储 rawJson
3. **复用 core 模块**：API 请求、Parser 全部复用 core 模块
4. **默认行为**：没有配置时，默认显示第一个账号的数据

## 一、数据层级说明

### 1.1 三层结构

```
米游社账号 (Account)
  └── 游戏 (Game: genshin/starrail/zzz)
        └── 角色 (Role: UID + 服务器)
              └── 便签数据 (DailyNote rawJson)
```

### 1.2 实际案例

```
账号 348366494 (旅行者A)
  ├── genshin
  │     ├── roleUid: 250375401, server: cn_gf01, roleName: 荧
  │     └── roleUid: 123456789, server: cn_qd01, roleName: 空
  ├── starrail
  │     └── roleUid: 809182009, server: prod_gf_cn, roleName: 开拓者
  └── zzz
        └── roleUid: 999888777, server: prod_gf_cn, roleName: 代理人

账号 182692936 (旅行者B)
  └── genshin
        └── roleUid: 109050292, server: cn_gf01, roleName: 空
```

## 二、存储结构设计

### 2.1 全局数据存储（WidgetDataStore）

所有 Widget 共享的一份数据，包含所有账号所有游戏角色的便签 rawJson。

**存储位置**：Preferences 文件名 `widget_data_store`，Key `global_data`

**字段命名说明**：与 core 模块 `GameRoleRow` 保持一致：
- `accountId` — 米游社账号 UID（string）
- `gameId` — 游戏 ID（GameId 枚举值）
- `roleId` — 游戏内 UID（对应 core 的 `roleId` 字段）
- `server` — 服务器大区标识

```json
{
  "version": 1,
  "updatedAt": 1715040000,
  "accounts": [
    {
      "accountId": "348366494",
      "accountName": "旅行者A",
      "games": [
        {
          "gameId": "genshin",
          "roles": [
            {
              "roleId": "250375401",
              "nickname": "荧",
              "server": "cn_gf01",
              "rawJson": "{\"retcode\":0,\"message\":\"OK\",\"data\":{\"current_resin\":88,\"max_resin\":200,\"resin_recovery_time\":\"53401\",\"finished_task_num\":4,\"total_task_num\":4,\"is_extra_task_reward_received\":true,\"current_expedition_num\":5,\"max_expedition_num\":5,\"expeditions\":[...],\"current_home_coin\":270,\"max_home_coin\":2400,\"transformer\":{...}}}"
            },
            {
              "roleId": "123456789",
              "nickname": "空",
              "server": "cn_qd01",
              "rawJson": "{\"retcode\":0,\"message\":\"OK\",\"data\":{...}}"
            }
          ]
        },
        {
          "gameId": "starrail",
          "roles": [
            {
              "roleId": "809182009",
              "nickname": "开拓者",
              "server": "prod_gf_cn",
              "rawJson": "{\"retcode\":0,\"message\":\"OK\",\"data\":{\"current_stamina\":200,\"max_stamina\":300,\"current_reserve_stamina\":2400,...}}"
            }
          ]
        },
        {
          "gameId": "zzz",
          "roles": [
            {
              "roleId": "999888777",
              "nickname": "代理人",
              "server": "prod_gf_cn",
              "rawJson": "{\"retcode\":0,\"message\":\"OK\",\"data\":{\"energy\":{\"progress\":{\"current\":180,\"max\":240}},...}}"
            }
          ]
        }
      ]
    },
    {
      "accountId": "182692936",
      "accountName": "旅行者B",
      "games": [
        {
          "gameId": "genshin",
          "roles": [
            {
              "roleId": "109050292",
              "nickname": "空",
              "server": "cn_gf01",
              "rawJson": "{\"retcode\":0,\"message\":\"OK\",\"data\":{\"current_resin\":140,\"max_resin\":200,...}}"
            }
          ]
        }
      ]
    }
  ]
}
```

#### 字段说明

**WidgetDataStore 字段**：

| 字段 | 类型 | 说明 |
|-----|------|-----|
| version | number | 数据版本号，用于迁移 |
| updatedAt | number | 数据更新时间戳（秒） |
| accounts | array | 账号列表 |

**WidgetAccount 字段**：

| 字段 | 类型 | 说明 |
|-----|------|-----|
| accountId | string | 米游社账号 UID |
| accountName | string | 账号昵称（用于显示） |
| games | array | 该账号下的游戏列表 |

**WidgetGame 字段**：

| 字段 | 类型 | 说明 |
|-----|------|-----|
| gameId | string | 游戏 ID（GameId 枚举值：genshin/starrail/zzz） |
| roles | array | 该游戏下的角色列表 |

**WidgetRole 字段**：

| 字段 | 类型 | 说明 |
|-----|------|-----|
| roleId | string | 游戏内 UID（对应 core 的 `GameRoleRow.roleId`） |
| nickname | string | 游戏内昵称 |
| server | string | 服务器大区标识（如 cn_gf01、prod_gf_cn） |
| rawJson | string | API 原始响应 JSON 字符串 |

### 2.2 Widget 配置存储（WidgetConfig）

每个 Widget 只存储选择的 slot 索引，不存储 rawJson。

**存储位置**：Preferences 文件名 `widget_configs`，Key `form_{formId}`

```json
{
  "formId": "12345",
  "formName": "widget_1x2_genshin",
  "size": "2x2",
  "slots": [
    { "accountId": "348366494", "gameId": "genshin", "roleId": "250375401" },
    { "accountId": "182692936", "gameId": "genshin", "roleId": "109050292" }
  ]
}
```

**字段说明**：

| 字段 | 类型 | 说明 |
|-----|------|-----|
| formId | string | Widget 实例 ID |
| formName | string | 卡片模板名（如 `widget_1x2_genshin`、`widget_1x2_starrail`、`widget_1x2_zzz`、`widget_2x2`、`widget_2x4`、`widget_4x4`） |
| size | string | Widget 尺寸（1x2/2x2/2x4/4x4） |
| slots | array | 选择的槽位列表（三元组：accountId + gameId + roleId） |

**Slot 三元组说明**：

| 字段 | 类型 | 说明 |
|-----|------|-----|
| accountId | string | 米游社账号 UID |
| gameId | string | 游戏 ID |
| roleId | string | 游戏内 UID |

**formName 用途**：
- 用于区分 1x2 的三个游戏专属模板
- `WidgetPayloadBuilder.getDefaultSlots()` 根据 `formName` 过滤游戏类型：
  - `widget_1x2_genshin` → 只返回原神角色
  - `widget_1x2_starrail` → 只返回星铁角色
  - `widget_1x2_zzz` → 只返回绝区零角色
  - 其他模板 → 返回所有游戏角色

### 2.3 默认行为

如果 `slots` 为空（用户未配置），则根据 Widget 尺寸自动选择：

1. 从 `WidgetDataStore.accounts[0]` 取第一个账号
2. 根据 Widget 尺寸选择该账号的前 N 个游戏角色：
   - 1×2: 第一个游戏的第一个角色
   - 2×2: 前两个游戏的第一个角色（或同一游戏的两个角色）
   - 4×4: 前三个游戏的第一个角色

### 2.4 尺寸与槽位数量

| Widget 尺寸 | 最大 slots 数量 | 说明 |
|------------|----------------|------|
| 1×2 | 1 | 单个角色 |
| 2×2 | 2 | 两个角色 |
| 2×4 | 2 | 两个角色 |
| 4×4 | 2 | 两个角色（两个 2x4 布局纵向排列） |

## 三、数据流设计

### 3.1 App 进程：数据同步

```
App 启动 / 手动刷新
  ↓
遍历所有账号的所有游戏角色
  ↓
调用 core ApiService 拉取便签数据
  ↓
更新 WidgetDataStore.accounts[i].games[j].roles[k].rawJson
  ↓
保存到 Preferences
  ↓
触发所有 Widget 刷新
```

### 3.2 App 进程：配置 Widget

```
用户在 WidgetSettings 页面选择 slots
  ↓
选择 { accountId, gameId, roleId } 三元组
  ↓
保存 WidgetConfig（只存三元组）
  ↓
调用 formProvider.openFormManager() 添加 Widget
```

### 3.3 FormExtension 进程：渲染 Widget

```
onAddForm / onUpdateForm 被调用
  ↓
读取 WidgetConfig（获取 slots 列表）
  ↓
读取 WidgetDataStore（获取 rawJson）
  ↓
根据 slots 提取对应的 rawJson
  ↓
调用 core Parser 解析 rawJson
  ↓
构建 LocalStorage payload
  ↓
渲染 Widget UI
```

### 3.4 FormExtension 进程：自动刷新数据

```
onUpdateForm 被调用（定时/系统触发）
  ↓
读取 WidgetDataStore
  ↓
遍历所有 accounts.games.roles
  ↓
调用 core ApiService 拉取最新便签数据
  ↓
更新 rawJson 并保存
  ↓
触发 UI 刷新
```

### 3.5 数据流图

```
┌─────────────────────────────────────────────────────────────┐
│                        App 进程                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │ 数据同步      │    │ ApiService   │    │ Preferences  │  │
│  │ 遍历所有角色  │ → │ 拉取便签数据  │ → │ 保存rawJson  │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│  ┌──────────────┐              ↓                           │
│  │ WidgetSettings│    formProvider.updateForm()            │
│  │ 配置slots    │                                           │
│  └──────────────┘                                           │
└─────────────────────────────────────────────────────────────┘
                               │
                               ↓
┌─────────────────────────────────────────────────────────────┐
│                 FormExtensionAbility 进程                    │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │ Preferences  │    │ ApiService   │    │ Parser       │  │
│  │ 读取Data+Conf│ → │ 自动刷新数据  │ → │ 解析rawJson  │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│                              ↓                              │
│                    LocalStorage → Widget 渲染               │
└─────────────────────────────────────────────────────────────┘
```

## 四、LocalStorage Payload 结构

### v1.1 新格式（当前使用）

传递给 Widget 组件的数据结构：

```json
{
  "payload": "{\"version\":1,\"updatedAt\":1715040000,\"accounts\":[{\"accountId\":\"348366494\",\"accountName\":\"旅行者A\",\"games\":[{\"gameId\":\"genshin\",\"roles\":[{\"roleId\":\"250375401\",\"nickname\":\"荧\",\"server\":\"cn_gf01\",\"rawJson\":\"{\\\"retcode\\\":0,\\\"data\\\":{...}}\"}]}]}]}"
}
```

Widget 组件：
1. 解析 `payload` 获取 `ParsedPayload` 对象
2. 遍历 `accounts[i].games[j].roles[k]` 获取角色数据
3. 从 `rawJson` 解析游戏专属数据（原神/星铁/绝区零）

### 解析器

**WidgetPayloadParser.ets**:
- `parsePayload(payloadJson: string): ParsedPayload`
- `ParsedPayload` 类包含 `accounts: ParsedAccount[]`
- `ParsedRole` 自动检测游戏类型并解析体力数据

**WidgetSlotDataParser.ets**:
- `parseSlotJson(slotJson: string): ParsedSlotData`
- 解析 `rawJson` 中的游戏专属字段

### 旧格式（已废弃，不再支持）

```json
{
  "slotCount": "2",
  "widgetSize": "2x2",
  "slot0Json": "...",
  "slot0GameId": "genshin"
}
```

旧格式相关代码已全部删除，不再兼容。

## 五、配置页面设计

### 5.1 数据来源

配置页面展示「所有账号的所有游戏角色」供用户选择：

```typescript
// 从 WidgetDataStore 读取（已在数据同步时填充）
const dataStore = await WidgetDataStoreManager.load();
for (const account of dataStore.accounts) {
  for (const game of account.games) {
    for (const role of game.roles) {
      // 显示：账号名 + 游戏名 + 角色名 + roleId
    }
  }
}
```

### 5.2 Slot 选择 UI

```
┌────────────────────────────────────────────────┐
│  选择要显示的角色（最多 2 个）                    │
├────────────────────────────────────────────────┤
│  ☑ 旅行者A - 原神                               │
│      荧 · roleId: 250375401 · 国服              │
│      体力 88/200                                │
├────────────────────────────────────────────────┤
│  ☐ 旅行者A - 原神                               │
│      空 · roleId: 123456789 · 渠道服            │
│      体力 140/200                               │
├────────────────────────────────────────────────┤
│  ☐ 旅行者A - 星穹铁道                           │
│      开拓者 · roleId: 809182009                 │
│      开拓力 200/300                             │
├────────────────────────────────────────────────┤
│  ☐ 旅行者A - 绝区零                             │
│      代理人 · roleId: 999888777                 │
│      电量 180/240                               │
├────────────────────────────────────────────────┤
│  ☑ 旅行者B - 原神                               │
│      空 · roleId: 109050292 · 国服              │
│      体力 50/200                                │
└────────────────────────────────────────────────┘
```

## 六、刷新策略

### 6.1 App 触发刷新

- App 同步便签数据后，更新 WidgetDataStore
- 调用 `formProvider.setFormNextRefreshTime(formId, 5)` 触发 Widget 刷新

### 6.2 FormExtension 自动刷新

- 系统定时调用 `onUpdateForm`（最短 5 分钟间隔）
- 遍历所有角色，调用 ApiService 拉取最新数据
- 更新 WidgetDataStore

## 七、错误处理

### 7.1 数据为空

- 显示占位提示："暂无数据"

### 7.2 账号已删除

- 配置中的 accountId 找不到对应数据
- 显示占位提示："账号已移除"

### 7.3 数据解析失败

- 返回默认空数据，不崩溃
- 记录错误日志

## 八、核心类设计

### 8.1 数据模型

```
entry/src/main/ets/widget/models/
├── WidgetDataStore.ets    ← 全局数据存储模型
├── WidgetAccount.ets      ← 账号模型
├── WidgetGame.ets         ← 游戏模型
├── WidgetRole.ets         ← 角色模型（含 rawJson）
└── WidgetConfig.ets       ← Widget 配置模型（只存 slot 索引）
```

### 8.2 存储管理

```
entry/src/main/ets/widget/utils/
├── WidgetDataStoreManager.ets  ← 管理 WidgetDataStore 的读写
└── WidgetConfigStore.ets       ← 管理 WidgetConfig 的读写
```

### 8.3 Payload 构建

```
entry/src/main/ets/widget/utils/
└── WidgetPayloadBuilder.ets    ← 从 DataStore + Config 构建 LocalStorage payload
```

---

## 九、ArkTS Widget Form 技术限制

> ⚠️ **重要**: Widget Form 使用独立的渲染引擎，存在以下严格限制

### 9.1 禁止使用的语法

| 禁止项 | 原因 | 替代方案 |
|-------|------|---------|
| `??` 空值合并运算符 | ArkTS 严格模式不支持 | `x !== undefined ? x : default` |
| `?.` 可选链 | ArkTS 严格模式不支持 | 显式 null 检查 + 直接访问 |
| `Type \| null` union 类型 | Widget 渲染引擎不支持 | 使用非 null 类型 + 默认值 |
| `console.log` / `hilog` | Form 不支持日志系统 | 无法调试，只能通过行为推断 |
| `any` / `ESObject` 类型 | ArkTS 严格模式禁止 | 显式接口类型 + 类型断言 |

### 9.2 @Builder 方法调用规范

```typescript
// ❌ 错误 — 会导致 Widget 黑屏
build() {
  if (this.isMini) {
    this.buildMiniLayout();  // 分号会导致问题
  }
}

// ✅ 正确
build() {
  if (this.isMini) {
    this.buildMiniLayout()  // 无分号
  }
}
```

### 9.3 @Component 装饰器

Widget 必须使用 `@Component`（V1 体系），不支持 `@ComponentV2`。

### 9.4 数据流调试

由于 Form 不支持日志，调试时需要：
1. 在 `EntryFormAbility` 中使用 `Logger`（主进程支持）
2. 验证 `WidgetPayloadBuilder.buildPayload()` 输出的 JSON 结构
3. 通过 Widget 行为推断渲染逻辑是否正确

### 9.5 FormExtension 异步初始化

**重要**: FormExtension 在独立进程中运行，所有存储初始化必须异步完成：

```typescript
// ❌ 错误 — 同步调用异步方法，导致后续 load() 失败
private initStoreSync(): void {
  WidgetConfigStore.init(this.context);  // 异步但不等待
  WidgetDataStoreManager.init(this.context);  // 异步但不等待
}

// ✅ 正确 — 等待初始化完成后再调用 load()
private async initStoreAsync(): Promise<void> {
  await WidgetConfigStore.init(this.context);
  await WidgetDataStoreManager.init(this.context);
}

onAddForm(want: Want): formBindingData.FormBindingData {
  // 立即返回占位数据
  const placeholder = this.createPlaceholderData(config);
  
  // 异步初始化并更新
  this.initStoreAsync().then(() => {
    this.loadDataAndUpdate(formId, config);
  });
  
  return placeholder;
}
```

---

## 十、文件清单

### 10.1 数据模型

| 文件 | 职责 |
|-----|------|
| `entry/src/main/ets/widget/models/WidgetDataStore.ets` | 全局数据存储模型 |
| `entry/src/main/ets/widget/models/WidgetAccount.ets` | 账号模型 |
| `entry/src/main/ets/widget/models/WidgetGame.ets` | 游戏模型 |
| `entry/src/main/ets/widget/models/WidgetRole.ets` | 角色模型（含 rawJson） |
| `entry/src/main/ets/widget/models/WidgetConfig.ets` | Widget 配置模型 |

### 10.2 存储管理

| 文件 | 职责 |
|-----|------|
| `entry/src/main/ets/widget/utils/WidgetDataStoreManager.ets` | 全局数据读写 |
| `entry/src/main/ets/widget/utils/WidgetConfigStore.ets` | 配置读写 |

### 10.3 数据构建

| 文件 | 职责 |
|-----|------|
| `entry/src/main/ets/widget/utils/WidgetDataStoreBuilder.ets` | 从 DB 构建数据 |
| `entry/src/main/ets/widget/utils/WidgetPayloadBuilder.ets` | 构建 LocalStorage payload |
| `entry/src/main/ets/widget/utils/WidgetPayloadParser.ets` | 解析 v1.1 payload 格式 |
| `entry/src/main/ets/widget/utils/WidgetSlotDataParser.ets` | 解析游戏专属数据 |

### 10.4 Widget 组件

| 文件 | 职责 |
|-----|------|
| `entry/src/main/ets/widget/pages/Widget2x2.ets` | 2x2 卡片入口 |
| `entry/src/main/ets/widget/pages/Widget4x4.ets` | 4x4 卡片入口 |
| `entry/src/main/ets/widget/components/WidgetCardContent.ets` | 卡片内容组件 |
| `entry/src/main/ets/widget/components/WidgetSlotRenderer.ets` | Slot 渲染组件 |

### 10.5 Form Extension

| 文件 | 职责 |
|-----|------|
| `entry/src/main/ets/entryformability/EntryFormAbility.ets` | Form 生命周期管理 |


---

## 十一、黑屏问题注意事项（关键）

> ⚠️ **重要**: FormExtension 进程生命周期限制导致 Widget 可能黑屏

### 11.1 问题根因

1. **FormExtension 进程只能存活 10 秒**：`onAddForm()` 返回后，进程在 10 秒内无新回调就会被杀掉
2. **异步更新可能不执行**：`onAddForm()` 中调用异步方法更新数据，可能在进程被杀前未完成
3. **设备重启使用 `onAddForm()` 返回值**：如果返回空数据，卡片会永久显示空状态

### 11.2 解决方案

**必须在 `onAddForm()` 中同步读取并返回真实数据**：

```typescript
onAddForm(want: Want): formBindingData.FormBindingData {
  // ✅ 同步读取 Preferences
  const prefs = preferences.getPreferencesSync(this.context, 'widget_data_store');
  const json = prefs.getSync('global_data', '') as string;
  
  if (json.length > 0) {
    // 返回真实数据
    return formBindingData.createFormBindingData({ payload: json });
  }
  
  // 兜底：返回空数据
  return formBindingData.createFormBindingData({
    payload: '{"version":1,"updatedAt":0,"accounts":[]}'
  });
}
```

### 11.3 Preferences 同步 API（API 10+）

| 方法 | 说明 |
|-----|------|
| `getPreferencesSync(context, name)` | 同步获取 Preferences 实例 |
| `getSync(key, defaultValue)` | 同步读取数据 |
| `getAllSync()` | 同步获取所有数据 |

### 11.4 Widget 组件空数据处理

Widget 组件必须能正确处理空数据（`accounts: []`），显示占位 UI 而不是黑屏：

```typescript
build() {
  Column() {
    if (this.parsedPayload.accounts.length === 0) {
      // 显示"暂无数据"占位 UI
      Text('暂无数据')
        .fontSize(12)
        .fontColor($r('app.color.colorTextSecondary'))
    } else {
      // 正常渲染
      // ...
    }
  }
}
```

### 11.5 参考资料

- **详细调研报告**：`.kiro/specs/widget/research-notes.md`
- **技术笔记**：`design/research/FormKit-Notes.md`（第 14-16 节）
- **官方文档**：[卡片数据同步异常](https://developer.huawei.com/consumer/cn/doc/architecture-guides/news-v1_2-ts_c80-0000002411768157)


---

## 十二、Widget LocalStorage 使用规范

### 12.1 官方示例验证

根据官方示例仓库 [CardInfoRefresh](https://gitee.com/harmonyos_samples/CardInfoRefresh/blob/master/entry/src/main/ets/widget/pages/WidgetCard.ets)，Widget 必须创建 LocalStorage 实例并传给 `@Entry`：

```typescript
// ✅ 正确写法（官方示例）
let storageLocal = new LocalStorage();

@Entry(storageLocal)
@Component
struct WidgetCard {
  @LocalStorageProp('formTime') formTime: string = '';
  @LocalStorageProp('formId') formId: string = '';
  @LocalStorageProp('cardList') cardList: Array<CardListItemData> = [];
}
```

### 12.2 数据注入机制

`FormExtensionAbility.onAddForm()` 返回的数据会自动注入到 Widget 的 LocalStorage：

1. **FormExtensionAbility** 调用 `formBindingData.createFormBindingData(data)`
2. **系统框架** 将 `data` 对象的字段注入到 Widget 的 LocalStorage
3. **Widget 组件** 通过 `@LocalStorageProp('fieldName')` 读取数据

### 12.3 支持的数据格式

`createFormBindingData()` 支持两种格式：

| 格式 | 示例 | 使用场景 |
|------|------|---------|
| 对象 | `{ formId: '123', formTime: '...' }` | 多字段传递（官方示例） |
| Record | `{ payload: '...' }` | 单一 JSON 字段（本项目） |

### 12.4 本项目的实现

本项目使用单一 `payload` 字段传递完整 JSON：

```typescript
// EntryFormAbility.onAddForm()
const dataStore = WidgetDataStoreManager.loadSync(this.context);
const payload = WidgetPayloadBuilder.buildPayload(config, dataStore);
const record = payload.toLocalStorageRecord(); // { payload: "..." }
return formBindingData.createFormBindingData(record);
```

```typescript
// Widget 组件
let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct Widget2x2 {
  @LocalStorageProp('payload') payloadJson: string = '';
  
  // 解析 payload
  private get parsed(): ParsedPayload {
    return parsePayload(this.payloadJson);
  }
}
```

### 12.5 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| Widget 黑屏 | LocalStorage 实例未正确初始化 | 确保使用 `let storage = new LocalStorage();` + `@Entry(storage)` |
| 数据为空 | `onAddForm()` 返回时 Preferences 中无数据 | 确保 App 进程在启动时写入初始 payload |
| 设备重启后数据丢失 | 只依赖 `onAddForm()` 返回值 | Preferences 作为持久化存储，`onAddForm()` 同步读取 |

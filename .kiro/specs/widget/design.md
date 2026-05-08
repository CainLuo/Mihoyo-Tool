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
| 4×4 | 3 | 三个角色 |

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

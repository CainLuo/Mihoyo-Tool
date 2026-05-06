# Widget 多账号混合显示 - 任务列表

## 任务概览

| 阶段 | 任务 | 优先级 | 状态 |
|-----|------|-------|------|
| 1 | 设计并实现数据模型 | P0 | done |
| 2 | 实现全局数据存储 | P0 | done |
| 3 | 实现配置存储 | P0 | done |
| 4 | 实现 WidgetDataStoreBuilder | P0 | done |
| 5 | 实现 WidgetPayloadBuilder | P0 | done |
| 6 | 重构 Widget 组件 | P0 | done |
| 7 | 重构配置页面 | P1 | done |
| 8 | 更新 EntryFormAbility | P1 | done |
| 9 | 数据同步集成 | P1 | done |
| 10 | 测试验证 | P1 | pending |
| 11 | v1.1 Payload 格式迁移 | P0 | in-progress |

---

## Phase 1: 数据模型 ✅

### Task 1.1: 创建 WidgetRole 模型 ✅

**文件**: `entry/src/main/ets/widget/models/WidgetRole.ets` ✅

**内容**:
- `roleId` — 游戏内 UID（对应 core 的 GameRoleRow.roleId）
- `nickname` — 游戏内昵称
- `server` — 服务器大区标识
- `rawJson` — API 原始响应 JSON 字符串

---

### Task 1.2: 创建 WidgetGame 模型 ✅

**文件**: `entry/src/main/ets/widget/models/WidgetGame.ets` ✅

**内容**:
- `gameId` — 游戏 ID
- `roles` — 角色列表

---

### Task 1.3: 创建 WidgetAccount 模型 ✅

**文件**: `entry/src/main/ets/widget/models/WidgetAccount.ets` ✅

**内容**:
- `accountId` — 米游社账号 UID
- `accountName` — 账号昵称
- `games` — 游戏列表

---

### Task 1.4: 创建 WidgetDataStore 模型 ✅

**文件**: `entry/src/main/ets/widget/models/WidgetDataStore.ets` ✅

**内容**:
- `version` — 数据版本号
- `updatedAt` — 更新时间戳
- `accounts` — 账号列表
- `getRole()` — 根据三元组获取角色
- `getAllSlots()` — 获取所有 slot 列表
- `WidgetSlotRef` — Slot 引用类（三元组）

---

### Task 1.5: 创建 WidgetConfig 模型 ✅

**文件**: `entry/src/main/ets/widget/models/WidgetConfig.ets` ✅

**内容**:
- `formId` — Widget 实例 ID
- `size` — Widget 尺寸
- `slots` — 选择的槽位列表（WidgetSlotRef[]）
- `WidgetSize` 枚举
- `getMaxSlots()` 函数

---

## Phase 2: 数据存储 ✅

### Task 2.1: 实现 WidgetDataStoreManager ✅

**文件**: `entry/src/main/ets/widget/utils/WidgetDataStoreManager.ets` ✅

**内容**:
- `init(context)` — 初始化 Preferences
- `save(data)` — 保存全局数据
- `load()` — 加载全局数据
- `clear()` — 清除数据

---

### Task 2.2: 实现 WidgetConfigStore ✅

**文件**: `entry/src/main/ets/widget/utils/WidgetConfigStore.ets` ✅

**内容**:
- `init(context)` — 初始化 Preferences
- `saveConfig(config)` — 保存 Widget 配置
- `loadConfig(formId)` — 加载 Widget 配置
- `deleteConfig(formId)` — 删除 Widget 配置
- `getAllConfigs()` — 获取所有配置

---

## Phase 3: 数据构建 ✅

### Task 3.1: 实现 WidgetDataStoreBuilder ✅

**文件**: `entry/src/main/ets/widget/utils/WidgetDataStoreBuilder.ets` ✅

**内容**:
- `buildFromDB()` — 从数据库读取所有账号数据，构建完整 WidgetDataStore
- `refreshAndSave()` — 重新构建并保存
- `initAndSave()` — 首次初始化
- `updateRoleRawJson()` — 增量更新单个角色

**验收标准**:
- [x] 正确读取所有账号的游戏角色数据
- [x] 填充 rawJson 字段
- [x] 复用 core Repository

---

### Task 3.2: 实现 WidgetPayloadBuilder ✅

**文件**: `entry/src/main/ets/widget/utils/WidgetPayloadBuilder.ets` ✅

**内容**:
- `buildPayload(config, dataStore)` — 根据配置提取 slots 数据
- `buildForFormExtension()` — 为 FormExtension 构建 LocalStorage 数据
- `getDefaultSlots()` — 默认行为（取第一个账号的前 N 个角色）
- `WidgetSlotData` 类 — 单个 Slot 的完整数据
- `WidgetPayload` 类 — 构建结果，含 `toLocalStorageRecord()` 方法

**验收标准**:
- [x] 正确匹配 slots 三元组
- [x] 处理 slots 为空时的默认行为
- [x] 构建符合 Widget 组件预期的 LocalStorage 格式

---

## Phase 4: Widget 组件 ✅

### Task 4.1: 创建 WidgetSlotDataParser ✅

**文件**: `entry/src/main/ets/widget/utils/WidgetSlotDataParser.ets` ✅

**内容**:
- `parseSlotJson()` — 从 WidgetSlotData JSON 解析为 ParsedSlotData
- `parseGenshinData()` — 解析原神便签数据
- `parseStarRailData()` — 解析星铁便签数据
- `parseZZZData()` — 解析绝区零便签数据
- `ParsedSlotData` 类 — 统一的解析结果

**验收标准**:
- [x] 支持原神/星铁/绝区零三种游戏
- [x] 解析失败时返回默认值，不崩溃
- [x] 字段与 UI 显示需求对齐

---

### Task 4.2: 创建 WidgetSlotRenderer 组件 ✅

**文件**: `entry/src/main/ets/widget/components/WidgetSlotRenderer.ets` ✅

**内容**:
- 接收单个 ParsedSlotData
- 根据 slotSize 选择布局（1x2 迷你布局 / 2x2 标准布局）
- 支持 1x2、2x2、2x4、4x4 四种尺寸
- 渲染：游戏名 + UID + 体力 + 恢复时间 + 额外数据行

**验收标准**:
- [x] 支持原神/星铁/绝区零三种游戏
- [x] 星铁特殊布局（后备开拓力在右侧）
- [x] 字体大小、颜色符合规范
- [x] 体力颜色：0-30% 红色，30-70% 橙色，70-100% 游戏主题色

---

### Task 4.3: 更新 WidgetCardContent 组件 ✅

**文件**: `entry/src/main/ets/widget/components/WidgetCardContent.ets` ✅

**内容**:
- 支持新格式（slot0Json、slot1Json、slot2Json）
- 向后兼容旧格式（game0Json、game1Json、game2Json）
- 自动检测 payload 格式并选择渲染方式

**验收标准**:
- [x] 新旧格式自动切换
- [x] 单 Slot 使用 WidgetSlotRenderer
- [x] 多 Slot 使用 Column 布局

---

### Task 4.4: 更新 Widget2x2 页面（保持现有实现）✅

**文件**: `entry/src/main/ets/widget/pages/Widget2x2.ets` ✅

**说明**: 现有实现已支持通过 WidgetCardContent 自动适配新格式，无需修改。

---

## Phase 5: 配置页面

### Task 5.1: 重构 WidgetConfigViewModel ✅

**文件**: `entry/src/main/ets/viewmodel/WidgetConfigViewModel.ets` ✅

**内容**:
- 修改为支持多账号 slot 选择
- slots 数组存储选中的 WidgetSlotRef（三元组）
- 根据尺寸限制 slots 数量

**验收标准**:
- [x] 支持跨账号选择游戏
- [x] 预览正确显示选中的 slots

---

### Task 5.2: 重构配置页面 UI ✅

**文件**: `entry/src/main/ets/pages/WidgetSettings.ets` ✅

**内容**:
- Slot 选择步骤改为显示所有账号的所有角色
- 支持跨账号选择
- 更新预览组件

**验收标准**:
- [x] 显示所有账号的游戏列表
- [x] 支持多选（受尺寸限制）
- [x] 预览实时更新

---

### Task 5.3: 更新 WidgetConfigPreview 组件 ✅

**文件**: `entry/src/main/ets/components/widgetconfig/WidgetConfigPreview.ets` ✅

**内容**:
- 接收 selectedSlots 数组
- 渲染对应数量的 Slot 预览
- 正确显示渐变背景

**验收标准**:
- [x] 预览与实际 Widget 一致
- [x] 渐变背景正确

---

## Phase 6: EntryFormAbility 集成 ✅

### Task 6.1: 更新 onAddForm ✅

**文件**: `entry/src/main/ets/entryformability/EntryFormAbility.ets` ✅

**内容**:
- 解析 want.parameters 中的 widgetConfig
- 保存 Widget 配置到 WidgetConfigStore
- 构建初始 payload

**验收标准**:
- [x] 配置正确保存
- [x] Widget 正确显示初始数据

---

### Task 6.2: 更新 onUpdateForm ✅

**文件**: `entry/src/main/ets/entryformability/EntryFormAbility.ets` ✅

**内容**:
- 读取全局数据 WidgetDataStore
- 根据 formId 读取配置 WidgetConfig
- 构建更新 payload

**验收标准**:
- [x] 数据正确更新
- [x] 处理配置不存在的情况

---

### Task 6.3: 更新 onRemoveForm ✅

**文件**: `entry/src/main/ets/entryformability/EntryFormAbility.ets` ✅

**内容**:
- 删除 Widget 配置

**验收标准**:
- [x] 配置正确清理

---

## Phase 7: 数据同步 ✅

### Task 7.1: 更新数据同步逻辑 ✅

**文件**: 
- `core/src/main/ets/repository/SyncQueueRunner.ets` ✅
- `entry/src/main/ets/entryability/EntryAbility.ets` ✅

**内容**:
- 在 `SyncQueueRunner` 中添加 `registerOnComplete()` 回调机制
- 在 `EntryAbility.onCreate()` 中注册 Widget 数据刷新回调
- 同步完成后自动调用 `WidgetDataStoreBuilder.refreshAndSave()`

**验收标准**:
- [x] 同步后 Widget 数据更新
- [x] 回调机制可扩展（支持多个回调）

---

## 测试计划

### 单元测试

- [ ] 数据模型序列化/反序列化
- [ ] Payload 构建逻辑
- [ ] 配置存储读写

### 集成测试

- [ ] 添加 Widget 流程
- [ ] Widget 数据刷新
- [ ] 多账号混合显示
- [ ] 删除账号后的处理

### UI 测试

- [ ] 配置页面交互
- [ ] 预览正确性
- [ ] Widget 点击跳转

---

## Phase 11: v1.1 Payload 格式迁移 🔄

### 背景说明

旧格式（已废弃）：
```json
{
  "slotCount": "2",
  "widgetSize": "2x2",
  "slot0Json": "...",
  "slot0GameId": "genshin",
  "slot1Json": "...",
  "slot1GameId": "starrail"
}
```

新格式（v1.1 设计规范）：
```json
{
  "payload": "{\"version\":1,\"updatedAt\":1715040000,\"accounts\":[...]}"
}
```

### Task 11.1: 创建 WidgetPayloadParser ✅

**文件**: `entry/src/main/ets/widget/utils/WidgetPayloadParser.ets` ✅

**内容**:
- `ParsedPayload` 类 — 解析后的完整 payload
- `ParsedAccount` 类 — 账号数据
- `ParsedGame` 类 — 游戏数据
- `ParsedRole` 类 — 角色数据（含体力解析）
- `parsePayload()` 函数 — 解析 payload JSON

**注意事项**:
- ArkTS 严格模式禁止使用 `ESObject` 和 `any` 类型
- 所有 JSON.parse() 结果必须显式类型断言
- 使用 `as PayloadJson` 等接口类型

---

### Task 11.2: 更新 WidgetPayloadBuilder ✅

**文件**: `entry/src/main/ets/widget/utils/WidgetPayloadBuilder.ets` ✅

**内容**:
- `WidgetPayloadItem` 类 — 新 payload 结构
- `WidgetAccountPayloadItem` 类
- `WidgetGamePayloadItem` 类
- `WidgetRolePayloadItem` 类
- `toLocalStorageRecord()` — 输出单一 `payload` 字段

**注意事项**:
- 对象字面量必须显式类型（`const record: Record<string, string> = {}`）
- 禁止直接返回 `{ 'payload': ... }`

---

### Task 11.3: 更新 WidgetCardContent ✅

**文件**: `entry/src/main/ets/widget/components/WidgetCardContent.ets` ✅

**内容**:
- 接收 `payloadJson: string` prop（从父组件传入）
- 使用 `parsePayload()` 解析
- 使用 `parseSlotJson()` 解析游戏专属数据
- 根据 `isSingleGame` 和角色数量选择渲染方式

**注意事项**:
- 不再使用 `@LocalStorageProp`，改为普通 prop
- 父组件负责从 `@LocalStorageProp('payload')` 读取并传入

---

### Task 11.4: 更新 Widget 页面 ✅

**文件**:
- `entry/src/main/ets/widget/pages/Widget2x2.ets` ✅
- `entry/src/main/ets/widget/pages/Widget2x4.ets` ✅
- `entry/src/main/ets/widget/pages/Widget4x4.ets` ✅
- `entry/src/main/ets/widget/pages/Widget1x2Genshin.ets` ✅
- `entry/src/main/ets/widget/pages/Widget1x2StarRail.ets` ✅
- `entry/src/main/ets/widget/pages/Widget1x2ZZZ.ets` ✅

**内容**:
- 使用 `@LocalStorageProp('payload')` 接收单一 JSON
- 传递给 `WidgetCardContent` 或 `WidgetSlotRenderer`

---

### Task 11.5: 删除旧格式代码 ✅

**已删除**:
- 所有 `slot0Json`、`slot1Json`、`slot2Json` 字段
- 所有 `slot0GameId`、`slot1GameId`、`slot2GameId` 字段
- `slotCount` 字段
- 旧格式兼容代码

---

### Task 11.6: 修复 ArkTS 严格模式编译错误 ⏳

**编译错误**（已修复）:
1. ✅ `ESObject` 类型限制 — 改用显式接口类型
2. ✅ `any` 类型禁止 — 改用显式类型断言
3. ✅ 对象字面量无类型 — 声明变量后赋值

**待验证**:
- [ ] 编译通过
- [ ] Widget 显示正确
- [ ] 1x2 单游戏卡片正常
- [ ] 2x2 多游戏卡片正常
- [ ] 2x4 卡片正常
- [ ] 4x4 卡片正常

---

### 调试笔记

**问题**: 所有 Widget 不显示内容

**排查步骤**:
1. 检查 `WidgetPayloadBuilder.toLocalStorageRecord()` 输出
2. 检查 `parsePayload()` 解析结果
3. 检查 `WidgetCardContent.buildSlotData()` 传参
4. 检查 `parseSlotJson()` 解析游戏数据

**关键数据流**:
```
FormExtension
  → WidgetPayloadBuilder.buildPayload()
  → WidgetPayload.toLocalStorageRecord()
  → { 'payload': JSON.stringify(...) }
  → LocalStorage
  → @LocalStorageProp('payload')
  → WidgetCardContent({ payloadJson })
  → parsePayload(payloadJson)
  → ParsedPayload
  → WidgetSlotRenderer({ data })
```

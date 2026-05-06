# Widget 多账号混合显示 - 开发状态记录

**最后更新**: 2026-05-06

## 当前进度

核心功能已完成，需要构建验证。

### 最近修复（2026-05-06）

1. **WidgetStepIndicator Light Mode 适配**
   - 未激活圆圈边框颜色改为 `rgba(255, 255, 255, 0.3)`
   - 确保浅色模式下圆圈可见

2. **Widget2x2 新格式支持**
   - 添加新格式字段：`slot0Json`、`slot1Json`、`slot2Json`
   - 解析新格式数据获取游戏 ID 列表
   - 正确渲染渐变背景

3. **build-profile.json5 签名配置修复**
   - 启用 `default` 签名配置（用于 mock/debug）
   - 将绝对路径改为相对路径

### 已完成的 Phase

| Phase | 任务 | 状态 |
|-------|------|------|
| 1 | 数据模型（WidgetRole, WidgetGame, WidgetAccount, WidgetDataStore, WidgetConfig） | ✅ |
| 2 | 数据存储（WidgetDataStoreManager, WidgetConfigStore） | ✅ |
| 3 | 数据构建（WidgetDataStoreBuilder, WidgetPayloadBuilder, WidgetSlotDataParser, WidgetSlotRenderer） | ✅ |
| 4 | Widget 组件（WidgetCardContent 支持新格式） | ✅ |
| 5 | 配置页面（WidgetConfigViewModel, WidgetSettings, WidgetConfigPreview） | ✅ |
| 6 | EntryFormAbility 集成 | ✅ |
| 7 | 数据同步集成（SyncQueueRunner 回调机制） | ✅ |

### 最后修改的文件

1. `core/src/main/ets/repository/SyncQueueRunner.ets`
   - 添加 `SyncCompleteCallback` 类型
   - 添加 `registerOnComplete()` 方法
   - 添加 `clearOnCompleteCallbacks()` 方法
   - 在 `runTasks()` 完成后触发回调

2. `entry/src/main/ets/entryability/EntryAbility.ets`
   - 导入 `SyncQueueRunner`, `WidgetDataStoreBuilder`, `WidgetDataStoreManager`
   - 在 `CoreInitializer.initCore()` 成功后初始化 `WidgetDataStoreManager`
   - 注册同步完成回调：`SyncQueueRunner.registerOnComplete(() => WidgetDataStoreBuilder.refreshAndSave())`

---

## 待办事项

### 1. 测试验证（Phase 10）

目前 tasks.md 中标记为 pending。

需要验证的场景：
- [ ] 添加 Widget 流程
- [ ] Widget 数据刷新
- [ ] 多账号混合显示
- [ ] 删除账号后的处理
- [ ] 同步完成后 Widget 自动更新

### 2. 可能需要检查的问题

根据打开的编辑器文件，有以下潜在问题需要确认：

#### 2.1 旧 Widget 组件文件（重要）

以下组件使用旧的 `WidgetGameData` 模型，**尚未迁移到新架构**：

**1x2 单游戏页面**：
- `entry/src/main/ets/widget/pages/Widget1x2Genshin.ets`
- `entry/src/main/ets/widget/pages/Widget1x2StarRail.ets`
- `entry/src/main/ets/widget/pages/Widget1x2ZZZ.ets`

**1x2 单游戏内容组件**：
- `entry/src/main/ets/widget/components/Widget1x2Content.ets`
- `entry/src/main/ets/widget/components/Widget1x2StarRailContent.ets`

**2x2 / 4x4 单游戏组件**：
- `entry/src/main/ets/widget/components/Widget2x2SingleGame.ets`
- `entry/src/main/ets/widget/components/Widget4x4SingleGame.ets`

**通用渲染组件**：
- `entry/src/main/ets/widget/components/WidgetStaminaRing.ets`
- `entry/src/main/ets/widget/components/WidgetStarRailExtraRows.ets`
- `entry/src/main/ets/widget/components/WidgetZZZExtraRows.ets`
- `entry/src/main/ets/widget/components/WidgetCompactGameRow.ets`

**新架构组件**（已创建）：
- `entry/src/main/ets/widget/components/WidgetSlotRenderer.ets` — 新的统一渲染组件
- `entry/src/main/ets/widget/components/WidgetCardContent.ets` — 已更新，支持新旧两种格式

**当前状态**：
- `WidgetCardContent` 已支持新格式（`slot0Json`, `slot1Json`, `slot2Json`）和旧格式（`game0Json`, `game1Json`, `game2Json`）的自动检测
- 旧的 Widget 页面（1x2 Genshin/StarRail/ZZZ）仍然使用旧格式
- 需要决定：是统一迁移到新架构，还是保持兼容

#### 2.2 WidgetDataBuilder.ets（旧的构建器）

文件：`entry/src/main/ets/widget/utils/WidgetDataBuilder.ets`

这是旧的构建器，构建 `WidgetGameData` 格式的数据。

新架构使用：
- `entry/src/main/ets/widget/utils/WidgetDataStoreBuilder.ets` — 构建全局数据
- `entry/src/main/ets/widget/utils/WidgetPayloadBuilder.ets` — 构建单个 Widget 的 payload

**当前状态**：两个构建器共存，旧的用于旧 Widget 格式，新的用于新格式。

#### 2.3 模型文件

**旧模型**：
- `entry/src/main/ets/widget/models/WidgetModels.ets` — 包含 `WidgetGameData`, `WidgetAccountData`, `WidgetSingleGameData`

**新模型**：
- `entry/src/main/ets/widget/models/WidgetRole.ets`
- `entry/src/main/ets/widget/models/WidgetGame.ets`
- `entry/src/main/ets/widget/models/WidgetAccount.ets`
- `entry/src/main/ets/widget/models/WidgetDataStore.ets`
- `entry/src/main/ets/widget/models/WidgetConfig.ets`

### 3. 潜在的清理工作

**迁移方案 A（推荐）：渐进式迁移**
1. 保留旧的 Widget 组件和模型，确保现有功能不受影响
2. 新 Widget 实例使用新架构（通过 WidgetConfig 页面配置）
3. 旧 Widget 实例继续使用旧格式
4. 后续逐步迁移旧组件

**迁移方案 B：完全迁移**
1. 将所有 Widget 页面（1x2 Genshin/StarRail/ZZZ, 2x2, 4x4）更新为使用 `WidgetSlotRenderer`
2. 删除旧的 `WidgetModels.ets` 和 `WidgetDataBuilder.ets`
3. 需要大量改动，风险较高

**当前建议**：
- 采用方案 A，保持向后兼容
- `WidgetCardContent` 已支持新旧格式自动检测
- 新架构专注于多账号混合显示的 2x2 Widget

---

## 架构说明

### 数据流

```
DB (rawJson) 
  → WidgetDataStoreBuilder.buildFromDB() 
  → WidgetDataStore (存储所有账号数据)
  → WidgetDataStoreManager.save() (持久化到 Preferences)

同步完成 
  → SyncQueueRunner.onCompleteCallbacks 
  → WidgetDataStoreBuilder.refreshAndSave()

Widget 刷新 
  → EntryFormAbility.onUpdateForm()
  → WidgetPayloadBuilder.buildPayload(config, dataStore)
  → formProvider.updateForm()
```

### 配置存储

- `WidgetDataStore` — 全局数据，所有 Widget 共享
- `WidgetConfig` — 每个 Widget 实例的配置（选择的 slots）
- `WidgetSlotRef` — 三元组（accountId, gameId, roleId）

---

## 继续开发步骤

1. 运行构建验证：
   ```bash
   export DEVECO_SDK_HOME='/Applications/DevEco-Studio.app/Contents/sdk'
   /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleHap -p product=mock
   ```

2. 检查 Widget 功能：
   - 添加 2x2 Widget（使用 WidgetConfig 页面配置）
   - 验证多账号混合显示
   - 验证同步后 Widget 数据更新

3. 如需迁移旧 Widget 组件：
   - 参考 `WidgetSlotRenderer.ets` 的实现
   - 将 `WidgetGameData` 替换为 `ParsedSlotData`
   - 统一使用 `WidgetCardContent`

4. 如有问题，查看：
   - `design.md` — 设计文档
   - `tasks.md` — 任务列表
   - 新架构文件：
     - `WidgetDataStore.ets`, `WidgetConfig.ets`
     - `WidgetDataStoreBuilder.ets`, `WidgetPayloadBuilder.ets`
     - `WidgetSlotRenderer.ets`, `WidgetCardContent.ets`


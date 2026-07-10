# Home 模块架构设计文档

## 一、现状分析

### 1.1 文件结构

```
entry/src/main/ets/
├── pages/
│   └── Home.ets                    # 页面（~170 行）
├── viewmodel/
│   └── HomeViewModel.ets           # ViewModel（839 行）
├── models/
│   └── HomeModels.ets              # UI State 模型（192 行）
└── components/home/
    ├── HomeContent.ets             # ❌ 冗余：未被使用（48 行）
    ├── HomeSkeletonView.ets        # 骨架屏
    ├── HomePlaceholderView.ets     # 空态占位
    ├── UserGameSection.ets         # 账号游戏卡片区
    ├── UserGameSectionHeader.ets   # 账号标题行
    ├── GameToolCard.ets            # 游戏卡片
    ├── GameToolCardHeader.ets      # 卡片标题
    ├── GameToolCardContent.ets     # 卡片内容
    ├── GameStaminaBlock.ets        # 体力进度块
    ├── GameDataRow.ets             # 数据行
    ├── AccountSkeletonCard.ets     # 骨架卡片
    └── SkeletonBlock.ets           # 骨架色块
```

### 1.2 问题详情

#### 问题 1：`HomeContent.ets` 冗余

- **现象**：`HomeContent` 组件定义了根据 `viewState` 切换渲染的逻辑
- **实际情况**：`Home.ets` 的 `build()` 方法直接实现了相同逻辑，没有使用 `HomeContent`
- **影响**：增加维护成本，可能引起混淆

#### 问题 2：`HomeViewModel` 过大（839 行）

**方法分布**：

| 方法名 | 行数估算 | 职责 |
|--------|----------|------|
| `loadData()` | ~80 | 冷启动加载入口 |
| `refresh()` / `forceRefresh()` | ~50 | 手动刷新 |
| `onGeetestResult()` | ~40 | Geetest 回调 |
| `syncDailyNote()` | ~50 | 单角色同步 |
| `syncIfNeeded()` / `syncAllDailyNotes()` | ~60 | 批量同步 |
| `loadDailyNoteSnapshot()` | **~250** | **三游戏数据解析** |
| `buildRoleCards()` | ~40 | 构建 UI State |
| 其他辅助方法 | ~100 | 定时器、工具函数 |

**核心问题**：`loadDailyNoteSnapshot()` 方法包含了原神、星铁、绝区零三套游戏的详细解析逻辑，每套约 80-100 行，这些逻辑应该抽取到独立的 Parser 类。

**对比 Widget 模块**：
- Widget 模块有专门的 `WidgetPayloadParser` 和 `WidgetDataHelper`
- Home 模块的解析逻辑直接写在 ViewModel 里，违反单一职责原则

---

## 二、设计方案

### 2.1 移除 `HomeContent.ets`

**删除理由**：
1. `Home.ets` 已实现完整的 viewState 切换逻辑
2. `HomeContent` 没有被任何组件引用
3. 保留会增加维护成本

**风险评估**：低风险
- 该组件未被 import
- 删除后不影响任何功能

### 2.2 HomeViewModel 拆分评估

**结论：暂不拆分**

**原因分析**：

1. **当前职责清晰**
   - ViewModel 负责数据加载、状态管理、业务逻辑
   - 数据解析虽然代码量大，但逻辑线性、易于理解
   - 已有 `GenshinDailyNoteParser`、`StarRailDailyNoteParser`、`ZZZDailyNoteParser` 处理解析

2. **`loadDailyNoteSnapshot()` 的职责**
   - 该方法主要做两件事：读取 DB + 调用 Parser + 构建 UI State
   - 真正的 JSON 解析由 `*Parser` 完成
   - 该方法只是把 Parser 结果映射到 `GameNoteSnapshotVM`
   - 这正是 ViewModel 应该做的事（把业务数据转换为 UI State）

3. **与 Widget 模块对比**
   - Widget 模块的 `WidgetPayloadParser` 是因为 FormExtensionAbility 不能导入 core 模块
   - Home 模块没有这个限制，可以直接使用 core 的 Parser
   - `loadDailyNoteSnapshot()` 实际上是"Mapper"而非"Parser"

4. **拆分代价大于收益**
   - 如果抽取 `HomeNoteSnapshotMapper`，需要传入 Parser 结果，增加一层间接
   - 代码可读性不会明显提升（只是从一个文件挪到另一个文件）
   - 增加文件数量，增加理解成本

**保留现有结构的理由**：
- 代码虽有 839 行，但方法职责清晰
- 每个方法都是 ViewModel 应该做的事
- 不存在跨多个 ViewModel 复用的逻辑
- 不违反 MVVM 规范

### 2.3 替代优化建议（可选）

如果未来需要优化，可以考虑：

1. **抽取 `GameDataRowBuilder`**：如果 `loadDailyNoteSnapshot()` 中的数据行构建逻辑变复杂
2. **抽取 `GameNoteSnapshotMapper`**：如果其他页面也需要相同的映射逻辑

当前阶段不执行这些优化，等待实际需求驱动。

---

## 三、测试策略

### 3.1 移除 `HomeContent.ets` 验证

- 编译验证：确保没有编译错误
- 搜索验证：确认没有引用

### 3.2 不新增测试

- 本次重构只是删除冗余代码，不涉及新增功能
- 现有测试应保持通过

---

## 四、实施步骤

| 步骤 | 操作 | 验证方式 |
|------|------|----------|
| 1 | 搜索 `HomeContent` 引用 | 确认只有注释引用 |
| 2 | 删除 `HomeContent.ets` | 编译通过 |
| 3 | 更新 CHANGELOG.md | 记录删除原因 |

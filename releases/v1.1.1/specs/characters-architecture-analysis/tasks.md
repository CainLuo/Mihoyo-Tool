# Characters 模块架构优化任务清单

## 任务 1：创建 genshin 子目录及组件

**状态**：已完成

**操作**：
1. 创建 `components/characters/genshin/` 目录
2. 创建 `GenshinTopLeftBadge.ets`（从 `genshinTopLeft()` 提取）
3. 创建 `GenshinBottomBar.ets`（从 `genshinBottomBar()` 提取）

**验收标准**：
- [x] 目录已创建
- [x] 两个组件文件已创建
- [x] 编译通过

---

## 任务 2：创建 starrail 子目录及组件

**状态**：已完成

**操作**：
1. 创建 `components/characters/starrail/` 目录
2. 创建 `StarRailTopLeftBadge.ets`
3. 创建 `StarRailBottomBar.ets`

**验收标准**：
- [x] 目录已创建
- [x] 两个组件文件已创建
- [x] 编译通过

---

## 任务 3：创建 zzz 子目录及组件

**状态**：已完成

**操作**：
1. 创建 `components/characters/zzz/` 目录
2. 创建 `ZZZTopLeftBadge.ets`
3. 创建 `ZZZBottomBar.ets`

**验收标准**：
- [x] 目录已创建
- [x] 两个组件文件已创建
- [x] 编译通过

---

## 任务 4：重构 CharacterCard.ets

**状态**：已完成

**操作**：
1. 删除 6 个 `@Builder` 方法
2. 导入新组件
3. 在 `build()` 中使用新组件

**验收标准**：
- [x] `CharacterCard.ets` 中无 `@Builder` 方法
- [x] 编译通过

---

## 任务 5：更新 CHANGELOG.md

**状态**：已完成

**验收标准**：
- [x] 已添加重构记录

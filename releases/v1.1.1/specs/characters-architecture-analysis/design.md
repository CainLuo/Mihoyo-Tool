# Characters 模块架构设计文档

## 一、现状分析

### 1.1 文件结构

```
entry/src/main/ets/components/characters/
├── AccountSwitchDialog.ets      # 账号切换弹窗
├── CharacterCard.ets            # ❌ 违规：包含 6 个 @Builder 方法
├── CharacterDataSource.ets      # LazyForEach 数据源
├── CharactersContent.ets       # 内容区（正常）
├── CharactersEmptyView.ets     # 空态视图（正常）
├── CharactersSkeleton.ets      # 骨架屏（正常）
└── GameTabBar.ets              # 游戏 Tab 栏（正常）
```

### 1.2 问题详情

`CharacterCard.ets` 中的 `@Builder` 方法：

| 方法名 | 行数 | 职责 | 应拆成 |
|--------|------|------|--------|
| `genshinTopLeft()` | ~15 | 原神左上角元素图标 | `GenshinTopLeftBadge.ets` |
| `starrailTopLeft()` | ~25 | 星铁左上角属性+命途图标 | `StarRailTopLeftBadge.ets` |
| `zzzTopLeft()` | ~30 | 绝区零左上角稀有度+属性+特性图标 | `ZZZTopLeftBadge.ets` |
| `genshinBottomBar()` | ~18 | 原神底部等级+好感度 | `GenshinBottomBar.ets` |
| `starrailBottomBar()` | ~12 | 星铁底部等级 | `StarRailBottomBar.ets` |
| `zzzBottomBar()` | ~20 | 绝区零底部等级+阵营图标 | `ZZZBottomBar.ets` |

---

## 二、设计方案

### 2.1 拆分原则

根据规范：
> 凡是有独立语义的 UI 块必须拆成独立的组件文件

拆分策略：
1. **按游戏拆分子目录**：`components/characters/` 下创建 `genshin/`、`starrail/`、`zzz/` 子目录
2. **统一命名**：`<Game>TopLeftBadge.ets` 和 `<Game>BottomBar.ets`
3. **保持 `CharacterCard.ets` 简洁**：只负责组合子组件

### 2.2 拆分后的目录结构

```
entry/src/main/ets/components/characters/
├── AccountSwitchDialog.ets
├── CharacterCard.ets               # 简化：只组合子组件
├── CharacterDataSource.ets
├── CharactersContent.ets
├── CharactersEmptyView.ets
├── CharactersSkeleton.ets
├── GameTabBar.ets
├── genshin/                        # 原神专用子组件
│   ├── GenshinTopLeftBadge.ets
│   └── GenshinBottomBar.ets
├── starrail/                       # 星铁专用子组件
│   ├── StarRailTopLeftBadge.ets
│   └── StarRailBottomBar.ets
└── zzz/                            # 绝区零专用子组件
    ├── ZZZTopLeftBadge.ets
    └── ZZZBottomBar.ets
```

### 2.3 组件参数设计

**TopLeftBadge 组件**：
```typescript
@ComponentV2
export struct GenshinTopLeftBadge {
  @Param element: string = '';  // 元素字符串（如 'Hydro'、'Pyro'）
}
```

**BottomBar 组件**：
```typescript
@ComponentV2
export struct GenshinBottomBar {
  @Param level: number = 0;
  @Param fetter: number = 0;  // 好感度
}
```

---

## 三、实施步骤

| 步骤 | 操作 | 验证方式 |
|------|------|----------|
| 1 | 创建 `genshin/` 目录 | 目录存在 |
| 2 | 创建 `GenshinTopLeftBadge.ets` | 编译通过 |
| 3 | 创建 `GenshinBottomBar.ets` | 编译通过 |
| 4 | 创建 `starrail/` 目录及组件 | 编译通过 |
| 5 | 创建 `zzz/` 目录及组件 | 编译通过 |
| 6 | 重构 `CharacterCard.ets` 使用新组件 | 编译通过 |
| 7 | 更新 CHANGELOG.md | 记录重构 |

---

## 四、测试策略

- 编译验证：每一步都确保编译通过
- 不新增单元测试（重构不改变行为）

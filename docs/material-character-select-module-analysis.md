# MaterialCharacterSelect 模块独立分析文档

> 生成时间：2026-10-24 | 作用 scope：`features/material/src/main/ets/pages/MaterialCharacterSelectPage.ets`（493 行）+ `MaterialCharacterSelectViewModel` + `CharacterSelectCard` 内嵌子组件
> 代码版本：`105c8d3`（本文档分析基线，2026-10-24 复核）

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 3 |
| Low | 3 |

**整体评级：A**

> 口径：skills `harmonyos-review` 官方 A-F 评级（0 Critical + 0 High，Medium ≤ 5）。旧百分制已废弃，原分 87/100 仅作历史参考。
>
> **债务点数**：3×2 + 3×1 = 9；密度 9 ÷ (493/100) ≈ 1.8（源行数只计页面文件）。

---

## 1. 文件清单

| 文件 | 类型 | 行数 | 职责 |
|------|------|------|------|
| `MaterialCharacterSelectPage.ets` | Page / @ComponentV2 | 360 | 角色选择页——游戏角色网格列表 + 多选（最多 4 个）+ 底部按钮栏 |
| `views/CharacterSelectCard.ets` | @ComponentV2 | 156 | 网格角色卡片（原内嵌于页面，M7 提取） |
| `viewmodel/MaterialCharacterSelectViewModel.ets` | @ObservedV2 ViewModel | 432 | 账号/角色加载、选中状态、历史记录、调用 `MaterialComputeService` |
| `builders/MaterialCharacterSelectPageBuilder.ets` | 路由 Builder | 22 | routerMap 的 `buildFunction`，把 `param` 强转为 interface 后透传 |

> 行数为 M7 重构后现状（原页面 493 / VM 448）；§2 / §6 保留重构前基线。

**直接导入依赖（15+）**：ThemeManager、UIContext/SymbolGlyphModifier/ComponentContent、AccountSwitchDialog、ViewState、GameId/Logger、MaterialCharacterSelectViewModel/Param/SelectableCharacterVM、MaterialComputeResult、MaterialTargetConfigParam、DialogDedup、MaterialRoutes（materialListRoute/materialTargetConfigRoute）、PlaceholderView、AppRoutes、GameIdUtil、GenshinElement、StarRailElement、ZZZElement。其中 `MaterialCharacterSelectParam`（L15）、`AppRoutes`（L23）、`gameIdToColor`（L24）只被导入、页面内未使用。

## 2. 架构分析（结构树）

```
MaterialCharacterSelect (@ComponentV2)
├── @Local vm: MaterialCharacterSelectViewModel / tm: ThemeManager
├── @Param detailStack: NavPathStack | null / param: MaterialCharacterSelectRouteParam | null
├── private uiContext / localStack: NavPathStack | null
├── aboutToAppear(): void → uiCtx 获取 + if(param) vm.init(gameId)（只用 gameId；param.accountId / roleUid 被忽略，VM 固定取账号下标 0 的首个该游戏角色）
├── @Monitor('vm.canStart') → onCanStartChanged() (空实现——自动刷新 UI)
├── build()
│   └── NavDestination (title=gameName + hideTitleBar(false))
│       ├── .menus(buildMenuItems()) — 历史记录 / 目标配置 / 切换账号（条件渲染）
│       ├── .onReady(ctx → localStack = ctx.pathStack)
│       └── .onShown() → vm.loadHistory()
│       └── Column
│           ├── if(viewState === LOADING) → LoadingProgress
│           ├── else if(viewState === EMPTY) → PlaceholderView
│           └── else → Scroll + GridRow({xs:4,sm:4,md:6,lg:8})
│               ├── ForEach(vm.characters) → CharacterSelectCard { onTap }
│               └── this.buildBottomBar()（同在 else 分支内）— 已选数量 + 开始计算按钮（enabled = canStart && !isSyncing）
├── buildMenuItems(): NavigationMenuItem[] — 动态构建三个菜单项
├── openHistory() → pushPathByName(materialListRoute(gameId)) 
├── openTargetConfig() → pushPathByName(materialTargetConfigRoute(gameId))
├── showAccountMenu() → ComponentContent + openCustomDialog (底部弹窗) → onSelect → vm.selectAccount(idx)（未 await / catch）
├── @Builder buildBottomBar() — Row(计数 + Button) + 阴影效果
├── async onStartTap(): Promise<void> — 核心流程:
│   ├── selectedCount === 0 → return
│   ├── hasSavedConfig() === false → showConfigRequiredDialog
│   ├── startCompute(selection) → SUCCESS/NO_NEEDS/NO_CONFIG/FAILED 四分支处理
│   └── SUCCESS → replacePathByName(materialListRoute(gameId), selection)
├── showConfigRequiredDialog(stack, selection) — AlertDialog + DialogDedup 防重复
└── CharacterSelectCard (@ComponentV2, 内嵌子组件)
    ├── @Param character / gameId / onTap / @Local tm
    ├── private badgeIcons(): Resource[] — 三游戏元素/命途/特性图标映射
    └── build() → Stack(头像 + 等级遮罩 + 左上图标 + 武器信息 + 选中标记)

MaterialCharacterSelectRouteParam (interface) — accountId / roleUid / gameId
```

**架构模式**：多状态视图（LOADING/EMPTY/NORMAL）+ 动态菜单 + DialogDedup 防重复交互。核心选择流程通过 async onStartTap 串联配置检查 → 计算 → 路由替换。

## 3. ArkTS 合规性检查

| 检查项 | 状态 | 说明 |
|--------|------|------|
| `@ComponentV2` + `struct` | ✅ 通过 | |
| CharacterSelectCard 内嵌 `@ComponentV2` | ✅ 通过 | 网格卡片独立组件，@Param 注入数据 |
| `interface MaterialCharacterSelectRouteParam` | ⚠️ 需关注 | 使用 interface 而非 class——路由参数推荐 class + 默认实例化（与 AppearanceSettingsPage 风格不一致）|
| @Monitor('vm.canStart') 空实现 | ⚠️ 需关注 | 仅用于触发 UI 刷新，实际无逻辑——可改用 @Watch 或直接依赖响应式更新 |
| ComponentContent + wrapBuilder | ✅ 通过 | 标准动态 Dialog 创建模式 |
| GridRow/GridCol 响应式列数 | ✅ 通过 | {xs:4,sm:4,md:6,lg:8} 适配不同屏幕宽度 |

**ArkTS 结论：通过（存在需关注项）**

## 4. 组件复用分析

- **CharacterSelectCard** 内嵌于本文件——可提取为独立组件（与 CharactersPage.ets 中的角色卡片功能相似但实现不同）
- **DialogDedup 工具类**：防重复弹框，已在多处复用——良好的跨页面模式
- **MaterialRoutes(materialListRoute/materialTargetConfigRoute)**：三游戏路由函数统一入口——避免硬编码路径
- **GameIdUtil(gameIdToName)**：三游戏通用工具——集中管理映射（`gameIdToColor` 仅被导入，未使用）

## 5. 安全审查

| 风险 | 级别 | 说明 |
|------|------|------|
| onStartTap 中 stack = this.localStack ?? this.detailStack 回退逻辑 | ⚠️ 低 | 三处使用（openHistory L181 / openTargetConfig L195 / onStartTap L285）；`localStack` 在 `onReady`（L137-139）赋值，早于任何用户点击，Builder 又从不传 `detailStack`，因此 `?? this.detailStack` 分支实际不可达，是死代码而非运行时风险 |
| showConfigRequiredDialog 的 DialogDedup | ✅ 信息 | `onDidDisappear`（L349-351）在按钮/外部/返回键关闭时统一 release，key 释放时机正确；原"无 try-catch 导致防重失效"判断不成立，已撤回 |

**安全结论：通过（存在需关注项）**

## 6. 风险清单

- [x] **中优先级**：`CharacterSelectCard` 内嵌在 493 行文件里——✅ 已提取为 `views/CharacterSelectCard.ets`（M7）
- [x] **中优先级**：路由参数 `MaterialCharacterSelectRouteParam` 使用 interface 而非 class——与项目其他路由参数风格不一致（如 AppearanceSettingsParam）；保留（改 class 属契约变更）
- [ ] **中优先级**：切换账号失败会卡在 LOADING——`selectAccount()`（VM L168-179）先设 `viewState = LOADING`、清空列表，再 `await loadCurrentAccount()`；后者经 `loadCharacters` 调用的 `getAvatarList`（L346 / L362 / L379）不在任何 try-catch 内（`loadHistory` 自带 catch；只有 `init()` 的 L133-162 包了 try）。页面 `showAccountMenu` 的 `onSelect`（L212-214）既不 await 也不 catch，异常变成 unhandled rejection，页面永久转圈。属行为变更，单独提交。
- [x] **低优先级**：@Monitor('vm.canStart') 仅触发 UI 刷新无逻辑——✅ 已删除（M7），Button.enabled 已绑定 vm.canStart
- [x] **低优先级**：`this.localStack ?? this.detailStack` 回退模式——✅ 已删除 `@Param detailStack` 与三处回退（M7），只保留 `localStack`
- [x] **低优先级**：死导入 / 死代码——✅ 已删除页面 `MaterialCharacterSelectParam` / `AppRoutes` / `getGameColor` / 未使用图标函数导入、`uiContext` 死字段，以及 VM 的 `getGameColor` / `getGameLogo` / `getGameName` 导入

*本文档仅分析，不修改代码。*

## 7. 重构执行备注（M7 · MaterialCharacterSelect）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 路由 | `custom_router_map.json:99-101`：`MaterialCharacterSelect` 的 `pageSourceFile` 是 `builders/MaterialCharacterSelectPageBuilder.ets`，**Builder 文件路径 / 函数名冻结** |
| 页面 | `builders/MaterialCharacterSelectPageBuilder.ets:7` 直接 import `pages/MaterialCharacterSelect`；页面移动需同步 Builder，但 M7 不建议移动 |
| 路由参数 | `MaterialCharacterSelectRouteParam` 在 Builder（`builders/...:11`）与页面（`pages/...:30`）各定义一份 interface；入口 `ToolsPage.ets:117-122` 实际 push 的是 VM 里的 class `MaterialCharacterSelectParam`（`viewmodel/MaterialCharacterSelectViewModel.ets:56`，`ToolsPage.ets:17` 导入）。三处字段（accountId / roleUid / gameId）必须一致；页面目前只消费 `gameId` |
| 测试 | `MaterialCharacterSelectViewModel`（448 行）**没有** Local Test；M7 只有 `MaterialCalcViewModel.test.ets` |
| 共享工具 | `MaterialRoutes`、`GameIdUtil`、`DialogDedup`、`PlaceholderView` 均被多个模块使用，不移动 |

### 重构范围（已执行）

- 页面 493 行、ViewModel 448 行，均接近 500 行阈值；本轮**不拆 VM**（无测试保护），只做页面结构清理。
- `CharacterSelectCard` 提取为 `views/CharacterSelectCard.ets`（156L），页面 493 → 360 行；卡片仍是 `@ComponentV2` + `@Param` 注入，状态归属不变。
- 删除空实现的 `@Monitor('vm.canStart')`；Button 已绑定 `vm.canStart`。
- 删除 `@Param detailStack` 与三处 `localStack ?? detailStack` 回退，只保留 `onReady` 获取的 `localStack`。
- 新增 `private get gameId()`，替换卡片与标题里重复的 `param !== null ? param.gameId : GameId.GENSHIN`。
- 删除页面 `uiContext` 死字段与死导入（`MaterialCharacterSelectParam` / `AppRoutes` / `getGameColor` / 图标函数），VM 删除未使用的 `getGameColor` / `getGameLogo` / `getGameName` 导入。
- `MaterialCharacterSelectRouteParam` 保持 interface（改 class 属契约变更）；切换账号失败卡 LOADING 属行为修复，单独提交。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. 无 Local Test：冒烟——角色选择页三游戏、网格响应式列数、多选上限 4、历史记录/目标配置/切换账号菜单、开始计算四分支（SUCCESS / NO_NEEDS / NO_CONFIG / FAILED）。

### 已知问题归属

- Medium（Param 用 interface）：保留，属契约变更。
- Medium（切换账号失败卡 LOADING）：单独提交（行为变更）。
- 页面 / VM 拆分：记录，待补测试后再做。

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 契约） | 页面 493 / VM 448 / Builder 22；路由 `custom_router_map.json:99-101`；Builder import L7、interface L11：页面 interface L30 | ✅ 全部精确匹配 |
| 第 2 轮（结构 + 行为） | aboutToAppear L53-58、@Monitor L63 空实现、GridRow L97 `{xs:4,sm:4,md:6,lg:8}`、menus L149 三项条件、buildBottomBar L232、onStartTap L279、CharacterSelectCard L360 + badgeIcons L368 | ✅ |
| 第 3 轮（全面复核） | 回退表达式实际 L181/L195/L285；`openHistory` 用 `pushPathByName`；无 Local Test；`NO_CONFIG` 枚举存在且页面有分支；`localStack` 已优先 | ✅ 修正 3 处（replace→push、行号、回退风险描述） |
| 第 4 轮（2026-10-27 逐条复核） | 摘要 Low 3 / 清单 Low 2 不符；回退分支可达性；DialogDedup release 时机；`selectAccount` 异常路径；导入使用情况；Tools 入口参数类型 | ✅ 撤回 1 条不成立的安全项、Low 回退项改述为死代码；新增 1 Medium（切换账号卡 LOADING）+ 1 Low（死导入）；§1 补 VM / Builder 行；路由参数契约补第三处定义 |
| 第 5 轮（2026-11-04 M7 执行后） | 页面 360L + `CharacterSelectCard` 156L + VM 432L；`@Monitor` / `detailStack` / `uiContext` / 死导入已删；`bash run.sh uat` 通过 | ✅ 行数与结构复核一致 |

# MaterialCalc 模块独立分析文档

> 生成时间：2026-10-24
> 代码版本：`105c8d3`（本文档分析基线，2026-10-24 复核）
> 作用 scope：`features/material/src/main/ets/pages/MaterialCalcPage.ets` + `MaterialCalcViewModel` + material-calc 子组件组（ContentView / EmptyView / LoadingView / LevelPicker）

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 1 |
| Medium | 4 |
| Low | 3 |

**整体评级：B**

> 口径：skills `harmonyos-review` 官方 A-F 评级（0 Critical + High ≤ 3）。旧百分制已废弃，原分 88/100 仅作历史参考。
>
> **High 判定理由**：`MaterialCalc` 既不在 `custom_router_map.json`，也不在任何 `.navDestination()` Builder 中，角色详情里的「材料计算」入口点击后无法打开本页——用户可直接感知（按 README §4 第 3 点"用户能否感知故障"口径）。其余 Medium 均以该入口修通为前提才会暴露。
>
> **为何「目标等级设置占位实现」定 Medium 而非 High**：按"用户能否感知故障"口径，当前用户根本进不了本页，能感知到的只有 H-1（入口无效），该故障只在 H-1 计一次；占位实现、EMPTY 被覆盖、材料行回退、init 卡 LOADING 四条均为入口后的潜伏缺陷，统一记 Medium。修 H-1 让页面可达时，应同步重评这四条（届时它们都会变成用户可感知故障，至少占位实现与材料行回退应升 High）。
>
> **债务点数**：1×3 + 4×2 + 3×1 = 14；密度 14 ÷ (111/100) ≈ 12.6（源行数只计页面文件 `MaterialCalcPage.ets` 111 行，与 README §2 口径一致）。

---

## 1. 文件清单

| 文件 | 类型 | 行数 | 职责 |
|------|------|------|------|
| `MaterialCalcPage.ets` | Page / @ComponentV2 | 111 | 单角色材料计算页，支持角色/武器/技能目标等级设置 |
| `viewmodel/MaterialCalcViewModel.ets` | @ObservedV2 ViewModel | 493 | 读本地 DB 组装角色/技能/材料 Section；目标等级 setter |
| `models/MaterialCalcModels.ets` | 模型 | 165 | `MaterialCalcCharacterVM` / `SkillTargetVM` / `MaterialSectionVM` / `LevelOptionVM` 等（被测试引用） |
| `components/materialcalc/`（8 个） | 子组件 | 781 | LevelPicker 137 / Character 134 / ContentView 81 / EmptyView 43 / Item 130 / LoadingView 34 / Section 115 / Skills 107 |

**直接导入依赖**：`ThemeManager`, `ViewState`, `MaterialCalcViewModel`, 4 个页面级子组件（ContentView / EmptyView / LoadingView / LevelPicker）、`LevelOptionVM`。另有 `MaterialCalcViewModelKeys`（L13）与 `GameId`（L19）被导入但页面内未使用。Character / Section / Skills / Item 由 `MaterialCalcContentView` 间接使用，页面不直接导入。

## 2. 架构分析（结构树）

```
MaterialCalc (@ComponentV2)
├── @Param param: MaterialCalcParam (accountId, roleUid, avatarId)
├── @Local vm: MaterialCalcViewModel
├── @Local showLevelPicker: boolean (弹窗可见性)
├── @Local levelPickerType: 'character' | 'weapon'
├── @Local levelOptions: LevelOptionVM[]
├── @Local tm: ThemeManager
├── aboutToAppear()
│   ├── vm.init(accountId, roleUid, avatarId)
│   └── levelOptions = vm.getLevelOptions()
├── build()
│   └── NavDestination
│       └── Column
│           ├── 条件渲染 (vm.viewState):
│           │   ├── LOADING → MaterialCalcLoadingView()
│           │   ├── EMPTY → MaterialCalcEmptyView()
│           │   └── DEFAULT → MaterialCalcContentView(...)
│           │       ├── character, skills, avatarSection, weaponSection
│           │       ├── onCharacterLevelTap → showLevelPicker = true
│           │       ├── onWeaponLevelTap → showLevelPicker = true（按钮在武器 Section 内，文案硬编码 'Lv.80→90'）
│           │       └── onSkillTap → 空实现（未实现）
│           └── LevelPicker 弹窗（覆盖在 Content 上）
│               ├── currentLevel: 根据 pickerType 动态选择
│               ├── onSelect → vm.setCharTargetLevel(level) / setWeaponTargetLevel(level)（→ recalculateMaterials() 空实现）
│               └── onDismiss → showLevelPicker = false
├── MaterialCalcBuilder (路由 Builder)
└── MaterialCalcPreview (@Preview)
```

**架构模式**：MVVM + 弹窗控制器——ViewModel 负责计算逻辑，页面管理弹窗可见性与类型选择。

**入口调用链（当前断开）**：`CharDetailMaterialCalcEntry` → `GenshinCharacterDetail.goToMaterialCalc()`（`GenshinCharacterDetailPage.ets:93-102`）→ `localStack.pushPathByName('MaterialCalc')`。该栈来自 `NavDestination.onReady`（`GenshinCharacterDetailPage.ets:135`），即 `MainPage.ets:415` 的 `Navigation(this.stack)`，它没有 `.navDestination()`，只能靠 routerMap 解析；而 `custom_router_map.json` 没有 `MaterialCalc` 条目，`Index.ets:8-16` 的 `pageBuilder` 也只处理 Launch / Main / PrivacyConsent。`MaterialCalcBuilder` 在全工程无引用。

## 3. ArkTS 合规性检查

| 检查项 | 状态 | 说明 |
|--------|------|------|
| `@ComponentV2` + `struct` | ✅ 通过 | |
| `@Param param: MaterialCalcParam` | ✅ 通过 | class + 默认实例化，正确 |
| @Local ViewModel | ✅ 通过 | |
| 三级条件渲染 (VIEWSTATE) | ✅ 通过 | LOADING / EMPTY / DEFAULT 分支完整 |
| 弹窗管理 (@Local showLevelPicker) | ✅ 通过 | ArkUI V2 弹窗模式 |
| 空实现标记 (onSkillTap) | ⚠️ 信息 | 技能等级选择器尚未实现，留空回调 |
| 未使用导入 | ⚠️ 信息 | `MaterialCalcViewModelKeys`（L13）、`GameId`（L19） |
| i18n | ⚠️ | `MaterialCalcSection.ets:62-63` 硬编码中文 `缺少 N 个材料` / `材料已足够`；`:44` 硬编码 `'Lv.80→90 ▼'` |

**ArkTS 结论：通过（存在轻微瑕疵）**

## 4. 组件复用分析

- **子组件已充分拆分**：ContentView、EmptyView、LoadingView、LevelPicker、Character、Section、Skills、Item — 8 个子组件覆盖所有展示场景
- **弹窗复用模式**：`LevelPicker` 独立封装，通过 visible + onSelect/onDismiss 控制，可复用于其他选择器场景（如技能等级）
- **跨游戏通用性**：ViewModel 接收 avatarId/accountId/roleUid 参数化配置，同一页面适配多游戏角色

## 5. 安全审查

| 风险 | 级别 | 说明 |
|------|------|------|
| onSkillTap 未实现（空回调） | ⚠️ 低 | 空回调不会崩溃但 UX 不完整；用户点击无反馈 |
| LevelPicker 动态数据源 | ✅ 无 | `levelOptions` 已是 `@Local`（`MaterialCalcPage.ets:34`），`getLevelOptions()`（VM L142-152）返回固定 `[1,20,40,50,60,70,80,90]`，不存在不同步 |

**安全结论：通过（存在需关注项）**

## 6. 风险清单

- [ ] **高优先级（H-1）**：页面不可达——`MaterialCalc` 未注册到 `resources/base/profile/custom_router_map.json`，`MainPage.ets:415` 的内层 `Navigation(this.stack)` 无 `.navDestination()`，`Index.ets:8-16` 的 `pageBuilder` 也无此分支；`GenshinCharacterDetailPage.ets:100` 的 `pushPathByName(AppRoutes.MATERIAL_CALC, ...)` 找不到目标页，角色详情的「材料计算」卡片点击无效。**修复建议**：在 routerMap 补 `{ name: 'MaterialCalc', pageSourceFile: 'src/main/ets/pages/MaterialCalcPage.ets', buildFunction: 'MaterialCalcBuilder' }`（属行为变更，单独提交）。
- [ ] **中优先级**：`vm.init()` 的前置查询失败会让页面卡在 LOADING —— `init()` 在 L80 先设 `viewState = LOADING`，随后 L83 `await CoreInitializer.bbsRepository.getGameRoles(accountId)` **不在任何 try-catch 内**（`loadData()` 自己的 try-catch 只覆盖 L91 之后）。页面 `aboutToAppear`（`MaterialCalcPage.ets:38`）直接调用 `this.vm.init(...)`，既不 `await` 也不 `catch`，因此 DB/仓库异常会变成 unhandled rejection，且 LOADING 永远不会离开。**修复建议**：把 `getGameRoles` 包进 try-catch，失败时 `viewState = EMPTY`（或 ERROR 并补页面分支），或让页面 `init().catch(...)` 兜底。
- [ ] **中优先级**：目标等级设置链路是占位实现——`setCharTargetLevel` / `setWeaponTargetLevel`（VM L97-109）只改 `charTargetLevel` / `weaponTargetLevel`，`recalculateMaterials()`（L488-492）为空；角色卡显示的是 `character.targetLevel`（`MaterialCalcCharacter.ets:56`），从未被 setter 更新；武器按钮文案硬编码 `'Lv.80→90 ▼'`（`MaterialCalcSection.ets:44`）；技能等级固定为 `10/10`（原神/星铁，L348-349、L376-377）或 `1/12`（ZZZ，L412-413），并非角色真实数据。用户选择等级后界面与材料均无变化。
- [ ] **中优先级**：角色不存在时 EMPTY 被覆盖为 DATA——`loadGenshinData/StarRailData/ZZZData` 在找不到 avatar 时设 `EMPTY` 后 `return`（L179-181 / L240-242 / L295-297），但 `loadData()` 随后无条件执行 L165 `viewState = DATA`，页面显示空白角色卡而不是 EmptyView。
- [ ] **中优先级**：原神材料行回退到其他角色——`loadGenshinData` 在 L216 用 `computeRows.find(...) ?? computeRows[0]`；`getAllComputeData` 返回的是按角色分行的数据（`core/.../GenshinRepository.ets:838-848`），当前角色无行时会静默展示**另一个角色**的材料缺口。应在找不到时留空 Section。
- [ ] **低优先级**：`onSkillTap: () => {}` 为空实现——若 UI 展示"技能等级"点击区域但无响应会造成用户困惑；要么实现要么隐藏该交互元素
- [ ] **低优先级**：内容区底部显示「下拉刷新」提示（`MaterialCalcContentView.ets:56-62`，`material_calc_refresh_hint`），但页面没有 `Refresh` 容器，`vm.refresh()`（VM L127-137）无调用方
- [ ] **低优先级**：`MaterialCalcSection.ets:62-63` 硬编码中文文案 `缺少 ${deficitCount} 个材料` / `材料已足够`，未走 `$r('app.string.*')`，英文/繁中环境下仍显示简体中文

*本文档仅分析，不修改代码。*

---

## 重构执行备注（M7 · MaterialCalc）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 路由 | `MaterialCalc` **不在** `custom_router_map.json`；由 `GenshinCharacterDetailPage.ets:100` 用 `AppRoutes.MATERIAL_CALC` push——**当前无法解析，见 H-1** |
| 路由参数 | `MaterialCalcParam` 定义在 `pages/MaterialCalcPage.ets:22`，被 `GenshinCharacterDetailPage.ets:18` 直接 import。**类名与页面路径冻结**，否则 M10 编译失败 |
| Builder | `MaterialCalcBuilder` 在页面末尾（`MaterialCalcPage.ets:109`），本页不在 routerMap，Builder 目前无引用；修 H-1 时它将成为 routerMap 的 `buildFunction`，届时名称冻结 |
| 测试引用（冻结） | `viewmodel/MaterialCalcViewModel.ets`、`constants/ViewState.ets`、`models/MaterialCalcModels.ets` 被 `entry/src/test/MaterialCalcViewModel.test.ets` 导入 |
| 组件 | `components/materialcalc/` 8 个文件（LevelPicker / Character / ContentView / EmptyView / Item / LoadingView / Section / Skills），仅本页使用 |

### 重构范围（建议）

- 目录/命名已符合规范：**M7 的 MaterialCalc 部分没有必须的移动**。
- 不拆 `MaterialCalcViewModel`（493 行，< 500，且被测试引用）。
- `onSkillTap` 的空实现是功能缺口，不属于重构；要补也必须单独提交。
- 不要把 `MaterialCalcParam` 抽到 `models/`（会同时改 M10 的 `GenshinCharacterDetail`），除非单独立项。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. DevEco Local Test：`MaterialCalcViewModel.test.ets`（100 行）通过。
3. 冒烟：角色详情 → 材料计算 → 角色/武器等级 Picker。**注意**：H-1 未修前该入口打不开，冒烟只能确认"点击无效"这一现状不被重构改变；本页也没有"开始计算 → 材料清单"的跳转（材料清单由 Tools → MaterialCharacterSelect → TargetConfig 链路进入）。

### 已知问题归属

- High（H-1 页面未注册路由）：行为变更，单独提交；需同步 Refactor_Spec §11 与 genshin-character-detail 文档的入口说明。
- Medium（`vm.init()` 失败无兜底、等级设置占位实现、EMPTY 被覆盖为 DATA、原神材料行回退到其他角色）：记录；要修则单独提交。
- Low（`onSkillTap` 空实现、刷新提示无实现、Section 硬编码中文）：不在重构范围。

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 结构） | MaterialCalc 111 / VM 493 / 测试 100；material-calc 8 个组件全部存在且被引用；结构树三态 + LevelPicker 覆盖层 | ✅ 全部精确匹配 |
| 第 2 轮（关键引用） | 不在 routerMap；`GenshinCharacterDetailPage.ets:100` push `AppRoutes.MATERIAL_CALC`、L18 import Param；Param L22；Builder L109；`MaterialCalcParam` 默认实例 | ✅ |
| 第 3 轮（全面复核） | `init()` L76 为 async、L80 设 LOADING、L83 `getGameRoles` 在 try-catch 外、L91 才进 `loadData()`；`loadData` 失败→EMPTY（L169）；测试 13 用例引用的方法均存在；页面直接导入 4 个组件 | ✅ 修正 2 处（§1 直接导入清单 / §6 恢复 init 失败卡 LOADING 的 Medium） |
| 第 4 轮（2026-10-27 逐条复核） | 路由可达性（routerMap / `Index.ets` pageBuilder / `MainPage.ets:415` 无 navDestination）、VM 状态机 L165 覆盖、L216 回退、`recalculateMaterials` 空实现、组件硬编码 | ✅ 新增 H-1、3 条 Medium、2 条 Low；评级 A → B；§1 补 VM / 模型 / 组件行并标注 2 个未使用导入 |
| 第 5 轮（2026-10-27 对抗复核） | 路由注册方式全量排查（`custom_router_map.json` 无条目、`main_pages.json` 只有 `pages/Index`、全工程唯一 `.navDestination` 在 `Index.ets:30` 且 `pageBuilder` 无此分支、无 HMRouter/`@Route`/`router.pushUrl`、core 等模块无 routerMap 条目）；VM 各行号逐行复核 | ✅ H-1 及 4 条 Medium 成立；撤回 Low「levelOptions 非响应式」（`MaterialCalcPage.ets:34` 已是 `@Local`，选项固定，无问题）；§5 同步；补占位实现定 Medium 理由；L 4→3，债务 15→14，密度 13.5→12.6 |

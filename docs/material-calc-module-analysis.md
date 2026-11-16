# MaterialCalc 模块独立分析文档

> 生成时间：2026-10-24
> 代码版本：`105c8d3`（本文档分析基线，2026-10-24 复核）
> 作用 scope：`features/material/src/main/ets/pages/MaterialCalcPage.ets` + `MaterialCalcViewModel` + `views/` 下的 material-calc 子组件组（MaterialCalcContentView / MaterialCalcEmptyView / MaterialCalcLoadingView 等 7 个）

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | 1 |

**整体评级：A**

> 口径：skills `harmonyos-review` 官方 A-F 评级（0 Critical + High ≤ 3）。旧百分制已废弃，原分 88/100 仅作历史参考。
>
> **H-1 已关闭**：`MaterialCalc` 原本既不在 `custom_router_map.json`，也不在任何 `.navDestination()` Builder 中，角色详情里的「材料计算」入口点击后无法打开本页。**2026-11-14 随 GAP-02 修复**（`material_router_map.json:39-41`），本轮复核确认入口可达。
>
> **2026-11-16 四条 Medium 一并关闭**：入口修通后它们都会变成用户可感知故障，按本文原定口径重评并**直接修复**，不再记债——
> 1. 目标等级选择器是死交互（`recalculateMaterials()` 空实现）→ 移除选择器，等级改为只读，编辑入口统一跳该游戏的养成目标配置页（`7255959`）；
> 2. EMPTY 被 `loadData()` 覆盖为 DATA → 只在仍为 LOADING 时才置 DATA；
> 3. 原神材料行回退到其他角色（`find(...) ?? computeRows[0]`）→ 只取本角色行，缺失时留空并给出提示；
> 4. `init()` 前置查询失败永久停在 LOADING → `getGameRoles` 包 try-catch，失败落 EMPTY。
>
> **债务点数**：1×1 = **1**；密度 1 ÷ (113/100) ≈ **0.9**（源行数只计页面文件 `MaterialCalcPage.ets` 113 行，与 README §2 口径一致）。

---

## 1. 文件清单

| 文件 | 类型 | 行数 | 职责 |
|------|------|------|------|
| `features/material/src/main/ets/pages/MaterialCalcPage.ets` | Page / @ComponentV2 | 113 | 单角色材料计算页：目标等级只读展示 + 材料缺口；编辑入口跳养成目标配置页 |
| `features/material/src/main/ets/viewmodel/MaterialCalcViewModel.ets` | @ObservedV2 ViewModel | 479 | 读本地 DB 组装角色/技能/材料 Section；从 `material_target_config` 读目标等级 |
| `features/material/src/main/ets/model/MaterialCalcModels.ets` | 模型 | 136 | `MaterialCalcCharacterVM` / `SkillTargetVM` / `MaterialCalcSectionVM` 等（被测试引用）；`LevelOptionVM` 已随选择器删除；`MaterialItemRaw` 已上移到 `MaterialRawModels` |
| `features/material/src/main/ets/views/`（7 个） | 子组件 | 618 | MaterialCalcCharacter 121 / MaterialCalcContentView 93 / MaterialCalcEmptyView 44 / MaterialCalcItem 130 / MaterialCalcLoadingView 35 / MaterialCalcSection 95 / MaterialCalcSkills 100 |

> 行数为 2026-11-16 移除死交互后现状（M7 重构后为页面 109 / VM 465 / 组件 781）；§2–§6 的历史结论保留，状态已按本轮复核更新。

**计算服务（M7 拆分后）**：

| 文件 | 行数 | 职责 |
|------|------|------|
| `model/service/MaterialComputeService.ets` | 163 | facade：`hasSavedConfig` / `loadSavedTargets` / `compute` / `computeInternal` / `findAccount` / `findRole`；按 `gameId` 分派 |
| `model/service/MaterialComputeResult.ets` | 19 | `MaterialComputeResult` 枚举（由 facade re-export，原导入路径不变） |
| `model/service/MaterialComputeUtils.ets` | 44 | 日志 tag、`clampLevel` / `toResult` / `parseObject` / `getErrorMessage` |
| `model/service/GenshinMaterialCompute.ets` | 51 | 原神：`buildCalcItems` → `syncAvatarCompute` 批量计算 |
| `model/service/StarRailMaterialCompute.ets` | 210 | 星铁：逐角色计算 + 星魂加成解析 / 行迹目标换算 |
| `model/service/ZZZMaterialCompute.ets` | 142 | 绝区零：逐代理人计算 + `skill_type` 等级解析 |

> 拆分前 `MaterialComputeService.ets` 为 560 行；拆分后合计 629 行，增量来自各文件头部注释与独立 import。

**直接导入依赖**：`ThemeManager`, `ViewState`, `AppRoutes`, `GameId`, `MaterialCalcViewModel`, 3 个页面级子组件（MaterialCalcContentView / MaterialCalcEmptyView / MaterialCalcLoadingView）、`MaterialTargetConfigParam`。Character / Section / Skills / Item 由 `MaterialCalcContentView` 间接使用，页面不直接导入。

## 2. 架构分析（结构树）

```
MaterialCalcPage (@ComponentV2)
├── @Param param: MaterialCalcParam (accountId, roleUid, avatarId)
├── @Local vm: MaterialCalcViewModel
├── @Local tm: ThemeManager
├── localStack: NavPathStack | null（NavDestination.onReady 注入）
├── aboutToAppear() → vm.init(accountId, roleUid, avatarId)
├── build()
│   └── NavDestination
│       └── Column
│           └── 条件渲染 (vm.viewState):
│               ├── LOADING → MaterialCalcLoadingView()
│               ├── EMPTY → MaterialCalcEmptyView()
│               └── DEFAULT → MaterialCalcContentView(...)
│                   ├── character / skills / avatarSection / weaponSection（全部只读）
│                   ├── 无任何 Section 数据时显示 material_calc_no_compute_hint
│                   └── onEditTargets → goToTargetConfig()
│                       └── pushPathByName(<game>_MATERIAL_TARGET_CONFIG, MaterialTargetConfigParam)
├── .onShown() → 从配置页返回时 vm.refresh()
├── MaterialCalcPageBuilder (路由 Builder)
└── MaterialCalcPagePreview (@Preview)
```

> 组件名以 M7 重构后为准（原 `LevelPicker` / `MaterialCalcBuilder` / `MaterialCalcPreview`）；2026-11-16 起不再有等级选择器弹窗。

**架构模式**：MVVM + 只读展示——ViewModel 读 DB 组装展示模型，页面只负责三态渲染与「跳转养成目标配置页」。目标等级的唯一写入方是配置页（写 `material_target_config` 表并触发计算），本页不再持有编辑器。

**入口调用链（已通）**：角色详情「材料计算」→ `GenshinCharacterDetailPage.goToMaterialCalc()`（`:72-81`）→ `localStack.pushPathByName(AppRoutes.MATERIAL_CALC, params)`；栈来自 `NavDestination.onReady`，由 `material_router_map.json:39-41` 的 `MaterialCalc` 条目解析到 `MaterialCalcPageBuilder`。反向出口：本页「调整养成目标」→ 对应游戏的 `*MaterialTargetConfig` 页。

## 3. ArkTS 合规性检查

| 检查项 | 状态 | 说明 |
|--------|------|------|
| `@ComponentV2` + `struct` | ✅ 通过 | |
| `@Param param: MaterialCalcParam` | ✅ 通过 | class + 默认实例化，正确 |
| @Local ViewModel | ✅ 通过 | |
| 三级条件渲染 (VIEWSTATE) | ✅ 通过 | LOADING / EMPTY / DEFAULT 分支完整 |
| 弹窗管理 | ✅ 不适用 | 等级选择器已删除，页面不再有弹窗（`7255959`） |
| 空回调 | ✅ 已清理 | 原 `onSkillTap: () => {}` 已随死交互移除；页面只保留 `onEditTargets` 一个真实回调 |
| 未使用导入 | ✅ 已清理 | M7 删页面 `GameId` / ContentView `LevelOptionVM`；本轮又删除 `MaterialCalcLevelPicker` / `LevelOptionVM` 相关导入 |
| i18n | ⚠️ | `MaterialCalcSection.ets:43-44` 仍硬编码中文 `缺少 ${deficitCount} 个材料` / `材料已足够`（原 `'Lv.80→90 ▼'` 硬编码已随按钮删除） |

**ArkTS 结论：通过（存在轻微瑕疵）**

## 4. 组件复用分析

- **子组件已充分拆分**：ContentView、EmptyView、LoadingView、Character、Section、Skills、Item — 7 个子组件覆盖所有展示场景
- **等级编辑复用**：等级编辑统一复用既有 `*MaterialTargetConfig` 页（含 `LevelConfigRow`），不再维护第二套选择器
- **跨游戏通用性**：ViewModel 接收 avatarId/accountId/roleUid 参数化配置，同一页面适配多游戏角色

## 5. 安全审查

| 风险 | 级别 | 说明 |
|------|------|------|
| ~~onSkillTap 未实现（空回调）~~ | ✅ 已消除 | 技能项不再可点（`7255959`），不存在"点了没反应"的交互 |
| ~~LevelPicker 动态数据源~~ | ✅ 已消除 | 选择器与 `LevelOptionVM` / `getLevelOptions()` 一并删除 |

**安全结论：通过（存在需关注项）**

## 6. 风险清单

> 下列行号为 2026-11-16 的当前行号；M7 重构后未修的问题已在本轮全部处理，保留原描述便于对照。

- [x] **高优先级（H-1）✅ 已修复（GAP-02）**：原 `MaterialCalc` 未注册路由，角色详情「材料计算」点击无效。现已在 `features/material/src/main/resources/base/profile/material_router_map.json:39-41` 注册 `MaterialCalc` → `MaterialCalcPageBuilder`，入口与页面均编译通过；仍需真机点一次确认嵌套 `NavPathStack` 行为。
- [x] **中优先级 ✅ 已修复（2026-11-16，`7255959`）**：`vm.init()` 的前置查询失败会让页面卡在 LOADING —— `getGameRoles()` 原在 try-catch 外，异常时 `viewState` 永远是 LOADING。现包进 try-catch，失败时 `Logger.error` + `viewState = EMPTY` 并 return（VM `init()`）。
- [x] **中优先级 ✅ 已修复（2026-11-16，`7255959`）**：目标等级设置链路原是占位实现——`setCharTargetLevel` / `setWeaponTargetLevel` 只改内存字段，`recalculateMaterials()` 为空，用户选择等级后界面与材料均无变化；角色卡显示的 `character.targetLevel` 从未被 setter 更新；武器按钮文案硬编码 `'Lv.80→90 ▼'`。现**整体移除**这套死交互：等级只读展示，目标值来自 `material_target_config`（`MaterialComputeService.loadSavedTargets`），编辑入口改为跳对应游戏的 `*MaterialTargetConfig` 页；`setCharTargetLevel` / `setWeaponTargetLevel` / `setSkillTarget` / `recalculateMaterials` / `getLevelOptions` 与 `MaterialCalcLevelPicker`、`LevelOptionVM` 全部删除。
- [x] **中优先级 ✅ 已修复（2026-11-16，`7255959`）**：角色不存在时 EMPTY 被覆盖为 DATA——`loadGenshinData/StarRailData/ZZZData` 在找不到 avatar 时设 `EMPTY` 后 `return`，但 `loadData()` 随后无条件置 `DATA`，页面显示空白角色卡而不是 EmptyView。现 `loadData()` 只在 `viewState` 仍为 `LOADING` 时才置 `DATA`。
- [x] **中优先级 ✅ 已修复（2026-11-16，`7255959`）**：原神材料行回退到其他角色——`loadGenshinData` 原用 `computeRows.find(...) ?? computeRows[0]`，当前角色无计算行时会静默展示**另一个角色**的材料缺口。现只取本角色行，缺失时两个 Section 保持空并显示 `material_calc_no_compute_hint`（引导去配置页计算）。
- [x] **低优先级 ✅ 已消除（`7255959`）**：`onSkillTap: () => {}` 空实现已随技能项只读化删除。
- [x] **低优先级 ✅ 已消除（`7255959`）**：内容区底部「下拉刷新」提示在页面里没有 `Refresh` 容器、`vm.refresh()` 也无调用方，属假提示。现已删除该提示，改为 `NavDestination.onShown` 从配置页返回时调用 `vm.refresh()`（同时重读目标等级）。
- [ ] **低优先级**：`MaterialCalcSection.ets:43-44` 硬编码中文文案 `缺少 ${deficitCount} 个材料` / `材料已足够`，未走 `$r('app.string.*')`，英文/繁中环境下仍显示简体中文。
- [ ] **信息**：`MaterialCalcModels.ets` 中 `MaterialCalcSectionVM.iconUrl`、`SkillTargetVM.iconUrl`、`MaterialCalcCharacterVM.maxLevel`、`MaterialCalcWeaponVM.maxLevel` 无读取方；属模型层死字段，待后续统一清理。

*§6 为重构前基线分析；重构执行记录见下文。*

---

## 重构执行记录（M7 · MaterialCalc · 2026-11-04）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 路由 | ✅ 已注册：`features/material/src/main/resources/base/profile/material_router_map.json:39-41` 的 `MaterialCalc` → `MaterialCalcPageBuilder`；`GenshinCharacterDetailPage.ets:100` 用 `AppRoutes.MATERIAL_CALC` push |
| 路由参数 | `MaterialCalcParam` 定义在 `pages/MaterialCalcPage.ets:19`，被 `GenshinCharacterDetailPage.ets:14` 直接 import。**类名与页面路径冻结**，否则 M10 编译失败 |
| Builder | `MaterialCalcPageBuilder` 在页面末尾（`MaterialCalcPage.ets:110-113`），已是 routerMap 的 `buildFunction`，名称冻结 |
| 测试引用（冻结） | `viewmodel/MaterialCalcViewModel.ets`、`constants/ViewState.ets`、`model/MaterialCalcModels.ets` 被 `features/material/src/test/MaterialCalcViewModel.test.ets` 导入 |
| 组件 | `features/material/src/main/ets/views/` 下 7 个文件（MaterialCalcCharacter / MaterialCalcContentView / MaterialCalcEmptyView / MaterialCalcItem / MaterialCalcLoadingView / MaterialCalcSection / MaterialCalcSkills），仅本页使用；`MaterialCalcLevelPicker` 已于 2026-11-16 删除 |

### 重构范围（已执行）

- `views/LevelPicker.ets` → `views/MaterialCalcLevelPicker.ets`，struct 统一为 `MaterialCalcLevelPicker` / `MaterialCalcLevelPickerItem` / `MaterialCalcLevelPickerPreview`，与组内其他 `MaterialCalc*` 命名一致。
- 删除页面 `GameId` 死导入、`MaterialCalcContentView` 的 `LevelOptionVM` 死导入。
- `MaterialCalcViewModel` 三个 `buildGenshinSkills` / `buildStarRailSkills` / `buildZZZSkills` 的重复循环合并为 `buildSkillTargets(skillTypes, currentLevel, maxLevel)`；技能 ID、名称、初始等级完全保持（10/10/10、10/10/10、1/12/12）。
- `refresh()` / `isRefreshing` 保留：测试 `MaterialCalcViewModel.test.ets` 断言 `isRefreshing === false`；2026-11-16 起 `refresh()` 由 `NavDestination.onShown` 调用（从配置页返回时刷新），不再是死方法。
- 不拆 `MaterialCalcViewModel`（M7 时 465 行，2026-11-16 为 479 行，< 500，且被测试引用）。
- 不移动 `MaterialCalcParam`（被 `GenshinCharacterDetailPage` 直接 import）。
- 页面 111 → 109 行；VM 493 → 465 行；组件 781 行不变（LevelPicker 仅改名）。
- **2026-11-16 补充（`7255959`）**：删除 `views/MaterialCalcLevelPicker.ets`（137 行）与 `LevelOptionVM`，页面 109 → 113 行（新增 `onReady` / `onShown` / 跳转配置页），VM 465 → 479 行（新增 `applySavedTargets` / `reloadAll` / `getGameId`，删除 5 个死方法），组件 781 → 618 行。
- `MaterialComputeService`（560 行）按 facade 拆分：配置读取 / 账号角色查找 / 分派留在 facade（163 行），三个游戏的请求组装与结果判定分别进入 `GenshinMaterialCompute` / `StarRailMaterialCompute` / `ZZZMaterialCompute`，共用逻辑进入 `MaterialComputeUtils`，枚举独立为 `MaterialComputeResult`。日志 tag 值与所有日志文案保持不变；`MaterialComputeResult` 仍从原路径 `MaterialComputeService` 导出，调用方无需改动。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. DevEco Local Test：`MaterialCalcViewModel.test.ets` 通过；2026-11-16 删掉 3 条死 setter 用例后 material 模块 119 条全绿（原 122）。
3. 冒烟：角色详情 → 材料计算 → 查看只读等级与材料缺口 → 「调整养成目标」→ 配置页改等级并开始计算 → 返回本页应自动刷新。H-1 已修，可直接走入口；本页没有"开始计算 → 材料清单"的跳转（材料清单由 Tools → MaterialCharacterSelect → TargetConfig 链路进入）。

### 已知问题归属

- High（H-1 页面未注册路由）：✅ 已修复（GAP-02），路由表与入口已同步。
- Medium（`vm.init()` 失败无兜底、等级设置占位实现、EMPTY 被覆盖为 DATA、原神材料行回退到其他角色）：✅ 全部于 2026-11-16 修复（`7255959`），详见 §6。
- Low（`onSkillTap` 空实现、刷新提示无实现）：✅ 已随死交互删除；Low（Section 硬编码中文）：仍记录。
- 信息（模型层 4 个死字段）：记录，待模型层统一清理。
- 信息（日志 tag 复用）：facade 的通用日志（`loadSavedTargets` / `compute failed` / 配置读取失败 / 账号角色未找到）历史上使用 `GENSHIN_TAG`（`'GenshinCalc'`），拆分后原样保留以免改变日志检索口径；如需改为独立 tag 属行为变更，单独提交。

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 结构） | MaterialCalc 111 / VM 493 / 测试 100；material-calc 8 个组件全部存在且被引用；结构树三态 + LevelPicker 覆盖层 | ✅ 全部精确匹配 |
| 第 2 轮（关键引用） | 不在 routerMap；`GenshinCharacterDetailPage.ets:100` push `AppRoutes.MATERIAL_CALC`、L18 import Param；Param L22；Builder L109；`MaterialCalcParam` 默认实例 | ✅ |
| 第 3 轮（全面复核） | `init()` L76 为 async、L80 设 LOADING、L83 `getGameRoles` 在 try-catch 外、L91 才进 `loadData()`；`loadData` 失败→EMPTY（L169）；测试 13 用例引用的方法均存在；页面直接导入 4 个组件 | ✅ 修正 2 处（§1 直接导入清单 / §6 恢复 init 失败卡 LOADING 的 Medium） |
| 第 4 轮（2026-10-27 逐条复核） | 路由可达性（routerMap / `Index.ets` pageBuilder / `MainPage.ets:415` 无 navDestination）、VM 状态机 L165 覆盖、L216 回退、`recalculateMaterials` 空实现、组件硬编码 | ✅ 新增 H-1、3 条 Medium、2 条 Low；评级 A → B；§1 补 VM / 模型 / 组件行并标注 2 个未使用导入 |
| 第 5 轮（2026-10-27 对抗复核） | 路由注册方式全量排查（`custom_router_map.json` 无条目、`main_pages.json` 只有 `pages/Index`、全工程唯一 `.navDestination` 在 `Index.ets:30` 且 `pageBuilder` 无此分支、无 HMRouter/`@Route`/`router.pushUrl`、core 等模块无 routerMap 条目）；VM 各行号逐行复核 | ✅ H-1 及 4 条 Medium 成立；撤回 Low「levelOptions 非响应式」（`MaterialCalcPage.ets:34` 已是 `@Local`，选项固定，无问题）；§5 同步；补占位实现定 Medium 理由；L 4→3，债务 15→14，密度 13.5→12.6 |

| 第 6 轮（2026-10-30 命名核查） | Pages(9) / ViewModels(10) / Models(5) / Service(1) / Utils(1) / Views(15)，共 34 文件逐标识符核对；编译验证 `bash run.sh uat` → BUILD SUCCESSFUL in 14s 40ms | 🔶 命名零违规；本项为初步核查 |
| 第 7 轮（2026-11-04 M7 真重构执行后） | 页面 109L / VM 465L / 组件 781L；`views/LevelPicker.ets` → `views/MaterialCalcLevelPicker.ets`；三份技能构建合并为 `buildSkillTargets`；页面 `GameId` 与 ContentView `LevelOptionVM` 死导入已删；`bash run.sh uat` → BUILD SUCCESSFUL in 13s 649ms | ✅ 行数与结构复核一致 |
| 第 8 轮（2026-11-04 Service 拆分后） | `MaterialComputeService` 560L → facade 163L + Result 19L + Utils 44L + Genshin 51L + StarRail 210L + ZZZ 142L；`MaterialComputeResult` 由 facade re-export；`bash run.sh uat` → BUILD SUCCESSFUL in 14s 73ms | ✅ 编译通过，调用方 import 路径未变 |
| 第 9 轮（2026-11-16 死交互清理） | 回代码确认：`recalculateMaterials` / `setCharTargetLevel` / `setWeaponTargetLevel` / `setSkillTarget` / `getLevelOptions` / `LevelOptionVM` / `MaterialCalcLevelPicker` 已全部删除；`loadData` 只在 LOADING 时置 DATA；原神只取本角色 compute 行；`init` 的 `getGameRoles` 已包 try-catch；页面 113L / VM 479L / 组件 618L；`assembleHap` BUILD SUCCESSFUL；material 单测 119 条全绿 | H-1 与 4 条 Medium、2 条 Low 关闭；High 1 → 0、Medium 4 → 0、评级 B → A、债务 14 → 1 |

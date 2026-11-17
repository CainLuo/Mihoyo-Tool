# DailyDetail 家族模块分析

> **作用范围**：`GenshinDailyDetail` / `StarRailDailyDetail` / `ZZZDailyDetail` 三个页面 + 3 个 ViewModel + `features/dailynote/src/main/ets/views/`（17 个文件）+ `features/dailynote/src/main/ets/utils/`（3 个）
> **复核日期**：2026-11-02（M6 真重构后）
> 代码版本：M6 重构前基线 `105c8d3`（2026-10-24 分析）；M6 重构后见 `entry/Refactor_Spec.md` §M6 spec
> **HarmonyOS SDK**：`6.0.2(22)`（`targetSdkVersion` / `compatibleSdkVersion`，见根 `build-profile.json5`）
> **分析方式**：合并分析（三份页面结构高度相似，差异集中在游戏内容组件与标题资源）

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 2 |
| Low | 0 |

**整体评级：A**

> 口径：skills `harmonyos-review` 官方 A-F 评级（0 Critical + 0 High，Medium ≤ 5）。旧百分制已废弃，原分 90/100 仅作历史参考。
> 计数边界：`GenshinDailyDetailViewModel.test.ets` 当前为 32 行 / 2 个用例，只断言初始 `viewState` 与 `init` 可调用，无失效引用，DAILY-M2 关闭。
>
> 债务点数 = 2×2 = **4**。M6 重构关闭 DAILY-M1（三页骨架复制）、DAILY-L1（无效 window 监听）、DAILY-L2（排版不一致）；剩余 DAILY-M3（ERROR 渲染成不可点击空态）与 DAILY-M4（魔神任务卡片无数据源）均为行为变更，单独提交。

---

## 1. 文件基本信息

### 1.1 页面

| 文件 | 行数 | 装饰器 | 游戏内容组件 | 路由 Builder |
|------|------|--------|--------------|--------------|
| `features/dailynote/src/main/ets/pages/GenshinDailyDetailPage.ets` | 60 | `@ComponentV2` | `DailyNoteGenshin` | `GenshinDailyDetailPageBuilder` |
| `features/dailynote/src/main/ets/pages/StarRailDailyDetailPage.ets` | 57 | `@ComponentV2` | `DailyNoteStarRail` | `StarRailDailyDetailPageBuilder` |
| `features/dailynote/src/main/ets/pages/ZZZDailyDetailPage.ets` | 57 | `@ComponentV2` | `DailyNoteZZZ` | `ZZZDailyDetailPageBuilder` |

三页共用 `features/dailynote/src/main/ets/views/common/DailyDetailScaffold.ets`（67 行）渲染标题栏、三态分支与滚动容器。

### 1.2 ViewModel 与测试

| ViewModel | 行数 | Local Test |
|-----------|------|-----------|
| `features/dailynote/src/main/ets/viewmodel/GenshinDailyDetailViewModel.ets` | 82 | ✅ `features/dailynote/src/test/GenshinDailyDetailViewModel.test.ets`（32 行 / 2 个用例：初始 `LOADING`、`init` 可调用） |
| `features/dailynote/src/main/ets/viewmodel/StarRailDailyDetailViewModel.ets` | 70 | ❌ |
| `features/dailynote/src/main/ets/viewmodel/ZZZDailyDetailViewModel.ets` | 62 | ❌ |

三个 VM 共用 `utils/DailyNoteLoader.ets`（42 行，状态流转 + 异常日志）与 `utils/ExpeditionMapper.ets`（22 行，原神 / 星铁派遣转换）。

### 1.3 组件目录

`features/dailynote/src/main/ets/views/` 按职责与游戏分组：

- `common/` 7 个：DailyDetailScaffold、DailyNoteCard、DailyNoteDataRow、DailyNoteEmptyView、DailyNoteLoadingView、DailyNoteSectionLabel、ExpeditionItem
- `genshin/` 3 个：DailyNoteGenshin、GenshinDailyTaskContent、GenshinExpeditionSection
- `starrail/` 3 个：DailyNoteStarRail、StarRailStaminaCard、StarRailUniverseCard
- `zzz/` 4 个：DailyNoteZZZ、ZZZDailyCard、ZZZOtherCard、ZZZShopCard
- `utils/` 3 个：DailyNoteLoader、ExpeditionMapper、StaminaColorUtil（体力比例配色，三游戏共用）

---

## 2. 代码结构分析

### 2.1 整体结构（实际）

```
@ComponentV2 export struct XxxDailyDetailPage
├── @Param routerParam: XxxDailyDetailParam = new XxxDailyDetailParam()
├── @Local tm: ThemeManager = themeManager
├── @Local vm: XxxDailyDetailViewModel = new XxxDailyDetailViewModel()
├── aboutToAppear() → vm.init(accountId, roleUid) + vm.loadData()
├── @Builder gameContent() → DailyNoteXxx({ data: vm.note })
├── build() → DailyDetailScaffold({ title, viewState, content })
├── XxxDailyDetailPagePreview（@Preview）
└── @Builder export XxxDailyDetailPageBuilder(name, param) —— 路由入口
```

`DailyDetailScaffold`（`views/common/`）负责：

```
NavDestination
└── Column（页面背景 / 安全区）
    ├── LOADING → DailyNoteLoadingView
    ├── EMPTY / ERROR → DailyNoteEmptyView
    └── DATA → Scroll → Column（maxWidth 600）
        ├── Text(genshin_daily_data_delay_hint)
        └── content()  ← 页面注入的游戏内容
```

> 页面内**没有**内联 `@Builder itemCard`；任务卡片的渲染在各游戏的 `DailyNoteXxx` 组件里。`@Builder` 是游戏内容插槽与文件末尾的路由 Builder。

### 2.2 三文件差异对比

| 差异点 | 原神 | 星铁 | ZZZ |
|--------|------|------|-----|
| 游戏内容组件 | `DailyNoteGenshin` | `DailyNoteStarRail` | `DailyNoteZZZ` |
| 标题资源 | `genshin_daily_title` | `starrail_daily_title` | `zzz_daily_title` |
| ViewModel | `GenshinDailyDetailViewModel` | `StarRailDailyDetailViewModel` | `ZZZDailyDetailViewModel` |
| 路由参数类 | `GenshinDailyDetailParam` | `StarRailDailyDetailParam` | `ZZZDailyDetailParam` |

**结论**：三页现在只保留路由参数类、ViewModel 与内容组件三处差异；标题栏、三态分支、提示文案、滚动容器与宽屏约束全部由 `DailyDetailScaffold` 统一。

---

## 3. 合规审查

### 3.1 ArkTS / ArkUI

| 规则 | 状态 | 说明 |
|------|------|------|
| `@ComponentV2` 使用 | ✅ | 三个页面与 Preview 均为 V2，无 V1/V2 混用 |
| `@Param` 路由参数 | ✅ | `XxxDailyDetailParam` 由路由传入，Preview 用默认实例 |
| `@Local` 状态 | ✅ | `vm` / `tm` 均为 `@Local`；`windowWidthVp` 已删除 |
| Router Builder | ✅ | 文件末尾 `@Builder export function XxxDailyDetailPageBuilder`，符合 routerMap 约定 |
| 生命周期清理 | ✅ | 页面已无 window 监听；`aboutToAppear` 只做 `vm.init` + `vm.loadData`，无需 `aboutToDisappear` |
| 异常处理 | ⚠️ | 三页共用 `DailyNoteLoader`：catch 只记日志并设 `ERROR`，没有错误消息字段；页面把 ERROR 与 EMPTY 渲染成同一个空态（见 DAILY-M3） |
| ARKTS-014 import 走 `@kit.*` | ✅ | 原 `import display from '@ohos.display'` 与 `@kit.ArkUI` window 监听已随 DAILY-L1 删除 |
| `@Builder` 行内大段 UI | ✅ | 页面只保留游戏内容插槽；骨架在 `DailyDetailScaffold` |
| 类型声明 | ✅ | 字段与回调均有显式类型 |

### 3.2 命名与复用

| 规则 | 状态 | 说明 |
|------|------|------|
| 文件/struct PascalCase | ✅ | 与文件名一致 |
| 游戏组件命名 | ✅ | `DailyNoteGenshin/StarRail/ZZZ` 统一前缀 |
| 公共组件复用 | ✅ | Loading / Empty / Card / DataRow / SectionLabel 已在 `common/` |
| 页面骨架复用 | ✅ | 三页共用 `DailyDetailScaffold`，页面只保留参数、ViewModel 与内容插槽（DAILY-M1 关闭） |

### 3.3 主题适配

- ✅ 使用 `themeManager` + `ThemeFonts`；页面背景、文字色均取主题。
- ✅ 宽屏适配由 `DailyDetailScaffold` 统一使用 `constraintSize({ maxWidth: value600 })`；原三页只写不读的 `windowWidthVp` 与 `windowSizeChange` 监听已删除（DAILY-L1 关闭）。

---

## 4. 重复度评估

### 4.1 代码重复统计

- **页面结构**：标题栏、三态分支、提示文案、滚动容器已收敛到 `DailyDetailScaffold`；三页各 57–60 行，仅剩参数类、ViewModel 与内容插槽。
- **星铁 vs ZZZ**：页面级 diff 只剩游戏名、组件 / VM / Param 名与标题资源。
- **ViewModel**：`loadData()` 的 LOADING → EMPTY / DATA / ERROR 流程统一走 `DailyNoteLoader`；原神 / 星铁的派遣转换统一走 `ExpeditionMapper`。
- **体力配色**：原神树脂 / 星铁开拓力 / 绝区零电量的 30% / 70% 阈值配色统一走 `StaminaColorUtil`。
- **游戏内容**：已经拆到 `features/dailynote/src/main/ets/views/`，common 组件复用正常（各组件实际使用范围见 §7）。

### 4.2 合并建议

**页面级重复已在本轮消除，不再建议继续合并。**

理由：
1. 三个页面仍是三个独立路由入口（routerMap 需要不同 `name` / `buildFunction`），薄页面壳本身不是风险。
2. `DailyDetailScaffold` 已覆盖可复用部分；继续合并会把游戏内容组件也塞进条件分支，反而降低可读性。
3. 若未来新增第四游戏，只需新增 Param + VM + 内容组件 + 一个 60 行页面壳。

---

## 5. 问题与改进建议

| 优先级 | 编号 | 问题 | 说明 |
|--------|------|------|------|
| ✅ 已解决 | DAILY-M1 | 三份页面骨架复制（约 90%） | M6 抽出 `views/common/DailyDetailScaffold.ets`，三页只保留参数类、ViewModel 与内容插槽；页面 131/123/123 → 60/57/57 行。 |
| **Medium** | DAILY-M3 | ERROR 被渲染成"暂无数据，点击同步"，但点击无响应、无错误提示 | `utils/DailyNoteLoader.ets` 的 catch 只 `Logger.error` + 返回 `ViewState.ERROR`，没有错误消息字段；`DailyDetailScaffold` 把 `EMPTY \|\| ERROR` 都渲染为 `DailyNoteEmptyView()`。该组件文案为 `home_no_data_hint` = "暂无数据，点击同步"（`DailyNoteEmptyView.ets:12`），但组件和页面都没有 `onClick`，也没有重试入口。DB 读取或 `XxxDailyNoteParser.parse()` 抛错时，用户只看到一个点不动的"点击同步"。对比角色详情页 ERROR 会弹 `showFeedback`。 |
| **Medium** | DAILY-M4 | 原神"魔神任务"卡片数据从未赋值 | `DailyNoteGenshin.ets:81-89` 第一张卡片读 `data.isArchonQuestDone` / `data.archonQuestDesc`，但 `GenshinDailyDetailViewModel.toVM()`（L51-81）从不给这两个字段赋值，core 的 `GenshinDailyNoteData` 也没有对应字段；模型默认值为 `false` / `''`（`model/DailyNoteModels.ets:91-93`）。结果是每次进入原神便笺，首张"魔神任务"卡右侧都是空值（只有 Preview 的 mock 数据里有内容）。同理 `storedAdventure` 在 toVM 中固定传 `-1`（L62-67），"长效历练点"行永远隐藏（`GenshinDailyTaskContent.ets:55`）。 |
| ✅ 已解决 | DAILY-M2 | `GenshinDailyDetailViewModel.test.ets` 曾引用不存在的方法 | 当前测试 32 行 / 2 个用例，只断言初始 `viewState` 与 `init` 可调用；`vm.init('1', 'uid1')` 类型正确，无 `formatSeconds` / `formatTransformer` 引用。 |
| ✅ 已解决 | DAILY-L1 | 页面层 window 监听/尺寸换算样板重复 | 三页的 `display` / `windowWidthVp` / `sizeCallback` / `window.getLastWindow` / on/off 全部删除；宽屏约束保留在 `DailyDetailScaffold`。 |
| ✅ 已解决 | DAILY-L2 | 排版/注释风格不一致 | 三页统一为同一结构：Param → 两个 `@Local` → `aboutToAppear` → `@Builder gameContent` → `build`。 |
| ✅ 已完成 | DAILY-I1 | 可选的共享 Scaffold | 已落地为 `DailyDetailScaffold`；保留 3 个页面与 Builder 作为薄壳。 |

> 原文的 "Logger 导入未使用" 不成立：三个页面都没有从 `core` 导入 `Logger`。

---

## 6. 依赖文件索引（已核对）

| 类型 | 文件 |
|------|------|
| ViewModel | `features/dailynote/src/main/ets/viewmodel/{Genshin,StarRail,ZZZ}DailyDetailViewModel.ets` |
| Model | `features/dailynote/src/main/ets/model/DailyNoteModels.ets`（由 ViewModel 使用） |
| Util | `features/dailynote/src/main/ets/utils/{DailyNoteLoader,ExpeditionMapper,StaminaColorUtil}.ets` |
| Component | `features/dailynote/src/main/ets/views/common/{DailyDetailScaffold,DailyNoteLoadingView,DailyNoteEmptyView}` + `features/dailynote/src/main/ets/views/<game>/DailyNote<Game>` |
| Theme | `common/basic/src/main/ets/theme/ThemeManager.ets`、`common/basic/src/main/ets/theme/ThemeFonts.ets` |
| Constant | `common/basic/src/main/ets/constants/ViewState.ets` |
| 路由 | `features/dailynote/src/main/resources/base/profile/dailynote_router_map.json` 的 3 条 `*DailyDetail` 记录（页面内不直接引用 `AppRoutes`） |

---

## 7. 重构执行备注（M6 · Dailynote）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 路由 | `features/dailynote/src/main/resources/base/profile/dailynote_router_map.json`：三条路由分别指向三个页面与 `GenshinDailyDetailPageBuilder` / `StarRailDailyDetailPageBuilder` / `ZZZDailyDetailPageBuilder`，**页面路径与 Builder 名冻结** |
| 路由参数类 | `GenshinDailyDetailParam` / `StarRailDailyDetailParam` / `ZZZDailyDetailParam` 定义在各自页面文件并 `export`；`features/home/src/main/ets/viewmodel/HomeViewModel.ets:32` 与 `:46` 直接 import / 联合这三个类。**类名与所在文件路径冻结**，否则 M8 编译失败 |
| 测试引用（冻结） | `features/dailynote/src/test/GenshinDailyDetailViewModel.test.ets` 导入 `features/dailynote/src/main/ets/viewmodel/GenshinDailyDetailViewModel.ets`、`common/basic/src/main/ets/constants/ViewState.ets` |
| 共享组件 | `features/dailynote/src/main/ets/views/common/` 7 个文件不移动；实际使用分布：`DailyDetailScaffold` / `DailyNoteLoadingView` / `DailyNoteEmptyView` 被三页共用，`DailyNoteDataRow` / `DailyNoteSectionLabel` 用于 starrail + zzz，`DailyNoteCard` 仅 genshin（DailyNoteGenshin、GenshinDailyTaskContent），`ExpeditionItem` 仅 genshin（GenshinExpeditionSection） |
| ViewModel | 三个 VM 均 < 90 行，不拆分；StarRail / ZZZ 无测试 |

### 重构范围（已执行）

- 目录结构保持 `common/` + `genshin/` / `starrail/` / `zzz/`；新增 `utils/` 放跨页共用逻辑。
- 页面骨架收敛为 `views/common/DailyDetailScaffold.ets`（DAILY-M1 / DAILY-I1）：三页只保留 Param、ViewModel、`@Builder gameContent()` 与 `build()`。
- 删除三页只写不读的 `windowWidthVp`、`display` 导入、`sizeCallback` 与 `window.on/off`（DAILY-L1）。
- 三个 VM 的加载流程抽到 `utils/DailyNoteLoader.ets`；原神 / 星铁派遣转换抽到 `utils/ExpeditionMapper.ets`。
- 三游戏体力/电量阈值配色抽到 `utils/StaminaColorUtil.ets`。
- `DailyNoteCard` 删除从未使用的 `icon` / `hasIcon` / `customRight` / `hasCustomRight`；`title` 改 `@Require`。
- `DailyNoteDataRow` / `DailyNoteSectionLabel` / `GenshinDailyTaskContent` / `ExpeditionItem` 的必填参数改 `@Require`，去掉无意义默认值。
- `StarRailStaminaCard` 删除只赋值不读取的 `uiCtx` 字段与 `aboutToAppear`。
- Preview mock 函数统一命名：`createPreviewGenshinNote` / `createPreviewStarRailNote` / `createPreviewZzzNote`。
- 不要移动 `HomeViewModel` 依赖的三个 Param 类，也不要把 `common/` 组件下沉到游戏目录。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. DAILY-M2 已关闭：当前测试 32 行 / 2 个用例，无失效方法引用。
3. 冒烟：三个游戏便笺详情各进入一次；LOADING / EMPTY / ERROR 三态；宽屏 `maxWidth 600` 生效。

### 已知问题归属

- Medium（DAILY-M3 ERROR 显示为不可点击的"点击同步"空态）：行为修复，单独提交（区分 ERROR 空态文案或补 toast / 重试）；三页一起改。
- Medium（DAILY-M4 魔神任务卡片无数据源）：需产品决定"补数据源"还是"隐藏该卡片"，属行为变更，不随重构提交。

### 重构记录

| 轮次 | 范围 | 结果 |
| --- | --- | --- |
| 第 8 轮（2026-11-02 M6 真重构） | 页面 131/123/123 → 60/57/57 行；新增 `DailyDetailScaffold` 67 行、`DailyNoteLoader` 42 行、`ExpeditionMapper` 22 行、`StaminaColorUtil` 21 行；VM 97/82/63 → 82/70/62 行；删除死参数 / 死字段 | ✅ DAILY-M1 / L1 / L2 / I1 关闭；M2 确认已修复；编译 `bash run.sh uat` → BUILD SUCCESSFUL in 15s 175ms，安装/启动成功 |

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 结构） | 页面 133/125/125、VM 97/82/63、测试 87 行；dailynote 分组 6/3/3/4=16；三页面 hint 资源、无 Logger、`@Builder` 行号；路由 `4-6 / 39-41 / 44-46` | ✅ 全部精确匹配 |
| 第 2 轮（关键代码段） | Genshin `@Param` L26 / `@Local` L27-29 / 生命周期 / 三态 build；`HomeViewModel.ets:52-54` 三个 Param import；`ViewState.EMPTY \|\| ERROR` 分支 | ✅ |
| 第 3 轮（全面复核） | StarRail vs ZZZ `diff` 仅名称差异；Genshin vs StarRail 8 行差异来源；三 VM catch 均设 ERROR；测试引用不存在方法；`windowWidthVp` 只写不读；common 组件实际使用分布 | ✅ 修正 4 类（测试状态 / 宽屏声明 / 重复度描述 / 共享组件范围）+ 新增 DAILY-M2 |
| 第 4 轮（2026-10-26 复核） | 按 README §1.4 口径把 DAILY-M2（测试引用失效方法）移出评级计数；重算 0/0/1/2 | ✅ 债务 6→4 |
| 第 5 轮（2026-10-27 逐条复核） | 逐行对照全部锚点（修正 `@Param` / `@Local` 行号）；补读 VM catch、`DailyNoteEmptyView`、`DailyNoteGenshin` 与 `toVM()`；新增 DAILY-M3 / DAILY-M4；补 ARKTS-014 合规行（随 DAILY-L1 消除，不单独计数） | ✅ 0/0/3/2，债务 4→8 |

| 第 6 轮（2026-10-30 断链修复） | 迁移前路径 `components/dailynote/*` → `features/dailynote/src/main/ets/views/*`；页面 / ViewModel / Model / 测试全量更新为 `features/dailynote/src/main/ets/` 绝对路径；Theme 常量从 `shares/` 修正到 `theme/`；TimeFormatUtil 补全路径 | ✅ 12 处路径全部验证存在 |

| 第 7 轮（2026-10-30 命名核查） | Pages(3) / Models(1) / ViewModels(3) / Common Views(6) / Genshin Views(3) / StarRail Views(3) / ZZZ Views(4)，共 24 文件逐标识符核对；编译验证 `bash run.sh uat` → BUILD SUCCESSFUL in 15s 824ms | 🔶 命名零违规；本项为初步核查，M6 真重构（三件套去重、行为等价验证）待执行 |
| 第 8 轮（2026-11-02 M6 真重构） | 页面骨架 → `DailyDetailScaffold`；VM 加载 / 派遣转换 / 体力配色 → `utils/` 三个文件；删除死参数与死字段；复核全部行号、路由 Builder 名、`HomeViewModel` 引用位置；编译 `bash run.sh uat` → BUILD SUCCESSFUL in 15s 175ms，安装/启动成功 | ✅ 0/0/2/0，债务 8→4；DAILY-M1 / L1 / L2 / I1 关闭，M2 确认已修复；M3 / M4 保留待单独提交 |

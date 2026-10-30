# DailyDetail 家族模块分析

> **作用范围**：`GenshinDailyDetail` / `StarRailDailyDetail` / `ZZZDailyDetail` 三个页面 + 3 个 ViewModel + `features/dailynote/src/main/ets/views/`（16 个文件）
> **复核日期**：2026-10-24
> 代码版本：`105c8d3`（本文档分析基线，2026-10-24 复核）
> **HarmonyOS SDK**：`6.0.2(22)`（`targetSdkVersion` / `compatibleSdkVersion`，见根 `build-profile.json5`）
> **分析方式**：合并分析（三份页面结构高度相似，差异集中在游戏内容组件与标题资源）

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 3 |
| Low | 2 |

**整体评级：A**

> 口径：skills `harmonyos-review` 官方 A-F 评级（0 Critical + 0 High，Medium ≤ 5）。旧百分制已废弃，原分 90/100 仅作历史参考。
> 计数边界：`GenshinDailyDetailViewModel.test.ets` 引用失效方法（DAILY-M2）属测试资产缺陷，按 README §1.4 不计入本页评级，单独由 [test-suite-analysis.md](./test-suite-analysis.md) 汇总。
>
> 债务点数 = 3×2 + 2×1 = **8**；三页面合计 383 行（133 + 125 + 125），密度 **2.1**/百行。（2026-10-27 复核前为 0/0/1/2、4 点、1.0：新增 DAILY-M3「ERROR 渲染成"点击同步"空态但无点击 / 无错误提示」与 DAILY-M4「原神"魔神任务"卡片字段从未赋值」，两条均为 Medium——用户看到的是非数据态 / 空值卡片，不是伪装成功的数据页，故不升 High。）

---

## 1. 文件基本信息

### 1.1 页面

| 文件 | 行数 | 装饰器 | 游戏内容组件 | 路由 Builder |
|------|------|--------|--------------|--------------|
| `features/dailynote/src/main/ets/pages/GenshinDailyDetailPage.ets` | 133 | `@ComponentV2` | `DailyNoteGenshin` | `GenshinDailyDetailBuilder` |
| `features/dailynote/src/main/ets/pages/StarRailDailyDetailPage.ets` | 125 | `@ComponentV2` | `DailyNoteStarRail` | `StarRailDailyDetailBuilder` |
| `features/dailynote/src/main/ets/pages/ZZZDailyDetailPage.ets` | 125 | `@ComponentV2` | `DailyNoteZZZ` | `ZZZDailyDetailBuilder` |

### 1.2 ViewModel 与测试

| ViewModel | 行数 | Local Test |
|-----------|------|-----------|
| `features/dailynote/src/main/ets/viewmodel/GenshinDailyDetailViewModel.ets` | 97 | ⚠️ `features/dailynote/src/test/GenshinDailyDetailViewModel.test.ets`（87 行）存在，但引用已不存在的 `formatSeconds` / `formatTransformer`，11 个用例中 9 个必抛错（见 §5 DAILY-M2） |
| `features/dailynote/src/main/ets/viewmodel/StarRailDailyDetailViewModel.ets` | 82 | ❌ |
| `features/dailynote/src/main/ets/viewmodel/ZZZDailyDetailViewModel.ets` | 63 | ❌ |

### 1.3 组件目录

`features/dailynote/src/main/ets/views/common/` 等按游戏分组：

- `common/` 6 个（`features/dailynote/src/main/ets/views/common/`）：DailyNoteCard、DailyNoteDataRow、DailyNoteEmptyView、DailyNoteLoadingView、DailyNoteSectionLabel、ExpeditionItem
- `genshin/` 3 个（`features/dailynote/src/main/ets/views/genshin/`）：DailyNoteGenshin、GenshinDailyTaskContent、GenshinExpeditionSection
- `starrail/` 3 个（`features/dailynote/src/main/ets/views/starrail/`）：DailyNoteStarRail、StarRailStaminaCard、StarRailUniverseCard
- `zzz/` 4 个（`features/dailynote/src/main/ets/views/zzz/`）：DailyNoteZZZ、ZZZDailyCard、ZZZOtherCard、ZZZShopCard

---

## 2. 代码结构分析

### 2.1 整体结构（实际）

```
@ComponentV2 export struct XxxDailyDetail
├── @Param routerParam: XxxDailyDetailParam = new XxxDailyDetailParam()
├── @Local tm: ThemeManager = themeManager
├── @Local vm: XxxDailyDetailViewModel = new XxxDailyDetailViewModel()
├── @Local windowWidthVp: number
├── aboutToAppear()
│   ├── display.getDefaultDisplaySync() → windowWidthVp
│   ├── window.getLastWindow(...).on('windowSizeChange', sizeCallback)
│   └── vm.init(accountId, roleUid) + vm.loadData()
├── aboutToDisappear() → window.off('windowSizeChange', sizeCallback)
├── build() → NavDestination
│   └── Column
│       ├── LOADING → DailyNoteLoadingView
│       ├── EMPTY / ERROR → DailyNoteEmptyView
│       └── DATA → Scroll → Column
│           └── Text($r('app.string.genshin_daily_data_delay_hint'))（三文件均含，资源名虽带 genshin 前缀但实际内容通用）
│           └── DailyNoteGenshin/StarRail/ZZZ({ data: vm.note })
├── XxxDailyDetailPreview（@Preview）
└── @Builder export XxxDailyDetailBuilder(name, param) —— 路由入口
```

> 页面内**没有**内联 `@Builder itemCard`；任务卡片的渲染在各游戏的 `DailyNoteXxx` 组件里。`@Builder` 是文件末尾的路由 Builder。

### 2.2 三文件差异对比

| 差异点 | 原神 | 星铁 | ZZZ |
|--------|------|------|-----|
| 游戏内容组件 | `DailyNoteGenshin` | `DailyNoteStarRail` | `DailyNoteZZZ` |
| 标题资源 | `genshin_daily_title` | `starrail_daily_title` | `zzz_daily_title` |
| 额外提示文案 | 有（`genshin_daily_data_delay_hint`） | 有（同左，三文件均含） | 有（同左，三文件均含） |
| 排版/注释 | 展开写法、注释较完整 | 紧凑写法 | 紧凑写法 |
| ViewModel | `GenshinDailyDetailViewModel` | `StarRailDailyDetailViewModel` | `ZZZDailyDetailViewModel` |

**结论**：星铁与 ZZZ 除注释、游戏组件路径、标题资源外几乎逐行一致；三文件均含 `genshin_daily_data_delay_hint` 文案（文档此前错误标注为仅原神有，已修正）。原神与星铁的排版/注释风格差异为主。不是"只有 ViewModel + TAG 两处差异"。

---

## 3. 合规审查

### 3.1 ArkTS / ArkUI

| 规则 | 状态 | 说明 |
|------|------|------|
| `@ComponentV2` 使用 | ✅ | 三个页面与 Preview 均为 V2，无 V1/V2 混用 |
| `@Param` 路由参数 | ✅ | `XxxDailyDetailParam` 由路由传入，Preview 用默认实例 |
| `@Local` 状态 | ✅ | `vm` / `tm` / `windowWidthVp` 均为 `@Local` |
| Router Builder | ✅ | 文件末尾 `@Builder export function XxxDailyDetailBuilder`，符合 routerMap 约定 |
| 生命周期清理 | ✅ | `aboutToDisappear` 中 `window.off('windowSizeChange')`，有 `ctx === null` 守卫 |
| 异常处理 | ⚠️ | 页面层 display / window 调用均有 try-catch，`aboutToAppear` 的失败不会中断数据加载；但 VM `loadData()` 的 catch 只设 `ERROR`、不带消息，页面把 ERROR 与 EMPTY 渲染成同一个空态（见 DAILY-M3） |
| ARKTS-014 import 走 `@kit.*` | ⚠️ | `GenshinDailyDetailPage.ets:8`、`StarRailDailyDetailPage.ets:5`、`ZZZDailyDetailPage.ets:5` 均为 `import display from '@ohos.display'`；该导入只服务于无读取方的 `windowWidthVp`，随 DAILY-L1 删除监听即一并消失，故不单独计数 |
| `@Builder` 行内大段 UI | ✅ | 没有行内 item Builder；内容在游戏组件中 |
| 类型声明 | ✅ | 字段与回调均有显式类型 |

### 3.2 命名与复用

| 规则 | 状态 | 说明 |
|------|------|------|
| 文件/struct PascalCase | ✅ | 与文件名一致 |
| 游戏组件命名 | ✅ | `DailyNoteGenshin/StarRail/ZZZ` 统一前缀 |
| 公共组件复用 | ✅ | Loading / Empty / Card / DataRow / SectionLabel 已在 `common/` |
| 页面骨架复用 | ⚠️ | 三份页面仍各自维护 window 监听、生命周期与三态分支（见 4.1） |

### 3.3 主题适配

- ✅ 使用 `themeManager` + `ThemeFonts`；页面背景、文字色均取主题。
- ⚠️ 宽屏适配实际只靠 `constraintSize({ maxWidth: value600 })`；`windowWidthVp` 在三个页面里**只写不读**（`build()` 与所有 dailynote 子组件均未引用），配套的三处 `windowSizeChange` 监听也因此没有消费方（见 DAILY-M1 / DAILY-L1）。

---

## 4. 重复度评估

### 4.1 代码重复统计

- **页面结构**：约 90% 同构（window 监听、生命周期、LOADING / EMPTY+ERROR / DATA 分支、Scroll 容器）。
- **星铁 vs ZZZ**：`diff` 仅命中游戏名（StarRail/ZZZ）、组件/VM/Param 名与标题资源，代码结构与逻辑逐行一致。
- **原神 vs 星铁**：`diff` 显示差异集中在原神文件头多 4 行注释（含 Param 注释）与括号风格（`if (...) return` vs `if (...) { return }`、单行 vs 多行 `try/catch`），逻辑与结构一致；因此 133 vs 125 行是注释 + 排版差异，不是 import/空行。
- **游戏内容**：已经拆到 `features/dailynote/src/main/ets/views/`，common 组件复用正常（各组件实际使用范围见 §7）。

### 4.2 合并建议

**当前重复可接受，不建议在本轮做页面级合并。**

理由：
1. 三个页面是三个独立路由入口（routerMap 需要不同 `name` / `buildFunction`），薄页面壳本身不是主要风险。
2. 合并为共享 shell 需要 `@BuilderParam` 内容槽或参数化组件，ArkTS 下会改变组件树与生命周期顺序，收益小于风险。
3. 真正可复用的是 window 监听 + 三态分支这一段样板；如果未来新增第四游戏，建议先抽 `DailyDetailScaffold`，而不是继续复制。

---

## 5. 问题与改进建议

| 优先级 | 编号 | 问题 | 说明 |
|--------|------|------|------|
| **Medium** | DAILY-M1 | 三份页面骨架复制（约 90%） | window 监听、生命周期、三态分支重复；新增游戏需手动同步，容易漏改。且 `windowWidthVp` 无读取方，监听当前只更新死状态。 |
| **Medium** | DAILY-M3 | ERROR 被渲染成"暂无数据，点击同步"，但点击无响应、无错误提示 | 三个 VM 的 `loadData()` catch 只 `Logger.error` + `viewState = ERROR`，没有任何错误消息字段（`GenshinDailyDetailViewModel.ets:46-50`、`StarRailDailyDetailViewModel.ets:40-44`、`ZZZDailyDetailViewModel.ets:39-43`）；页面把 `EMPTY \|\| ERROR` 都渲染为 `DailyNoteEmptyView()`（`GenshinDailyDetailPage.ets:78-79`，星铁 / ZZZ `:70-71`）。该组件文案为 `home_no_data_hint` = "暂无数据，点击同步"（`DailyNoteEmptyView.ets:13`，`resources/base/element/string.json:40-41`），但组件和页面都没有 `onClick`，也没有重试入口。DB 读取或 `XxxDailyNoteParser.parse()` 抛错时，用户只看到一个点不动的"点击同步"。对比角色详情页 ERROR 会弹 `showFeedback`。 |
| **Medium** | DAILY-M4 | 原神"魔神任务"卡片数据从未赋值 | `DailyNoteGenshin.ets:89-96` 第一张卡片读 `data.archonQuestDone` / `data.archonQuestDesc`，但 `GenshinDailyDetailViewModel.toVM()`（L55-85）从不给这两个字段赋值，core 的 `GenshinDailyNoteData` 也没有对应字段；模型默认值为 `false` / `''`（`models/DailyNoteModels.ets:91-93`）。结果是每次进入原神便笺，首张"魔神任务"卡右侧都是空值（只有 Preview 的 mock 数据里有内容）。同理 `storedAdventure` 在 toVM 中固定传 `-1`（L70），"长效历练点"行永远隐藏（`GenshinDailyTaskContent.ets:56`）。 |
| **测试资产**（不计入评级，见 README §1.4） | DAILY-M2 | `GenshinDailyDetailViewModel.test.ets` 引用不存在的方法 | 测试通过索引调用 `GenshinDailyDetailViewModel['formatSeconds']` / `['formatTransformer']`，但这两个方法在 VM 中不存在（已迁移到 `common/basic/src/main/ets/utils/TimeFormatUtil.ets`，且签名多 `uiCtx` 参数）；11 个用例中 9 个必抛 `TypeError`。另有 `vm.init(1, 'uid1')` 传 number 与 `init(accountId: string, ...)` 不符。当前状态下 §7 的“测试通过”验收项无法达成。 |
| **Low** | DAILY-L1 | 页面层 window 监听/尺寸换算样板重复 | 三页各自维护 `sizeCallback` + `getLastWindow` + on/off；由于 `windowWidthVp` 从未被读取，可直接删除该监听（行为中性清理，建议与任何行为修改分开提交）。 |
| **Low** | DAILY-L2 | 排版/注释风格不一致 | 原神展开写法、星铁/ZZZ 紧凑写法；模板同步时容易产生无意义 diff。 |
| **信息** | DAILY-I1 | 可选的共享 Scaffold | 仅当新增第四游戏或页面逻辑继续增长时再做；保留 3 个页面与 Builder 作为薄壳。 |

> 原文的 "Logger 导入未使用" 不成立：三个页面都没有从 `core` 导入 `Logger`。

---

## 6. 依赖文件索引（已核对）

| 类型 | 文件 |
|------|------|
| ViewModel | `features/dailynote/src/main/ets/viewmodel/{Genshin,StarRail,ZZZ}DailyDetailViewModel.ets` |
| Model | `features/dailynote/src/main/ets/model/DailyNoteModels.ets`（由 ViewModel 使用） |
| Component | `features/dailynote/src/main/ets/views/common/{DailyNoteLoadingView,DailyNoteEmptyView}` + `features/dailynote/src/main/ets/views/<game>/DailyNote<Game>` |
| Theme | `common/basic/src/main/ets/theme/ThemeManager.ets`、`common/basic/src/main/ets/theme/ThemeFonts.ets` |
| Constant | `common/basic/src/main/ets/constants/ViewState.ets` |
| 路由 | `custom_router_map.json` 的 3 条 `*DailyDetail` 记录（页面内不直接引用 `AppRoutes`） |

---

## 7. 重构执行备注（M6 · Dailynote）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 路由 | `custom_router_map.json:4-6 / 39-41 / 44-46`：三条路由分别指向三个页面与 `GenshinDailyDetailBuilder` / `StarRailDailyDetailBuilder` / `ZZZDailyDetailBuilder`，**页面路径与 Builder 名冻结** |
| 路由参数类 | `GenshinDailyDetailParam` / `StarRailDailyDetailParam` / `ZZZDailyDetailParam` 定义在各自页面文件并 `export`；`features/home/src/main/ets/viewmodel/HomeViewModel.ets:52-54` 直接 import 这三个类。**类名与所在文件路径冻结**，否则 M8 编译失败 |
| 测试引用（冻结） | `features/dailynote/src/test/GenshinDailyDetailViewModel.test.ets` 导入`features/dailynote/src/main/ets/viewmodel/GenshinDailyDetailViewModel.ets`、`common/basic/src/main/ets/constants/ViewState.ets` |
| 共享组件 | `features/dailynote/src/main/ets/views/common/` 6 个文件不移动；实际使用分布：`DailyNoteLoadingView` / `DailyNoteEmptyView` 被三页共用，`DailyNoteDataRow` / `DailyNoteSectionLabel` 用于 starrail + zzz，`DailyNoteCard` 仅 genshin（DailyNoteGenshin、GenshinDailyTaskContent），`ExpeditionItem` 仅 genshin（GenshinExpeditionSection） |
| ViewModel | 三个 VM 均 < 100 行，不拆分；StarRail / ZZZ 无测试 |

### 重构范围（建议）

- 目录结构已经符合 N-4：`common/` + `genshin/` / `starrail/` / `zzz/`。**M6 没有必须的目录移动**。
- 可选的页面骨架收敛（`DailyDetailScaffold` + `@BuilderParam`）不建议在 M6 做：需要同时改 3 个页面、3 个 Builder 和路由参数类，回归面大于收益；记录为 DAILY-I1。
- 允许的等价清理：统一三页的排版/注释（DAILY-L2）；抽 window 监听 helper（DAILY-L1），但必须与任何行为修改分开提交。
- 不要移动 `HomeViewModel` 依赖的三个 Param 类，也不要把 `common/` 组件下沉到游戏目录。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. **先修复 DAILY-M2**：测试改为调用 `TimeFormatUtil.formatSeconds(seconds, uiCtx)` / `formatTransformer(day, hour, minute, uiCtx)`（或按新签名重写），并修正 `init(1, ...)` → `init('1', ...)`；修复后 `GenshinDailyDetailViewModel.test.ets` 11 个用例应全绿。StarRail / ZZZ 无测试。
3. 冒烟：三个游戏便笺详情各进入一次；LOADING / EMPTY / ERROR 三态；宽屏 `maxWidth 600` 生效；返回首页不残留监听。

### 已知问题归属

- Medium（页面骨架复制 + window 监听只喂死状态）：记录，不强制在 M6 处理。
- Medium（DAILY-M3 ERROR 显示为不可点击的"点击同步"空态）：行为修复，建议 M6 内单独提交（区分 ERROR 空态文案或补 toast / 重试）；三页一起改。
- Medium（DAILY-M4 魔神任务卡片无数据源）：需产品决定"补数据源"还是"隐藏该卡片"，属行为变更，不随重构提交。
- 测试资产（DAILY-M2，不计入评级但**M6 验收前必须修**）：`GenshinDailyDetailViewModel.test.ets` 引用不存在的方法，属测试基建缺陷，建议单独提交。
- Low（window 样板 / 排版不一致）：可直接删除无效 window 监听 / 统一排版，但需与行为修改分开提交。

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 结构） | 页面 133/125/125、VM 97/82/63、测试 87 行；dailynote 分组 6/3/3/4=16；三页面 hint 资源、无 Logger、`@Builder` 行号；路由 `4-6 / 39-41 / 44-46` | ✅ 全部精确匹配 |
| 第 2 轮（关键代码段） | Genshin `@Param` L26 / `@Local` L27-29 / 生命周期 / 三态 build；`HomeViewModel.ets:52-54` 三个 Param import；`ViewState.EMPTY \|\| ERROR` 分支 | ✅ |
| 第 3 轮（全面复核） | StarRail vs ZZZ `diff` 仅名称差异；Genshin vs StarRail 8 行差异来源；三 VM catch 均设 ERROR；测试引用不存在方法；`windowWidthVp` 只写不读；common 组件实际使用分布 | ✅ 修正 4 类（测试状态 / 宽屏声明 / 重复度描述 / 共享组件范围）+ 新增 DAILY-M2 |
| 第 4 轮（2026-10-26 复核） | 按 README §1.4 口径把 DAILY-M2（测试引用失效方法）移出评级计数；重算 0/0/1/2 | ✅ 债务 6→4 |
| 第 5 轮（2026-10-27 逐条复核） | 逐行对照全部锚点（修正 `@Param` / `@Local` 行号）；补读 VM catch、`DailyNoteEmptyView`、`DailyNoteGenshin` 与 `toVM()`；新增 DAILY-M3 / DAILY-M4；补 ARKTS-014 合规行（随 DAILY-L1 消除，不单独计数） | ✅ 0/0/3/2，债务 4→8 |

| 第 6 轮（2026-10-30 断链修复） | 迁移前路径 `components/dailynote/*` → `features/dailynote/src/main/ets/views/*`；页面 / ViewModel / Model / 测试全量更新为 `features/dailynote/src/main/ets/` 绝对路径；Theme 常量从 `shares/` 修正到 `theme/`；TimeFormatUtil 补全路径 | ✅ 12 处路径全部验证存在 |

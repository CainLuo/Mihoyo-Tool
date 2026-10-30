# 测试套件分析（专项）

> **分析对象**：`entry/src/test/` —— **20 个文件 / 2,312 行 / 286 条 `it` 用例**
> **分析日期**：2026-10-24
> **代码版本**：`105c8d3`
> **性质**：专项（测试资产索引 + 覆盖缺口），**不单独评级**
> **为什么需要这份文档**：`Refactor_Spec` 把"Local Test 全绿"写成每个模块的验收门禁，但仓库里**没有一处**说明这套测试实际覆盖了什么、当前能不能跑。本文件补齐这一层。

---

## 1. 现状一句话

**286 条用例，当前一条也跑不起来**：`List.test.ets` 汇总的 19 个套件里，`HomeViewModel.test.ets:4` 从 `../main/ets/components/home/HomeModels` 导入，而该文件实际是 `models/HomeModels.ets`（`components/home/` 下没有 `HomeModels`）；**且 `GAME_GENSHIN` / `GAME_STARRAIL` / `GAME_ZZZ` 在 entry 与 core 中都没有定义**（`models/HomeModels.ets` 只导出 4 个 VM 类），只改路径仍编译不过。除此之外，`HomeViewModel.test.ets` 自身的 `KEYS` 以及另外 4 个测试文件也引用了源码中已不存在的符号（见 §2 标红行与 T1 / T6）。任一处都会让整个 Local Test 套件编译失败——这就是 `Refactor_Spec` §0.4 记的"已知红色基线"（§8 Q-9 / Q-10）。

---

## 2. 文件清单（20 / 2,312 行 / 286 用例）

| 文件 | 行数 | 用例数 | 被测对象 |
| --- | --- | --- | --- |
| `WidgetDataHelper.test.ets` | 286 | 41 | `WidgetDataHelper`（体力比例/颜色/恢复文案） |
| `StaminaNotificationService.test.ets` | 220 | 26 | `NotificationModels` 常量 + `hashNotifId`（**测试内复制版**：`StaminaNotificationService.test.ets:18` 自写一份；源方法 `StaminaNotificationService.ets:684` 为 `private static`，服务类本身未被导入） |
| `WidgetPayloadParser.test.ets` | 195 | 23 | `WidgetPayloadParser` |
| `CharactersViewModel.test.ets` | 182 | 24 | `CharactersViewModel`（**红**：`:2` 从 VM 导入 `AccountOption`，但 VM 只 import 未导出，类在 `models/AccountOption.ets:9`；`:53` `vm.gameTabs` 不存在（只有 private `gameTabsInternal`）；`:174/178` `KEYS` 不存在；`:132/133/143/152` 给 `accountId: string` 传 number） |
| `Widget2x2ViewModel.test.ets` | 182 | 19 | `Widget2x2ViewModel` |
| `StaminaThresholdCalculator.test.ets` | 179 | 23 | `StaminaThresholdCalculator` |
| `LoginViewModel.test.ets` | 162 | 22 | `LoginViewModel` |
| `WidgetDataHelperExtraRows.test.ets` | 159 | 13 | 额外数据行排序/截断（三游戏） |
| `HomeViewModel.test.ets` | 111 | 16 | `HomeViewModel`（**红**：`:4` 导入路径失效且 `GAME_*` 全仓无定义；`:103/107` `HomeViewModel.KEYS` 不存在，VM 只有顶层 const `HOME_VM_*`（`HomeViewModel.ets:71-79`）） |
| `MaterialCalcViewModel.test.ets` | 100 | 13 | `MaterialCalcViewModel` |
| `GenshinCharacterDetailViewModel.test.ets` | 90 | 13 | 原神详情 VM（**红**：`:58-79` `propertyTypeToResource` 已迁为 `utils/GenshinPropertyUtil.ets:56` 的 `genshinPropertyTypeToResource`；`:86` `KEYS` 不存在（VM 只有 `GENSHIN_CHAR_DETAIL_VM_*` 常量）；`:51` `init(1, …)` 与 `init(accountId: string, …)` 不符） |
| `GenshinDailyDetailViewModel.test.ets` | 87 | 11 | 原神便签 VM（**红**：`:34-82` 索引访问的 `formatSeconds` / `formatTransformer` 已迁到 `utils/TimeFormatUtil.ets:38/63`；`:25` `init(1, 'uid1')` 传 number） |
| `WidgetExtraRowConfig.test.ets` | 67 | 11 | 优先级配置 |
| `PrivacyConsentViewModel.test.ets` | 63 | 10 | 隐私同意 VM |
| `ToolsViewModel.test.ets` | 47 | 4 | 工具页 VM |
| `WidgetExtraRowType.test.ets` | 47 | 8 | 行类型常量 |
| `List.test.ets` | 40 | 0 | 汇总入口（19 个套件） |
| `MyViewModel.test.ets` | 32 | 4 | 我的页 VM |
| `LocalUnit.test.ets` | 32 | 1 | hypium 模板用例（`assertContain`） |
| `AccountDetailViewModel.test.ets` | 31 | 4 | 账号详情 VM（**红**：`:22-27` `KEYS` 不存在，VM 只有 `ACCOUNT_DETAIL_VM_*` 常量） |

---

## 3. 覆盖矩阵

### 3.1 页面 ViewModel（24 个 → 10 个有测试）

| 有测试（10） | 无测试（14） |
| --- | --- |
| `AccountDetail` · `Characters` · `GenshinCharacterDetail` · `GenshinDailyDetail` · `Home` · `Login` · `MaterialCalc` · `My` · `PrivacyConsent` · `Tools` | `AppearanceSettings` · `NotificationSettings` · `WidgetConfig` · `MaterialCharacterSelect` · `Genshin/StarRail/ZZZMaterialList` · `Genshin/StarRail/ZZZMaterialTargetConfig` · `StarRail/ZZZCharacterDetail` · `StarRail/ZZZDailyDetail` |

### 3.2 其他层

| 层 | 有测试 | 无测试 |
| --- | --- | --- |
| widget ViewModel（4） | `Widget2x2ViewModel` | `Widget1x2` / `Widget2x4` / `Widget4x4` |
| widget utils（16） | `WidgetPayloadParser` · `WidgetDataHelper` · `WidgetExtraRowConfig` · `WidgetExtraRowType` | `WidgetPayloadBuilder`(358) · `WidgetDataStoreBuilder`(365) · `WidgetImageDownloader`(479) · `WidgetUpdateNotifier`(146) 等（另 `widget/models/WidgetDataStore`(452) 同样无测试；`WidgetUtils` 只被借用 `WIDGET_GAME_ID` 常量） |
| notification（5） | `StaminaThresholdCalculator` · `NotificationModels` 常量 | `StaminaNotificationService`（调度逻辑与 `hashNotifId` 均未直接测，见 §2）· 两个 Store |
| 共享层（52） | 仅被间接引用（`ViewStates` / `LoginTabEnum` / 3 个 models） | `utils/` 22 个文件全部无直接测试 |
| 组件（195） | — | 全部无测试（`@Preview` 是唯一的手工验证手段） |
| Ability（4） | — | 全部无测试（只能冒烟） |

### 3.3 关键结论

- **重构的主战场（组件目录）完全没有测试**：195 个组件 14,931 行，靠"编译 + 冒烟"兜底。
- **有测试的 10 个 ViewModel 恰好是 M1–M12 的主要对象**，所以 §2.5 的"路径冻结"实质是在保护这 10 个文件；但其中 5 个（Home / AccountDetail / Characters / GenshinCharacterDetail / GenshinDailyDetail）的测试已与实现脱节（§2 标红行），修好之前这 5 个模块的"Local Test 通过"不可兑现。
- **M14 的 3 个 High 所在文件基本无测试**（见 [widget-subsystem-modules-analysis.md](./widget-subsystem-modules-analysis.md) §6 / §7）：H1 `WidgetUpdateNotifier`、H2 `EntryFormAbility` / `WidgetMockData` 无测试；H3 链路中只有 `WidgetPayloadParser` 有单测（只测解析，不涉及新鲜度渲染）。

---

## 4. 运行方式与现实约束

| 项 | 事实 | 影响 |
| --- | --- | --- |
| 套件类型 | `entry/src/test` 是 **Local Test**（宿主机运行，不能碰 `@kit.*` 系统 API） | 只能测纯逻辑；任何依赖 preferences / reminderAgent / UI 的代码都测不到 |
| 入口 | `List.test.ets` 的 `testsuite()` 依次调用 19 个套件 | 任一文件编译失败 → 整套失败（当前即如此） |
| CLI | `hvigorw tasks --mode module -p module=entry@default` 只有 `tasks` / `taskTree` / `init`，**没有 test 任务** | 只能在 DevEco Studio 里 Run Test（`Refactor_Spec` §0.3） |
| 脚本 | `test-entry.sh` / `test-core.sh` 只 `assembleHap` ohosTest HAP（编译验证） | 不是测试执行器 |
| ohosTest | `log.md` 记录的编译失败原因是引用已不存在的 `../main/ets/parsers/*`；但当前 `entry/src/ohosTest/ets/test/core/*.test.ets` 已改为从 `'core'` 导入（如 `GenshinComputeParser.test.ets:12`），全目录不再出现 `parsers/`——该日志可能已过期，现状未验证 | 不在本次门禁内（§0.4） |

---

## 5. 风险与建议

| # | 问题 | 影响 | 建议 |
| --- | --- | --- | --- |
| T1 | `HomeViewModel.test.ets:4` 导入路径失效，且导入的 `GAME_GENSHIN` / `GAME_STARRAIL` / `GAME_ZZZ` 全仓无定义；`:103/107` 的 `HomeViewModel.KEYS` 也不存在 | **286 条用例全部无法编译**，"Local Test 全绿"门禁形同不存在 | 只改路径到 `models/HomeModels` **不够**：还要把 `GAME_*` 换成 core 的 `GameId` 枚举、`KEYS.*` 换成 `HOME_VM_*` 常量——需要 §8 Q-9 批准，因为 `entry/src/test` 在作用域外 |
| T2 | 14 个 ViewModel 无测试 | 重构这些模块时只有冒烟 | 需 §8 Q-1 批准新增测试；否则只能把冒烟清单写细（各模块文档的"验收"节已给出） |
| T3 | 组件层 0 测试 | 拆分组件（M9/M10/M7）几乎没有自动回归 | 同上；短期靠 `@Preview` + 真机冒烟 |
| T4 | 测试与实现的耦合是"相对路径 + 导出名" | 任何文件移动/改名都会打断测试 | 已成为 §2.5 白名单；重构时必须保留 facade |
| T5 | `LocalUnit.test.ets` 是模板残留 | 1 条 `assertContain('abc','b')`，不验证任何业务 | 可保留（成本为零），但不要把它计入覆盖率 |
| T6 | 另外 4 个测试文件引用已不存在 / 未导出的符号（明细见 §2 标红行）：`AccountDetailViewModel` / `CharactersViewModel` / `GenshinCharacterDetailViewModel` 的 `KEYS`；`CharactersViewModel.test.ets:2` 的 `AccountOption`、`:53` 的 `gameTabs`；`GenshinCharacterDetailViewModel.test.ets:58-79` 的 `propertyTypeToResource`；`GenshinDailyDetailViewModel.test.ets:34-82` 的 `formatSeconds` / `formatTransformer`；以及 3 个文件里共 6 处给 `string` 参数传 number | 与 T1 同样阻塞整套编译；`Refactor_Spec` §0.4 / Q-10 目前只列了其中 AccountDetail 与 GenshinDailyDetail 两处 | 测试侧对齐现有导出（常量 / `models/AccountOption` / `utils/GenshinPropertyUtil` / `utils/TimeFormatUtil`），不动产品代码；需 Q-10 批准，与 T1 合并为一个提交（Q-11） |

---

## 6. 与 Refactor_Spec 的关系

1. **§2.5 测试白名单**（24 个导入路径 + 导出符号）来自本文件的覆盖矩阵。路径层面：白名单记的是 `models/HomeModels`，测试实际导入的 `components/home/HomeModels` 不存在；符号层面：T1 / T6 列出的 `GAME_*`、`KEYS`、`AccountOption`（从 VM 导入）、`propertyTypeToResource`、`formatSeconds` / `formatTransformer` 在源码中不存在或未导出。
2. **§0.1 基线表**的 "Local Test" 一行已记为"已知失败（T1）"；原因描述只提 T1，需补 T6。
3. **每个模块的验收**：有测试的 10 个模块写"Local Test 通过"，其余 14 个只能写"冒烟"。各模块文档的"重构执行备注 → 验收"已按此区分。
4. **T1 + T6 是 Phase 0 的前置**：不修这些引用，"测试全绿"这条门禁无法成立；修它属于改 `entry/src/test`，必须由用户批准（Q-9 / Q-10）。

---

*本文档仅索引，不修改代码。*

### 复核记录（2026-10-26 第 4 轮）

| 检查项 | 结论 |
| --- | --- |
| 文件数 | 20 个 `*.test.ets`（含 `List.test.ets` 汇总入口），与 `find entry/src/test -name '*.test.ets'` 一致 |
| 用例数 | 逐文件 `grep -c "^\s*it("` 求和 = **286**；修正原表 2 行（`GenshinCharacterDetailViewModel.test.ets` 14→13、`GenshinDailyDetailViewModel.test.ets` 12→11） |
| 行数 | 20 个文件行数与表格逐行一致（最大 `WidgetDataHelper.test.ets` 286 行） |
| 红色基线 | `HomeViewModel.test.ets:4` 导入路径失效、`AccountDetailViewModel.test.ets:22-28` 引用不存在的 `KEYS`、`GenshinDailyDetailViewModel.test.ets` 索引调用已迁走的方法，三处均在 `List.test.ets` 注册链路上 |


### 复核记录（2026-10-27 第 5 轮）

| 检查项 | 结论 |
| --- | --- |
| 用例数 / 行数 | 逐文件 `grep -cE '^\s*it\('` 与 `wc -l` 复算：286 条 / 2,312 行，表格 20 行全部一致；修正页首 288→286 |
| 红色基线 | 脚本比对测试中所有 `Class.member` / `vm.member` / 具名导入与源码声明：除第 4 轮 3 处外，另有 `HomeViewModel.KEYS`、`GAME_*` 全仓无定义、`CharactersViewModel`（`AccountOption` 未导出 / `gameTabs` / `KEYS`）、`GenshinCharacterDetailViewModel`（`propertyTypeToResource` / `KEYS`），补为 T6 |
| 其他 | ohosTest 已不再引用 `parsers/*`；`WidgetDataStore` 位于 `widget/models/`；`hashNotifId` 为测试内复制版 |

【已核对代码一致性】

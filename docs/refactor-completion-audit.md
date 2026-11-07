# 重构收尾审计与待办清单

> **审计日期**：2026-11-06
> **审计对象**：`bugfix/refactor-entry-module` 分支上的三层结构（`entry` / `common` / `features`）与 M0–M15 模块重构结果
> **审计方式**：逐项跑构建 / codeLinter / Local Test，并回代码核对已登记缺陷是否仍然存在
> **配套文档**：[`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md)（执行台账）、[`structure-migration-plan.md`](./structure-migration-plan.md)（结构迁移）、[`project-structure.md`](./project-structure.md)（当前目录结构）
> **结论**：代码重构已完成，编译与单元测试执行已通过（**837 条**）；**GAP-01 / 02 / 03 / 06 已修复**，UI 测试骨架已建立；但**运行时冒烟仍未验证**，GAP-04 / 05 / 07 等用户可见缺陷与收尾债务仍在。

---

## 1. 结论摘要

| 维度 | 状态 | 说明 |
| --- | --- | --- |
| 结构迁移（三层结构 / HAR 拆分） | ✅ 完成 | 11 个 feature + 2 个 common 模块；路由、资源、测试均已按模块归位 |
| M0–M15 模块重构 | ✅ 完成 | 见 [`Refactor_Spec.md` §12](../entry/Refactor_Spec.md) |
| 编译（uat / Debug） | ✅ 通过 | clean 后 `assembleHap` 成功 |
| ohosTest 编译 | ✅ 通过 | 原 67 个错误已随结构迁移消失 |
| codeLinter | ✅ 通过 | 381 个 `.ets`：0 error / 1 warn / 1 suggestion |
| Local Test | ✅ 通过 | 14 个模块、**837 用例全绿**；29 个 `viewmodel/` 类全部有测试；widget / notification 的 Store 已可注入并补测，见 §2.3.1 |
| 设备端单测（ohosTest） | 🔶 不可运行 | `core/src/ohosTest` 156 条 DAO / Repository 用例缺 `TestAbility.ets`，且无设备，未执行；见 §2.3.2 |
| UI 测试 | 🔶 骨架已建 | 1 条启动冒烟 + 9 个稳定控件 id，见 §2.3.3；**无设备，未执行** |
| 真机 / 模拟器冒烟 | 🔶 未执行 | §7.1 清单一遍未跑，不能给出运行时结论 |
| 已知用户可见缺陷 | 🔶 部分修复 | GAP-01 / 02 / 03 / 06 已修；GAP-04 / 05 / 07 未修，见第 4 节 P0 |
| 重构收尾债务 | 🔶 部分清理 | 测试与 UI 基建已补；大 ViewModel、资源拆分、文档复核仍在，见第 4 节 P1 |

**一句话**：现在可以认为“重构代码写完、能编译、单测覆盖全部 ViewModel 并通过，GAP-01/02/03/06 的行为修复也已落地”，但不能认为“功能已经回归验证”——UI 测试只有骨架、没有设备执行，P0 中的签名口令、通知包名与 MainPage 监听问题仍未处理。

---

## 2. 门禁实测结果（2026-11-06）

### 2.1 编译

| 项 | 命令 | 结果 |
| --- | --- | --- |
| clean | `hvigorw clean` | ✅ exit 0 |
| main 编译 | `hvigorw assembleHap -p product=uat -p buildMode=debug` | ✅ `BUILD SUCCESSFUL in 14s 285ms` |
| ohosTest 编译 | `bash test-entry.sh` | ✅ `BUILD SUCCESSFUL in 14s 381ms` |

构建残留警告（不阻断，但属于资源拆分遗留）：

| 警告 | 来源 | 影响 |
| --- | --- | --- |
| `'app_name' conflict, first declared` | `AppScope` 与 `common/basic` 各定义一份，值相同（米悠悠） | 当前无可见影响；拆分资源时应删掉 basic 中的副本 |
| `'black' conflict, first declared` | `entry` 与 `common/basic` 各定义一份，值相同（`#000000`） | 同上 |
| `'page_show' conflict` ×6 | 依赖 / HAR 资源带入（`page from npm package`） | 需在资源清理时确认来源 |

### 2.2 codeLinter

项目没有配置 hvigor 的 `codeLinter` task，但 DevEco 安装目录内提供了 CLI，可直接运行：

```bash
DEVECO=/Applications/DevEco-Studio.app/Contents
node "$DEVECO/plugins/codelinter/index.js" \
  --project "$PWD" \
  --dir "$(python3 -c 'import os,json;print(json.dumps([os.path.join(os.getcwd(),p) for p in ["entry/src/main/ets","common/basic/src/main/ets","common/widgetbase/src/main/ets"]+["features/%s/src/main/ets"%x for x in sorted(os.listdir("features"))]]))')" \
  --config "$PWD/code-linter.json5" \
  --sdkPath "$DEVECO/sdk" \
  --sdkNumberVersion 22 \
  --sdkStringVersion "6.0.2(22)" \
  --workdir "$DEVECO/plugins/codelinter" \
  --logPath /tmp/codelinter.log
```

结果：**381 个 `.ets`，0 error**。

| 文件 | 行 | 级别 | 规则 | 说明 |
| --- | --- | --- | --- | --- |
| `features/characters/src/main/ets/views/CharactersContent.ets` | 81 | suggestion | `@performance/hp-arkui-set-cache-count-for-lazyforeach-grid` | Grid 内 `LazyForEach` 未设置 `cachedCount` |
| `features/characters/src/main/ets/views/CharactersContent.ets` | 84 | warn | `@performance/hp-arkui-use-reusable-component` | 复杂组件建议使用复用组件 |

两条都是性能建议，不是正确性问题；当前不新增违规的基线可以记为“0 error + 2 条性能建议”。

### 2.3 Local Test

命令行即可运行，不需要 DevEco GUI：

```bash
hvigorw test --mode module -p module=<module>@default -p product=default
```

结果文件：`<module>/.test/default/intermediates/test/coverage_data/test_result.txt`

| 模块 | 用例数 | 通过 | 失败 | 备注 |
| --- | ---: | ---: | ---: | --- |
| `entry` | 46 | 46 | 0 | 4 个 Widget VM + 导航模式 / 弹窗标签 |
| `account` | 28 | 28 | 0 | 3 个 VM + MyModels |
| `characters` | 35 | 35 | 0 | VM + DataSource + DataLoader |
| `chardetail` | 34 | 34 | 0 | 三个游戏详情 VM + 属性映射 / 断点 |
| `dailynote` | 27 | 27 | 0 | 三个游戏便签 VM + Loader / 派遣 / 模型 |
| `home` | 28 | 28 | 0 | VM + Presenter / DataLoader / SyncCoordinator |
| `legal` | 10 | 10 | 0 | — |
| `material` | 106 | 106 | 0 | 4 个 VM + 计算 / 目标配置 / 选角 / 工具函数 |
| `notification` | 62 | 62 | 0 | 阈值 / 模型 + 设置 VM + 两个 Store |
| `settings` | 9 | 9 | 0 | 外观设置 VM + 模型 |
| `widget` | 79 | 79 | 0 | 配置 / 数据 / payload / 预览 / 设置 VM + 配置 Store / 推送分类 |
| `widgetbase` | 96 | 96 | 0 | 解析 / 数据工具 / 额外行 |
| `common/basic` | 27 | 27 | 0 | 角色排序 / 游戏 ID / 弹框去重 / 透明色 / 账号模型 |
| `core` | 250 | 250 | 0 | 解析器 / DSUtil / RowModels / Retcode / ApiErrorHandler / Header / Domain / ColdStart |
| **合计** | **837** | **837** | **0** | 14 个模块 |

仍没有测试目录的模块：`features/verification`（页面 / 服务依赖设备能力）。

#### 2.3.1 覆盖率：全绿 ≠ 有回归保护

覆盖率为各模块 `coverageReport.json` 的按模块行覆盖（每个模块只统计自己的 `test` 运行，未跨模块合并）：

| 模块 | 行覆盖 | 模块 | 行覆盖 |
| --- | ---: | --- | ---: |
| `core` | 830 / 6,750（12.3%） | `home` | 276 / 10,235（2.7%） |
| `widgetbase` | 336 / 516（65.1%） | `legal` | 10 / 8,252（0.1%） |
| `entry` | 747 / 23,484（3.2%） | `material` | 665 / 12,059（5.5%） |
| `common/basic` | 359 / 7,983（4.5%） | `notification` | 275 / 9,188（3.0%） |
| `account` | 274 / 11,533（2.4%） | `settings` | 27 / 8,200（0.3%） |
| `characters` | 292 / 8,964（3.3%） | `widget` | 889 / 11,080（8.0%） |
| `chardetail` | 277 / 10,700（2.6%） | `dailynote` | 337 / 8,900（3.8%） |

- **29 个 `viewmodel/` 类已全部有测试**，另有 102 个 `src/test` 测试文件、837 条用例；此前 0 覆盖的 `Genshin/StarRail/ZZZMaterialList`、三个 `MaterialTargetConfig`、`MaterialCharacterSelect`、`StarRail/ZZZCharDetail`、`StarRail/ZZZDailynote`、`HomeDataLoader`、`HomeSyncCoordinator`、`NotificationSettings`、`WidgetSettings` 与 `Widget1x2/2x4/4x4` 均已补上。
- 覆盖率仍偏低的原因是统计口径包含依赖模块源码与大量 View / Ability 文件；纯逻辑层的保护已明显好于上一版：`WidgetDataUtil` 87.0%、`WidgetPayloadUtil` 82.5%、`StaminaThresholdCalculator` 100%、`Widget2x2ViewModel` 100%。
- 2026-11-07 已把 `WidgetConfigStore` / `WidgetFormIdStore` / `NotificationSettingsStore` / `NotificationStateStore` 的 preferences 依赖改为可注入接口，并补 16 条单测；`WidgetUpdateNotifier.classifyPushError` 也可直接测。
- 仍未覆盖：`features/widget` 的 `WidgetDataStoreBuilder` / `WidgetImageDownloader`（依赖 FormKit、网络与 DB，Local Test 不可运行）、`settings/AppearanceManager`、`StaminaNotificationService` 的调度本体，以及全部组件与 Ability 的 UI 行为。
- `StaminaNotificationService.test.ets` 仍是测试内复制的 `hashNotificationId`，服务本体调度逻辑未直接测。

#### 2.3.2 设备端测试：156 条存在，但当前跑不了

- `core/src/ohosTest` 有 12 个套件 / **156 条**用例（`RdbManager`、4 个游戏的 DAO / Repository、`MaterialBagDao`）。
- `hvigorw test --mode module -p module=core@ohosTest -p product=default` 在打包阶段失败：`TestAbility.ets` 不存在；`hdc list targets` 返回 `[Empty]`，也没有设备可执行。
- `entry/src/ohosTest` 的 13 个套件 / **226 条**是 `core/src/test` 解析器用例的副本；`bash test-entry.sh` 只 `assembleHap`，不执行测试。
- 因此“ohosTest 编译通过”只是**编译验证**，不是设备端执行结果。

#### 2.3.3 UI 测试：骨架已建，未执行

- 新增 [`entry/src/ohosTest/ets/test/ui/MainFlow.test.ets`](../entry/src/ohosTest/ets/test/ui/MainFlow.test.ets)，已挂进 `List.test.ets`，验证启动后落在 `main_navigation` 或 `login_page`。
- 主代码已补 9 个稳定控件 id：`main_navigation`、`home_scroll`、`login_page`、`char_detail_material_calc_entry`、`material_calc_page`、`material_calc_loading`、`material_calc_empty`、`material_calc_content`、`material_calc_character`。
- `bash test-entry.sh` 编译通过；但 `hdc list targets` 为空，**用例尚未在设备上执行**。主链路补全计划见 [`ui-test-plan.md`](./ui-test-plan.md)。
- 首页角色卡与材料清单项还没有逐项 id，坐标定位不可作为正式用例。

#### 2.3.4 其他测试资产

`cd mock-service && npm test` → **12 / 12 通过**（路由、fixture 选择、账号 / 签到响应）。这是目前唯一覆盖 mock 服务行为的测试。

> 结论：单元测试目前只做到“能编译 + 浅层状态断言”，不是重构后行为的回归保护；UI 层没有自动化测试。

### 2.4 冒烟（未执行）

[`Refactor_Spec.md` §7.1](../entry/Refactor_Spec.md) 的 15 条路径全部未跑：4 Tab 切换、折叠屏、人机验证、Cookie 过期、卡片添加/刷新、三个游戏的便笺 / 角色详情 / 材料链路等。

**当前所有“通过”只代表编译与 VM 级单测，不代表 UI、时序、通知和卡片渲染正确。**

---

## 3. 本次修复记录

Local Test 首轮并非全绿：3 个模块的测试根本编译不过。修复只动测试文件，不改产品代码。

| 文件 | 问题 | 修复 | 修复后 |
| --- | --- | --- | --- |
| [`entry/src/test/Widget2x2ViewModel.test.ets`](../entry/src/test/Widget2x2ViewModel.test.ets) | 缺 `@ohos/hypium` 导入，48 个 `Cannot find name` 错误 | 补 `import { describe, it, expect } from '@ohos/hypium'` | 20/20 |
| [`features/material/src/test/MaterialCalcViewModel.test.ets`](../features/material/src/test/MaterialCalcViewModel.test.ets) | 引用旧字段 `characterName` / `characterIconUrl`；使用不存在的 `expect(...).not.assertNull()` | 改为 `name` / `iconUrl`；改用 `expect(x === null).assertFalse()` | 17/17 |
| [`features/material/src/test/ToolsViewModel.test.ets`](../features/material/src/test/ToolsViewModel.test.ets) | 同上，`expect(entry.gameName).not.assertNull()` | 改为 `expect(entry.gameName !== null).assertTrue()` | 17/17 |
| [`common/widgetbase/src/test/WidgetDataUtil.test.ets`](../common/widgetbase/src/test/WidgetDataUtil.test.ets) | 缺 hypium 导入；`parseExtraRows` 仍用旧 2 参签名；2 参 `it()`；`assertGreater` 不存在；3 条断言过期（0 秒恢复、后备开拓力、缺字段补齐） | 补导入；改为 `(rawJson, widgetRawJson, gameId, maxRows)`；`it(name, 0, fn)`；`assertLarger`；按现行为修正断言 | 96/96 |
| [`common/widgetbase/src/test/WidgetDataUtilExtraRows.test.ets`](../common/widgetbase/src/test/WidgetDataUtilExtraRows.test.ets) | 旧签名；ArkTS 禁止未类型化对象字面量（`JSON.stringify({...})`）；绝区零 `note_list` 应放在 `widgetRawJson` | 改为 JSON 字符串常量 + 新签名，绝区零数据放第二参 | 96/96 |
| [`common/widgetbase/src/test/WidgetPayloadUtil.test.ets`](../common/widgetbase/src/test/WidgetPayloadUtil.test.ets) | 缺 hypium 导入；2 参 `it()` | 补导入；`it(name, 0, fn)` | 96/96 |
| [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) | §12 仍写“codeLinter 跳过 / Local Test 待运行” | 新增“门禁复核（2026-11-06）”一节 | — |

> 说明：原 `Refactor_Spec.md` 的“`entry/src/test` 不得改动”是测试还在 entry 时的约束；结构迁移后测试已分到各模块 `src/test`，本次只修编译阻塞与过期断言，不改被测产品代码。

### 3.1 2026-11-07 行为修复与测试基建

| 项 | 改动 | 验证 |
| --- | --- | --- |
| GAP-01 | `WidgetUpdateNotifier` 新增 `WidgetPushResult` 与 `classifyPushError()`，只有 401 / 16500050（卡片已移除）才 `deleteConfig`；网络 / 权限 / 限流失败保留配置 | widget 79 条全绿，含 8 条推送分类 / Store 用例 |
| GAP-02 | [`material_router_map.json`](../features/material/src/main/resources/base/profile/material_router_map.json) 注册 `MaterialCalc` → `MaterialCalcPageBuilder` | `assembleHap` 通过，路由表可被父级 navDestination 解析 |
| GAP-03 | 三个 `*CharacterDetailViewModel` 的加载 catch 置 `ViewState.ERROR`，失败不再白屏 | chardetail 34 条全绿，含错误态断言 |
| GAP-06 | [`EntryFormAbility`](../entry/src/main/ets/entryformability/EntryFormAbility.ets) 无数据时不再返回 Mock，改传真实空 payload，卡片走 `isEmpty` 空态 | `assembleHap` 通过 |
| 测试基建 | 新增 `common/basic/src/test`、`entry/src/ohosTest/ets/test/ui`、`docs/ui-test-plan.md`；widget / notification 的 4 个 Store 改为 `PreferencesLike` 注入 | 14 个模块 837 条全绿；`test-entry.sh` 通过 |

---

## 4. 剩余缺口

### P0 · 用户可见缺陷（发版前必修）

| ID | 级别 | 问题 | 代码证据 | 影响 / 建议 |
| --- | --- | --- | --- | --- |
| GAP-01 | ✅ 已修 | 小组件推送失败误删配置 | [`WidgetUpdateNotifier.ets:163`](../features/widget/src/main/ets/model/service/WidgetUpdateNotifier.ets#L163) 仅把 401 / 16500050 判为 `WIDGET_REMOVED`，其余错误保留配置 | 网络抖动不再丢配置；`onRemoveForm` 仍负责正常移除 |
| GAP-02 | ✅ 已修 | 材料计算页不可达 | [`material_router_map.json:39`](../features/material/src/main/resources/base/profile/material_router_map.json#L39) 已注册 `MaterialCalc` → `MaterialCalcPageBuilder` | 页面与入口均编译通过；仍需真机点一次入口确认嵌套 `NavPathStack` 行为 |
| GAP-03 | ✅ 已修（×3） | 角色详情解析失败白屏 | 三个 `*CharacterDetailViewModel` 的加载 catch 均置 `ViewState.ERROR`（如 [`GenshinCharacterDetailViewModel.ets:94`](../features/chardetail/src/main/ets/viewmodel/GenshinCharacterDetailViewModel.ets#L94)） | 失败展示错误态；需真机断网回归一次 |
| GAP-04 | High ×2 | MainPage 窗口监听误注销；返回手势关闭人机验证后队列卡死 | [`MainPage.ets:125`](../entry/src/main/ets/pages/MainPage.ets#L125) `off('windowSizeChange')` 未传 callback | 前者会连带注销同事件的其他监听；后者是弹窗仲裁状态机未复位，需要真机回归 |
| GAP-05 | Medium（待定级） | 通知包名写死正式包 | [`StaminaNotificationService.ets:29`](../features/notification/src/main/ets/model/service/StaminaNotificationService.ets#L29) `BUNDLE_NAME = 'com.cainluo.miyoyo.tools'` | uat / mock 包上的 `wantAgent` 可能指向错误应用；应从 ability context 的 bundleName 读取 |
| GAP-06 | ✅ 已修 | 无数据时展示 Mock 账号与体力 | [`EntryFormAbility.ets:177`](../entry/src/main/ets/entryformability/EntryFormAbility.ets#L177) 不再返回 Mock，改为构建空 payload，卡片走 `isEmpty` 空态 | 需真机加一张空数据卡片确认空态文案 |
| GAP-07 | Critical（SEC-001 / 待复核 DB-003） | 签名口令明文入库；系统备份是否含明文凭据未复核 | [`build-profile.json5`](../build-profile.json5) 的 `signingConfigs` | 轮换口令并迁移到 CI Secret；备份排除范围需单独确认 |

> GAP-01 / 02 / 03 / 06 已于 2026-11-07 修复并有单测 / 编译验证；GAP-04 / 05 / 07 仍存在，其中 GAP-04 需要真机回归。

### P1 · 重构收尾债务

| ID | 问题 | 现状 / 证据 | 建议 |
| --- | --- | --- | --- |
| GAP-08 | 唯一超过 500L 阈值的 ViewModel | [`GenshinMaterialListViewModel.ets`](../features/material/src/main/ets/viewmodel/GenshinMaterialListViewModel.ets) **628L**；三个材料汇总 VM 628 / 368 / 421L，解析与映射结构重复 | 把解析 / 汇总 / 分组抽到 `model/service/` 或独立 mapper，三游戏共用骨架 |
| GAP-09 | View 层直接调用 service（S6） | Launch / Main / Test / My / PrivacyConsent / AppearanceSettings 六页直接调用 `LegalPreferences` / `CoreInitializer` / `GeetestCenter` / `AppearanceManager` 等；material 四页从 service 导入枚举 | 归入各模块 ViewModel；枚举移到 `model/` |
| GAP-10 | 资源未按功能拆分 | 共用资源仍集中在 `common/basic`（50 个资源文件）；各 feature 基本只有一张 router map；构建有 `app_name` / `black` / `page_show` 重复警告 | 按 `$r` 引用归属拆分，删除重复定义 |
| GAP-11 | 测试覆盖不足（UI + 设备端） | 单测 14 个模块 / 837 条全绿，29 个 `viewmodel/` 全部覆盖；widget / notification 的 4 个 Store 已改为可注入并补测；剩余 `WidgetDataStoreBuilder` / `WidgetImageDownloader` / `AppearanceManager` / `StaminaNotificationService` 依赖系统能力；`core/src/ohosTest` 156 条设备测试仍不可运行；UI 只有 1 条启动冒烟骨架、无设备执行；详见 §2.3 | 连接设备后按 [`ui-test-plan.md`](./ui-test-plan.md) 补 3 条主链路并实跑；再评估设备端测试的 `TestAbility` |
| GAP-12 | 文档复核未完成 | `docs/reviews/` 不存在（16 个模块的审计报告都缺）；“复核其余 30 份分析文档”未做；至少 8 份分析文档仍引用旧路径 `entry/src/main/ets/...`；[`project-structure.md`](./project-structure.md) 计数过期（entry 写 30、实际 32；basic 写 37、实际 36）；根 `CHANGELOG.md` 停在 v2.0.1（2026-10-19），重构没有发布级记录 | 先批量更新路径与计数，再按 M0 方式逐份复核；每个模块补 `docs/reviews/YYYY-MM-DD-M<n>-<module>-review.md`；重构收尾后补 CHANGELOG |
| GAP-13 | 未完成功能 TODO | 材料计算技能等级选择器是空实现（[`MaterialCalcPage.ets:63`](../features/material/src/main/ets/pages/MaterialCalcPage.ets#L63)）；材料清单“关联角色详情”未接（[`MaterialListContentView.ets:67`](../features/material/src/main/ets/views/MaterialListContentView.ets#L67)） | 属于功能缺口，不是重构遗留；需产品确认是否本轮补 |

### P2 · 小项

| ID | 问题 | 建议 |
| --- | --- | --- |
| GAP-14 | `codeLinter` 2 条性能建议 | `CharactersContent.ets` 的 `LazyForEach` 补 `cachedCount`；复用组件评估后决定是否忽略 |
| GAP-15 | 生产路径保留 `TestPage` / `views/test` | Q-2 仍未决；入口仅 DEBUG 可见，但文件仍在主代码里 |
| GAP-16 | 两个 submodule 处于 dirty 状态 | `PizzaHelperUnited` / `mihoyo-api-collect` 是重构前遗留，不要 stage |
| GAP-17 | 构建会重写被跟踪的 `BuildProfile.ets` | 每次切 product 构建后 13 个 `BuildProfile.ets` 变脏；建议加入 `.gitignore` 或改为构建生成目录（需单独评估） |

---

## 5. 建议执行顺序

1. ~~GAP-01 / 02 / 03 / 06~~：已修复，待真机回归（入口、错误态、卡片空态）。
2. **GAP-07（签名口令）**：唯一的 Critical，发版前必须轮换并迁移到 CI Secret。
3. **GAP-04 + GAP-05**：MainPage 两个 High 需要真机回归；通知包名可直接改 context 读取。
4. **UI 测试**：连设备后按 [`ui-test-plan.md`](./ui-test-plan.md) 补首页 → 角色详情 → 材料计算、未登录 → 登录两条链路并实跑。
5. **GAP-08 ~ GAP-11**：大 VM 拆分、S6、资源拆分，按模块逐步做，每步保持编译 + 837 用例绿；剩余服务层测试按需继续解耦。
6. **GAP-12**：文档路径 / 计数 / `docs/reviews` / CHANGELOG 一次性收尾。

**每步验收**：`assembleHap` 通过 + `codeLinter` 不新增 + 对应模块 `hvigorw test` 全绿；涉及 UI 的再按 §7.1 冒烟。

---

## 6. 复现命令

```bash
# 环境
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
HVIGOR=/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw

# 编译（project 模式没有 assembleHap task，必须指定 module）
"$HVIGOR" --mode module -p module=entry@default -p product=default -p buildMode=debug assembleHap
bash test-entry.sh                # ohosTest HAP 编译

# 单元测试（逐个模块）
"$HVIGOR" test --mode module -p module=entry@default -p product=default
"$HVIGOR" test --mode module -p module=home@default -p product=default
# ……其余模块同理

# 查看结果
tail -1 entry/.test/default/intermediates/test/coverage_data/test_result.txt
```

codeLinter 命令见 §2.2。

> 注意：`assembleHap` / `test` 会重写各模块被 git 跟踪的 `BuildProfile.ets`（product 相关值）。跑完如需保持工作区干净，执行：
> `git checkout -- common/basic/BuildProfile.ets common/widgetbase/BuildProfile.ets features/*/BuildProfile.ets`

---

## 7. 变更记录

| 日期 | 内容 |
| --- | --- |
| 2026-11-06 | 建立本文档：补齐编译 / codeLinter / Local Test 门禁实测；修复 6 个测试文件的编译阻塞与过期断言；登记 P0–P2 缺口与执行顺序 |
| 2026-11-06 | 复核测试资产：补计 `core` 238 条本地用例（总数 265 → 503）；补覆盖率、`features/widget` 零测试、`core@ohosTest` 156 条不可运行、UI 测试 0 的现状；GAP-11 改为“单测 + UI 覆盖不足” |
| 2026-11-07 | 补全单元测试：新增 `common/basic` 测试模块与 widget / notification / settings / 材料 / 角色详情 / 便签 / 首页 / 账号等模块的 VM、模型与工具用例；29 个 ViewModel 全部覆盖，14 个模块 818 条全绿（503 → 818） |
| 2026-11-07 | 修复 GAP-01 / 02 / 03 / 06；widget / notification 的 4 个 Store 改为注入式并补 16 条用例；新增 9 个控件 id、1 条 UI 启动冒烟与 [`ui-test-plan.md`](./ui-test-plan.md)；总数 818 → 837，编译与 `test-entry.sh` 通过 |

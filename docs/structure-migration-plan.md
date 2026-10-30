# 工程结构迁移计划（多设备三层结构）

> **方案依据**：[structure-proposal.md](./structure-proposal.md)（官方"一次开发，多端部署"三层结构 + MVVM 模块内分层）
> **决策记录**（2026-10-28，用户确认）：
> - 采用官方三层结构：`common` / `features` / `products`；设备分组：现有 `entry`（phone / tablet / 2in1，**原位置、原模块名不动**，相当于官方 `products/default`），`products/wearable` = wearable（阶段 3）。
> - `core` 不动（不在 entry 重构范围）。
> - features 划分：官方只规定原则"各个 feature 高内聚、低耦合、可定制"（[introduction.md](https://gitee.com/openharmony/docs/blob/OpenHarmony-5.0.0-Release/zh-cn/application-dev/key-features/multi-device-app-dev/introduction.md)），未规定具体粒度；本项目按现有页面职责划为 11 个（见方案 §3），按该原则执行。
> - 手表：**仅规划**；功能范围只显示 widget（便笺 / 体力）相关内容；数据来源优先评估读取本地 DB。
> - 分阶段执行，本文档记录每一步的状态，**每完成一步更新本文**。

---

## 整体进度（2026-10-28 同步）

| 工作项 | 状态 | 记录位置 |
| --- | --- | --- |
| M0 共享层文档复核（13 轮，含 4 位独立审稿） | ✅ 完成 | [shared-layer-modules-analysis.md](./shared-layer-modules-analysis.md) 复核记录 |
| M0 共享层代码修复（M1 / M7 / L1–L9 / D1–D5 / 死代码） | ✅ 编译通过；⏳ codeLinter、Local Test、设备冒烟待用户执行 | 同上 §9；[Refactor_Spec](../entry/Refactor_Spec.md) `## M0 spec` |
| 全项目命名规范化（文件 / 类型 / 常量 / 布尔 / 方法 / 资源） | ✅ 编译通过 | [naming-conventions.md](./naming-conventions.md)、[naming-rename-map.md](./naming-rename-map.md) |
| 测试编译阻塞修复（5 个测试文件） | ✅ 静态检查通过；⏳ Local Test 待用户运行 | naming-rename-map §7 |
| 工程结构迁移（三层结构） | ✅ 阶段 0–2 与收尾完成并编译通过（2026-10-29），S6 / S7 归入 M1–M15；⏳ Local Test 与全量冒烟待用户；阶段 3（手表）仅规划 | 本文 |
| 其余 29 份分析文档复核（README 共 30 份，M0 已复核） | 🔄 进行中。用户决定（2026-10-29）：**只修文档**，代码缺陷记入文档、在 M1–M15 修；**逐份进行，一份确认无问题后才开始下一份**；每份：我逐条回代码核对并修正 → 独立审稿 → 有发现则修正后再审，直到一轮零发现 → 向用户汇报 | 本文"迁移完成后" |
| Refactor_Spec M1–M15 模块重构 | ⬜ 结构迁移完成后开始，按 feature 目录进行 | Refactor_Spec §4 / §7 |

**待用户决定 / 批准**：
1. M8（人机验证申请 / 提交失败提示）与外观页 High（切换失败不再静默返回）需新增提示字符串（改 `resources`）。
2. 材料计算"部分角色失败"是否新增结果并提示。

**结构迁移中新发现（未修，待定级）**：`features/notification/.../StaminaNotificationService.ets:20` 把包名写死为正式包 `com.cainluo.miyoyo.tools`，用于通知的 `bundleName` / `pkgName`（289、351、468、523 行）；uat / mock 包名不同（`.uat` / `.mock`），这两个包上相关调用可能指向错误的应用。按"只移动文件"未改，复核 notification 文档时核实影响并定级。

**未修复的 High 缺陷**（单独提交，不混入结构迁移；⚠️ 2026-10-29 发现此清单与 README 不一致——README 中 PrivacyConsent、Launch、Ability 均为 0 High。清单来源待复核各自文档时逐条核实，核实前不作为结论引用）：隐私页内容不足一屏时无法继续（PrivacyConsent）；core 初始化失败卡启动页（Launch）；MaterialCalc 页面不可达（路由未注册）；小组件更新瞬时失败删除卡片配置（Widget H1）；系统备份含明文凭据（Ability，DB-003）；角色详情解析失败显示空白（CharDetail ×3）；GeetestDialog 移除主窗口尺寸监听（Main H1）；返回手势关闭人机验证框后验证队列永久卡死（Main H2，2026-10-29 文档复核恢复）。

## 状态总览

| 阶段 | 内容 | 状态 |
| --- | --- | --- |
| 0 | 当前代码（M0 修复 + 命名改名）本地编译通过 | ✅ 编译通过（2026-10-28，用户确认）；codeLinter / Local Test 待确认 |
| 1a | entry 内按未来模块边界移动文件（不改逻辑） | ✅ 编译通过（2026-10-28） |
| 1b | 解开 home ↔ widget ↔ notification 循环依赖（需改代码） | ✅ 编译通过（2026-10-28）；冒烟并入阶段 2 全量冒烟 |
| 2 | 抽成真正的模块（common/basic、common/widgetbase、features/*；**core、entry 位置不动**） | 🔄 2-0 ✅；2a 已撤销（core 不在范围）；2b ✅；✅ 代码完成，编译通过（2026-10-29）；⏳ Local Test 与全量冒烟待用户 |
| 3 | 新增 products/wearable | ⬜ 未开始（仅规划） |
| — | Refactor_Spec M1–M15 模块重构 | ⬜ 阶段 1 完成后开始，按 feature 目录进行 |

---

## 阶段 0：编译门禁

- [x] 本地 `assembleHap`（default / debug）通过
- [ ] `codeLinter` 不超过基线
- [ ] Local Test 能编译运行

## 阶段 1a：entry 内按未来模块边界归位（不改逻辑）

目标：`entry/src/main/ets/` 下的目录结构 = 阶段 2 的模块划分，但仍是一个 entry 模块，构建配置不变。

```
entry/src/main/ets/
├── entryability/ entrybackupability/ entryformability/ widgetsyncability/   ← 留在 entry
├── pages/Index.ets LaunchPage.ets MainPage.ets TestPage.ets                ← 留在 entry
├── views/test/                                                             ← TestPage 组件，留在 entry
├── widget/pages/ widget/views/ widget/viewmodel/                           ← 卡片 UI，留在 entry
├── common/basic/{shares,theme,utils,constants,signals,config,model}/      ← 将来 common/basic 模块
└── features/<功能>/{pages,views,viewmodel,model,model/service,utils,constants}/   ← 将来 features/<功能> 模块
```

步骤：
- [x] 按 [structure-proposal.md 附录](./structure-proposal.md#附录逐文件归属阶段-1--阶段-2-共用) 移动 / 改名文件，自动重写 import（332 个文件移动，315 个文件 import 重写）
- [x] 同步 `custom_router_map.json` 的 `pageSourceFile`（19 条；路由名不变）
- [x] 同步 `entry/src/test` 的 import
- [x] 静态引用检查 0 问题；模块边界检查：`common/basic` 不 import `features/` 与 `products/`，`features/` 不 import `products/`——0 违规；剩余环仅 home / widget / notification（留给 1b）
- [x] 用户本地编译通过
- （docs 路径更新并入"迁移完成后"统一处理）

## 阶段 1b：解开循环依赖（改代码，行为等价）

现存环：`features/home → features/widget → features/home`，`features/notification → features/widget`（方案 §5）。

- [x] `UserGameSection` / `UserGameSectionHeader` 移到 `common/basic/shares`，改为通用容器：角色卡片由调用方通过 `@BuilderParam roleBuilder` 传入（首页传 `GameToolCard`，小组件设置传 `WidgetSlotOption`；`buildSlotRef` 移入 `WidgetSettingsSlotStep`）；按官方 @BuilderParam 文档用箭头函数包装以保持 `this` 指向调用方
- [x] `HomeModels` 整体（4 个互相引用的类）移到 `common/basic/model/AccountRoleModels.ets`；测试已不直接引用，未保留 re-export
- [x] 依赖倒置：`common/basic/signals/WidgetSyncHook`（接口 + 登记），`features/widget/utils/WidgetSyncHandlerImpl` 原样承接推送逻辑，`EntryAbility.onCreate` 最先注册；`StaminaNotificationService` 不再 import widget
- [x] 模块依赖图无环（脚本验证）；features 间剩余单向依赖：account→legal / settings / verification / widget，characters→chardetail，chardetail→material，home→dailynote / notification（阶段 2 各模块须直接声明）
- [ ] 用户本地编译 + 冒烟：首页、小组件设置选槽位、体力通知后卡片刷新

## 阶段 2：抽成真正的模块

### 开工前核实结果（2026-10-28）

| # | 问题 | 依据 | 处理 |
| --- | --- | --- | --- |
| P1 | **同步阻塞**：`mutagen.yml` 为白名单，只同步 `/core/`、`/entry/` 等目录，且排除各模块的 `oh-package.json5` / `build-profile.json5` / `hvigorfile.ts` / `Index.ets` 与根目录文件。在服务器侧新建 `common/` `features/` `products/` 不会同步到本地，而从 `entry/` 移走的文件的**删除会同步** | `mutagen.yml` | 用户先在本地改 `mutagen.yml` 并重建同步会话，再开工 |
| P2 | **模块名必须保持 `entry`**：Preferences / RDB / 日志文件用的是 UIAbility / FormExtension 的 context，沙箱路径按模块名区分（`pull-logs.sh` 读 `/haps/entry/files`）；改名会导致老用户账号、Cookie、卡片配置全部"丢失"，已添加的桌面卡片失效 | `core/.../RdbManager.ets:27`、`DeviceFpService`、`WidgetFormIdStore` 等；`pull-logs.sh:24` | entry 原位不动、不改名（用户 2026-10-28 决定） |
| P3 | HAR 的 `BuildProfile` 只有 `HAR_VERSION / BUILD_MODE_NAME / DEBUG / TARGET_NAME` 与自定义字段（`APP_ENV` 会透传），**没有 `VERSION_NAME`、`BUNDLE_NAME`** | `core/BuildProfile.ets`（生成文件） | `AboutSection:43`、`MyViewModel:42` 改用 `bundleManager.getBundleInfoForSelfSync().versionName`；`WidgetSettingsViewModel:489` 改用 `context.abilityInfo.bundleName` |
| P4 | HAR 不能引用 AppScope 资源；`app.string.app_name` 的 base 值只在 AppScope，被 4 个将来在 HAR 中的文件引用 | 官方 har-package.md「约束」第 15 行 | 在 `common/basic` 的 base 资源中补 `app_name`（值与 AppScope 相同，不是新文案） |
| P5 | 卡片 UI 页面**支持导入 HAR，不支持 HSP**，但导入链上只能有"支持在 ArkTS 卡片中使用"的 API，否则卡片加载异常。从 HAR 的 `Index.ets` 导入会执行它导出的全部文件（widget HAR 会带进 Preferences、core 网络等） | 官方 [arkts-form-overview.md「约束与限制」](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/form/arkts-form-overview.md) | 卡片导入链 9 个纯文件（`AppTheme`、`DefaultTheme`、`WidgetUIStateModels`、`WidgetUtils`、`WidgetPayloadParser`、`WidgetDataHelper`、`WidgetLogger`、`WidgetExtraRowConfig`、`WidgetExtraRowType`）须与 widget / basic 的其余代码隔离，方案待用户选择 |
| P6 | 资源 605 条字符串 + media / color / profile 全在 entry；HAR 中 `$r` 只能引用自身及依赖模块的资源 | 官方 har-package.md「导出资源」 | 方案待用户选择 |
| P7 | ~~`run.sh` HAP 路径随 entry 移动而变~~ | `run.sh:88-104` | entry 不挪，**不需要改** |

### 用户决定（2026-10-28）

- **P1 同步**：用户本地按当时提供的 `docs/mutagen.proposed.yml`（已应用，2026-10-29 删除）改 `mutagen.yml` 并重建同步会话；之后模块配置文件由我修改。新加 `!/common/` `!/features/` `!/products/` `!/build-profile.json5`；core / entry 的 `oh-package.json5` `build-profile.json5` `hvigorfile.ts` `Index.ets` 改为同步；排除各新模块 `build/` 与 `oh-package-lock.json5`。
- **P5 卡片隔离**：新建卡片专用 HAR `common/widgetbase`，只放卡片导入链上的 9 个纯文件；卡片页面、`features/widget`、`common/basic`（主题）都依赖它。
- **P6 资源**：阶段 2 先把共用资源整体移到 `common/basic`，entry 只保留 `module.json5`、卡片配置（`form_config` / profile）和启动页必需资源；**按功能细拆在 M1–M15 各模块重构时进行**（记入"迁移完成后"）。

### 步骤（每步一次编译门禁）

- [x] 2-0 用户改 `mutagen.yml`、重建会话；确认 `mutagen sync list` 无冲突（core / entry 的配置文件两侧若不一致会报冲突，以本地为准）
- ~~2a `core/` → `common/core/`~~ **已撤销**：本次只重构 entry，core 位置与内容不动（用户 2026-10-28）。各新模块依赖 core 时用相对路径指向根目录的 `core/`
- [x] 2b 新建 `common/widgetbase`（HAR）移入 9 个卡片文件；新建 `common/basic`（HAR）移入 `entry/.../common/basic/*` 与共用资源（`app_name` 只被 features 引用，P4 推迟到 2c）；两者在工程级 `modules` 中配置 default / release / uat / mock 四个 target；entry 直接声明依赖；import 改为包名；用户编译 + 卡片冒烟
  - 代码：`common/widgetbase` 9 个文件、`common/basic` 37 个文件；entry 内 597 处 import 改为包名 `'basic'` / `'widgetbase'`（同一文件对同一包的多条 import 合并）；卡片 UI 的非相对 import 只剩 `'widgetbase'`；`SegmentedTabBar` 中 M0 留下的 `SegmentedTabItem` 转导出已无调用方，删除
  - `Index.ets` 按官方 HAR 示例逐个具名导出（不用 `export *`）
  - 资源（按 `$r` 引用归属）：entry 只留 `module.json5` / profile / `layered_image` 引用的（字符串 21、颜色 1、图片 4 + 深色 1，及 `rawfile/legal`）；widgetbase 拿卡片导入链引用的（颜色 94 + 深色 19、字符串 20 × 3 语言）；其余全部进 basic（含 185 个当前无引用的资源，留待 M1–M15 清理）
  - 配置：工程级 `modules` 新增 widgetbase / basic（四个 target 与 core 相同）；entry 依赖新增两者；basic 依赖 core、widgetbase；`build-profile.json5` / `hvigorfile.ts` / 混淆规则 / `module.json5`（`type: har`，`deviceTypes` 同 core）以 core 为模板
  - 本次编译要核实：basic 引用了 5 个放在 widgetbase 的颜色（`color_primary` 等），即"HAR 的 `$r` 可引用依赖 HAR 的资源"
  - [ ] 用户本地：`ohpm install`（或 DevEco Sync）→ 编译 → 冒烟：桌面卡片 6 种显示正常（颜色、文字、深色模式）、首页 / 设置页主题颜色正常
- [ ] 2c 每个 `features/<功能>` 新建 HAR（`Index.ets` 导出、路由表拆入各自 `module.json5` 的 routerMap、路由名不变）；P3 三处改为运行时获取；P4 在 basic 的 base 资源补 `app_name`；各模块**直接**声明依赖（HAR 不支持依赖传递）；首个 feature 编译时核实"HAR 的 `$r` 能引用依赖 HAR 的资源"；用户编译
  - **开工前核实（2026-10-29）**：features 不引用 entry 的代码（0 处）；feature 间依赖无环：account → legal / settings / verification / widget，home → dailynote / notification，chardetail → material，characters → chardetail；entry 直接引用 9 个 feature（不直接引用 chardetail、dailynote）
  - **拆分顺序**（自底向上，每批一次编译门禁）：第 1 批 legal、settings、verification、material、dailynote、notification、widget（不依赖其他 feature）→ 第 2 批 chardetail、home、account → 第 3 批 characters
  - **Index 导出**：只导出模块外（entry、其他 feature、测试）实际用到的符号。原因：4 组同名不同定义只在模块内部使用——material 的 `MaterialItemRaw` / `MaterialSectionVM`（`MaterialListModels` 与 `MaterialCalcModels` 各定义一份）、widget 的 `WidgetConfig`（`WidgetConfigModels` 的 class 与 `WidgetFormIdStore` 的 interface）、chardetail 的 `ZZZSkillItem`（组件与模型同名）；重复定义本身不在本次处理，记入 M1–M15
  - **资源**：仍全部在 basic（P6 决定）。另需：P4 在 basic 的 base 补 `app_name`（account / dailynote / home / notification 引用，base 值目前只在 AppScope）；`ic_app_logo`（base + dark）与 `color.black` 被 account / notification / widget / characters 引用，但也被 `module.json5` 引用，entry 保留、basic 放一份相同内容（同名时 entry 优先，显示不变）
  - **rawfile 保留在 entry**：legal 用 `resource://rawfile/legal/...` 加载协议页，运行时按应用资源解析，留在 entry 行为不变
  - **路由表**：19 条 feature 路由拆到各 feature 的 `src/main/resources/base/profile/router_map.json` 并在其 `module.json5` 声明 `routerMap`；路由名不变；entry 保留 1 条
  - **P3**：`AboutSection` / `MyViewModel` 的 `VERSION_NAME` 改为 `bundleManager.getBundleInfoForSelfSync(...).versionName`；`WidgetSettingsViewModel` 的 `BUNDLE_NAME` 改为运行时取包名
  - **测试**：entry 下测试的 import 改为包名（2e 再搬到各模块）
  - 用户决定（2026-10-29）：**2c 只移动文件、不改逻辑**，重构留到 M1–M15；桌面卡片冒烟暂缓；P3 用运行时读取（`bundleManager.getBundleInfoForSelfSync(GET_BUNDLE_INFO_DEFAULT)` 的 `name` / `versionName`，不依赖 context）
  - [x] 第 1 批：legal、settings、verification、material、dailynote、notification、widget（147 个文件；跨模块 import 改写 41 处；14 条路由拆入各模块 `<模块>_router_map.json`，entry 留 6 条；P3 widget 一处；basic 补 `app_name` base 值、`black`、`ic_app_logo`（base + dark）；dailynote / notification 引用 widgetbase 的颜色，直接声明 widgetbase 依赖）备份 `scratchpad/p2c1`
    - [x] 用户编译 + 运行正常（2026-10-29）
  - [x] 第 2 批：chardetail、home、account（117 个文件；跨模块 import 改写 10 处；5 条路由拆入各模块，entry 只留 TestPage；P3 account 两处：`AboutSection` 版本号改为字段一次读取，`MyViewModel.exportLogs` 改为调用时读取）备份 `scratchpad/p2c2`
    - [x] 用户编译通过（2026-10-29）
  - [x] 第 3 批：characters（12 个文件；依赖 core / widgetbase / basic / chardetail）备份 `scratchpad/p2c3`；entry 的 `ets/` 只剩 4 个 Ability、`pages/`、`views/test/`、卡片 UI `widget/`
    - [x] 用户编译通过（2026-10-29）
  - 2e 备注：entry 对 chardetail、dailynote 的依赖只被测试使用，测试拆到各模块后从 entry 删除
- ~~2d `entry/` 移到 `products/default/`~~ **取消**：entry 原位不动、不改名（用户 2026-10-28）
- [x] 2e 测试按模块拆到各模块 `src/test`：entry/src/test 的 17 个测试按被测代码搬到 account（3）、characters、chardetail、dailynote、home、legal、material（2）、notification（2）、widgetbase（5）；entry 只留 LocalUnit 与 Widget2x2ViewModel（测 entry 内的卡片 ViewModel）。测试对本模块代码改用相对路径 `../main/ets/...`（同 core）；各模块生成 `List.test.ets`、补 devDependencies `@ohos/hypium`；feature 的 `Index.ets` 去掉只被测试用的导出（如 account 6 → 1）；entry 删除不再使用的 chardetail、dailynote 依赖。`entry/src/ohosTest`（core 的测试）不在范围，不动。备份 `scratchpad/p2e`
  - 脚本漏算 entry 的 `pages/Index.ets`（误按"模块根 Index"排除），legal 的 `PrivacyConsentPageBuilder` 导出被删；检查器报出，已补回并修正脚本
  - [x] 用户编译通过（2026-10-29）
  - [ ] 在 DevEco 中对各模块运行 Local Test（待用户）
- [ ] 用户本地编译 + 全量冒烟（Refactor_Spec §7.1），重点：老数据仍在（账号、Cookie）、已添加的桌面卡片仍正常刷新

原清单（已并入上方步骤）：
- [ ] 新建 `common/basic`（HAR），移入 `entry/.../common/basic/*`
- [ ] 每个 `features/<功能>` 新建 HAR，移入对应目录；各模块**直接**声明依赖（HAR 不支持依赖传递）
- ~~`entry` 改名 / 移到 `products/default`~~（取消，见上）
- [ ] 路由表拆到各模块 routerMap；路由名不变
- [ ] 资源（string / color / media）按使用方拆到各模块，共用的放 `common/basic`
- [ ] 测试按模块拆到各模块 `src/test`
- [ ] 用户本地编译 + 全量冒烟（Refactor_Spec §7.1）

## 阶段 2 收尾：结构核查遗留（2026-10-29 用户追问后逐项核查）

按 naming-conventions 的目录 / 文件命名规则与官方 MVVM 分层，对 entry、common、features 全部 `.ets` 自动核查，结果：

| # | 问题 | 位置 | 性质 |
| --- | --- | --- | --- |
| S1 | `utils/` 应只放函数集合（`XxxUtil`），widget 的 `utils/` 放了 11 个类：Store / Builder / Manager / Downloader / Notifier / SyncHandlerImpl / MockPayload / Log。其他 feature 的同类文件都在 `model/service/`。方案阶段写了"文件名不变"，未按规范核对 | `features/widget/src/main/ets/utils/` | 移动 / 改名 |
| S2 | widgetbase 的 `utils/` 6 个文件不符合 `XxxUtil`：`WidgetUtils`（复数）、`WidgetDataHelper`、`WidgetPayloadParser`、`WidgetLogger`、`WidgetExtraRowType`（枚举）、`WidgetExtraRowConfig`（配置表） | `common/widgetbase/src/main/ets/utils/` | 移动 / 改名 |
| S3 | `views/` 下 5 个非 UI 组件：`CharacterDataSource`（LazyForEach 数据源）、`GeetestBridge`、`GeetestDialogHelper`、`GeetestHtmlBuilder`、`WidgetPreviewUtils` | characters / verification / widget | 移动 |
| S4 | `pages/MaterialCharacterSelectPageBuilder.ets` 单独成文件，其余页面的 `XxxPageBuilder` 都写在页面文件内 | material | 合并进页面文件 + 路由表 |
| S5 | 空目录 `entry/src/main/resources/dark/element`（2b 移走深色颜色后残留） | entry | 删除 |
| S6 | View 层直接访问 Model 层（官方 MVVM 不允许）。**直接调用服务的页面 6 个**：`LaunchPage`（`LegalPreferences.hasAgreed`、`CoreInitializer.waitForReady`）、`MainPage`（`GeetestCenter` / `DeviceFpCenter`）、`TestPage`（core 的 Repository）、`MyPage`（`AppearanceManager`）、`PrivacyConsentPage`（`LegalPreferences.setAgreed`）、`AppearanceSettingsPage`（`AppearanceManager.applyColorMode`）。另有 material 的 4 个页面只从 `model/service/MaterialComputeService.ets` 导入枚举 `MaterialComputeResult`（不调用服务），枚举应移到 `model/`。2026-10-29 复核更正：初版只扫了相对路径 import，漏了按包名导入的 LaunchPage / MainPage / MyPage，并把 material 4 页的枚举导入误算为调用 | entry / account / legal / settings / material | **改逻辑**，归入 M1–M15 |
| S7 | widget 有两个日志类：`features/widget/utils/WidgetLog`（注释仍写"core 是 HSP"，与实际不符）与 `widgetbase/utils/WidgetLogger` | widget / widgetbase | **改逻辑**（合并），归入 M14 |
| S8 | `entry/hmrouter_config.json` 无任何代码引用（工程未使用 HMRouter），迁移前即存在 | entry 根目录 | 待用户确认是否删除 |

**处理结果（2026-10-29，用户同意"继续改"）**：
- [x] S1 widget 的 10 个类移到 `model/service/`（名称不变）；`WidgetLog` 留 `utils/` 待 S7 合并
- [x] S2 widgetbase：`WidgetUtils` → `WidgetUtil`、`WidgetDataHelper` → `WidgetDataUtil`、`WidgetPayloadParser` → `WidgetPayloadUtil`（只改文件名，类 / 函数名不变）；`WidgetExtraRowType` → `constants/WidgetExtraRowType`，`WidgetExtraRowConfig` → `constants/WidgetExtraRowConstants`（未合并成一个文件，避免两个测试对应同一文件）；对应测试文件同步改名（`<被测文件名>.test.ets`）；`WidgetLogger` 符合官方 `utils/XxxLogger` 写法，保留
- [x] S3 `CharacterDataSource` → `viewmodel/`（官方 codelab 的 `SongDataSource` 在 `viewmodel/`）；`GeetestBridge` → `model/service/`；`GeetestDialogHelper` → `utils/GeetestDialogUtil`；`GeetestHtmlBuilder` → `utils/GeetestHtmlUtil`；`WidgetPreviewUtils` → widget 的 `utils/WidgetPreviewUtil`
- [x] S4 `MaterialCharacterSelectPageBuilder` 合并进 `MaterialCharacterSelectPage.ets` 末尾（页面文件已有同一个路由参数接口），路由表同步
- [x] S5 删除空目录
- 被移动文件的头注释与引用旧文件名的注释已同步；naming-conventions 补充日志类、服务类、懒加载数据源、路由 Builder 四条规则
- 复查：全部 `.ets` 按目录命名 / 内容核查只剩 `WidgetLog`（S7）；`p2_check` 0 错误 0 警告；旧检查器 0 问题；19 条 feature 路由有效。备份 `scratchpad/p2s`
- S6、S7 归入 M1–M15
- [x] S8 删除 `entry/hmrouter_config.json`（用户 2026-10-29：没用到的文件和空目录都删）
- [x] **清理未使用的文件 / 资源 / 空目录**（用户 2026-10-29）：
  - 代码文件：从入口（Ability、页面、路由、卡片页面、测试）按 import 可达性扫描，**0 个**未使用；13 个模块根 `BuildProfile.ets` 是构建自动生成的，不删
  - 资源：删除 126 个未引用的资源（字符串 81、颜色 44、float 1；含各语言 / 深色版本共 251 条）与 5 个未引用的图片（`ic_refresh`、`startIcon`、`tab_characters`、`tab_home`、`tab_settings`）；空的 `float.json` 一并删除。引用统计包含 `$r(...)`、配置文件、AppScope、资源间互相引用、运行时按名字查找（`getStringByNameSync` / `getColorByName*`）、core 中的引用
  - **保留** `material_target_config_level_suffix`：`StarRailMaterialTargetConfigPage.formatLevel` 把"级"写死为中文（英文 / 繁体也显示"级"），该字符串是为修这个问题准备的，归入 M1–M15（缺陷）
  - 发现脚本缺陷：`$r` 统计只匹配无参数写法 `$r('app.x.y')`，带格式化参数的 `$r('app.x.y', a)` 被漏算。影响：2b 把 widgetbase 用到的 3 个字符串（`widget_recovery_hours` / `_hours_minutes` / `_minutes`）分进了 basic（编译能过是因为资源最终合并进应用），已移回 widgetbase；检查器同步修正，修正后才报出这 3 处。备份 `scratchpad/p2clean`
  - 复查：`p2_check` 0 错误 0 警告；旧检查器 0 问题；空目录 0
- [x] 用户编译通过（2026-10-29）

## 阶段 3：products/wearable（仅规划）

功能范围：只显示 widget 相关内容（各账号便笺 / 体力）。

待核实（开工前）：
- [ ] **数据来源**：手表上运行的是同一应用在手表上的独立安装，有自己的沙箱与数据库，**读不到手机上的 DB**。"从 DB 获取"的前提是手表本地 DB 有数据，需要二选一：(A) 手表自己登录并调用 core 拉取数据写入本地 DB；(B) 手机把数据同步到手表，再写入手表本地 DB（手机 ↔ 手表通信能力待核实）
- [ ] **能力核实**（改 core 的 `deviceTypes`，超出 entry 重构范围，需用户单独批准）：`core` 与 `products/wearable` 的 `deviceTypes` 加 `"wearable"` 后编译，记录不支持的 API（网络、RDB、Preferences、Form Kit、Notification、ArkWeb）
- [ ] `core` 的 `deviceTypes` 加 `"wearable"`（同上，需用户批准）
- [ ] 新建 `products/wearable`（entry，`deviceTypes: ["wearable"]`），页面按手表交互设计，复用 `features/widget` / `features/dailynote` 的 viewmodel / model

---

## 迁移完成后

- [ ] 复核其余 30 份分析文档（按 M0 的方式：逐条回代码、独立审稿、直到一轮零发现），同步 README 总表与 Refactor_Spec §11
- [ ] 文档中的文件路径改为迁移后的模块路径（`file:line` 行号随复核重新核对）
- [ ] 资源按功能细拆（阶段 2 暂放 `common/basic`），随 M1–M15 各模块重构进行
- [x] 删除临时文件 `docs/mutagen.proposed.yml`（2026-10-29）

## 执行记录

| 日期 | 阶段 | 内容 | 验证 |
| --- | --- | --- | --- |
| 2026-10-28 | — | 计划建立 | — |
| 2026-10-28 | 0 / 1a | 用户本地编译通过 | assembleHap |
| 2026-10-28 | 1a | 332 个文件移入 `common/basic/` 与 `features/<功能>/`；widget 模型文件加 Model 后缀；`DialogDedup` → `DialogDedupUtil`、`LegalI18nRouter` → `LegalI18nUtil`；单个模型文件加 Model 后缀（类名不变）；路由表 19 条同步 | 静态检查 0 问题；边界检查 0 违规；备份 `scratchpad/main.before-p1`、`test.before-p1` |
| 2026-10-28 | 1b | UserGameSection 通用化 + 账号角色模型移到 common + WidgetSyncHook 依赖倒置 | 静态检查 0 问题；边界 0 违规；模块依赖无环；备份 `scratchpad/main.before-p1b` |
| 2026-10-28 | 1a 遗留 | clean 构建报 7 个编译错误：`features/account/views/Login*.ets` 中 10 处模块名绝对路径 import（`'entry/ets/viewmodel/LoginViewModel'`、`'entry/ets/components/login/...'`）在 1a 移动文件时未被重写（脚本与检查器只处理 `./`、`../` 相对路径）；1a 时的"编译通过"应为增量构建未重编这些文件。已改为相对路径；检查器补充解析 `entry/ets/` 形式 | 对 1b 前备份重跑检查器能报出全部 10 处；当前代码 0 问题；全项目除 `core` 与系统 / 三方包外已无其他非相对 import。**阶段 2 拆模块后这种写法会失效，脚本须同时处理** |
| 2026-10-28 | 1b | 用户 clean 构建通过 | assembleHap（uat） |
| 2026-10-28 | 2 | 开工前核实 P1–P7；用户决定：改 mutagen、单独建卡片 HAR、资源先整体放 basic | 官方 har-package.md、arkts-form-overview.md；生成的 `core/BuildProfile.ets` |
| 2026-10-28 | 2-0 | 用户改 mutagen 并重建会话；测试文件 `common/SYNC_CHECK.txt` 同步到本地，`mutagen sync list` 无冲突 | 用户确认 |
| 2026-10-28 | 2a | `core/` 移到 `common/core/` 后**撤销**：用户指出本次只重构 entry，不涉及 core。已从备份还原 `build-profile.json5` 与 `entry/oh-package.json5`，`core/` 移回原位，删除空的 `common/` | `diff -r` core 与备份一致；方案与计划中 core 迁移项已删除 |
| 2026-10-28 | 2 | 用户决定结构：保留官方三层的 `common/`、`features/`，**entry 不挪到 `products/default`、不改名**；2d 与 P7 取消；方案文档同步 | — |
| 2026-10-28 | 2b | 抽出 `common/widgetbase`、`common/basic` 两个 HAR（详见步骤 2b） | 新检查器 `scratchpad/p2_check.py`（相对路径、越界、包依赖须直接声明、具名导出、`$r` 资源归属、依赖环）0 错误；注入 4 类错误均能报出；旧检查器 0 问题；备份 `scratchpad/p2b` |
| 2026-10-28 | 2b | 用户编译失败 2 项：① 未执行 `ohpm install`，新模块依赖未安装（`dependency which is not installed`）；② `$string:EntryAbility_label_uat` 未定义——`entry/build-profile.json5` 的 uat / mock target 覆盖 Ability label 引用了 `EntryAbility_label_uat` / `_mock`，资源归属扫描漏了该文件，二者被分进 basic。已移回 entry；检查器新增"配置文件引用的资源须在 entry 自身或 AppScope 定义"（含 entry 的 `build-profile.json5`、`module.json5`、profile、media json，工程级 `build-profile.json5`、`app.json5`） | 检查器 0 错误；删掉该 key 的副本能报出 |
| 2026-10-28 | 2b | 用户用 `run.sh` 编译：33 个 `Failed to resolve OhmUrl "widgetbase"`（均来自卡片 UI 文件），同时持续出现 `dependency which is not installed`。原因：`run.sh` 只做 clean + assembleHap，不执行 `ohpm install`，新模块未安装到 entry 的 `oh_modules`。非代码问题；建议 `run.sh` 在构建前加 `ohpm install --all` | 日志分析；代码检查器 0 错误 |
| 2026-10-29 | 2b | 用户用 DevEco 运行正常（Sync 时自动执行 `ohpm install --all`）→ 代码无问题；确认 HAR 可引用依赖 HAR 的资源（basic 引用 widgetbase 的 5 个颜色）。`run.sh` 缺依赖安装步骤，建议用户在 Clean 前加 `ohpm install --all`（根目录文件不同步，用户本地改） | DevEco 运行 |
| 2026-10-29 | 2b | `run.sh` 新增 `OHPM` 变量与「2.5 安装依赖」步骤（Clean 前执行 `ohpm install --all`） | `bash -n` 语法检查 |
| 2026-10-29 | 2c-1 | 第 1 批 7 个 feature 抽成 HAR（见步骤 2c） | `p2_check` 0 错误 0 警告；旧检查器 0 问题（扩大 `@Monitor` 字段搜索范围到 common / features / core）；feature 路由 14 条全部指向存在的页面与 builder，全工程 20 条路由无重名 |
| 2026-10-29 | 2c-1 | 用户编译、运行正常 | 用户确认 |
| 2026-10-29 | 2c-2 | 第 2 批 chardetail、home、account 抽成 HAR；P3 account 两处 | `p2_check` 0 错误 0 警告；旧检查器 0 问题；feature 路由 19 条全部有效，全工程 20 条无重名；features / common 中无 HAR 不存在的 `BuildProfile` 字段 |
| 2026-10-29 | 2c-2 | 用户编译通过 | 用户确认 |
| 2026-10-29 | 2c-3 | 第 3 批 characters 抽成 HAR；11 个 feature 全部拆完 | `p2_check` 0 错误 0 警告；旧检查器 0 问题 |
| 2026-10-29 | 2c-3 | 用户编译通过 | 用户确认 |
| 2026-10-29 | 2e | 本地单元测试按模块拆分（详见步骤 2e） | `p2_check` 0 错误 0 警告（含各模块 `src/test` 的 import 与跨模块导出）；旧检查器 0 问题 |
| 2026-10-29 | 2e | 用户编译通过；阶段 2 代码部分完成 | 用户确认 |
| 2026-10-29 | 2 收尾 | 结构核查 S1–S8；S1–S5 已移动 / 改名（见"阶段 2 收尾"） | 检查器全部通过；⏳ 用户编译 |
| 2026-10-29 | 2 收尾 | 删除 hmrouter_config.json、126 个未用资源与 5 张未用图片；3 个字符串移回 widgetbase；修正 `$r` 统计脚本缺陷 | 检查器全部通过；⏳ 用户编译 |
| 2026-10-29 | 2 收尾 | 用户编译通过；结构迁移（阶段 0–2 + 收尾）完成 | 用户确认 |
| 2026-10-28 | — | 构建警告 `'page_show' conflict`：来自三方包 `@ohos/axios` 与 `@ohos/crypto-js` 各自声明的同名字符串，项目资源中无此 key，与本次迁移无关，不处理 | grep 项目资源 |

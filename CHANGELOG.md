# Changelog

## v2.1.1（未发布，2026-11-12）— 卡片与页面重构收尾

> `AppScope/app.json5` 的 `versionName` 仍为 `2.0.1`，本节为待发布记录。

### 重构

- **MainPage 478 → 277 行**：弹窗仲裁抽到 `entry/src/main/ets/utils/MainDialogArbiter.ets`，标题栏菜单与 Tab 项抽到 `utils/MainMenuItems.ets`，`@Builder` 外置到 `MainPageBuilders.ets`
- **Widget4x4SingleGame 337 → 131 行**：拆为 `Widget4x4Header` / `Widget4x4StaminaBlock` / `Widget4x4ExtraRowsGroup` / `Widget4x4ExpeditionBlock`
- **2×4 / 4×4 共享组件**：新增 `WidgetDataRow` / `WidgetExpeditionAvatar`；`WidgetExtraDataRows`（2×2）接入共享数据行
- **配置页预览去重**：新增 `PreviewExtraDataRow` / `PreviewExpeditionAvatar`，`Preview2x4SingleGame` 221 → 194 行、`Preview4x4SingleGame` 241 → 221 行
- **Widget ViewModel 去重**：新增 `WidgetRoleStateBuilder`（`WidgetRoleLayout` 表达尺寸差异），`Widget2x2/2x4/4x4ViewModel` 从 161+162+159 行降到 111+60+60 行；`buildUIState` 签名与类名不变

### 性能

- **Widget 页面缓存 payload 解析**：6 个卡片页面按 payload 字符串缓存 `ParsedPayload` + `UIState`，单次 `build()` 的 `JSON.parse` 从 9（2×2）/ 7（2×4、4×4）/ 2（1×2）次降为 1 次

### 修复

- **「我的」页元素持续上下浮动**：骨架屏使用 `animateTo({ iterations: -1 })` 产生永不结束的全局隐式动画，骨架销毁后仍接管页面布局；改为组件级 `.animation()` + `onAppear` 触发，实测布局静止

### 工程

- `run.sh` 适配 DevEco Studio 6.1 模拟器启动参数（`-start <name> -instancePath <root>`）
- 停止跟踪构建生成的 13 个 `BuildProfile.ets`（hvigor 每次按 product 重写），修复切换 product 构建后工作区变脏

### 文档

- 新增《HarmonyOS UI 组件与页面开发及重构规范》与《组件拆分分析总索引》
- 关闭 W-V1 / W-V2 / W-V3 / W-V4 / W-V5 / W-Pages / W-VM 与 M1 待办；`TestPage` / `LaunchPage` 评估为不拆分
- 修正 Widget 子系统文档的 ViewModel 行数、测试现状与体量统计

---

## v2.1.0 (2026-11-08) — 入口模块重构收尾

### 架构变更

> 本次版本为 `entry` 模块重构的最终发布。将原存放在 `entry/src/main/ets/components/` 的代码按功能拆分到 `features/*` HAR，公共代码收归 `common/basic`。

- **M0 路由表抽离**：`AppRoutes.ets` 从 `EntryAbility.ets` 抽出至 `common/basic/constants/AppRoutes.ets`，集中管理所有路由 Path 常量
- **M1 首页双模式合并**：`HomeHeader` 的账号/游戏角色双模式（4 回调）简化为统一的 `account` + `roleBuilder` 单接口；组件从 `entry/src/main/ets/components/home/HomePage.ets` 迁入 `common/basic/shares/UserGameSection.ets`
- **M2 底部 Tab 模型抽离**：Tab 数据模型（`BottomTabModel`）从 `MainPage.ets` 抽出至 `BasicModule.bottomTabs`，主页仅负责渲染
- **M3 home ↔ widget 双向依赖消除**：home 不再直接导入 widget 模块，改为通过信号（`SyncRetrySignal`）和回调实现解耦；widget 设置页数据迁移至 `common/basic/shares/`
- **M4 全局路由栈抽离**：`RouterUtil.ets` 从 `entry/src/main/ets/utils/` 抽出至 `common/basic/utils/RouterUtil.ets`
- **M5 空 catch / 空 `.catch()` 修复**：全局扫描并补全所有空错误捕获，添加有意义的 fallback / 日志
- **M6 首页组件命名规范**：`Home` → `HomePage`，符合 ArkUI 页面无 `Home/My/Main` 前缀规则
- **M7 主页布局模式统一**：`MainNavigationMode.ets` 迁入 `entry/src/main/ets/utils/`
- **M8-M10** 公共工具归类：颜色、时间格式、游戏 ID 映射等移至 `common/basic/utils/`
- **M11 旧组件删除确认**：确认根级 `components/` 下无活跃引用后，清理废弃模块；添加失败回退提示
- **M12 哨兵错误码映射**：统一敏感数据错误码（`9568305` / `9568322`）到 `ReportType` 的映射
- **M13 init() 返回值改为 boolean**：`NotificationScheduler.ets` 返回布尔值，调用方据此确认初始化结果
- **M14 H1/H2 组件分离**：首页 Header 与副标题精确拆分，职责单一化
- **M15 体力提醒 on/off 精确控制**：仅对实际开启的账号/游戏注册通知，避免全量轮询

### GAP 修复

| 编号 | 内容 |
| --- | --- |
| GAP-04 | 补全局空 catch 扫描脚本与修复（M5） |
| GAP-05 | `StaminaNotificationService` getter 旧包名修复 |
| GAP-06 | `EntryFormAbility` 无数据时不再返回 Mock，改为构建空 payload |
| GAP-07 | 签名口令入库（不在 .ets 范围，未在本轮修改） |
| GAP-08 | 模块依赖拓扑验证，确认无循环依赖 |
| GAP-12 | 文档收尾：批量修复分析文档中引用旧路径；更新 `project-structure.md` 计数（entry 30→32，basic 37→36） |

### 行为修复

- 预览模式 UID 固定为测试账号（不再每次随机）
- M15 H1/H2 on/off 精确控制：已关闭提醒的账号不进入轮询队列
- M12 哨兵错误码：`9568305`(Cookies过期) / `9568322`(设备指纹失败) 统一映射到 `ReportType`

### 统计变更

| 模块 | 旧计数 | 新计数 | 说明 |
| --- | --- | --- | --- |
| entry | 30 `.ets` | 32 `.ets` | 新增 `utils/MainDialogLabels.ets`、`utils/MainNavigationMode.ets`，补列遗漏 widget views |
| common/basic | 37 `.ets` | 36 `.ets` | 修正多记的 `SettingRow.ets`（不存在） |

---

## v2.0.1 (2026-11-07)

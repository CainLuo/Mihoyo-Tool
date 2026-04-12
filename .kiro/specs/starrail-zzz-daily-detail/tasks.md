# 星穹铁道 & 绝区零便笺详情页 — Task List

## Task 1：StarRailDailyNoteParser（core 层）

- [ ] 新建 `core/src/main/ets/parsers/StarRailDailyNoteParser.ets`
  - 定义 `StarRailExpeditionData` 数据类（avatarSideIcon / name / remainedTime / finishTime / status）
  - 定义 `StarRailDailyNoteData` 数据类（覆盖 REQ-1.2 所有字段，含默认值）
  - 实现 `StarRailDailyNoteParser.parse(rawJson: string): StarRailDailyNoteData`
  - 解析失败时返回默认值对象，不抛异常
- [ ] 在 `core/Index.ets` 中导出 `StarRailDailyNoteParser`、`StarRailDailyNoteData`、`StarRailExpeditionData`

## Task 2：ZZZDailyNoteParser（core 层）

- [ ] 新建 `core/src/main/ets/parsers/ZZZDailyNoteParser.ets`
  - 定义 `ZZZDailyNoteData` 数据类（覆盖 REQ-2.2 所有字段，含默认值）
  - 实现 `ZZZDailyNoteParser.parse(rawJson: string): ZZZDailyNoteData`
  - 解析 `energy.progress.current/max`、`energy.restore`
  - 解析 `vitality.current/max`
  - 解析 `vhs_sale.sale_state`、`card_sign`
  - 解析 `abyss_refresh`
  - 解析 `member_card.is_open`、`member_card.member_card_state`
  - 解析 `cafe_state`
  - 解析 `temple_running.expedition_state`、`temple_running.current_currency`
  - null 字段（bounty_commission / survey_points / coffee / weekly_task）忽略
  - 解析失败时返回默认值对象，不抛异常
- [ ] 在 `core/Index.ets` 中导出 `ZZZDailyNoteParser`、`ZZZDailyNoteData`

## Task 3：更新 DailyNoteModels.ets

- [ ] 更新 `entry/src/main/ets/components/dailynote/DailyNoteModels.ets`
  - `StarRailDailyNoteVM` 补全字段：`currentReserveStamina`、`isReserveStaminaFull`、`acceptedExpeditionNum`、`totalExpeditionNum`、`weeklyCocoonCnt`、`weeklyCocoonLimit`、`rogueTournWeeklyUnlocked`、`rogueTournWeeklyCur`、`rogueTournWeeklyMax`、`rogueTournExpIsFull`、`gridFightWeeklyCur`、`gridFightWeeklyMax`
  - `ZZZDailyNoteVM` 补全字段：`vhsSaleState`、`cardSign`、`abyssRefresh`、`memberCardIsOpen`、`memberCardState`、`cafeState`、`templeExpeditionState`、`templeCurrentCurrency`
  - 移除 `ZZZDailyNoteVM` 中已废弃的 `bountyCommissionDone/Total` 字段

## Task 4：新增字符串资源

- [ ] 在 `entry/src/main/resources/base/element/string.json` 中添加 design.md 字符串资源清单中所有 key（简体中文）
- [ ] 在 `entry/src/main/resources/zh_HK/element/string.json` 中同步添加（繁体中文）
- [ ] 在 `entry/src/main/resources/en/element/string.json` 中同步添加（英文）

## Task 5：StarRailDailyDetailViewModel

- [ ] 新建 `entry/src/main/ets/viewmodel/StarRailDailyDetailViewModel.ets`
  - `@ObservedV2` 类，`@Trace viewState`、`@Trace note: StarRailDailyNoteVM`
  - `init(accountId: string, roleUid: string)` 方法
  - `loadData()` 方法：从 `CoreInitializer.starRailRepository.getDailyNote()` 读取 → `StarRailDailyNoteParser.parse()` → `toVM()` 转换
  - `toVM()` 静态方法：`StarRailDailyNoteData` → `StarRailDailyNoteVM`，包含 `toExpeditionVMs()` 转换
  - 状态枚举映射（vhsSaleState 等）在此处处理，转换为显示用字符串 key

## Task 6：ZZZDailyDetailViewModel

- [ ] 新建 `entry/src/main/ets/viewmodel/ZZZDailyDetailViewModel.ets`
  - `@ObservedV2` 类，`@Trace viewState`、`@Trace note: ZZZDailyNoteVM`
  - `init(accountId: string, roleUid: string)` 方法
  - `loadData()` 方法：从 `CoreInitializer.zzzRepository.getDailyNote()` 读取 → `ZZZDailyNoteParser.parse()` → `toVM()` 转换
  - `toVM()` 静态方法：`ZZZDailyNoteData` → `ZZZDailyNoteVM`，状态枚举映射在此处处理

## Task 7：DailyNoteStarRail 组件

- [ ] 新建 `entry/src/main/ets/components/dailynote/DailyNoteStarRail.ets`
  - `@Param data: StarRailDailyNoteVM`
  - 第一组（日常）：开拓力（大数字 + 进度条 + 恢复倒计时）、后备开拓力、委托派遣、每日实训、历战余响
  - 第二组（宇宙）：模拟宇宙积分（进度条）、差分宇宙（含经验已满标签）、黄金与机械（max=0 时显示"未解锁"）
  - 组标题使用 `SectionHeader` 或内联样式
  - 文件末尾添加 `@Preview`

## Task 8：DailyNoteZZZ 组件

- [ ] 新建 `entry/src/main/ets/components/dailynote/DailyNoteZZZ.ets`
  - `@Param data: ZZZDailyNoteVM`
  - 第一组（日常）：电量（大数字 + 进度条 + 恢复倒计时）、活跃度（进度条）
  - 第二组（商店）：录像店（状态文字 + 颜色）、刮刮卡（状态文字 + 颜色）
  - 第三组（其他）：式舆防卫战（状态 + 货币数量）、会员卡（状态）、咖啡厅（状态）
  - 文件末尾添加 `@Preview`

## Task 9：StarRailDailyDetail 页面

- [ ] 新建 `entry/src/main/ets/pages/StarRailDailyDetail.ets`
  - 路由参数类 `StarRailDailyDetailParam { accountId: string, roleUid: string }`
  - `@ComponentV2` struct，结构与 `GenshinDailyDetail.ets` 完全对称
  - LOADING / EMPTY / ERROR / DATA 四种状态
  - DATA 状态：`Scroll` + `DailyNoteStarRail` 组件
  - 监听窗口尺寸变化（`window.on('windowSizeChange')`）

## Task 10：ZZZDailyDetail 页面

- [ ] 新建 `entry/src/main/ets/pages/ZZZDailyDetail.ets`
  - 路由参数类 `ZZZDailyDetailParam { accountId: string, roleUid: string }`
  - `@ComponentV2` struct，结构与 `GenshinDailyDetail.ets` 完全对称
  - DATA 状态：`Scroll` + `DailyNoteZZZ` 组件

## Task 11：路由注册

- [ ] 在 `entry/src/main/ets/constants/AppRoutes.ets` 中添加：
  - `static readonly STARRAIL_DAILY_DETAIL = 'StarRailDailyDetail'`
  - `static readonly ZZZ_DAILY_DETAIL = 'ZZZDailyDetail'`
- [ ] 新建 `entry/src/main/ets/pages/router/StarRailDailyDetailBuilder.ets`
  - `HdsNavDestination` 包裹 `StarRailDailyDetail`
  - `.titleBar({ content: { title: { mainTitle: $r('app.string.starrail_daily_title') } } })`
  - 处理 `statusBarHeight` padding
- [ ] 新建 `entry/src/main/ets/pages/router/ZZZDailyDetailBuilder.ets`
  - `HdsNavDestination` 包裹 `ZZZDailyDetail`
  - `.titleBar({ content: { title: { mainTitle: $r('app.string.zzz_daily_title') } } })`
  - 处理 `statusBarHeight` padding
- [ ] 在 `entry/src/main/resources/base/profile/custom_router_map.json` 中注册两个路由条目
- [ ] 在 `entry/src/main/ets/pages/Index.ets` 的 `builderMap` 中注册两个 `wrapBuilder`

## Task 12：Home 页跳转接入

- [ ] 修改 `entry/src/main/ets/viewmodel/HomeViewModel.ets` 中的 `onCardTap` 方法
  - `genshin` → `RouterUtil.push(AppRoutes.GENSHIN_DAILY_DETAIL, param)`
  - `starrail` → `RouterUtil.push(AppRoutes.STARRAIL_DAILY_DETAIL, param)`
  - `zzz` → `RouterUtil.push(AppRoutes.ZZZ_DAILY_DETAIL, param)`
- [ ] 确认 `GameRoleCardVM` 包含 `accountId` 和 `roleUid` 字段（如缺失则补充）

## Task 13：构建验证

- [ ] 运行 `bash run.sh` 确认 BUILD SUCCESSFUL
- [ ] 在模拟器上验证：
  - 点击 Home 页星铁卡片 → 跳转到星铁便笺详情页，数据正确显示
  - 点击 Home 页绝区零卡片 → 跳转到绝区零便笺详情页，数据正确显示
  - 两个页面的 LOADING / EMPTY / DATA 状态均正常

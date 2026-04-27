# 星穹铁道 & 绝区零便笺详情页 — 需求文档

## 背景

原神便笺详情页（`GenshinDailyDetail`）已完整实现。
星穹铁道和绝区零目前只有 Home 页的卡片摘要（`StarRailGameToolCardContent` / `ZZZGameToolCardContent`），
点击卡片后没有对应的详情页可以跳转。

本 Spec 补全这两个游戏的便笺详情页，与原神保持一致的架构风格。

## 参考原型

- 星铁：`design/prototypes/v1.0/viewer/pages/starrail-daily-detail.js`
- 绝区零：`design/prototypes/v1.0/viewer/pages/zzz-daily-detail.js`

## 参考 Mock 数据

- 星铁：`core/src/main/resources/rawfile/mock/182692936/102731382/game_record_app_hkrpg_api_note.json`
- 绝区零：`core/src/main/resources/rawfile/mock/182692936/37716744/event_game_record_zzz_api_zzz_note.json`

---

## 功能需求

### REQ-1：星穹铁道便笺 Parser（core 层）

**REQ-1.1** 新建 `core/src/main/ets/parsers/StarRailDailyNoteParser.ets`，
将 `rawJson` 字符串解析为 `StarRailDailyNoteData` 数据对象。

**REQ-1.2** 解析字段覆盖 API Response 所有有效字段：

| 字段                       | 类型                     | 说明                               |
| -------------------------- | ------------------------ | ---------------------------------- |
| `currentStamina`           | number                   | 当前开拓力                         |
| `maxStamina`               | number                   | 最大开拓力                         |
| `staminaRecoverTime`       | number                   | 恢复剩余秒数                       |
| `currentReserveStamina`    | number                   | 后备开拓力                         |
| `isReserveStaminaFull`     | boolean                  | 后备是否已满                       |
| `acceptedExpeditionNum`    | number                   | 已派遣数                           |
| `totalExpeditionNum`       | number                   | 派遣上限                           |
| `expeditions`              | StarRailExpeditionData[] | 派遣列表                           |
| `currentTrainScore`        | number                   | 每日实训当前积分                   |
| `maxTrainScore`            | number                   | 每日实训上限                       |
| `currentRogueScore`        | number                   | 模拟宇宙本周积分                   |
| `maxRogueScore`            | number                   | 模拟宇宙本周积分上限               |
| `weeklyCocoonCnt`          | number                   | 历战余响已用次数                   |
| `weeklyCocoonLimit`        | number                   | 历战余响每周上限                   |
| `rogueTournWeeklyUnlocked` | boolean                  | 差分宇宙是否已解锁                 |
| `rogueTournWeeklyCur`      | number                   | 差分宇宙本周积分                   |
| `rogueTournWeeklyMax`      | number                   | 差分宇宙本周积分上限               |
| `rogueTournExpIsFull`      | boolean                  | 差分宇宙经验是否已满               |
| `gridFightWeeklyCur`       | number                   | 黄金与机械本周进度                 |
| `gridFightWeeklyMax`       | number                   | 黄金与机械本周上限（0 表示未解锁） |

**REQ-1.3** 解析失败（无效 JSON、空字符串）时返回默认值对象，不抛异常。

---

### REQ-2：绝区零便笺 Parser（core 层）

**REQ-2.1** 新建 `core/src/main/ets/parsers/ZZZDailyNoteParser.ets`，
将 `rawJson` 字符串解析为 `ZZZDailyNoteData` 数据对象。

**REQ-2.2** 解析字段覆盖 API Response 所有有效字段：

| 字段                    | 类型    | 说明                                   |
| ----------------------- | ------- | -------------------------------------- |
| `currentEnergy`         | number  | 当前电量                               |
| `maxEnergy`             | number  | 最大电量                               |
| `energyRecoverTime`     | number  | 电量恢复剩余秒数（`energy.restore`）   |
| `currentVitality`       | number  | 当前活跃度                             |
| `maxVitality`           | number  | 活跃度上限                             |
| `vhsSaleState`          | string  | 录像店状态（`SaleStateDone/Doing/No`） |
| `cardSign`              | string  | 刮刮卡状态（`CardSignDone/No`）        |
| `abyssRefresh`          | number  | 式舆防卫战刷新倒计时（秒）             |
| `memberCardIsOpen`      | boolean | 会员卡是否开通                         |
| `memberCardState`       | string  | 会员卡状态字符串                       |
| `cafeState`             | string  | 咖啡厅状态（`CafeStateNo/Open/Done`）  |
| `templeExpeditionState` | string  | 式舆防卫战派遣状态                     |
| `templeCurrentCurrency` | number  | 式舆防卫战当前货币                     |

**REQ-2.3** null 字段（`bounty_commission`、`survey_points`、`coffee`、`weekly_task`）忽略，不解析。

**REQ-2.4** 解析失败时返回默认值对象，不抛异常。

---

### REQ-3：更新 ViewModel 数据模型（entry 层）

**REQ-3.1** 更新 `entry/src/main/ets/components/dailynote/DailyNoteModels.ets` 中的 `StarRailDailyNoteVM`，
补全所有字段以匹配 REQ-1.2 的完整数据：

新增字段：

- `currentReserveStamina: number`
- `isReserveStaminaFull: boolean`
- `acceptedExpeditionNum: number`
- `totalExpeditionNum: number`
- `weeklyCocoonCnt: number`
- `weeklyCocoonLimit: number`
- `rogueTournWeeklyUnlocked: boolean`
- `rogueTournWeeklyCur: number`
- `rogueTournWeeklyMax: number`
- `rogueTournExpIsFull: boolean`
- `gridFightWeeklyCur: number`
- `gridFightWeeklyMax: number`

**REQ-3.2** 更新 `ZZZDailyNoteVM`，补全所有字段以匹配 REQ-2.2 的完整数据：

新增字段：

- `vhsSaleState: string`
- `cardSign: string`
- `abyssRefresh: number`
- `memberCardIsOpen: boolean`
- `memberCardState: string`
- `cafeState: string`
- `templeExpeditionState: string`
- `templeCurrentCurrency: number`

---

### REQ-4：星穹铁道便笺详情页（entry 层）

**REQ-4.1** 新建 `entry/src/main/ets/components/dailynote/DailyNoteStarRail.ets`，
展示星铁便笺完整数据，分两组：

- 第一组（日常）：开拓力（含进度条 + 恢复倒计时）、后备开拓力、委托派遣、每日实训、历战余响
- 第二组（宇宙）：模拟宇宙积分（含进度条）、差分宇宙（含经验已满标签）、黄金与机械

**REQ-4.2** 新建 `entry/src/main/ets/viewmodel/StarRailDailyDetailViewModel.ets`，
从 DB 读取 `rawJson` → `StarRailDailyNoteParser.parse()` → 转换为 `StarRailDailyNoteVM`。

**REQ-4.3** 新建 `entry/src/main/ets/pages/StarRailDailyDetail.ets`，
页面结构与 `GenshinDailyDetail.ets` 保持一致：

- LOADING 状态：居中 `LoadingProgress`
- EMPTY/ERROR 状态：居中提示文字
- DATA 状态：`Scroll` + `DailyNoteStarRail` 组件

**REQ-4.4** 新建 `entry/src/main/ets/pages/router/StarRailDailyDetailBuilder.ets`，
注册路由 Builder。

**REQ-4.5** 在 `AppRoutes.ets` 中添加 `STARRAIL_DAILY_DETAIL = 'StarRailDailyDetail'`。

**REQ-4.6** 在 `custom_router_map.json` 中注册路由条目。

**REQ-4.7** 在 `Index.ets` 的 `builderMap` 中注册 `wrapBuilder`。

---

### REQ-5：绝区零便笺详情页（entry 层）

**REQ-5.1** 新建 `entry/src/main/ets/components/dailynote/DailyNoteZZZ.ets`，
展示绝区零便笺完整数据，分三组：

- 第一组（日常）：电量（含进度条 + 恢复倒计时）、活跃度（含进度条）
- 第二组（商店）：录像店、刮刮卡
- 第三组（其他）：式舆防卫战（状态 + 货币）、会员卡、咖啡厅

**REQ-5.2** 新建 `entry/src/main/ets/viewmodel/ZZZDailyDetailViewModel.ets`，
从 DB 读取 `rawJson` → `ZZZDailyNoteParser.parse()` → 转换为 `ZZZDailyNoteVM`。

**REQ-5.3** 新建 `entry/src/main/ets/pages/ZZZDailyDetail.ets`，
页面结构与 `GenshinDailyDetail.ets` 保持一致。

**REQ-5.4** 新建 `entry/src/main/ets/pages/router/ZZZDailyDetailBuilder.ets`，
注册路由 Builder。

**REQ-5.5** 在 `AppRoutes.ets` 中添加 `ZZZ_DAILY_DETAIL = 'ZZZDailyDetail'`。

**REQ-5.6** 在 `custom_router_map.json` 中注册路由条目。

**REQ-5.7** 在 `Index.ets` 的 `builderMap` 中注册 `wrapBuilder`。

---

### REQ-6：Home 页跳转接入

**REQ-6.1** `HomeViewModel` 中 `onCardTap` 方法根据 `gameId` 路由到对应详情页：

- `genshin` → `AppRoutes.GENSHIN_DAILY_DETAIL`
- `starrail` → `AppRoutes.STARRAIL_DAILY_DETAIL`
- `zzz` → `AppRoutes.ZZZ_DAILY_DETAIL`

**REQ-6.2** 路由参数统一使用 `{ accountId, roleUid }` 结构。

---

### REQ-7：core 模块导出

**REQ-7.1** 在 `core/Index.ets` 中导出 `StarRailDailyNoteParser` 和 `ZZZDailyNoteParser`，
以及对应的数据类型 `StarRailDailyNoteData`、`ZZZDailyNoteData`。

---

## 非功能需求

- 所有字符串资源必须在 `string.json`（base/zh_HK/en）中声明，不得硬编码
- 时间格式化（"X小时Y分钟后恢复"）在 ViewModel 层生成，不放资源文件
- 状态枚举映射（`SaleStateDone` → "已结算"）在 ViewModel 层处理
- 组件必须在文件末尾添加 `@Preview`

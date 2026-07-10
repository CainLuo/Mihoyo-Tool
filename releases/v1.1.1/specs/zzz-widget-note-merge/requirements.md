# 需求：绝区零 Note API 与 Widget API 数据融合

## 背景

绝区零有两个实时便笺 API：

| API | 路径 | 特点 | 数据字段 |
|-----|------|------|----------|
| Note API | `/event/game_record_zzz/api/zzz/note` | 会触发 1034 风控，请求频率受限 | energy、vitality、vhs_sale、card_sign、bounty_commission、weekly_task、cafe_state、member_card、temple_running |
| Widget API | `/event/game_record_zzz/api/zzz/widget` | 无风控，可高频请求 | energy、vitality、vhs_sale、card_sign、bounty_commission、weekly_task + **note_list** + activity_list |

**核心差异**：Widget API 有 `note_list` 字段（米游社预格式化的额外信息列表），Note API 没有。

## 需求

1. **API 独立调用** — Note API 和 Widget API 分开调用，互不影响
2. **数据融合存储** — 两个 API 的数据存储在同一条记录中，基础字段后请求的覆盖前请求的
3. **Widget 显示增强** — Widget 额外信息行优先使用 `note_list`，降级时从原始字段构建

## 验收标准

### 数据层

- [ ] `ZZZDailyNoteRow` 新增 `widgetRawJson` 字段
- [ ] `zzz_daily_note` 表新增 `widget_raw_json` 列
- [ ] 现有数据升级后不受影响（新列自动填充空字符串）
- [ ] `ZZZDailyNoteDao.upsert()` 支持新字段读写

### Repository 层

- [ ] `ZZZRepository.syncDailyNote()` 只更新 `rawJson` 和基础字段
- [ ] `ZZZRepository` 新增 `syncDailyNoteWidget()` 方法，只更新 `widgetRawJson` 和基础字段
- [ ] 两个方法共用 `SyncDataType.ZZZ_DAILY_NOTE`
- [ ] 两个 API 调用互不影响，基础字段后请求的覆盖前请求的

### Widget 数据解析

- [ ] `WidgetDataHelper.parseExtraRows()` 新增 `widgetRawJson` 参数
- [ ] 绝区零解析逻辑：
  - 优先从 `widgetRawJson` 解析 `note_list`
  - 降级从 `widgetRawJson` 或 `rawJson` 的原始字段构建
- [ ] `Widget2x2ViewModel` 传入双参数
- [ ] `Widget2x4ViewModel` 传入双参数（如果有用到）

### Mock 数据

- [ ] Note API Mock 文件路径正确：`mock/{accountId}/{roleId}/event_game_record_zzz_api_zzz_note.json`
- [ ] Widget API Mock 文件路径正确：`mock/{accountId}/{roleId}/event_record_app_zzz_widget.json`

## 影响范围

| 文件 | 修改类型 |
|------|----------|
| `core/src/main/ets/models/ZZZRows.ets` | 新增字段 |
| `core/src/main/ets/database/TableSchema.ets` | 新增列定义 |
| `core/src/main/ets/database/ZZZDao.ets` | 修改 upsert/mapRow |
| `core/src/main/ets/repository/ZZZRepository.ets` | 新增方法 |
| `entry/src/main/ets/widget/utils/WidgetDataHelper.ets` | 修改方法签名 |
| `entry/src/main/ets/widget/viewmodel/Widget2x2ViewModel.ets` | 修改调用 |
| `entry/src/main/ets/widget/viewmodel/Widget2x4ViewModel.ets` | 修改调用 |

## 约束

- 遵循项目编码规范（禁止硬编码、字符串资源化等）
- 遵循 MVVM 架构（数据解析在 ViewModel 层）
- 数据库新增列必须有默认值，保证升级兼容性

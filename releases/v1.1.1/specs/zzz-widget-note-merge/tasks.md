# 任务清单：绝区零 Note API 与 Widget API 数据融合

## 状态说明

- [ ] 待完成
- [x] 已完成
- [~] 进行中

---

## 任务列表

### 一、数据层修改

- [x] **Task 1.1**：修改 `ZZZDailyNoteRow` 模型
  - 文件：`core/src/main/ets/models/ZZZRows.ets`
  - 内容：新增 `widgetRawJson: string = ''` 字段
  - 验证：编译通过

- [x] **Task 1.2**：修改 `zzz_daily_note` 表结构
  - 文件：`core/src/main/ets/database/TableSchema.ets`
  - 内容：`ZZZ_DAILY_NOTE_TABLE` 新增列 `widget_raw_json TEXT DEFAULT ''`
  - 验证：编译通过

- [x] **Task 1.3**：修改 `ZZZDailyNoteDao`
  - 文件：`core/src/main/ets/database/ZZZDao.ets`
  - 内容：
    - `upsert()` 方法写入新字段
    - `mapRow()` 方法读取新字段
  - 验证：编译通过

---

### 二、Repository 层修改

- [x] **Task 2.1**：修改 `syncDailyNote()` 方法
  - 文件：`core/src/main/ets/repository/ZZZRepository.ets`
  - 内容：确认只更新 `rawJson` 和基础字段，不更新 `widgetRawJson`
  - 验证：编译通过

- [x] **Task 2.2**：新增 `syncDailyNoteWidget()` 方法
  - 文件：`core/src/main/ets/repository/ZZZRepository.ets`
  - 内容：
    - 调用 `ZZZApiService.getDailyNoteWidget()`
    - 更新 `widgetRawJson` 和基础字段
    - 不更新 `rawJson`
  - 验证：编译通过，Mock 环境测试通过

---

### 三、Widget 数据解析修改

- [x] **Task 3.1**：修改 `WidgetDataHelper.parseExtraRows()`
  - 文件：`entry/src/main/ets/widget/utils/WidgetDataHelper.ets`
  - 内容：
    - 新增 `widgetRawJson` 参数
    - 绝区零解析逻辑：优先 `note_list`，降级原始字段
  - 验证：编译通过

- [x] **Task 3.2**：修改 `Widget2x2ViewModel`
  - 文件：`entry/src/main/ets/widget/viewmodel/Widget2x2ViewModel.ets`
  - 内容：传入双参数 `parseExtraRows(rawJson, widgetRawJson, ...)`
  - 验证：编译通过，Widget 显示正常

- [x] **Task 3.3**：修改 `Widget2x4ViewModel`
  - 文件：`entry/src/main/ets/widget/viewmodel/Widget2x4ViewModel.ets`
  - 内容：传入双参数 `parseExtraRows(rawJson, widgetRawJson, ...)`
  - 验证：编译通过，Widget 显示正常

- [x] **Task 3.4**：修改 `Widget4x4ViewModel`
  - 文件：`entry/src/main/ets/widget/viewmodel/Widget4x4ViewModel.ets`
  - 内容：传入双参数 `parseExtraRows(rawJson, widgetRawJson, ...)`
  - 验证：编译通过

- [x] **Task 3.5**：修改 `WidgetSlotData` 模型
  - 文件：`entry/src/main/ets/widget/models/WidgetDataStore.ets`
  - 内容：新增 `widgetRawJson` 字段，修改 `toJson()` 和 `fromJson()`
  - 验证：编译通过

- [x] **Task 3.6**：修改 `ParsedRole` 模型
  - 文件：`entry/src/main/ets/widget/utils/WidgetPayloadParser.ets`
  - 内容：新增 `widgetRawJson` 字段，修改解析逻辑
  - 验证：编译通过

- [x] **Task 3.7**：修改 `WidgetRolePayloadItem` 模型
  - 文件：`entry/src/main/ets/widget/utils/WidgetPayloadBuilder.ets`
  - 内容：新增 `widgetRawJson` 字段，修改构建逻辑
  - 验证：编译通过

- [x] **Task 3.8**：修改 `WidgetDataStoreBuilder`
  - 文件：`entry/src/main/ets/widget/utils/WidgetDataStoreBuilder.ets`
  - 内容：`buildSlotData()` 和 `updateRoleRawJson()` 读取 `widgetRawJson`
  - 验证：编译通过

---

### 四、Mock 数据验证

- [ ] **Task 4.1**：验证 Mock 文件路径
  - 文件：
    - `core/src/mock/resources/rawfile/mock/{accountId}/{roleId}/event_game_record_zzz_api_zzz_note.json`
    - `core/src/mock/resources/rawfile/mock/{accountId}/{roleId}/event_record_app_zzz_widget.json`
  - 内容：确认文件存在，数据格式正确
  - 验证：Mock 环境运行通过

---

### 五、测试覆盖

- [ ] **Task 5.1**：补充 `ZZZDailyNoteRow` 单元测试
  - 文件：`core/src/test/RowModels.test.ets`（如存在）
  - 内容：新增字段默认值验证

- [ ] **Task 5.2**：补充 `parseExtraRows()` 单元测试
  - 文件：`entry/src/test/WidgetDataHelper.test.ets`（如存在）
  - 内容：双参数解析逻辑验证

- [ ] **Task 5.3**：补充 `ZZZRepository` 集成测试
  - 文件：`core/src/ohosTest/ZZZRepository.test.ets`（如存在）
  - 内容：两个同步方法互不影响验证

---

## 完成标准

1. 所有任务标记为 `[x]`
2. `bash run-mock.sh` 构建通过
3. Widget 显示正常（有 `note_list` 时显示 `note_list`，无时降级显示）
4. 现有数据升级后不受影响

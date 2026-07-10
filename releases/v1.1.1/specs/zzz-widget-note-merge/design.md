# 设计：绝区零 Note API 与 Widget API 数据融合

## 一、数据模型修改

### 1.1 ZZZDailyNoteRow 扩展

```typescript
export class ZZZDailyNoteRow {
  // ... 现有字段 ...
  
  /** 原始 API 响应 JSON（来自 zzz/note 接口） */
  rawJson: string = '';
  
  /** Widget API 响应 JSON（来自 zzz/widget 接口，含 note_list 字段） */
  widgetRawJson: string = '';  // 新增
  
  /** 数据更新时间（Unix 秒） */
  updateTime: number = 0;
}
```

### 1.2 表结构扩展

`zzz_daily_note` 表新增列：

```sql
widget_raw_json TEXT DEFAULT ''
```

**升级兼容性**：SQLite `ALTER TABLE ADD COLUMN` 是非破坏性操作，现有数据自动填充默认值 `''`。

---

## 二、Repository 层修改

### 2.1 syncDailyNote() — 同步 Note API

```typescript
async syncDailyNote(
  accountId: string, 
  roleUid: string, 
  server: string, 
  cookie: string, 
  geetestChallenge?: string
): Promise<void>
```

**行为**：
1. 调用 Note API
2. 更新 `rawJson` 和基础字段（energy、vitality 等）
3. **不更新** `widgetRawJson`
4. 记录 sync_meta 状态

### 2.2 syncDailyNoteWidget() — 同步 Widget API（新增）

```typescript
async syncDailyNoteWidget(
  accountId: string,
  roleUid: string,
  widgetCookie: string
): Promise<void>
```

**行为**：
1. 调用 Widget API
2. 更新 `widgetRawJson` 和基础字段（energy、vitality 等）
3. **不更新** `rawJson`
4. 记录 sync_meta 状态（复用 `ZZZ_DAILY_NOTE`）

### 2.3 数据流示意

```
用户手动刷新 ──────► syncDailyNote() ──────► rawJson + 基础字段
                                              │
                                              └──► DB 更新

Widget 定时刷新 ───► syncDailyNoteWidget() ──► widgetRawJson + 基础字段
                                              │
                                              └──► DB 更新（同一行记录）
```

---

## 三、Widget 数据解析修改

### 3.1 parseExtraRows() 签名修改

```typescript
static parseExtraRows(
  rawJson: string,           // Note API 响应
  widgetRawJson: string,     // Widget API 响应（新增）
  gameId: string,
  maxRows: number = 0
): ParsedExtraRow[]
```

### 3.2 绝区零解析逻辑

```typescript
// 1. 优先从 widgetRawJson 解析 note_list
if (widgetRawJson 非空 && 有 note_list 字段) {
  直接返回 note_list 内容;
}

// 2. 降级从原始字段构建
//    优先用 widgetRawJson（数据更新），如果没有则用 rawJson
const data = widgetRawJson 非空 ? JSON.parse(widgetRawJson) : JSON.parse(rawJson);
从 data 解析 vhs_sale、card_sign、bounty_commission、weekly_task;
```

### 3.3 原神/星铁逻辑不变

原神和星铁没有 `note_list` 字段，继续使用原有逻辑。

---

## 四、ViewModel 层修改

### 4.1 Widget2x2ViewModel

```typescript
// 修改前
WidgetDataHelper.parseExtraRows(noteRow.rawJson, gameId, 2)

// 修改后
WidgetDataHelper.parseExtraRows(noteRow.rawJson, noteRow.widgetRawJson, gameId, 2)
```

### 4.2 Widget2x4ViewModel

同样修改，传入双参数。

---

## 五、Mock 文件路径

| API | Mock 文件路径 |
|-----|---------------|
| Note API | `mock/{accountId}/{roleId}/event_game_record_zzz_api_zzz_note.json` |
| Widget API | `mock/{accountId}/{roleId}/event_record_app_zzz_widget.json` |

两个文件都在 `{accountId}/{roleId}/` 目录下，符合 `MockServiceBase.pathToFileName()` 映射规则。

---

## 六、测试策略

### 单元测试

| 测试项 | 文件位置 |
|--------|----------|
| `ZZZDailyNoteRow` 新增字段默认值 | `core/src/test/RowModels.test.ets` |
| `parseExtraRows()` 双参数解析 | `entry/src/test/WidgetDataHelper.test.ets` |

### 集成测试（设备端）

| 测试项 | 文件位置 |
|--------|----------|
| `syncDailyNote()` 不更新 `widgetRawJson` | `core/src/ohosTest/ZZZRepository.test.ets` |
| `syncDailyNoteWidget()` 不更新 `rawJson` | `core/src/ohosTest/ZZZRepository.test.ets` |
| DB 升级后现有数据保留 | `core/src/ohosTest/RdbManager.test.ets` |

---

## 七、风险与缓解

| 风险 | 缓解措施 |
|------|----------|
| DB 升级失败 | 新增列使用 `DEFAULT ''`，保证非空约束 |
| 现有数据丢失 | SQLite ADD COLUMN 是非破坏性操作 |
| 解析逻辑复杂度增加 | 优先使用 `note_list`，降级逻辑复用现有代码 |

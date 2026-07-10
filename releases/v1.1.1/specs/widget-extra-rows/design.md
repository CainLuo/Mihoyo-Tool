# Widget 额外信息行优化 - 设计文档

## 一、数据结构分析

### 原神 (`game_record_app_genshin_widget.json`)

**额外信息字段**：
- `expeditions` / `max_expedition_num` — 探索派遣
- `current_home_coin` / `max_home_coin` — 洞天宝钱
- `finished_task_num` / `total_task_num` / `is_extra_task_reward_received` — 每日委托
- `transformer` — 参量质变仪（JSON 中可能不存在）
- `week_active_progress.progress_current` / `progress_total` — 周活跃进度

### 星铁 (`game_record_app_hkrpg_widget_large.json`)

**额外信息字段**：
- `accepted_expedition_num` / `total_expedition_num` — 委托派遣
- `current_train_score` / `max_train_score` — 每日实训/周期积分
- `rogue_tourn_weekly_cur` / `rogue_tourn_weekly_max` — 模拟宇宙积分

**注意**：`current_reserve_stamina`（后备开拓力）属于体力相关，在 ViewModel 中单独处理，不属于额外信息。

### 绝区零 (`event_record_app_zzz_widget.json`)

**`note_list` 字段**：
```json
"note_list": [
  { "name": "饼铺盲盒/刮刮卡/占卜", "value": "已完成", "value_color": "E5FFFFFF", "value_highlight": false },
  { "name": "录像店经营", "value": "正在营业", "value_color": "E5FFFFFF", "value_highlight": false },
  { "name": "悬赏委托", "value": "0/8000", "value_color": "FFDE00", "value_highlight": true },
  { "name": "丽都周纪积分", "value": "100/2100", "value_color": "FFDE00", "value_highlight": true }
]
```

直接使用 `note_list`，无需手动解析原始字段。

---

## 二、架构设计

### 文件结构

```
entry/src/main/ets/widget/
├── utils/
│   ├── WidgetUtils.ets
│   ├── WidgetDataHelper.ets        ← 修改：添加 maxRows 参数
│   ├── WidgetExtraRowType.ets      ← 新增：额外信息类型枚举
│   └── WidgetExtraRowConfig.ets    ← 新增：优先级配置
├── viewmodel/
│   ├── Widget2x2ViewModel.ets      ← 修改：调用时传入 maxRows
│   ├── Widget2x4ViewModel.ets      ← 修改：调用时传入 maxRows
│   └── Widget4x4ViewModel.ets      ← 修改：调用时传入 maxRows
```

### 数据流

```
rawJson (原始 JSON)
    ↓
WidgetDataHelper.parseExtraRows(rawJson, gameId, maxRows)  ← 工具方法，纯函数
    ↓
ParsedExtraRow[] (已排序、已截断)
    ↓
ViewModel.convertExtraRows()  ← 转换为 WidgetExtraRow
    ↓
WidgetExtraRow[] (UIState)
    ↓
WidgetExtraDataRows (组件渲染)
```

---

## 三、枚举设计

### `ExtraRowType` 枚举

只用于原神和星铁的优先级排序，绝区零不需要。

```typescript
/**
 * 额外信息行类型枚举
 * 用于原神和星铁的优先级排序
 * 
 * 绝区零直接使用 note_list，不需要此枚举
 */
export enum ExtraRowType {
  // ── 原神 ──
  GENSHIN_EXPEDITION = 'expedition',
  GENSHIN_HOME_COIN = 'home_coin',
  GENSHIN_DAILY_TASK = 'daily_task',
  GENSHIN_TRANSFORMER = 'transformer',
  GENSHIN_WEEK_ACTIVE = 'week_active',

  // ── 星铁 ──
  STARRAIL_EXPEDITION = 'starrail_expedition',
  STARRAIL_TRAIN_SCORE = 'train_score',
  STARRAIL_ROGUE_TOURN = 'rogue_tourn',
}
```

### `WidgetExtraRowConfig` 优先级配置

```typescript
export class WidgetExtraRowConfig {
  /** 原神优先级：探索派遣 > 洞天宝钱 > 每日委托 > 参量质变仪 > 周活跃进度 */
  static readonly GENSHIN_PRIORITY: Record<string, number> = {
    'expedition': 1,
    'home_coin': 2,
    'daily_task': 3,
    'transformer': 4,
    'week_active': 5,
  };

  /** 星铁优先级：委托派遣 > 每日实训 > 模拟宇宙积分 */
  static readonly STARRAIL_PRIORITY: Record<string, number> = {
    'starrail_expedition': 1,
    'train_score': 2,
    'rogue_tourn': 3,
  };

  /** 根据游戏 ID 获取优先级配置 */
  static getPriority(gameId: string): Record<string, number> {
    // ...
  }
}
```

---

## 四、方法签名变更

### `WidgetDataHelper.parseExtraRows()`

```typescript
/**
 * 解析额外数据行
 * 
 * @param rawJson 原始 JSON 字符串
 * @param gameId 游戏 ID
 * @param maxRows 最多返回几行（0 = 不限制，默认 0）
 * @returns 额外数据行数组，已按优先级排序并截断
 * 
 * 原神/星铁：解析原始字段，按优先级排序后截断
 * 绝区零：直接使用 note_list，按 maxRows 截断
 */
static parseExtraRows(
  rawJson: string,
  gameId: string,
  maxRows: number = 0
): ParsedExtraRow[]
```

### 绝区零 `note_list` 解析

```typescript
/**
 * 解析绝区零 note_list 字段
 * 
 * @param rawJson 原始 JSON 字符串
 * @param maxRows 最多返回几行（0 = 不限制）
 */
private static parseZZZNoteList(rawJson: string, maxRows: number): ParsedExtraRow[]
```

---

## 五、ViewModel 调用方式

### `Widget2x2ViewModel`

```typescript
private static buildRoleUIState(role: ParsedRole): WidgetRoleUIState {
  // ...
  
  // 2x2 Widget 最多显示 2 行额外信息
  const extraRows = WidgetDataHelper.parseExtraRows(role.rawJson, role.gameId, 2);
  state.extraRows = Widget2x2ViewModel.convertExtraRows(extraRows);
  
  return state;
}
```

### `Widget2x4ViewModel`

```typescript
// 2x4 Widget 最多显示 4 行额外信息
const extraRows = WidgetDataHelper.parseExtraRows(role.rawJson, role.gameId, 4);
```

### `Widget4x4ViewModel`

```typescript
// 4x4 Widget 不限制额外信息行数
const extraRows = WidgetDataHelper.parseExtraRows(role.rawJson, role.gameId, 0);
```

---

## 六、测试策略

### 单元测试（`entry/src/test/`）

1. **`ExtraRowType` 枚举值验证**
   - 确认枚举值与字符串字面量一致

2. **`WidgetExtraRowConfig` 优先级配置验证**
   - 确认每个游戏的优先级配置正确
   - 确认 `getPriority()` 返回正确的配置

3. **`parseExtraRows` 数量限制测试**
   - 原神：模拟 5 行数据，`maxRows=2` 返回前 2 行（按优先级）
   - 星铁：模拟 3 行数据，`maxRows=2` 返回前 2 行（按优先级）
   - 绝区零：模拟 4 行 `note_list`，`maxRows=2` 返回前 2 行
   - `maxRows=0` 返回全部行

4. **绝区零 `note_list` 解析测试**
   - 正常 JSON 解析
   - 空 `note_list`
   - 无 `note_list` 字段

### 组件 @Preview（组件文件末尾）

- `WidgetExtraDataRows` 添加多行数据预览，验证布局

---

## 七、兼容性说明

### 对现有代码的影响

| 文件 | 变更 |
|------|------|
| `WidgetDataHelper.ets` | 方法签名变更，添加可选参数 `maxRows`，默认值 0（不限制），**向后兼容** |
| `Widget2x2ViewModel.ets` | 调用时传入 `maxRows=2` |
| `Widget2x4ViewModel.ets` | 调用时传入 `maxRows=4`（如需限制） |
| `Widget4x4ViewModel.ets` | 调用时传入 `maxRows=0`（不限制） |

### 废弃字段处理

绝区零原来手动解析的字段（`vitality`、`card_sign`、`vhs_sale`）改为使用 `note_list`，旧的解析逻辑可以保留作为 fallback，或者直接删除。

建议：直接删除旧逻辑，保持代码简洁。

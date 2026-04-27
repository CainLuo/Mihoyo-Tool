# Design Document

## Overview

本设计文档描述 `core/src/test/` 下本地单元测试的实现方案。所有测试覆盖纯函数和静态方法，不依赖设备，不涉及 DB 层。

测试框架：`@ohos/hypium`（`describe/it/expect`）
测试入口：`core/src/test/List.test.ets`

---

## Architecture

### 测试文件结构

```
core/src/test/
├── List.test.ets                    ← 入口，注册所有测试套件
├── DSUtilV2.test.ets                ← DS 签名生成测试（已有 + 补充）
├── MockServiceBase.test.ets         ← 路径映射 + Cookie 解析测试（已有 + 补充）
├── GenshinDailyNoteParser.test.ets  ← 原神便笺解析测试（已有 + 补充）
├── StarRailDailyNoteParser.test.ets ← 星铁便笺解析测试（已有 + 补充）
├── ZZZDailyNoteParser.test.ets      ← 绝区零便笺解析测试（已有 + 补充）
├── SyncDataType.test.ets            ← 枚举值一致性测试（已有）
└── RowModels.test.ets               ← Row 模型默认值测试（已有）
```

### 被测类依赖关系

```
DSUtilV2.test.ets
  └── core/src/main/ets/network/v2/DSUtilV2.ets
  └── core/src/main/ets/network/APIs.ets (RequestParams)

MockServiceBase.test.ets
  └── core/src/main/ets/network/v2/mock/MockServiceBase.ets

GenshinDailyNoteParser.test.ets
  └── core/src/main/ets/parsers/genshin/GenshinDailyNoteParser.ets

StarRailDailyNoteParser.test.ets
  └── core/src/main/ets/parsers/starrail/StarRailDailyNoteParser.ets

ZZZDailyNoteParser.test.ets
  └── core/src/main/ets/parsers/zzz/ZZZDailyNoteParser.ets

SyncDataType.test.ets
  └── core/src/main/ets/constants/SyncDataType.ets

RowModels.test.ets
  └── core/src/main/ets/models/v2/*.ets
```

---

## Components and Interfaces

### DSUtilV2 测试设计

**已有测试覆盖（DSUtilV2.test.ets）：**

- generateV1/V2/X6 格式验证（3 段逗号分隔）
- timestamp 近期 Unix 秒验证
- random 6 位字符验证
- md5 32 位十六进制验证
- 多参数/单参数/空参数/undefined 参数不崩溃
- 有 body/空 body 不崩溃

**需要补充的测试用例：**

| 测试用例 ID | 测试名                                     | 输入                         | 预期                           |
| ----------- | ------------------------------------------ | ---------------------------- | ------------------------------ |
| DS-S-01     | `sortedQuery_zam_isAlphabetical`           | params `{z:1, a:2, m:3}`     | query 为 `a=2&m=3&z=1`         |
| DS-S-02     | `sortedQuery_ba_isAlphabetical`            | params `{b:1, a:2}`          | query 为 `a=2&b=1`             |
| DS-S-03     | `sortedQuery_roleIdVsRole_isAlphabetical`  | params `{role_id:1, role:2}` | query 为 `role=2&role_id=1`    |
| DS-S-04     | `random_100calls_onlyAlphanumeric`         | 调用 100 次 generateV1()     | 每次 random 只含 `[a-zA-Z0-9]` |
| DS-S-05     | `params_100keys_doesNotCrash`              | 100 个键值对                 | DS 正常生成                    |
| DS-S-06     | `params_valueZero_serializedAsZero`        | `params.set('level', 0)`     | 序列化为 `level=0`             |
| DS-S-07     | `params_negativeValue_serializedCorrectly` | `params.set('offset', -1)`   | 序列化为 `offset=-1`           |
| DS-S-08     | `body_unicode_doesNotCrash`                | `body = '{"name":"旅行者"}'` | DS 正常生成                    |

**字典序验证实现思路：**
由于 DS 的 MD5 包含了 query 字符串，无法直接从 DS 结果反推 query。需要通过 mock 或暴露内部方法来验证字典序。如果 DSUtilV2 没有暴露 `buildQuery` 等内部方法，则通过验证"不同顺序的相同参数生成相同 DS"来间接验证字典序（幂等性属性）。

### MockServiceBase 测试设计

**已有测试覆盖（MockServiceBase.test.ets）：**

- 6 条通用路径映射
- 5 条特殊映射表
- 3 条带 query 参数的路径
- 6 条 extractAccountId 基础场景

**需要补充的测试用例：**

pathToFileName 边界场景：

| 测试用例 ID | 测试名                                       | 输入                                        | 预期                           |
| ----------- | -------------------------------------------- | ------------------------------------------- | ------------------------------ |
| MSB-P-01    | `pathWithUppercase_preservesCase`            | `/Game_Record/App`                          | `Game_Record_App.json`         |
| MSB-P-02    | `pathWithNumbers_mapsCorrectly`              | `/api/v3/data`                              | `api_v3_data.json`             |
| MSB-P-03    | `pathWithHyphen_preservesHyphen`             | `/game-record/api`                          | `game-record_api.json`         |
| MSB-P-04    | `pathWithMultipleQueryParams_stripsAll`      | `/api?a=1&b=2&c=3`                          | `api.json`                     |
| MSB-P-05    | `specialMappingWithQuery_specialMappingWins` | `/event/rpgcalc/compute?game=hkrpg&uid=123` | `hkrpg_character_compute.json` |

extractAccountId 边界场景：

| 测试用例 ID | 测试名                                | 输入                           | 预期 |
| ----------- | ------------------------------------- | ------------------------------ | ---- |
| MSB-E-01    | `accountIdZero_returnsZero`           | `'account_id=0'`               | `0`  |
| MSB-E-02    | `accountIdFloat_truncatesToInt`       | `'account_id=1.5'`             | `1`  |
| MSB-E-03    | `accountIdDuplicate_returnsFirst`     | `'account_id=1; account_id=2'` | `1`  |
| MSB-E-04    | `accountIdNonNumeric_returnsFallback` | `'account_id=abc'`             | `1`  |
| MSB-E-05    | `accountIdWithSpaces_returnsFallback` | `'account_id = 1'`             | `1`  |

### Parser 测试设计

所有 Parser 遵循相同的测试模式：

1. 构造标准 VALID_JSON 常量
2. 验证每个字段的正常解析
3. 验证边界值（0、最大值、超限值）
4. 验证容错（无效 JSON、空字符串、空对象、null、数组）

**GenshinDailyNoteParser 补充测试：**

| 测试用例 ID | 测试名                                          | 输入                       | 预期                                    |
| ----------- | ----------------------------------------------- | -------------------------- | --------------------------------------- |
| GNP-B-01    | `parse_currentResinZero_returnsZero`            | `current_resin: 0`         | `currentResin = 0`                      |
| GNP-B-02    | `parse_currentResinOverLimit_returnsAsIs`       | `current_resin: 999`       | `currentResin = 999`                    |
| GNP-B-03    | `parse_resinRecoveryTimeZeroString_returnsZero` | `resin_recovery_time: "0"` | `resinRecoveryTime = 0`                 |
| GNP-B-04    | `parse_emptyExpeditions_returnsEmptyArray`      | `expeditions: []`          | `expeditions.length = 0`                |
| GNP-B-05    | `parse_transformerNull_returnsDefault`          | `transformer: null`        | 不崩溃，返回默认 GenshinTransformerData |
| GNP-B-06    | `parse_jsonArray_returnsDefault`                | `'[1,2,3]'`                | 返回默认值不崩溃                        |
| GNP-B-07    | `parse_jsonNull_returnsDefault`                 | `'null'`                   | 返回默认值不崩溃                        |

**StarRailDailyNoteParser 补充测试：**

| 测试用例 ID | 测试名                                        | 输入                 | 预期                     |
| ----------- | --------------------------------------------- | -------------------- | ------------------------ |
| SRP-B-01    | `parse_currentStaminaZero_returnsZero`        | `current_stamina: 0` | `currentStamina = 0`     |
| SRP-B-02    | `parse_gridFightWeeklyCurMissing_returnsZero` | 无此字段             | `gridFightWeeklyCur = 0` |
| SRP-B-03    | `parse_maxStaminaZero_doesNotCrash`           | `max_stamina: 0`     | `maxStamina = 0`         |

**ZZZDailyNoteParser 补充测试：**

| 测试用例 ID | 测试名                                 | 输入                           | 预期                                 |
| ----------- | -------------------------------------- | ------------------------------ | ------------------------------------ |
| ZZP-B-01    | `parse_energyCurrentZero_returnsZero`  | `energy.progress.current: 0`   | `currentEnergy = 0`                  |
| ZZP-B-02    | `parse_energyRestoreZero_returnsZero`  | `energy.restore: 0`            | `energyRecoverTime = 0`              |
| ZZP-B-03    | `parse_vhsSaleMissing_returnsEmpty`    | 无 vhs_sale 字段               | `videoStoreState = ''`               |
| ZZP-B-04    | `parse_memberCardMissing_returnsFalse` | 无 member_card 字段            | `memberCardIsOpen = false`           |
| ZZP-B-05    | `parse_cardSignDone_isCorrect`         | `card_sign: 'CardSignDone'`    | `cardSign = 'CardSignDone'`          |
| ZZP-B-06    | `parse_cardSignNo_isCorrect`           | `card_sign: 'CardSignNo'`      | `cardSign = 'CardSignNo'`            |
| ZZP-B-07    | `parse_saleStateDone_isCorrect`        | `sale_state: 'SaleStateDone'`  | `videoStoreState = 'SaleStateDone'`  |
| ZZP-B-08    | `parse_saleStateDoing_isCorrect`       | `sale_state: 'SaleStateDoing'` | `videoStoreState = 'SaleStateDoing'` |
| ZZP-B-09    | `parse_saleStateNo_isCorrect`          | `sale_state: 'SaleStateNo'`    | `videoStoreState = 'SaleStateNo'`    |
| ZZP-B-10    | `parse_jsonArray_returnsDefault`       | `'[1,2,3]'`                    | 返回默认值不崩溃                     |

---

## Data Models

### 测试数据构造规范

每个 Parser 测试文件顶部定义 `VALID_JSON` 常量，包含所有字段的典型值。边界测试用例在 `it` 块内部构造局部 JSON。

```typescript
// 标准模式
const VALID_JSON = JSON.stringify({
  field1: value1,
  field2: value2,
  // ...
});

// 边界测试
it("parse_fieldZero_returnsZero", 0, () => {
  const json = JSON.stringify({ field1: 0 /* 其他必要字段 */ });
  const data = Parser.parse(json);
  expect(data.field1).assertEqual(0);
});
```

---

## Error Handling

所有 Parser 必须满足以下容错要求：

- 无效 JSON → 返回默认值对象，不抛异常
- 空字符串 → 返回默认值对象，不抛异常
- JSON 为数组/null/数字/布尔值 → 返回默认值对象，不抛异常
- 字段缺失 → 使用 `?? defaultValue` 兜底

---

## Correctness Properties

以下属性基于 testing-core.md 第八节的极端测试场景设计：

### 1. Round-Trip Property（解析幂等性）

FOR ALL valid JSON strings that GenshinDailyNoteParser can parse:

- `parse(json).currentResin` 等于 JSON 中 `current_resin` 的值（类型转换后）

### 2. Invariant（DS 格式不变量）

FOR ALL calls to `DSUtilV2.generateV1()`:

- 结果始终为 3 段逗号分隔的字符串
- 第 1 段为近期 Unix 秒时间戳
- 第 2 段为 6 位字母数字字符
- 第 3 段为 32 位十六进制字符串

### 3. Metamorphic Property（字典序排列）

FOR ALL RequestParams with the same key-value pairs but different insertion order:

- `DSUtilV2.generateV1(params1)` 的 MD5 段 == `DSUtilV2.generateV1(params2)` 的 MD5 段
  （相同参数不同顺序应生成相同签名，因为内部按字典序排列）

### 4. Error Condition（容错属性）

FOR ALL invalid JSON inputs (non-object, empty, null, array):

- Parser.parse(input) 不抛异常
- Parser.parse(input).currentXxx 等于对应默认值（通常为 0 或 ''）

### 5. Idempotence（幂等性）

FOR ALL valid JSON strings:

- `parse(json)` 调用两次返回相同结果（无副作用）

---

## Testing Strategy

### 测试命名规范

遵循 testing-core.md 第五节规范：

```
{被测方法}_{测试场景}_{预期结果}

示例：
  parse_currentResin_isCorrect
  pathToFileName_batchCompute_usesSpecialMapping
  extractAccountId_emptyCookie_returns1AsFallback
  generateV1_format_isTimestampRandomMd5
```

### 测试分组

每个测试文件使用 `describe` 按被测类/方法分组：

- `DSUtilV2` — 所有 DS 生成测试
- `MockServiceBase.pathToFileName` — 路径映射测试
- `MockServiceBase.extractAccountId` — Cookie 解析测试
- `GenshinDailyNoteParser` — 原神便笺解析测试
- `StarRailDailyNoteParser` — 星铁便笺解析测试
- `ZZZDailyNoteParser` — 绝区零便笺解析测试
- `SyncDataType` — 枚举值测试
- 各 Row 类名 — 默认值测试

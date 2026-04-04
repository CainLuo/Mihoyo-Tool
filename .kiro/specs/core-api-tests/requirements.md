# Requirements Document

## Introduction

本 Spec 专门覆盖 `core/src/test/` 下的本地单元测试，测试对象为纯函数和静态方法，不依赖设备，不需要真实 RDB。

测试框架：`@ohos/hypium`，使用 `describe/it/expect` 断言。
测试入口：`core/src/test/List.test.ets`。

约束：

- 所有测试文件位于 `core/src/test/`
- 不得 import DB 层（DAO/RdbManager）的任何类
- 使用 `@ohos/hypium` 框架

## Glossary

- **DSUtilV2**: 负责生成米哈游 DS 动态签名的工具类，位于 `core/src/main/ets/network/v2/DSUtilV2.ets`
- **MockServiceBase**: Mock 服务基类，提供路径映射和 Cookie 解析静态方法，位于 `core/src/main/ets/network/v2/mock/MockServiceBase.ets`
- **GenshinDailyNoteParser**: 原神便笺 JSON 解析器，位于 `core/src/main/ets/parsers/genshin/GenshinDailyNoteParser.ets`
- **StarRailDailyNoteParser**: 星铁便笺 JSON 解析器，位于 `core/src/main/ets/parsers/starrail/StarRailDailyNoteParser.ets`
- **ZZZDailyNoteParser**: 绝区零便笺 JSON 解析器，位于 `core/src/main/ets/parsers/zzz/ZZZDailyNoteParser.ets`
- **SyncDataType**: 枚举类，定义 sync_meta 表的 data_type 字段值，位于 `core/src/main/ets/constants/SyncDataType.ets`
- **Row_Model**: v2 数据库行模型类，位于 `core/src/main/ets/models/v2/` 目录下
- **RequestParams**: 请求参数容器类，位于 `core/src/main/ets/network/APIs.ets`
- **DS**: Dynamic Signature，米哈游 API 请求头中的动态签名字段，格式为 `{timestamp},{random},{md5}`

---

## Requirements

### Requirement 1: DSUtilV2 DS 格式验证

**User Story:** As a developer, I want to verify that DSUtilV2 generates correctly formatted DS signatures, so that API requests are authenticated properly.

#### Acceptance Criteria

1. WHEN `DSUtilV2.generateV1()` is called, THE DSUtilV2 SHALL return a string with exactly 3 comma-separated segments
2. WHEN `DSUtilV2.generateV1()` is called, THE DSUtilV2 SHALL return a timestamp segment within 5 seconds of the current Unix time
3. WHEN `DSUtilV2.generateV1()` is called, THE DSUtilV2 SHALL return a random segment of exactly 6 characters
4. WHEN `DSUtilV2.generateV1()` is called, THE DSUtilV2 SHALL return an md5 segment of exactly 32 lowercase hexadecimal characters
5. WHEN `DSUtilV2.generateV2()` is called, THE DSUtilV2 SHALL return a string with exactly 3 comma-separated segments
6. WHEN `DSUtilV2.generateX6()` is called, THE DSUtilV2 SHALL return a string with exactly 3 comma-separated segments

### Requirement 2: DSUtilV2 query 参数序列化

**User Story:** As a developer, I want DSUtilV2 to serialize query parameters in lexicographic order, so that the DS signature is consistent and verifiable.

#### Acceptance Criteria

1. WHEN `DSUtilV2.generateV1(params)` is called with multiple params, THE DSUtilV2 SHALL generate a valid DS without crashing
2. WHEN `DSUtilV2.generateV1(params)` is called with params `{z:1, a:2, m:3}`, THE DSUtilV2 SHALL serialize query as `a=2&m=3&z=1` (lexicographic order)
3. WHEN `DSUtilV2.generateV1(params)` is called with params `{b:1, a:2}`, THE DSUtilV2 SHALL serialize query as `a=2&b=1`
4. WHEN `DSUtilV2.generateV1(params)` is called with params `{role_id:1, role:2}`, THE DSUtilV2 SHALL serialize query as `role=2&role_id=1`
5. WHEN `DSUtilV2.generateV1(undefined)` is called, THE DSUtilV2 SHALL generate a valid DS without crashing
6. WHEN `DSUtilV2.generateV1(new RequestParams())` is called with empty params, THE DSUtilV2 SHALL generate a valid DS without crashing
7. WHEN `DSUtilV2.generateV1(params)` is called with a param value of `0`, THE DSUtilV2 SHALL serialize it as `key=0` without filtering it out
8. WHEN `DSUtilV2.generateV1(params)` is called with a negative param value, THE DSUtilV2 SHALL serialize it as `key=-1`

### Requirement 3: DSUtilV2 POST body 参数处理

**User Story:** As a developer, I want DSUtilV2 to handle POST body parameters correctly, so that POST requests are signed properly.

#### Acceptance Criteria

1. WHEN `DSUtilV2.generateV1(undefined, body)` is called with a JSON body string, THE DSUtilV2 SHALL generate a valid DS without crashing
2. WHEN `DSUtilV2.generateV1(undefined, '')` is called with an empty body, THE DSUtilV2 SHALL generate a valid DS without crashing
3. WHEN `DSUtilV2.generateV1(undefined, body)` is called with a Unicode body `{"name":"旅行者"}`, THE DSUtilV2 SHALL generate a valid DS without crashing

### Requirement 4: DSUtilV2 随机性和极端参数

**User Story:** As a developer, I want DSUtilV2 to produce random values and handle extreme inputs, so that the signature is unpredictable and robust.

#### Acceptance Criteria

1. WHEN `DSUtilV2.generateV1()` is called 100 times, THE DSUtilV2 SHALL produce a random segment containing only characters from `[a-zA-Z0-9]` each time
2. WHEN `DSUtilV2.generateV1(params)` is called with 100 key-value pairs, THE DSUtilV2 SHALL generate a valid DS without crashing

### Requirement 5: MockServiceBase pathToFileName 通用规则

**User Story:** As a developer, I want MockServiceBase.pathToFileName to map URL paths to file names correctly, so that mock responses are loaded from the right files.

#### Acceptance Criteria

1. WHEN `MockServiceBase.pathToFileName('/game_record/app/genshin/api/dailyNote')` is called, THE MockServiceBase SHALL return `'game_record_app_genshin_api_dailyNote.json'`
2. WHEN `MockServiceBase.pathToFileName('/game_record/app/genshin/api/character/list')` is called, THE MockServiceBase SHALL return `'game_record_app_genshin_api_character_list.json'`
3. WHEN `MockServiceBase.pathToFileName('/game_record/app/hkrpg/api/note')` is called, THE MockServiceBase SHALL return `'game_record_app_hkrpg_api_note.json'`
4. WHEN `MockServiceBase.pathToFileName('/event/game_record_zzz/api/zzz/avatar/basic')` is called, THE MockServiceBase SHALL return `'event_game_record_zzz_api_zzz_avatar_basic.json'`
5. WHEN `MockServiceBase.pathToFileName('/user/api/getUserFullInfo')` is called, THE MockServiceBase SHALL return `'user_api_getUserFullInfo.json'`
6. WHEN `MockServiceBase.pathToFileName('/binding/api/getUserGameRolesByCookie')` is called, THE MockServiceBase SHALL return `'binding_api_getUserGameRolesByCookie.json'`
7. WHEN a path contains uppercase letters, THE MockServiceBase SHALL preserve the original case in the file name
8. WHEN a path contains numbers such as `/api/v3/data`, THE MockServiceBase SHALL return `'api_v3_data.json'`
9. WHEN a path contains hyphens such as `/game-record/api`, THE MockServiceBase SHALL preserve hyphens and return `'game-record_api.json'`

### Requirement 6: MockServiceBase pathToFileName 特殊映射

**User Story:** As a developer, I want MockServiceBase.pathToFileName to use a special mapping table for certain paths, so that compute and sign-in endpoints return the correct mock files.

#### Acceptance Criteria

1. WHEN `MockServiceBase.pathToFileName('/event/e20200928calculate/v3/batch_compute')` is called, THE MockServiceBase SHALL return `'genshin_character_batch_compute.json'`
2. WHEN `MockServiceBase.pathToFileName('/event/rpgcalc/compute')` is called, THE MockServiceBase SHALL return `'hkrpg_character_compute.json'`
3. WHEN `MockServiceBase.pathToFileName('/event/nap_cultivate_tool/avatar_calc')` is called, THE MockServiceBase SHALL return `'zzz_character_compute.json'`
4. WHEN `MockServiceBase.pathToFileName('/app/api/signIn')` is called, THE MockServiceBase SHALL return `'apihub_app_api_signIn.json'`
5. WHEN `MockServiceBase.pathToFileName('/game_record/app/genshin/api/character/detail')` is called, THE MockServiceBase SHALL return `'game_record_app_genshin_api_character_detail_all.json'`

### Requirement 7: MockServiceBase pathToFileName query 参数去除

**User Story:** As a developer, I want MockServiceBase.pathToFileName to strip query parameters before mapping, so that the same endpoint always maps to the same file regardless of query string.

#### Acceptance Criteria

1. WHEN a path contains query parameters, THE MockServiceBase SHALL strip all query parameters before mapping to a file name
2. WHEN a path with query parameters matches a special mapping, THE MockServiceBase SHALL apply the special mapping after stripping query parameters
3. WHEN a path contains multiple query parameters such as `?a=1&b=2&c=3`, THE MockServiceBase SHALL strip all of them

### Requirement 8: MockServiceBase extractAccountId

**User Story:** As a developer, I want MockServiceBase.extractAccountId to extract the account_id from a Cookie string, so that mock responses are served for the correct account.

#### Acceptance Criteria

1. WHEN a Cookie string contains `account_id=N`, THE MockServiceBase SHALL return the integer value N
2. WHEN a Cookie string does not contain `account_id`, THE MockServiceBase SHALL return `1` as fallback
3. WHEN an empty Cookie string is provided, THE MockServiceBase SHALL return `1` as fallback
4. WHEN `account_id=0` is in the Cookie, THE MockServiceBase SHALL return `0` (zero is a valid value, not a fallback trigger)
5. WHEN `account_id=1.5` is in the Cookie, THE MockServiceBase SHALL return `1` (parseInt truncates decimal)
6. WHEN `account_id` appears multiple times in the Cookie, THE MockServiceBase SHALL return the first match
7. WHEN `account_id=abc` is in the Cookie, THE MockServiceBase SHALL return `1` as fallback (parseInt of non-numeric is NaN)
8. WHEN the Cookie contains `account_id = 1` with spaces around `=`, THE MockServiceBase SHALL return `1` as fallback (regex does not match spaces)

### Requirement 9: GenshinDailyNoteParser 正常解析

**User Story:** As a developer, I want GenshinDailyNoteParser to correctly parse all fields from a valid JSON response, so that the daily note data is accurately displayed.

#### Acceptance Criteria

1. WHEN a valid JSON with `current_resin: 120` is parsed, THE GenshinDailyNoteParser SHALL return `currentResin = 120`
2. WHEN a valid JSON with `max_resin: 200` is parsed, THE GenshinDailyNoteParser SHALL return `maxResin = 200`
3. WHEN a valid JSON with `resin_recovery_time: '3600'` is parsed, THE GenshinDailyNoteParser SHALL return `resinRecoveryTime = 3600` (string to integer)
4. WHEN a valid JSON with expedition data is parsed, THE GenshinDailyNoteParser SHALL return the correct expedition count and status fields
5. WHEN a valid JSON with transformer data is parsed, THE GenshinDailyNoteParser SHALL return the correct obtained, reached, day, and hour fields
6. WHEN `current_resin` is `0`, THE GenshinDailyNoteParser SHALL return `currentResin = 0`
7. WHEN `current_resin` is `999` (above limit), THE GenshinDailyNoteParser SHALL return `currentResin = 999` without validation
8. WHEN `resin_recovery_time` is `"0"`, THE GenshinDailyNoteParser SHALL return `resinRecoveryTime = 0`
9. WHEN `expeditions` is an empty array, THE GenshinDailyNoteParser SHALL return `expeditions.length = 0`

### Requirement 10: GenshinDailyNoteParser 容错处理

**User Story:** As a developer, I want GenshinDailyNoteParser to handle invalid or incomplete JSON gracefully, so that the app does not crash on malformed API responses.

#### Acceptance Criteria

1. WHEN an invalid JSON string is parsed, THE GenshinDailyNoteParser SHALL return default GenshinDailyNoteData with `currentResin = 0`
2. WHEN an empty string is parsed, THE GenshinDailyNoteParser SHALL return default data without throwing
3. WHEN an empty object `'{}'` is parsed, THE GenshinDailyNoteParser SHALL return default data without throwing
4. WHEN `resin_recovery_time` is a non-numeric string, THE GenshinDailyNoteParser SHALL return `resinRecoveryTime = 0`
5. WHEN `transformer` is `null`, THE GenshinDailyNoteParser SHALL return default GenshinTransformerData without crashing
6. WHEN the JSON is an array `[1,2,3]`, THE GenshinDailyNoteParser SHALL return default data without crashing
7. WHEN the JSON is the string `'null'`, THE GenshinDailyNoteParser SHALL return default data without crashing

### Requirement 11: StarRailDailyNoteParser 正常解析与容错

**User Story:** As a developer, I want StarRailDailyNoteParser to correctly parse all fields and handle invalid input, so that Star Rail daily note data is accurate and robust.

#### Acceptance Criteria

1. WHEN a valid JSON is parsed, THE StarRailDailyNoteParser SHALL return correct values for all fields including currentStamina, maxStamina, staminaRecoverTime, currentReserveStamina, isReserveStaminaFull, currentTrainScore, maxTrainScore, weeklyCocoonCnt, weeklyCocoonLimit, rogueTournWeeklyCur, rogueTournWeeklyMax, gridFightWeeklyCur, gridFightWeeklyMax
2. WHEN an invalid JSON string is parsed, THE StarRailDailyNoteParser SHALL return default data with `currentStamina = 0` and `maxStamina = 240`
3. WHEN an empty string is parsed, THE StarRailDailyNoteParser SHALL return default data without throwing
4. WHEN `current_stamina` is `0`, THE StarRailDailyNoteParser SHALL return `currentStamina = 0`
5. WHEN `grid_fight_weekly_cur` field is missing, THE StarRailDailyNoteParser SHALL return `gridFightWeeklyCur = 0` (via `?? 0` fallback)
6. WHEN `max_stamina` is `0`, THE StarRailDailyNoteParser SHALL return `maxStamina = 0` without crashing

### Requirement 12: ZZZDailyNoteParser 正常解析与容错

**User Story:** As a developer, I want ZZZDailyNoteParser to correctly parse all fields and handle edge cases, so that ZZZ daily note data is accurate and robust.

#### Acceptance Criteria

1. WHEN a valid JSON is parsed, THE ZZZDailyNoteParser SHALL return correct values for currentEnergy, maxEnergy, energyRecoverTime, currentVitality, maxVitality, cardSign, videoStoreState, abyssRefresh, memberCardIsOpen
2. WHEN an invalid JSON string is parsed, THE ZZZDailyNoteParser SHALL return default data with `currentEnergy = 0` and `maxEnergy = 240`
3. WHEN an empty string is parsed, THE ZZZDailyNoteParser SHALL return default data without throwing
4. WHEN `energy.progress.current` is `0`, THE ZZZDailyNoteParser SHALL return `currentEnergy = 0`
5. WHEN `energy.restore` is `0` (full energy), THE ZZZDailyNoteParser SHALL return `energyRecoverTime = 0`
6. WHEN `vhs_sale` field is missing, THE ZZZDailyNoteParser SHALL return `videoStoreState = ''`
7. WHEN `member_card` field is missing, THE ZZZDailyNoteParser SHALL return `memberCardIsOpen = false`
8. WHEN `card_sign` is `'CardSignDone'`, THE ZZZDailyNoteParser SHALL return `cardSign = 'CardSignDone'`
9. WHEN `card_sign` is `'CardSignNo'`, THE ZZZDailyNoteParser SHALL return `cardSign = 'CardSignNo'`
10. WHEN `vhs_sale.sale_state` is `'SaleStateDone'`, THE ZZZDailyNoteParser SHALL return `videoStoreState = 'SaleStateDone'`
11. WHEN `vhs_sale.sale_state` is `'SaleStateDoing'`, THE ZZZDailyNoteParser SHALL return `videoStoreState = 'SaleStateDoing'`
12. WHEN `vhs_sale.sale_state` is `'SaleStateNo'`, THE ZZZDailyNoteParser SHALL return `videoStoreState = 'SaleStateNo'`
13. WHEN the JSON is an array, THE ZZZDailyNoteParser SHALL return default data without crashing

### Requirement 13: SyncDataType 枚举值一致性

**User Story:** As a developer, I want SyncDataType enum values to match the actual database table names, so that sync_meta queries work correctly after any refactoring.

#### Acceptance Criteria

1. THE SyncDataType SHALL define 15 enum values that exactly match their corresponding database table name strings
2. WHEN `SyncDataType.ACCOUNT` is accessed, THE SyncDataType SHALL equal `'account_table'`
3. WHEN `SyncDataType.GAME_ROLE` is accessed, THE SyncDataType SHALL equal `'game_role_table'`
4. WHEN any of the 13 game-specific SyncDataType values are accessed, THE SyncDataType SHALL equal the corresponding table name string (e.g. `GENSHIN_DAILY_NOTE` = `'genshin_daily_note'`)

### Requirement 14: v2 Row 模型默认值

**User Story:** As a developer, I want all v2 Row model classes to have correct default field values, so that database writes do not fail due to uninitialized fields.

#### Acceptance Criteria

1. WHEN `new AccountRowV2()` is instantiated, THE AccountRowV2 SHALL have `id=0`, `username=''`, `cookie=''`, `stoken=''`, `isActive=0`, `uid=''`, `nickname=''`, `avatarUrl=''`
2. WHEN `new GameRoleRowV2()` is instantiated, THE GameRoleRowV2 SHALL have `id=0`, `accountId=0`, `gameId=''`, `roleId=''`, `level=0`, `isChosen=0`, `isPublic=0`
3. WHEN any Genshin Row model is instantiated, THE Row_Model SHALL have all numeric fields defaulting to `0` and all string fields defaulting to `''`
4. WHEN any StarRail Row model is instantiated, THE Row_Model SHALL have all numeric fields defaulting to `0` and all string fields defaulting to `''`
5. WHEN any ZZZ Row model is instantiated, THE Row_Model SHALL have all numeric fields defaulting to `0` and all string fields defaulting to `''`, except `ZZZAvatarBasicRow.rarity` which defaults to `''` (TEXT type)
6. WHEN `new SyncMetaRow()` is instantiated, THE SyncMetaRow SHALL have `id=0`, `accountId=0`, `roleUid=''`, `dataType=''`, `lastSyncTime=0`, `syncStatus=''`, `errorMsg=''`

### Requirement 15: 测试文件注册

**User Story:** As a developer, I want all test suites to be registered in List.test.ets, so that they are all executed when the test runner is invoked.

#### Acceptance Criteria

1. THE List.test.ets SHALL import and call all test suite functions: dsUtilV2Test, mockServiceBaseTest, genshinDailyNoteParserTest, starRailDailyNoteParserTest, zzzDailyNoteParserTest, syncDataTypeTest, rowModelsTest
2. FOR ALL test suite functions registered in List.test.ets, THE test runner SHALL execute them without import errors

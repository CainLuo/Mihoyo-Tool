# Implementation Plan

## Tasks

- [-] 1. 补充 DSUtilV2.test.ets 测试用例
  - [x] 1.1 添加字典序排列验证：params `{z:1, a:2, m:3}` → query `a=2&m=3&z=1`
  - [x] 1.2 添加字典序排列验证：params `{b:1, a:2}` → query `a=2&b=1`
  - [x] 1.3 添加字典序排列验证：params `{role_id:1, role:2}` → query `role=2&role_id=1`
  - [x] 1.4 添加 random 字符集验证：调用 100 次，每次 random 只含 `[a-zA-Z0-9]`
  - [x] 1.5 添加极端参数测试：100 个键值对，DS 正常生成不崩溃
  - [x] 1.6 添加边界值测试：params 值为数字 0，序列化为 `key=0` 不被过滤
  - [x] 1.7 添加边界值测试：params 值为负数，序列化为 `key=-1`
  - [x] 1.8 添加 Unicode body 测试：`{"name":"旅行者"}`，DS 正常生成

- [-] 2. 补充 MockServiceBase.test.ets 测试用例
  - [ ] 2.1 添加 pathToFileName 边界：路径含大写字母，保留原始大小写
  - [ ] 2.2 添加 pathToFileName 边界：路径含数字 `/api/v3/data`，正确映射
  - [ ] 2.3 添加 pathToFileName 边界：路径含连字符 `/game-record/api`，连字符保留
  - [ ] 2.4 添加 pathToFileName 边界：路径含多个 query 参数 `/api?a=1&b=2&c=3`，去掉所有 query
  - [ ] 2.5 添加 pathToFileName 边界：特殊映射路径含 query，特殊映射优先
  - [ ] 2.6 添加 extractAccountId 边界：account_id=0，返回 0（0 是有效值）
  - [ ] 2.7 添加 extractAccountId 边界：account_id 为浮点数 `1.5`，parseInt 截断返回 1
  - [ ] 2.8 添加 extractAccountId 边界：account_id 出现多次，取第一个匹配
  - [ ] 2.9 添加 extractAccountId 边界：account_id 值含字母 `abc`，parseInt 为 NaN，fallback 返回 1
  - [ ] 2.10 添加 extractAccountId 边界：Cookie 含空格 `account_id = 1`，正则不匹配，fallback 返回 1

- [ ] 3. 补充 GenshinDailyNoteParser.test.ets 测试用例
  - [ ] 3.1 添加边界值：current_resin 为 0，返回 0
  - [ ] 3.2 添加边界值：current_resin 超过上限 999，Parser 不校验，返回 999
  - [ ] 3.3 添加边界值：resin_recovery_time 为 "0"，返回 0
  - [ ] 3.4 添加边界值：expeditions 为空数组，返回 `expeditions.length=0`
  - [ ] 3.5 添加容错：transformer 为 null，不崩溃，返回默认 GenshinTransformerData
  - [ ] 3.6 添加容错：JSON 为数组 `[1,2,3]`，返回默认值不崩溃
  - [ ] 3.7 添加容错：JSON 为 null 字符串 `'null'`，返回默认值不崩溃

- [ ] 4. 补充 StarRailDailyNoteParser.test.ets 测试用例
  - [ ] 4.1 添加边界值：current_stamina 为 0，返回 0
  - [ ] 4.2 添加容错：grid_fight_weekly_cur 字段缺失，返回 0（`?? 0` 兜底）
  - [ ] 4.3 添加边界值：max_stamina 为 0，返回 0 不崩溃

- [ ] 5. 补充 ZZZDailyNoteParser.test.ets 测试用例
  - [ ] 5.1 添加边界值：energy.progress.current 为 0，返回 0
  - [ ] 5.2 添加边界值：energy.restore 为 0（已满），energyRecoverTime=0
  - [ ] 5.3 添加容错：vhs_sale 字段缺失，videoStoreState=''
  - [ ] 5.4 添加容错：member_card 字段缺失，memberCardIsOpen=false
  - [ ] 5.5 添加边界值：card_sign 为 'CardSignDone'，返回 'CardSignDone'
  - [ ] 5.6 添加边界值：card_sign 为 'CardSignNo'，返回 'CardSignNo'
  - [ ] 5.7 添加边界值：vhs_sale.sale_state 为 'SaleStateDone'，返回 'SaleStateDone'
  - [ ] 5.8 添加边界值：vhs_sale.sale_state 为 'SaleStateDoing'，返回 'SaleStateDoing'
  - [ ] 5.9 添加边界值：vhs_sale.sale_state 为 'SaleStateNo'，返回 'SaleStateNo'
  - [ ] 5.10 添加容错：JSON 为数组，返回默认值不崩溃

- [ ] 6. 验证 SyncDataType.test.ets 覆盖完整（已有，无需修改）
  - [ ] 6.1 确认 15 个枚举值全部有对应测试用例

- [ ] 7. 验证 RowModels.test.ets 覆盖完整（已有，无需修改）
  - [ ] 7.1 确认 AccountRowV2、GameRoleRowV2 默认值测试存在
  - [ ] 7.2 确认所有 Genshin/StarRail/ZZZ Row 默认值测试存在
  - [ ] 7.3 确认 SyncMetaRow 默认值测试存在

- [ ] 8. 验证 List.test.ets 注册完整（已有，无需修改）
  - [ ] 8.1 确认所有 7 个测试套件均已在 List.test.ets 中注册

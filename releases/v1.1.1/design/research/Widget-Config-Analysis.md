# Widget 配置数据结构对比分析

## 一、官方数据大小限制

根据 `@ohos.app.form.formBindingData` API 文档：

| API Version | 数据总大小 | 图片数量 | 图片单张限制 |
|-------------|-----------|---------|-------------|
| API 19 及之前 | 未明确 | 5 张 | 2MB |
| API 20+ | **10MB** | 20 张 | 未明确 |

**结论**：Widget 传递的数据总大小限制为 **10MB**，足够容纳多账号多角色的便笺数据。

---

## 二、真实数据示例

### 2.1 账号数据（来自 API）

**账号 A（米游社 UID: 182692936，昵称: CainLuo）**：

| 游戏 | game_biz | region | game_uid（roleId） | nickname | level | region_name |
|------|----------|--------|-------------------|----------|-------|-------------|
| 原神 | hk4e_cn | cn_gf01 | 109050292 | 凹凸曼的小怪兽 | 60 | 天空岛 |
| 星铁 | hkrpg_cn | prod_gf_cn | 102731382 | 凹凸曼的小怪兽 | 70 | 星穹列车 |
| 绝区零 | nap_cn | prod_gf_cn | 37716744 | 凹凸曼的小怪兽 | 51 | 新艾利都 |

**账号 B（米游社 UID: 348366494，昵称: 摆烂的班主任）**：

| 游戏 | game_biz | region | game_uid（roleId） | nickname | level | region_name |
|------|----------|--------|-------------------|----------|-------|-------------|
| 原神 | hk4e_cn | cn_gf01 | 250375401 | 狂野的沙滩裤 | 57 | 天空岛 |
| 星铁 | hkrpg_cn | prod_gf_cn | 111310091 | &符公子 | 67 | 星穹列车 |

### 2.2 DailyNote API 原始响应（rawJson）

**原神（账号A，roleId: 109050292）**：

```json
{
  "retcode": 0,
  "message": "OK",
  "data": {
    "current_resin": 152,
    "max_resin": 200,
    "resin_recovery_time": "22825",
    "finished_task_num": 0,
    "total_task_num": 4,
    "is_extra_task_reward_received": false,
    "remain_resin_discount_num": 3,
    "resin_discount_num_limit": 3,
    "current_expedition_num": 5,
    "max_expedition_num": 5,
    "expeditions": [
      { "avatar_side_icon": "...", "status": "Finished", "remained_time": "0" },
      { "avatar_side_icon": "...", "status": "Finished", "remained_time": "0" },
      { "avatar_side_icon": "...", "status": "Finished", "remained_time": "0" },
      { "avatar_side_icon": "...", "status": "Finished", "remained_time": "0" },
      { "avatar_side_icon": "...", "status": "Finished", "remained_time": "0" }
    ],
    "current_home_coin": 1230,
    "max_home_coin": 2400,
    "home_coin_recovery_time": "139968",
    "transformer": {
      "obtained": true,
      "recovery_time": { "Day": 6, "Hour": 0, "Minute": 0, "Second": 0, "reached": false }
    },
    "daily_task": {
      "total_num": 4,
      "finished_num": 0,
      "is_extra_task_reward_received": false
    }
  }
}
```

**原神（账号B，roleId: 250375401）**：

```json
{
  "retcode": 0,
  "message": "OK",
  "data": {
    "current_resin": 88,
    "max_resin": 200,
    "resin_recovery_time": "53401",
    "finished_task_num": 4,
    "total_task_num": 4,
    "is_extra_task_reward_received": true,
    "remain_resin_discount_num": 3,
    "resin_discount_num_limit": 3,
    "current_expedition_num": 5,
    "max_expedition_num": 5,
    "expeditions": [
      { "avatar_side_icon": "...", "status": "Ongoing", "remained_time": "9786" },
      { "avatar_side_icon": "...", "status": "Ongoing", "remained_time": "20586" },
      { "avatar_side_icon": "...", "status": "Ongoing", "remained_time": "20586" },
      { "avatar_side_icon": "...", "status": "Ongoing", "remained_time": "20586" },
      { "avatar_side_icon": "...", "status": "Ongoing", "remained_time": "20586" }
    ],
    "current_home_coin": 270,
    "max_home_coin": 2400,
    "home_coin_recovery_time": "253340",
    "transformer": {
      "obtained": true,
      "recovery_time": { "Day": 4, "Hour": 0, "Minute": 0, "Second": 0, "reached": false }
    },
    "daily_task": {
      "total_num": 4,
      "finished_num": 4,
      "is_extra_task_reward_received": true
    }
  }
}
```

**星铁（账号A，roleId: 102731382）**：

```json
{
  "retcode": 0,
  "message": "OK",
  "data": {
    "current_stamina": 300,
    "max_stamina": 300,
    "stamina_recover_time": 0,
    "current_train_score": 0,
    "max_train_score": 500,
    "current_rogue_score": 0,
    "max_rogue_score": 14000,
    "weekly_cocoon_cnt": 3,
    "weekly_cocoon_limit": 3,
    "current_reserve_stamina": 2400,
    "is_reserve_stamina_full": true,
    "rogue_tourn_weekly_max": 1000,
    "rogue_tourn_weekly_cur": 0,
    "grid_fight_weekly_cur": 0,
    "grid_fight_weekly_max": 0
  }
}
```

**绝区零（账号A，roleId: 37716744）**：

```json
{
  "retcode": 0,
  "message": "OK",
  "data": {
    "energy": {
      "progress": { "max": 240, "current": 240 },
      "restore": 0
    },
    "vitality": { "max": 400, "current": 0 },
    "vhs_sale": { "sale_state": "SaleStateDone" },
    "card_sign": "CardSignNo",
    "member_card": { "is_open": false }
  }
}
```

---

## 三、当前数据结构存在的问题

### 3.1 当前结构

```
WidgetDataStore
  └── accounts: WidgetAccount[]
        └── games: WidgetGame[]
              └── roles: WidgetRole[]
                    └── rawJson: string (API 原始响应)
```

### 3.2 问题场景

**用户场景**：
- 账号 A（182692936）：有原神（国服）、星铁（国服）、绝区零（国服）
- 账号 B（348366494）：有原神（国服）、星铁（国服）

**用户需求**：在 2x2 卡片显示「账号A的国服原神 + 账号B的国服原神」

**当前结构无法支持的原因**：

1. 当前结构按 `accountId → gameId → roles` 嵌套，Widget 渲染时遍历 `games[]` 数组
2. 如果用户选择「账号A的原神」和「账号B的原神」，payload 会是：

```json
{
  "accounts": [{
    "accountId": "182692936",
    "accountName": "CainLuo",
    "games": [{ "gameId": "genshin", "roles": [...] }]
  }, {
    "accountId": "348366494",
    "accountName": "摆烂的班主任",
    "games": [{ "gameId": "genshin", "roles": [...] }]
  }]
}
```

3. Widget 渲染逻辑需要：
   - 判断有几个账号
   - 判断每个账号有几个游戏
   - 判断是否是同一个游戏（合并显示还是分开显示？）
   - 2x2/2x4/4x4 的渲染逻辑完全不同，无法统一

4. 更复杂的情况：账号B的原神有外服和渠道服两个角色，用户只选了外服那个，如何表达？

---

## 四、新的数据结构设计

### 4.1 设计原则

1. **保留完整数据**：`WidgetDataStore` 保持不变，存储所有账号所有角色的完整数据（rawJson）
2. **用户选择的是角色**：不是「游戏」，是具体的「角色（roleId）」
3. **Payload 扁平化**：传递给 Widget 的 payload 是扁平的 slot 列表，不是嵌套结构
4. **一个 slot = 一个角色**：每个 slot 包含完整的渲染所需数据

### 4.2 新的 Payload 结构

```json
{
  "version": 1,
  "updatedAt": 1779012632,
  "slots": [
    {
      "slotIndex": 0,
      "accountId": "182692936",
      "accountName": "CainLuo",
      "gameId": "genshin",
      "roleId": "109050292",
      "nickname": "凹凸曼的小怪兽",
      "server": "cn_gf01",
      "serverName": "天空岛",
      "level": 60,
      "rawJson": "{\"retcode\":0,\"message\":\"OK\",\"data\":{\"current_resin\":152,\"max_resin\":200,...}}"
    },
    {
      "slotIndex": 1,
      "accountId": "348366494",
      "accountName": "摆烂的班主任",
      "gameId": "genshin",
      "roleId": "250375401",
      "nickname": "狂野的沙滩裤",
      "server": "cn_gf01",
      "serverName": "天空岛",
      "level": 57,
      "rawJson": "{\"retcode\":0,\"message\":\"OK\",\"data\":{\"current_resin\":88,\"max_resin\":200,...}}"
    }
  ]
}
```

### 4.3 关键变化

| 对比项 | 当前结构 | 新结构 |
|--------|---------|--------|
| 嵌套层级 | 3 层（account → game → role） | 1 层（扁平 slots） |
| 用户选择对象 | 游戏（gameId） | 角色（roleId） |
| 同游戏不同服 | 无法区分 | 通过 roleId 精确定位 |
| 跨账号同游戏 | 难以处理 | 每个角色独立 slot |
| Widget 渲染 | 需要遍历嵌套结构 | 直接遍历 slots[] |

---

## 五、WidgetConfig 结构

用户在 WidgetSetting 页面的选择，存储的是 `WidgetSlotRef`（角色引用）：

```json
{
  "formId": "",
  "formName": "widget_2x2",
  "size": "2x2",
  "slots": [
    {
      "accountId": "182692936",
      "accountName": "CainLuo",
      "gameId": "genshin",
      "roleId": "109050292",
      "nickname": "凹凸曼的小怪兽",
      "server": "cn_gf01",
      "serverName": "天空岛",
      "level": 60
    },
    {
      "accountId": "348366494",
      "accountName": "摆烂的班主任",
      "gameId": "genshin",
      "roleId": "250375401",
      "nickname": "狂野的沙滩裤",
      "server": "cn_gf01",
      "serverName": "天空岛",
      "level": 57
    }
  ]
}
```

---

## 六、数据流

```
┌─────────────────────────────────────────────────────────────────┐
│                          主应用进程                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. 数据同步                                                     │
│     Repository.syncDailyNote()                                  │
│           ↓                                                     │
│     DB 写入 rawJson                                             │
│           ↓                                                     │
│  2. 构建 WidgetDataStore（完整数据）                              │
│     WidgetDataStoreBuilder.build()                              │
│           ↓                                                     │
│     Preferences.save(widget_data_store, global_data)            │
│           ↓                                                     │
│  3. 用户在 WidgetSetting 选择角色                                 │
│     WidgetConfigViewModel.complete()                            │
│           ↓                                                     │
│     Preferences.save(widget_configs, widget_2x2)                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                    (Preferences 文件共享)
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                       FormExtension 进程                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  4. onAddForm() / onUpdateForm()                                │
│     loadSync(widget_data_store) → WidgetDataStore（完整数据）     │
│     loadSync(widget_configs) → 用户选择的 slots                  │
│           ↓                                                     │
│  5. buildPayload()                                              │
│     for each slot in userSlots:                                 │
│       role = WidgetDataStore.getRole(accountId, gameId, roleId) │
│       payloadSlot = { ...slot, rawJson: role.rawJson }          │
│           ↓                                                     │
│  6. 返回 FormBindingData                                         │
│     { slots: [payloadSlot0, payloadSlot1, ...] }                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                      (LocalStorage 传递)
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         Widget 组件                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  7. 渲染                                                        │
│     ForEach(slots, slot => WidgetSlotCard({ slot }))            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```


---

## 七、场景验证

### 场景一：用户首次登录，直接添加卡片（无配置）

**WidgetConfig**：不存在

**Payload 构建**：fallback 逻辑，取第一个账号的前 N 个角色

```json
{
  "version": 1,
  "updatedAt": 1779012632,
  "slots": [
    {
      "slotIndex": 0,
      "accountId": "182692936",
      "accountName": "CainLuo",
      "gameId": "genshin",
      "roleId": "109050292",
      "nickname": "凹凸曼的小怪兽",
      "server": "cn_gf01",
      "serverName": "天空岛",
      "level": 60,
      "rawJson": "{\"retcode\":0,\"message\":\"OK\",\"data\":{\"current_resin\":152,\"max_resin\":200,\"resin_recovery_time\":\"22825\",\"finished_task_num\":0,\"total_task_num\":4,\"is_extra_task_reward_received\":false,\"current_home_coin\":1230,\"max_home_coin\":2400,\"transformer\":{\"obtained\":true,\"recovery_time\":{\"Day\":6,\"Hour\":0}}}}"
    },
    {
      "slotIndex": 1,
      "accountId": "182692936",
      "accountName": "CainLuo",
      "gameId": "starrail",
      "roleId": "102731382",
      "nickname": "凹凸曼的小怪兽",
      "server": "prod_gf_cn",
      "serverName": "星穹列车",
      "level": 70,
      "rawJson": "{\"retcode\":0,\"message\":\"OK\",\"data\":{\"current_stamina\":300,\"max_stamina\":300,\"stamina_recover_time\":0,\"current_train_score\":0,\"max_train_score\":500,\"weekly_cocoon_cnt\":3,\"weekly_cocoon_limit\":3,\"current_reserve_stamina\":2400,\"is_reserve_stamina_full\":true}}"
    }
  ]
}
```

**Widget 显示**：原神（账号A）+ 星铁（账号A）

---

### 场景二：用户选择「账号A的国服原神 + 账号B的国服原神」

**WidgetConfig**：

```json
{
  "formId": "",
  "formName": "widget_2x2",
  "size": "2x2",
  "slots": [
    {
      "accountId": "182692936",
      "accountName": "CainLuo",
      "gameId": "genshin",
      "roleId": "109050292",
      "nickname": "凹凸曼的小怪兽",
      "server": "cn_gf01",
      "serverName": "天空岛",
      "level": 60
    },
    {
      "accountId": "348366494",
      "accountName": "摆烂的班主任",
      "gameId": "genshin",
      "roleId": "250375401",
      "nickname": "狂野的沙滩裤",
      "server": "cn_gf01",
      "serverName": "天空岛",
      "level": 57
    }
  ]
}
```

**Payload 构建**（从 WidgetDataStore 查询 rawJson）：

```json
{
  "version": 1,
  "updatedAt": 1779012632,
  "slots": [
    {
      "slotIndex": 0,
      "accountId": "182692936",
      "accountName": "CainLuo",
      "gameId": "genshin",
      "roleId": "109050292",
      "nickname": "凹凸曼的小怪兽",
      "server": "cn_gf01",
      "serverName": "天空岛",
      "level": 60,
      "rawJson": "{\"retcode\":0,\"message\":\"OK\",\"data\":{\"current_resin\":152,\"max_resin\":200,\"resin_recovery_time\":\"22825\",\"finished_task_num\":0,\"total_task_num\":4,\"is_extra_task_reward_received\":false,\"current_home_coin\":1230,\"max_home_coin\":2400,\"transformer\":{\"obtained\":true,\"recovery_time\":{\"Day\":6,\"Hour\":0}}}}"
    },
    {
      "slotIndex": 1,
      "accountId": "348366494",
      "accountName": "摆烂的班主任",
      "gameId": "genshin",
      "roleId": "250375401",
      "nickname": "狂野的沙滩裤",
      "server": "cn_gf01",
      "serverName": "天空岛",
      "level": 57,
      "rawJson": "{\"retcode\":0,\"message\":\"OK\",\"data\":{\"current_resin\":88,\"max_resin\":200,\"resin_recovery_time\":\"53401\",\"finished_task_num\":4,\"total_task_num\":4,\"is_extra_task_reward_received\":true,\"current_home_coin\":270,\"max_home_coin\":2400,\"transformer\":{\"obtained\":true,\"recovery_time\":{\"Day\":4,\"Hour\":0}}}}"
    }
  ]
}
```

**Widget 显示**：
- 2x2 卡片显示两个原神角色的体力条
- 两个都是原神，但来自不同账号
- 渲染逻辑只需遍历 `slots[]`，无需关心嵌套关系

---

### 场景三：用户选择「账号A的原神 + 账号A的绝区零」

**WidgetConfig**：

```json
{
  "formId": "",
  "formName": "widget_2x2",
  "size": "2x2",
  "slots": [
    {
      "accountId": "182692936",
      "accountName": "CainLuo",
      "gameId": "genshin",
      "roleId": "109050292",
      "nickname": "凹凸曼的小怪兽",
      "server": "cn_gf01",
      "serverName": "天空岛",
      "level": 60
    },
    {
      "accountId": "182692936",
      "accountName": "CainLuo",
      "gameId": "zzz",
      "roleId": "37716744",
      "nickname": "凹凸曼的小怪兽",
      "server": "prod_gf_cn",
      "serverName": "新艾利都",
      "level": 51
    }
  ]
}
```

**Payload 构建**：

```json
{
  "version": 1,
  "updatedAt": 1779012632,
  "slots": [
    {
      "slotIndex": 0,
      "accountId": "182692936",
      "accountName": "CainLuo",
      "gameId": "genshin",
      "roleId": "109050292",
      "nickname": "凹凸曼的小怪兽",
      "server": "cn_gf01",
      "serverName": "天空岛",
      "level": 60,
      "rawJson": "{\"retcode\":0,\"message\":\"OK\",\"data\":{\"current_resin\":152,\"max_resin\":200,\"resin_recovery_time\":\"22825\"}}"
    },
    {
      "slotIndex": 1,
      "accountId": "182692936",
      "accountName": "CainLuo",
      "gameId": "zzz",
      "roleId": "37716744",
      "nickname": "凹凸曼的小怪兽",
      "server": "prod_gf_cn",
      "serverName": "新艾利都",
      "level": 51,
      "rawJson": "{\"retcode\":0,\"message\":\"OK\",\"data\":{\"energy\":{\"progress\":{\"max\":240,\"current\":240},\"restore\":0},\"vitality\":{\"max\":400,\"current\":0},\"vhs_sale\":{\"sale_state\":\"SaleStateDone\"},\"card_sign\":\"CardSignNo\"}}"
    }
  ]
}
```

**Widget 显示**：原神（账号A）+ 绝区零（账号A），同一账号不同游戏

---

### 场景四：4x4 卡片显示 4 个角色

**WidgetConfig**：

```json
{
  "formId": "",
  "formName": "widget_4x4",
  "size": "4x4",
  "slots": [
    {
      "accountId": "182692936",
      "accountName": "CainLuo",
      "gameId": "genshin",
      "roleId": "109050292",
      "nickname": "凹凸曼的小怪兽",
      "server": "cn_gf01",
      "serverName": "天空岛",
      "level": 60
    },
    {
      "accountId": "182692936",
      "accountName": "CainLuo",
      "gameId": "starrail",
      "roleId": "102731382",
      "nickname": "凹凸曼的小怪兽",
      "server": "prod_gf_cn",
      "serverName": "星穹列车",
      "level": 70
    },
    {
      "accountId": "182692936",
      "accountName": "CainLuo",
      "gameId": "zzz",
      "roleId": "37716744",
      "nickname": "凹凸曼的小怪兽",
      "server": "prod_gf_cn",
      "serverName": "新艾利都",
      "level": 51
    },
    {
      "accountId": "348366494",
      "accountName": "摆烂的班主任",
      "gameId": "genshin",
      "roleId": "250375401",
      "nickname": "狂野的沙滩裤",
      "server": "cn_gf01",
      "serverName": "天空岛",
      "level": 57
    }
  ]
}
```

**Widget 显示**：原神（账号A）+ 星铁（账号A）+ 绝区零（账号A）+ 原神（账号B）

---

## 八、实现要点

### 8.1 需要修改的文件

1. **WidgetPayloadBuilder.ets**：构建扁平 slots payload
2. **WidgetCardContent.ets**：接收 `slots[]` 数组，遍历渲染
3. **WidgetConfigViewModel.ets**：用户选择的是角色，不是游戏
4. **EntryFormAbility.ets**：buildPayload 逻辑调整

### 8.2 兼容性考虑

- WidgetDataStore（全局数据）保持不变，只是查询方式从嵌套遍历改为三元组直接查询
- 旧卡片配置（如果存在）需要迁移或忽略


## 九、最终设计

### 9.1 数据结构

```json
{
  "version": 1,
  "updatedAt": 1779012632,
  "data": {
    "182692936": {
      "accountName": "CainLuo",
      "slots": {
        "109050292": {
          "gameId": "genshin",
          "nickname": "凹凸曼的小怪兽",
          "server": "cn_gf01",
          "serverName": "天空岛",
          "level": 60,
          "rawJson": "{\"retcode\":0,\"message\":\"OK\",\"data\":{\"current_resin\":152,\"max_resin\":200,\"resin_recovery_time\":\"22825\",\"finished_task_num\":0,\"total_task_num\":4,\"is_extra_task_reward_received\":false,\"current_home_coin\":1230,\"max_home_coin\":2400,\"transformer\":{\"obtained\":true,\"recovery_time\":{\"Day\":6,\"Hour\":0}}}}"
        },
        "102731382": {
          "gameId": "starrail",
          "nickname": "凹凸曼的小怪兽",
          "server": "prod_gf_cn",
          "serverName": "星穹列车",
          "level": 70,
          "rawJson": "{\"retcode\":0,\"message\":\"OK\",\"data\":{\"current_stamina\":300,\"max_stamina\":300,\"stamina_recover_time\":0,\"current_train_score\":0,\"max_train_score\":500,\"weekly_cocoon_cnt\":3,\"weekly_cocoon_limit\":3,\"current_reserve_stamina\":2400,\"is_reserve_stamina_full\":true}}"
        },
        "37716744": {
          "gameId": "zzz",
          "nickname": "凹凸曼的小怪兽",
          "server": "prod_gf_cn",
          "serverName": "新艾利都",
          "level": 51,
          "rawJson": "{\"retcode\":0,\"message\":\"OK\",\"data\":{\"energy\":{\"progress\":{\"max\":240,\"current\":240},\"restore\":0},\"vitality\":{\"max\":400,\"current\":0},\"vhs_sale\":{\"sale_state\":\"SaleStateDone\"},\"card_sign\":\"CardSignNo\"}}"
        }
      }
    },
    "348366494": {
      "accountName": "摆烂的班主任",
      "slots": {
        "250375401": {
          "gameId": "genshin",
          "nickname": "狂野的沙滩裤",
          "server": "cn_gf01",
          "serverName": "天空岛",
          "level": 57,
          "rawJson": "{\"retcode\":0,\"message\":\"OK\",\"data\":{\"current_resin\":88,\"max_resin\":200,\"resin_recovery_time\":\"53401\",\"finished_task_num\":4,\"total_task_num\":4,\"is_extra_task_reward_received\":true,\"current_home_coin\":270,\"max_home_coin\":2400,\"transformer\":{\"obtained\":true,\"recovery_time\":{\"Day\":4,\"Hour\":0}}}}"
        },
        "111310091": {
          "gameId": "starrail",
          "nickname": "&符公子",
          "server": "prod_gf_cn",
          "serverName": "星穹列车",
          "level": 67,
          "rawJson": "{\"retcode\":0,\"message\":\"OK\",\"data\":{\"current_stamina\":200,\"max_stamina\":300}}"
        }
      }
    }
  },
  "widgets": {
    "widget12": ["182692936/109050292"],
    "widget22": ["182692936/109050292", "348366494/250375401"],
    "widget24": ["182692936/102731382", "182692936/37716744"],
    "widget44": ["182692936/109050292", "182692936/102731382", "182692936/37716744", "348366494/250375401"]
  }
}
```

### 9.2 结构说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `version` | number | 数据版本号 |
| `updatedAt` | number | 数据更新时间戳（秒） |
| `data` | object | 所有账号数据，key 为 accountId |
| `data.{accountId}.accountName` | string | 账号昵称 |
| `data.{accountId}.slots` | object | 该账号下所有角色，key 为 roleId |
| `data.{accountId}.slots.{roleId}.gameId` | string | 游戏 ID（genshin/starrail/zzz） |
| `data.{accountId}.slots.{roleId}.nickname` | string | 游戏内昵称 |
| `data.{accountId}.slots.{roleId}.server` | string | 服务器标识（cn_gf01/prod_gf_cn） |
| `data.{accountId}.slots.{roleId}.serverName` | string | 服务器名称（天空岛/星穹列车） |
| `data.{accountId}.slots.{roleId}.level` | number | 冒险等级 |
| `data.{accountId}.slots.{roleId}.rawJson` | string | DailyNote API 原始响应 JSON |
| `widgets` | object | 各尺寸卡片的配置 |
| `widgets.{widgetName}` | string[] | 卡片要显示的角色索引，格式为 `accountId/roleId` |

### 9.3 Widget 渲染查询逻辑

以 `widget22` 为例：

```
widget22 = ["182692936/109050292", "348366494/250375401"]
                ↓
遍历每个 "accountId/roleId"
                ↓
slot0 = data["182692936"].slots["109050292"] → 原神角色数据（树脂 152/200）
slot1 = data["348366494"].slots["250375401"] → 原神角色数据（树脂 88/200）
                ↓
渲染 2x2 卡片，显示两个原神角色的体力条
```

### 9.4 场景验证

| 场景 | widgets 配置 | 显示内容 |
|------|-------------|---------|
| 1x2 显示账号A的原神 | `widget12: ["182692936/109050292"]` | 单个原神角色 |
| 2x2 显示账号A的原神 + 账号B的原神 | `widget22: ["182692936/109050292", "348366494/250375401"]` | 两个原神角色（跨账号） |
| 2x4 显示账号A的星铁 + 绝区零 | `widget24: ["182692936/102731382", "182692936/37716744"]` | 星铁 + 绝区零（同账号） |
| 4x4 显示 4 个角色 | `widget44: [...]` | 最多 4 个角色任意组合 |

### 9.5 设计优势

1. **数据完整**：`data` 存储所有账号所有角色的完整数据，不会丢失
2. **精确定位**：`accountId/roleId` 格式全局唯一，跨账号查询无歧义
3. **查询高效**：O(1) 时间复杂度直接定位，无需遍历
4. **扩展性好**：新增账号/角色只需在 `data` 下添加，新增卡片尺寸只需在 `widgets` 下添加
5. **符合直觉**：`data` 是「数据源」，`widgets` 是「视图配置」，职责分离清晰


---

## 十、场景数据流

### 10.1 场景一：用户新安装 App

**数据状态**：

```json
{
  "version": 1,
  "updatedAt": 0,
  "data": {},
  "widgets": {}
}
```

**说明**：
- `data` 为空，没有登录过任何账号
- `widgets` 为空，没有配置过任何卡片
- 用户添加卡片时，`onAddForm` 检测到 `data` 为空，显示「未登录，点击前往登录」占位

---

### 10.2 场景二：用户登录完成，未去 WidgetSetting 设置

假设用户登录了账号 A（182692936），同步完成后：

**数据状态**：

```json
{
  "version": 1,
  "updatedAt": 1779012632,
  "data": {
    "182692936": {
      "accountName": "CainLuo",
      "slots": {
        "109050292": { "gameId": "genshin", "nickname": "凹凸曼的小怪兽", "server": "cn_gf01", "level": 60, "rawJson": "..." },
        "102731382": { "gameId": "starrail", "nickname": "凹凸曼的小怪兽", "server": "prod_gf_cn", "level": 70, "rawJson": "..." },
        "37716744": { "gameId": "zzz", "nickname": "凹凸曼的小怪兽", "server": "prod_gf_cn", "level": 51, "rawJson": "..." }
      }
    }
  },
  "widgets": {}
}
```

**说明**：
- `data` 已填充账号 A 的所有角色数据
- `widgets` 为空，用户没有配置过卡片
- 用户添加卡片时，`onAddForm` 检测到 `widgets.widget22` 不存在，使用 **fallback 逻辑**

**Fallback 逻辑**：
- 取第一个账号（182692936）的第一个角色（109050292）作为 widget12
- 取第一个账号的前两个角色（109050292, 102731382）作为 widget22
- 取第一个账号的前四个角色（按游戏顺序取）作为 widget44

**用户添加 2x2 卡片后显示**：原神 + 星铁（按角色列表顺序）

---

### 10.3 场景三：用户添加卡片后，再去 WidgetSetting 设置

**步骤 1：用户添加 2x2 卡片（未配置，使用 fallback）**

桌面显示：原神 + 星铁

**步骤 2：用户进入 WidgetSetting，选择「绝区零 + 星铁」**

用户点击「完成」后，`widgets.widget22` 被写入：

```json
{
  "widgets": {
    "widget22": ["182692936/37716744", "182692936/102731382"]
  }
}
```

**问题：桌面卡片会更新吗？**

**答案：不会自动更新**。

**原因**：
- 桌面卡片已经添加，`formId` 已固定
- `widgets.widget22` 是「预配置」，只在 `onAddForm` 时读取
- 已添加的卡片有自己的 `formId`，存储在 `widgets.{formId}` 中

**解决方案**：

有两种设计选择：

**方案 A：用户保存后主动刷新已添加的卡片**

```typescript
// WidgetSetting 页面点击「完成」后
formProvider.updateForm(formId, formBindingData)
```

优点：即时生效，用户体验好
缺点：需要维护 `formId` → `widgetName` 的映射关系

**方案 B：区分「预配置」和「已添加卡片配置」**

```json
{
  "widgets": {
    "widget22": ["182692936/37716744", "182692936/102731382"],
    "form_12345678": ["182692936/109050292", "182692936/102731382"]
  }
}
```

- `widget22`：预配置，新添加的卡片使用
- `form_12345678`：已添加卡片的具体配置

用户在 WidgetSetting 修改后：
1. 更新 `widgets.widget22`（预配置）
2. 遍历所有 `form_*` 开头的 key，如果是对应尺寸的卡片，也同步更新
3. 调用 `formProvider.updateForm()` 刷新桌面卡片

---

### 10.4 推荐方案：方案 B（区分预配置和已添加配置）

**完整数据结构**：

```json
{
  "version": 1,
  "updatedAt": 1779012632,
  "data": {
    "182692936": {
      "accountName": "CainLuo",
      "slots": {
        "109050292": { "gameId": "genshin", "...": "..." },
        "102731382": { "gameId": "starrail", "...": "..." },
        "37716744": { "gameId": "zzz", "...": "..." }
      }
    }
  },
  "widgets": {
    "widget12": ["182692936/109050292"],
    "widget22": ["182692936/37716744", "182692936/102731382"],
    "widget24": [],
    "widget44": [],
    "form_12345678": ["182692936/109050292", "182692936/102731382"],
    "form_87654321": ["182692936/37716744"]
  }
}
```

**字段说明**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `widgets.widget12` | string[] | 1x2 卡片的预配置（新添加卡片时使用） |
| `widgets.widget22` | string[] | 2x2 卡片的预配置 |
| `widgets.widget24` | string[] | 2x4 卡片的预配置 |
| `widgets.widget44` | string[] | 4x4 卡片的预配置 |
| `widgets.{formId}` | string[] | 已添加卡片的具体配置 |

**数据流**：

1. **用户首次添加卡片**：`onAddForm` 读取 `widgets.widget22`，如果不存在则 fallback
2. **卡片添加成功**：写入 `widgets.{formId}` = 当前使用的配置
3. **用户在 WidgetSetting 修改**：
   - 更新 `widgets.widget22`
   - 查找所有 `form_` 开头的 key，找到对应尺寸的卡片
   - 更新 `widgets.{formId}` 并调用 `formProvider.updateForm()`

**示例**：

用户已添加两个 2x2 卡片：
- form_12345678 显示「原神 + 星铁」
- form_87654321 显示「绝区零 + 星铁」

用户在 WidgetSetting 把 widget22 改成「绝区零 + 原神」：

```typescript
// 伪代码
const newConfig = ["182692936/37716744", "182692936/109050292"];
widgets["widget22"] = newConfig;

// 更新所有 2x2 尺寸的已添加卡片
for (const key of Object.keys(widgets)) {
  if (key.startsWith("form_") && is2x2Card(key)) {
    widgets[key] = newConfig;
    formProvider.updateForm(key, buildFormBindingData(newConfig));
  }
}
```

结果：
- form_12345678 更新为「绝区零 + 原神」
- form_87654321 更新为「绝区零 + 原神」
- 桌面两个卡片都刷新显示新配置

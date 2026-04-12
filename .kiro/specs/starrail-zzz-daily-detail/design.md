# 星穹铁道 & 绝区零便笺详情页 — 设计文档

## 架构概览

与原神便笺详情页完全对称，遵循 MVVM 分层：

```
core/src/main/ets/parsers/
├── StarRailDailyNoteParser.ets   ← 新增：rawJson → StarRailDailyNoteData
└── ZZZDailyNoteParser.ets        ← 新增：rawJson → ZZZDailyNoteData

entry/src/main/ets/
├── components/dailynote/
│   ├── DailyNoteModels.ets       ← 修改：补全 StarRailDailyNoteVM / ZZZDailyNoteVM 字段
│   ├── DailyNoteStarRail.ets     ← 新增：星铁便笺 UI 组件
│   └── DailyNoteZZZ.ets          ← 新增：绝区零便笺 UI 组件
├── viewmodel/
│   ├── StarRailDailyDetailViewModel.ets  ← 新增
│   └── ZZZDailyDetailViewModel.ets       ← 新增
├── pages/
│   ├── StarRailDailyDetail.ets   ← 新增
│   ├── ZZZDailyDetail.ets        ← 新增
│   └── router/
│       ├── StarRailDailyDetailBuilder.ets  ← 新增
│       └── ZZZDailyDetailBuilder.ets       ← 新增
└── constants/
    └── AppRoutes.ets             ← 修改：添加两个路由常量
```

---

## core 层设计

### StarRailDailyNoteParser

```typescript
// core/src/main/ets/parsers/StarRailDailyNoteParser.ets

export class StarRailExpeditionData {
  avatarSideIcon: string = "";
  name: string = "";
  remainedTime: string = "0";
  finishTime: string = "";
  status: string = "";
}

export class StarRailDailyNoteData {
  currentStamina: number = 0;
  maxStamina: number = 240;
  staminaRecoverTime: number = 0;
  currentReserveStamina: number = 0;
  isReserveStaminaFull: boolean = false;
  acceptedExpeditionNum: number = 0;
  totalExpeditionNum: number = 4;
  expeditions: StarRailExpeditionData[] = [];
  currentTrainScore: number = 0;
  maxTrainScore: number = 500;
  currentRogueScore: number = 0;
  maxRogueScore: number = 14000;
  weeklyCocoonCnt: number = 0;
  weeklyCocoonLimit: number = 3;
  rogueTournWeeklyUnlocked: boolean = false;
  rogueTournWeeklyCur: number = 0;
  rogueTournWeeklyMax: number = 1000;
  rogueTournExpIsFull: boolean = false;
  gridFightWeeklyCur: number = 0;
  gridFightWeeklyMax: number = 0;
}

export class StarRailDailyNoteParser {
  static parse(rawJson: string): StarRailDailyNoteData {
    const result = new StarRailDailyNoteData();
    try {
      const d = JSON.parse(rawJson) as Record<string, Object>;
      // ... 字段映射
    } catch (_) {}
    return result;
  }
}
```

### ZZZDailyNoteParser

```typescript
// core/src/main/ets/parsers/ZZZDailyNoteParser.ets

export class ZZZDailyNoteData {
  currentEnergy: number = 0;
  maxEnergy: number = 240;
  energyRecoverTime: number = 0;
  currentVitality: number = 0;
  maxVitality: number = 400;
  vhsSaleState: string = "";
  cardSign: string = "";
  abyssRefresh: number = 0;
  memberCardIsOpen: boolean = false;
  memberCardState: string = "";
  cafeState: string = "";
  templeExpeditionState: string = "";
  templeCurrentCurrency: number = 0;
}

export class ZZZDailyNoteParser {
  static parse(rawJson: string): ZZZDailyNoteData {
    const result = new ZZZDailyNoteData();
    try {
      const d = JSON.parse(rawJson) as Record<string, Object>;
      // ... 字段映射
    } catch (_) {}
    return result;
  }
}
```

---

## entry 层设计

### DailyNoteModels.ets 更新

`StarRailDailyNoteVM` 补全字段（与 `StarRailDailyNoteData` 一一对应）：

```typescript
export class StarRailDailyNoteVM {
  currentStamina: number = 0;
  maxStamina: number = 240;
  staminaRecoverySeconds: number = 0; // 来自 staminaRecoverTime
  currentReserveStamina: number = 0;
  isReserveStaminaFull: boolean = false;
  acceptedExpeditionNum: number = 0;
  totalExpeditionNum: number = 4;
  expeditions: ExpeditionVM[] = [];
  currentTrainScore: number = 0;
  maxTrainScore: number = 500;
  currentRogueScore: number = 0;
  maxRogueScore: number = 14000;
  weeklyCocoonCnt: number = 0;
  weeklyCocoonLimit: number = 3;
  rogueTournWeeklyUnlocked: boolean = false;
  rogueTournWeeklyCur: number = 0;
  rogueTournWeeklyMax: number = 1000;
  rogueTournExpIsFull: boolean = false;
  gridFightWeeklyCur: number = 0;
  gridFightWeeklyMax: number = 0;
}
```

`ZZZDailyNoteVM` 补全字段：

```typescript
export class ZZZDailyNoteVM {
  currentEnergy: number = 0;
  maxEnergy: number = 240;
  energyRecoverySeconds: number = 0; // 来自 energyRecoverTime
  currentVitality: number = 0;
  maxVitality: number = 400;
  vhsSaleState: string = "";
  cardSign: string = "";
  abyssRefresh: number = 0;
  memberCardIsOpen: boolean = false;
  memberCardState: string = "";
  cafeState: string = "";
  templeExpeditionState: string = "";
  templeCurrentCurrency: number = 0;
}
```

---

### ViewModel 设计

两个 ViewModel 与 `GenshinDailyDetailViewModel` 结构完全对称：

```typescript
// StarRailDailyDetailViewModel.ets
@ObservedV2
export class StarRailDailyDetailViewModel {
  @Trace viewState: ViewState = ViewState.LOADING
  @Trace note: StarRailDailyNoteVM = new StarRailDailyNoteVM()

  private accountId: string = ''
  private roleUid: string = ''

  init(accountId: string, roleUid: string): void { ... }
  async loadData(): Promise<void> { ... }

  private static toVM(data: StarRailDailyNoteData): StarRailDailyNoteVM { ... }
  private static toExpeditionVMs(raws: StarRailExpeditionData[]): ExpeditionVM[] { ... }
}
```

时间格式化逻辑（`formatSeconds`）在 ViewModel 内部实现，不暴露给 View。

---

### 页面路由参数

两个详情页共用同一参数类型（与原神一致）：

```typescript
export class StarRailDailyDetailParam {
  accountId: string = "";
  roleUid: string = "";
}

export class ZZZDailyDetailParam {
  accountId: string = "";
  roleUid: string = "";
}
```

---

### DailyNoteStarRail 组件布局

```
Scroll
└── Column
    ├── Text（数据延迟提示）
    ├── SectionHeader（"日常"）
    └── Card（日常组）
        ├── StaminaRow（开拓力 + 进度条 + 恢复倒计时）
        ├── Divider
        ├── DataRow（后备开拓力）
        ├── DataRow（委托派遣）
        ├── DataRow（每日实训）
        └── DataRow（历战余响）
    ├── SectionHeader（"宇宙"）
    └── Card（宇宙组）
        ├── RogueScoreRow（模拟宇宙积分 + 进度条）
        ├── Divider
        ├── DataRow（差分宇宙，含经验已满标签）
        └── DataRow（黄金与机械，max=0 时显示"未解锁"）
```

### DailyNoteZZZ 组件布局

```
Scroll
└── Column
    ├── Text（数据延迟提示）
    ├── SectionHeader（"日常"）
    └── Card（日常组）
        ├── EnergyRow（电量 + 进度条 + 恢复倒计时）
        ├── Divider
        └── VitalityRow（活跃度 + 进度条）
    ├── SectionHeader（"商店"）
    └── Card（商店组）
        ├── DataRow（录像店）
        └── DataRow（刮刮卡）
    ├── SectionHeader（"其他"）
    └── Card（其他组）
        ├── DataRow（式舆防卫战，状态 + 货币）
        ├── DataRow（会员卡）
        └── DataRow（咖啡厅）
```

---

### 状态枚举映射（ViewModel 层处理）

**录像店（vhsSaleState）**

| API 值           | 显示文字 |
| ---------------- | -------- |
| `SaleStateDone`  | 已结算   |
| `SaleStateDoing` | 营业中   |
| `SaleStateNo`    | 未开启   |
| 其他             | 原始值   |

**刮刮卡（cardSign）**

| API 值         | 显示文字 |
| -------------- | -------- |
| `CardSignDone` | 已完成   |
| `CardSignNo`   | 未完成   |

**式舆防卫战（templeExpeditionState）**

| API 值                   | 显示文字 |
| ------------------------ | -------- |
| `ExpeditionStateUnknown` | 未知     |
| `ExpeditionStateRunning` | 进行中   |
| `ExpeditionStateDone`    | 已完成   |
| `ExpeditionStateIdle`    | 空闲     |

**会员卡（memberCardState）**

| API 值                   | 显示文字 |
| ------------------------ | -------- |
| `MemberCardStateNo`      | 未开通   |
| `MemberCardStateActive`  | 生效中   |
| `MemberCardStateExpired` | 已过期   |

**咖啡厅（cafeState）**

| API 值          | 显示文字 |
| --------------- | -------- |
| `CafeStateNo`   | 未开启   |
| `CafeStateOpen` | 营业中   |
| `CafeStateDone` | 已结算   |

---

### Home 页跳转逻辑

`HomeViewModel.onCardTap(card: GameRoleCardVM)` 修改为：

```typescript
onCardTap(card: GameRoleCardVM): void {
  const param = new DailyDetailParam()
  param.accountId = card.accountId
  param.roleUid = card.roleUid
  if (card.gameId === GameId.GENSHIN) {
    RouterUtil.push(AppRoutes.GENSHIN_DAILY_DETAIL, param)
  } else if (card.gameId === GameId.STARRAIL) {
    RouterUtil.push(AppRoutes.STARRAIL_DAILY_DETAIL, param)
  } else if (card.gameId === GameId.ZZZ) {
    RouterUtil.push(AppRoutes.ZZZ_DAILY_DETAIL, param)
  }
}
```

---

## 字符串资源清单（需新增）

以下 key 需在 `base/zh_HK/en` 三个 `string.json` 中同步添加：

| key                             | 简体中文                 | 繁体中文                 | 英文                              |
| ------------------------------- | ------------------------ | ------------------------ | --------------------------------- |
| `starrail_daily_title`          | 星穹铁道便笺             | 星穹鐵道便箋             | Star Rail Notes                   |
| `zzz_daily_title`               | 绝区零便笺               | 絕區零便箋               | ZZZ Notes                         |
| `daily_note_stamina`            | 开拓力                   | 開拓力                   | Stamina                           |
| `daily_note_reserve_stamina`    | 后备开拓力               | 後備開拓力               | Reserve Stamina                   |
| `daily_note_expedition`         | 委托派遣                 | 委托派遣                 | Expeditions                       |
| `daily_note_train_score`        | 每日实训                 | 每日實訓                 | Daily Training                    |
| `daily_note_cocoon`             | 历战余响                 | 歷戰餘響                 | Echo of War                       |
| `daily_note_rogue_score`        | 模拟宇宙积分             | 模擬宇宙積分             | Simulated Universe                |
| `daily_note_rogue_tourn`        | 差分宇宙                 | 差分宇宙                 | Divergent Universe                |
| `daily_note_rogue_tourn_locked` | 未解锁                   | 未解鎖                   | Locked                            |
| `daily_note_rogue_exp_full`     | 经验已满                 | 經驗已滿                 | EXP Full                          |
| `daily_note_grid_fight`         | 黄金与机械               | 黃金與機械               | Gold & Gears                      |
| `daily_note_grid_fight_locked`  | 未解锁                   | 未解鎖                   | Locked                            |
| `daily_note_section_daily`      | 日常                     | 日常                     | Daily                             |
| `daily_note_section_universe`   | 宇宙                     | 宇宙                     | Universe                          |
| `daily_note_energy`             | 电量                     | 電量                     | Battery                           |
| `daily_note_vitality`           | 活跃度                   | 活躍度                   | Vitality                          |
| `daily_note_vhs_sale`           | 录像店                   | 錄像店                   | Video Store                       |
| `daily_note_card_sign`          | 刮刮卡                   | 刮刮卡                   | Scratch Card                      |
| `daily_note_section_shop`       | 商店                     | 商店                     | Shop                              |
| `daily_note_section_other`      | 其他                     | 其他                     | Other                             |
| `daily_note_temple`             | 式舆防卫战               | 式輿防衛戰               | Hollow Zero                       |
| `daily_note_member_card`        | 会员卡                   | 會員卡                   | Member Card                       |
| `daily_note_cafe`               | 咖啡厅                   | 咖啡廳                   | Café                              |
| `daily_note_vhs_done`           | 已结算                   | 已結算                   | Settled                           |
| `daily_note_vhs_doing`          | 营业中                   | 營業中                   | Open                              |
| `daily_note_vhs_no`             | 未开启                   | 未開啟                   | Closed                            |
| `daily_note_card_done`          | 已完成                   | 已完成                   | Done                              |
| `daily_note_card_no`            | 未完成                   | 未完成                   | Not Done                          |
| `daily_note_temple_unknown`     | 未知                     | 未知                     | Unknown                           |
| `daily_note_temple_running`     | 进行中                   | 進行中                   | Running                           |
| `daily_note_temple_done`        | 已完成                   | 已完成                   | Done                              |
| `daily_note_temple_idle`        | 空闲                     | 空閒                     | Idle                              |
| `daily_note_member_no`          | 未开通                   | 未開通                   | Not Active                        |
| `daily_note_member_active`      | 生效中                   | 生效中                   | Active                            |
| `daily_note_member_expired`     | 已过期                   | 已過期                   | Expired                           |
| `daily_note_cafe_no`            | 未开启                   | 未開啟                   | Closed                            |
| `daily_note_cafe_open`          | 营业中                   | 營業中                   | Open                              |
| `daily_note_cafe_done`          | 已结算                   | 已結算                   | Settled                           |
| `daily_note_reserve_full`       | 已满                     | 已滿                     | Full                              |
| `daily_note_vitality_done`      | 本日活跃度已完成         | 本日活躍度已完成         | Daily vitality complete           |
| `daily_note_vitality_hint`      | 完成日常任务可获得活跃度 | 完成日常任務可獲得活躍度 | Complete daily tasks for vitality |

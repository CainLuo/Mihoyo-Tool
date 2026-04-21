# 设计文档：游戏体力通知提醒

## 概述

本功能为米悠悠 HarmonyOS App 新增本地通知能力，在原神树脂、崩坏：星穹铁道开拓力、绝区零电量等体力值达到用户设定的提醒值时，向系统通知栏推送提醒。

核心设计思路：

- **触发时机**：每次便笺数据同步完成后（前台手动刷新 + 后台 30 分钟定时同步），由 `StaminaNotificationService` 读取 DB 中的 Recovery_Time 字段，计算体力达到提醒值所需的剩余秒数，调用 `reminderAgentManager.publishReminder` 注册系统级代理提醒。
- **系统级代理提醒**：使用 `@kit.BackgroundTasksKit` 的 `reminderAgentManager` 模块，通知由系统代理管理，**App 被杀掉后时间到了系统仍会自动弹出通知**，与 iOS 的 Local Notification 机制完全一致。
- **幂等调度**：每次同步后对比新旧 Recovery_Time 快照，若发生变化则取消旧提醒（`cancelReminder`）并重新注册，确保通知时间始终与服务器数据一致。
- **持久化**：通知设置通过 `@kit.ArkData` 的 `preferences` 模块持久化；Recovery_Time 快照存储在 preferences 中，用于判断是否需要重新调度。
- **架构归属**：通知调度逻辑放在 `entry` 模块的 `notification/` 目录，不污染 `core` 模块。
- **体力上限值来自 API**：原神 `maxResin`、星铁 `maxStamina`、绝区零 `energy.progress.max` 均从便笺 API 响应中读取，不在代码中 hard code，DB 中的 Row 模型已存储这些字段。
- **按账号 × 游戏动态配置**：通知设置页只展示该账号实际拥有游戏角色的游戏，不强制显示三个游戏。
- **提醒配额上限**：`reminderAgentManager` 对普通应用的上限为 **30 个**（API 10+，错误码 1700002）。超出上限时 `publishReminder` 会抛出错误，需在调度前检查当前已注册数量，超限时弹出 Dialog 提示用户关闭部分游戏通知。

### 权限说明

使用 `reminderAgentManager` 需要申请 `ohos.permission.PUBLISH_AGENT_REMINDER` 权限。该权限属于**受限开放权限**，普通应用需通过 AppGallery Connect（AGC）审核后才能使用。

#### 在 module.json5 中声明权限

```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.PUBLISH_AGENT_REMINDER",
        "reason": "$string:permission_reason_agent_reminder",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "always"
        }
      }
    ]
  }
}
```

同时在 `entry/src/main/resources/base/element/string.json` 中添加：

```json
{
  "name": "permission_reason_agent_reminder",
  "value": "用于在游戏体力值达到设定值时推送本地提醒通知"
}
```

#### AGC 受限权限申请流程

1. 登录 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)
2. 进入「我的应用」→ 选择对应应用 → 「应用信息」→「权限申请」
3. 找到 `ohos.permission.PUBLISH_AGENT_REMINDER`，点击申请
4. 填写使用场景说明，建议描述为：
   > 本应用为米哈游游戏（原神/崩坏：星穹铁道/绝区零）的非官方数据查看工具。用户在 App 内设置体力值提醒阈值后，App 通过代理提醒功能在体力值达到阈值时向用户推送本地通知，帮助用户及时消耗体力、避免溢出浪费。通知完全在本地触发，不涉及任何网络请求或数据上传。
5. 等待华为审核（通常 1-3 个工作日）
6. 审核通过后，在 AGC 重新下载 Profile 文件，替换项目中的签名配置文件，重新打包上架

#### 开发阶段调试

**开发阶段无需等待 AGC 审核**，直接通过 DevEco Studio 将调试包安装到真机即可测试完整通知功能。AGC 审核只在正式上架应用市场时才需要。

#### 参考资料

- [后台提醒与代理提醒：HarmonyOS Next 的智能提醒管理](https://www.cnblogs.com/samex/p/18508051) — 包含三种代理提醒类型的完整代码示例
- [鸿蒙Next权限申请进阶：受限开放权限与ACL申请秘籍](https://www.cnblogs.com/samex/p/18527107) — 详细说明受限权限的 AGC 申请流程
- [ArkTS实现闹钟](https://www.cnblogs.com/auguse/articles/18047258) — 基于 `reminderAgentManager` 的实际闹钟案例，可参考倒计时提醒的实现方式

---

## 架构

### 模块划分

```
entry/src/main/ets/
├── notification/
│   ├── StaminaNotificationService.ets   ← 通知调度核心服务（单例）
│   ├── NotificationSettingsStore.ets    ← 通知设置持久化（preferences）
│   ├── NotificationStateStore.ets       ← 通知状态持久化（preferences）
│   ├── StaminaThresholdCalculator.ets   ← 纯函数：阈值计算逻辑
│   └── NotificationModels.ets           ← 数据模型（设置、状态、通知内容）
├── viewmodel/
│   └── NotificationSettingsViewModel.ets ← 通知设置页 ViewModel
└── components/
    └── my/
        └── NotificationSection.ets       ← 通知设置 UI 组件
```

### 数据流

```
便笺同步完成（HomeViewModel.syncAllDailyNotes）
    ↓
StaminaNotificationService.onDailyNotesSynced()
    ↓
读取 DB（GenshinDailyNoteRow / StarRailDailyNoteRow / ZZZDailyNoteRow）
    ↓
StaminaThresholdCalculator.calcDelaySeconds(recoveryTime, threshold, maxStamina)
    ↓
对比 NotificationStateStore 中的 Recovery_Time 快照
    ↓ 若 Recovery_Time 变化
取消旧提醒（reminderAgentManager.cancelReminder(reminderId)）
    ↓
注册新提醒（reminderAgentManager.publishReminder(ReminderRequestTimer)）
    ↓
更新 NotificationStateStore 快照（存储 reminderId + recoveryTimeSnapshot）
```

### 与现有代码的集成点

| 集成点                                              | 方式                                                                                       |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| `HomeViewModel.syncAllDailyNotes()` 完成后          | 在 `syncAllDailyNotes` 末尾调用 `StaminaNotificationService.instance.onDailyNotesSynced()` |
| `HomeViewModel.refresh()` / `forceRefresh()` 完成后 | 同上，在 `fetchFromLocal` 之后调用                                                         |
| `My.ets` 页面                                       | 在「外观设置」区域下方插入 `NotificationSection` 组件                                      |
| `CoreInitializer.initCore()` 完成后                 | 在 `EntryAbility.onWindowStageCreate` 中初始化 `StaminaNotificationService`                |

---

## 组件与接口

### StaminaNotificationService（entry 层单例）

```typescript
import { reminderAgentManager } from "@kit.BackgroundTasksKit";

class StaminaNotificationService {
  static readonly instance: StaminaNotificationService;

  /** App 启动时初始化：加载持久化状态 */
  async init(context: common.UIAbilityContext): Promise<void>;

  /** 便笺同步完成后调用，触发阈值检查和提醒注册 */
  async onDailyNotesSynced(): Promise<void>;

  /** 用户关闭总开关时调用，取消所有已注册的代理提醒 */
  async cancelAll(): Promise<void>;

  /** 用户修改某游戏阈值时调用，取消该游戏所有已注册的代理提醒 */
  async cancelByGame(gameId: string): Promise<void>;

  /** 请求通知权限（ohos.permission.PUBLISH_AGENT_REMINDER），返回是否授权成功 */
  async requestPermission(context: common.UIAbilityContext): Promise<boolean>;

  /** 检查当前通知权限状态 */
  async checkPermission(): Promise<boolean>;

  /**
   * 注册单个代理提醒（倒计时类型）
   * triggerTimeInSeconds 直接使用 API 返回的 Recovery_Time 减去阈值偏移量
   */
  private async scheduleReminder(
    key: string,
    triggerTimeInSeconds: number,
    title: string,
    content: string,
    notificationId: number,
  ): Promise<number>; // 返回系统分配的 reminderId
}
```

**核心调用示例**：

```typescript
// 注册倒计时代理提醒（App 被杀后系统仍会在时间到时弹出通知）
const reminder: reminderAgentManager.ReminderRequestTimer = {
  reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
  triggerTimeInSeconds: delaySeconds, // calcDelaySeconds 计算出的剩余秒数
  title: "原神 · 凹凸曼的小怪兽",
  content: "原粹树脂已达 200/200，请及时消耗",
  notificationId: 10001,
  wantAgent: {
    pkgName: "com.cainluo.miyoyo.tools",
    abilityName: "EntryAbility",
  },
  actionButton: [
    {
      title: "关闭",
      type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE,
    },
  ],
};
const reminderId = await reminderAgentManager.publishReminder(reminder);
// 保存 reminderId 用于后续取消
```

### StaminaThresholdCalculator（纯函数模块）

```typescript
/** 计算体力达到阈值所需的剩余秒数（负数表示已超过阈值） */
function calcDelaySeconds(
  recoveryTime: number, // API 返回的恢复至满值所需秒数
  threshold: number, // 用户设定的阈值（体力值）
  maxStamina: number, // 该游戏体力上限
): number;

/** 解析原神 resin_recovery_time 字符串为整数秒数 */
function parseGenshinRecoveryTime(raw: string | number): number;

/** 判断是否需要重新调度（Recovery_Time 快照发生变化） */
function shouldReschedule(
  oldSnapshot: number,
  newRecoveryTime: number,
): boolean;
```

**计算公式**：

原神每格树脂恢复时间为 8 分钟（480 秒），星铁每点开拓力恢复时间为 6 分钟（360 秒），绝区零每点电量恢复时间为 6 分钟（360 秒）。

但 API 直接返回的是「距离满值还需多少秒」，因此：

```
当前体力 = maxStamina - ceil(recoveryTime / secondsPerUnit)
达到阈值还需秒数 = recoveryTime - (maxStamina - threshold) * secondsPerUnit
```

若结果 ≤ 0，表示当前体力已达到或超过阈值，应立即发送通知。

### NotificationSettingsStore（preferences 持久化）

```typescript
interface NotificationSettings {
  enabled: boolean; // 总开关
  style: NotificationStyle; // 'styleA' | 'styleB'
  genshinEnabled: boolean; // 原神独立开关
  genshinThreshold: number; // 原神阈值（默认 160）
  starRailEnabled: boolean; // 星铁独立开关
  starRailThreshold: number; // 星铁阈值（默认 230）
  zzzEnabled: boolean; // 绝区零独立开关
  zzzThreshold: number; // 绝区零阈值（默认 200）
}

class NotificationSettingsStore {
  static readonly instance: NotificationSettingsStore;
  async load(): Promise<NotificationSettings>;
  async save(settings: NotificationSettings): Promise<void>;
  async getDefaults(): Promise<NotificationSettings>;
}
```

### NotificationStateStore（preferences 持久化）

```typescript
/** 每个 Game_Role 每个阈值的通知状态 */
interface NotificationStateEntry {
  notificationId: number; // 已调度的通知 ID
  recoveryTimeSnapshot: number; // 调度时的 Recovery_Time 快照
  threshold: number; // 对应的阈值
  scheduledAt: number; // 调度时的 Unix 时间戳（秒）
}

/** key 格式："{accountId}_{roleUid}_{gameId}_{threshold}" */
class NotificationStateStore {
  static readonly instance: NotificationStateStore;
  async load(): Promise<Map<string, NotificationStateEntry>>;
  async save(state: Map<string, NotificationStateEntry>): Promise<void>;
  async getEntry(key: string): Promise<NotificationStateEntry | null>;
  async setEntry(key: string, entry: NotificationStateEntry): Promise<void>;
  async removeEntry(key: string): Promise<void>;
  async clear(): Promise<void>;
}
```

### NotificationSettingsViewModel

```typescript
/** 单个账号下某游戏的通知配置（UI 展示用） */
class GameNotificationConfig {
  gameId: string = ""; // 'genshin' | 'starrail' | 'zzz'
  gameName: string = ""; // 显示名称
  staminaName: string = ""; // 体力名称（原粹树脂 / 开拓力 / 电量）
  enabled: boolean = true;
  threshold: number = 0;
  maxStamina: number = 0; // 来自 DB 的 API 实际上限，0 表示尚无数据
  secondsPerUnit: number = 0; // 每点恢复秒数
}

/** 单个账号的通知配置（UI 展示用） */
class AccountNotificationConfig {
  accountId: number = 0;
  nickname: string = "";
  uid: string = "";
  games: GameNotificationConfig[] = []; // 只包含该账号实际拥有的游戏
  isExpanded: boolean = true; // 折叠/展开状态
}

@ObservedV2
class NotificationSettingsViewModel {
  @Trace enabled: boolean = false;
  @Trace style: NotificationStyle = NotificationStyle.STYLE_A;
  @Trace permissionDenied: boolean = false;
  @Trace accounts: AccountNotificationConfig[] = []; // 动态，来自 DB 账号列表
  @Trace reminderUsed: number = 0; // 当前已注册的代理提醒数量
  @Trace reminderLimit: number = 30; // 系统上限（API 10+ 普通应用为 30）
  @Trace showLimitDialog: boolean = false; // 超限 Dialog 显示状态

  async loadSettings(): Promise<void>;
  async onToggleEnabled(context: common.UIAbilityContext): Promise<void>;
  async onStyleChange(style: NotificationStyle): Promise<void>;
  async onGameToggle(
    accountId: number,
    gameId: string,
    enabled: boolean,
  ): Promise<void>;
  async onThresholdChange(
    accountId: number,
    gameId: string,
    threshold: number,
  ): Promise<void>;
  async onFullValueShortcut(accountId: number): Promise<void>; // 仅对当前账号生效
  async onToggleAccountExpanded(accountId: number): Promise<void>;
}
```

---

## 数据模型

### NotificationStyle 枚举

```typescript
enum NotificationStyle {
  STYLE_A = "styleA", // 每个角色独立一条普通文本通知
  STYLE_B = "styleB", // 所有角色合并为一条多行文本通知
}
```

### NotificationSettings（持久化到 preferences）

全局设置（所有账号共用）：

| 字段      | 类型                | 默认值    | 说明     |
| --------- | ------------------- | --------- | -------- |
| `enabled` | `boolean`           | `false`   | 总开关   |
| `style`   | `NotificationStyle` | `STYLE_A` | 通知样式 |

每个账号 × 游戏的独立设置，key 格式为 `"{accountId}_{gameId}"`：

| 字段        | 类型      | 默认值 | 说明                                                    |
| ----------- | --------- | ------ | ------------------------------------------------------- |
| `enabled`   | `boolean` | `true` | 该账号该游戏的通知开关                                  |
| `threshold` | `number`  | 见上表 | 阈值（1 ≤ threshold ≤ maxStamina，maxStamina 来自 API） |

只有账号实际拥有该游戏角色时，才会在设置页显示对应的配置项。

### NotificationStateEntry（持久化到 preferences）

| 字段                   | 类型     | 说明                              |
| ---------------------- | -------- | --------------------------------- |
| `notificationId`       | `number` | 已调度的通知 ID（用于取消）       |
| `recoveryTimeSnapshot` | `number` | 调度时的 Recovery_Time 快照（秒） |
| `threshold`            | `number` | 对应的阈值                        |
| `scheduledAt`          | `number` | 调度时的 Unix 时间戳（秒）        |

**State Key 格式**：`"{accountId}_{roleUid}_{gameId}_{threshold}"`

例：`"182692936_109050292_genshin_160"`

### 通知 ID 分配策略

为避免通知 ID 冲突，采用哈希方式生成唯一 ID：

```
notificationId = hash(accountId + roleUid + gameId + threshold) % 100000 + 10000
```

范围：10000-109999，避免与系统通知 ID 冲突。

### 游戏常量

**体力上限值不得 hard code**，必须从便笺 API 响应中读取并存入 DB：

| 游戏   | `gameId`   | API 上限字段                                              | 每点恢复秒数 | 体力名称 | 默认阈值 |
| ------ | ---------- | --------------------------------------------------------- | ------------ | -------- | -------- |
| 原神   | `genshin`  | `GenshinDailyNoteRow.maxResin`（来自 `max_resin`）        | 480（8分钟） | 原粹树脂 | 160      |
| 星铁   | `starrail` | `StarRailDailyNoteRow.maxStamina`（来自 `max_stamina`）   | 360（6分钟） | 开拓力   | 230      |
| 绝区零 | `zzz`      | `ZZZDailyNoteRow.energyMax`（来自 `energy.progress.max`） | 360（6分钟） | 电量     | 200      |

若 DB 中尚无便笺数据（首次使用），阈值输入框的 `max` 属性使用已知的参考上限（原神 200 / 星铁 300 / 绝区零 240）作为 fallback，待首次同步后更新为 API 实际值。

### 提醒配额上限

`reminderAgentManager` 对普通应用的上限为 **30 个**（API 10+，错误码 `1700002`）。

**上限计算方式**：每个「账号 × 游戏」组合占用 1 个提醒配额。例如 2 个账号各有 3 个游戏 = 6 个配额。

**超限处理策略**：

1. 每次调度前调用 `reminderAgentManager.getValidReminders()` 获取当前已注册数量
2. 在通知设置页顶部显示当前使用量（如「已使用 6 / 30」）
3. 当用户尝试开启某游戏通知导致总数将超过 30 时，弹出 Dialog 提示：「当前提醒数量已达上限（30 个），请先关闭部分游戏的通知开关，再开启新的通知」，并阻止本次开启操作
4. 若 `publishReminder` 因上限抛出 `1700002` 错误，同样弹出上述 Dialog，并将该游戏开关回退为关闭状态

---

## 正确性属性

_属性是在系统所有有效执行中都应成立的特征或行为——本质上是关于系统应该做什么的形式化陈述。属性是人类可读规范与机器可验证正确性保证之间的桥梁。_

### 属性 1：阈值剩余秒数计算正确性

_对任意_ 合法的 Recovery_Time（≥ 0）、阈值（1 ≤ threshold ≤ maxStamina）和体力上限（maxStamina > 0），`calcDelaySeconds` 计算出的剩余秒数应满足：当 Recovery_Time = 0 时结果 ≤ 0（立即通知）；当 threshold = maxStamina 时结果等于 Recovery_Time；当 threshold < maxStamina 时结果 < Recovery_Time。

**验证：需求 2.1、2.3、6.7**

### 属性 2：Recovery_Time 变化检测正确性

_对任意_ 新旧 Recovery_Time 对（oldSnapshot, newRecoveryTime），`shouldReschedule` 的返回值应满足：当两者相等时返回 false（不重新调度）；当两者不等时返回 true（需要重新调度）。

**验证：需求 2.2、2.4**

### 属性 3：通知设置持久化 round-trip

_对任意_ 合法的 `NotificationSettings` 对象，将其写入 `NotificationSettingsStore` 后再读取，得到的对象应与写入的对象字段完全一致。

**验证：需求 4.8**

### 属性 4：通知状态持久化 round-trip

_对任意_ 合法的 `NotificationStateEntry` 集合，将其写入 `NotificationStateStore` 后再读取，得到的集合应与写入的集合完全一致（key 和 value 均相同）。

**验证：需求 2.5**

### 属性 5：Style_A 通知格式正确性

_对任意_ 合法的 Game_Role（包含游戏名、角色昵称、体力当前值、体力上限、服务器名、角色 UID），`buildStyleANotification` 生成的通知内容应满足：标题包含游戏名和角色昵称；正文包含体力名称、当前值和上限值；附加信息包含服务器名和角色 UID。

**验证：需求 3.2**

### 属性 6：Style_B 通知行数限制

_对任意_ 满足条件的 Game_Role 列表（长度 ≥ 1），`buildStyleBNotification` 生成的多行通知展开后的行数应 ≤ 3。

**验证：需求 3.3**

### 属性 7：阈值范围 clamp 正确性

_对任意_ 输入的阈值数值，`clampThreshold(value, gameId)` 的返回值应始终在该游戏的合法范围内（原神 1-200，星铁 1-300，绝区零 1-240）。

**验证：需求 4.4、4.5、4.6**

### 属性 8：多阈值独立计算

_对任意_ 阈值列表（包含 2 个或以上阈值）和 Recovery_Time，对每个阈值独立调用 `calcDelaySeconds` 的结果应互不影响，且结果集合的大小等于阈值列表的大小。

**验证：需求 2.6**

---

## 错误处理

### 通知权限相关

| 场景               | 处理方式                                                                                       |
| ------------------ | ---------------------------------------------------------------------------------------------- |
| 首次请求权限被拒绝 | 总开关回退为 false，显示提示信息                                                               |
| 已选择「不再询问」 | 引导用户前往系统设置，不再触发系统弹窗                                                         |
| 运行期间权限被撤销 | 捕获 `reminderAgentManager.publishReminder` 的错误，不崩溃；下次进入设置页时同步总开关为 false |

### 通知调度相关

| 场景                                        | 处理方式                                      |
| ------------------------------------------- | --------------------------------------------- |
| 便笺数据同步失败                            | 跳过该 Game_Role 的阈值检查，不修改已注册提醒 |
| Cookie 过期                                 | 跳过该账号下所有 Game_Role，不影响其他账号    |
| 未登录任何账号                              | 跳过所有阈值检查                              |
| `reminderAgentManager.cancelReminder` 失败  | 记录日志，继续执行后续注册，不崩溃            |
| `reminderAgentManager.publishReminder` 失败 | 记录日志，不更新状态快照（下次同步时重试）    |

### 持久化相关

| 场景                 | 处理方式                           |
| -------------------- | ---------------------------------- |
| preferences 读取失败 | 使用默认值，记录日志               |
| preferences 写入失败 | 记录日志，不崩溃（内存状态仍有效） |
| 状态数据格式损坏     | 清空状态，重新开始（不影响设置）   |

---

## 测试策略

### 单元测试（`entry/src/test/`）

#### StaminaThresholdCalculator 纯函数测试（`NotificationThresholdTest.test.ets`）

测试 `StaminaThresholdCalculator` 中的纯函数，不依赖设备或真实通知系统。

**属性测试**（使用 `@ohos/fast-check` 或手动生成随机输入）：

| 测试用例                            | 对应属性 | 验证内容                                                        |
| ----------------------------------- | -------- | --------------------------------------------------------------- |
| 属性 1：calcDelaySeconds 计算正确性 | 属性 1   | 对随机 Recovery_Time/threshold/maxStamina，验证计算结果符合公式 |
| 属性 2：shouldReschedule 变化检测   | 属性 2   | 对随机新旧值对，验证相等时 false，不等时 true                   |
| 属性 7：clampThreshold 范围限制     | 属性 7   | 对随机输入值，验证结果始终在合法范围内                          |
| 属性 8：多阈值独立计算              | 属性 8   | 对随机阈值列表，验证每个阈值独立计算互不影响                    |

**示例测试**：

| 测试用例                            | 输入                                       | 预期结果                                                |
| ----------------------------------- | ------------------------------------------ | ------------------------------------------------------- |
| 原神 resin_recovery_time 字符串解析 | `"22825"`                                  | 解析为 22825 秒                                         |
| 星铁 stamina_recover_time 整数解析  | `0`                                        | 解析为 0 秒（已满）                                     |
| 绝区零 energy.restore 整数解析      | `3600`                                     | 解析为 3600 秒                                          |
| 体力值已达阈值（Recovery_Time = 0） | 当前值 200，阈值 160                       | 返回 ≤ 0（立即通知）                                    |
| 体力值未达阈值                      | 当前值 140，阈值 160，Recovery_Time = 2400 | 返回 2400 - (200-160)\*480 = 2400 - 19200 < 0，立即通知 |
| Recovery_Time 变化触发重新调度      | 旧快照 3600，新值 2400                     | shouldReschedule 返回 true                              |
| Recovery_Time 未变化不重新调度      | 旧快照 3600，新值 3600                     | shouldReschedule 返回 false                             |

#### NotificationSettingsViewModel 单元测试（`NotificationSettingsViewModelTest.test.ets`）

| 测试用例                      | 前置条件             | 操作                                  | 预期结果                              |
| ----------------------------- | -------------------- | ------------------------------------- | ------------------------------------- |
| 初始 enabled 为 false         | 新建实例             | `new NotificationSettingsViewModel()` | `enabled === false`                   |
| 初始 style 为 STYLE_A         | 新建实例             | `new NotificationSettingsViewModel()` | `style === NotificationStyle.STYLE_A` |
| 初始 genshinThreshold 为 160  | 新建实例             | `new NotificationSettingsViewModel()` | `genshinThreshold === 160`            |
| 初始 starRailThreshold 为 230 | 新建实例             | `new NotificationSettingsViewModel()` | `starRailThreshold === 230`           |
| 初始 zzzThreshold 为 200      | 新建实例             | `new NotificationSettingsViewModel()` | `zzzThreshold === 200`                |
| 满值快捷开关设置三个游戏阈值  | 任意初始状态         | `onFullValueShortcut()`               | genshin=200, starRail=300, zzz=240    |
| 阈值超出上限被 clamp          | genshinThreshold=201 | `onThresholdChange('genshin', 201)`   | `genshinThreshold === 200`            |
| 阈值低于下限被 clamp          | genshinThreshold=0   | `onThresholdChange('genshin', 0)`     | `genshinThreshold === 1`              |

#### 通知内容构建测试（`NotificationContentBuilderTest.test.ets`）

**属性测试**：

| 测试用例                   | 对应属性 | 验证内容                                          |
| -------------------------- | -------- | ------------------------------------------------- |
| 属性 5：Style_A 格式正确性 | 属性 5   | 对随机 Game_Role 数据，验证标题/正文/附加信息格式 |
| 属性 6：Style_B 行数限制   | 属性 6   | 对随机 Game_Role 列表，验证展开行数 ≤ 3           |

### Mock 环境测试（`entry/src/ohosTest/`）

在模拟器上运行，使用项目已有的 Mock 便笺数据验证完整通知流程。

#### 通知设置 UI 测试（`NotificationSettingsPageTest.test.ets`）

| 测试用例                    | 前置条件                                  | 操作             | 预期结果                               |
| --------------------------- | ----------------------------------------- | ---------------- | -------------------------------------- |
| 通知设置区域可见            | 已登录账号                                | 进入 My 页       | 「通知设置」区域显示在「外观设置」下方 |
| 总开关默认关闭              | 首次安装                                  | 进入通知设置     | 总开关为关闭状态                       |
| 开启总开关触发权限申请      | 未授权通知权限                            | 点击总开关       | 弹出权限说明 Dialog                    |
| 样式选择有示例预览          | 总开关已开启                              | 查看样式选择区域 | 两种样式各有示例文字                   |
| 阈值输入范围限制            | 总开关已开启                              | 输入原神阈值 201 | 输入被限制为 200                       |
| Mock 立即通知（原神满值）   | Mock JSON 设置 `resin_recovery_time: "0"` | 触发同步         | 系统通知栏出现原神通知                 |
| Mock 立即通知（星铁满值）   | Mock JSON 设置 `stamina_recover_time: 0`  | 触发同步         | 系统通知栏出现星铁通知                 |
| Mock 立即通知（绝区零满值） | Mock JSON 设置 `energy.restore: 0`        | 触发同步         | 系统通知栏出现绝区零通知               |
| 关闭总开关取消通知          | 已有调度中的通知                          | 关闭总开关       | 系统通知队列中的定时通知被取消         |
| 点击通知跳转便笺页          | 已收到 Style_A 通知                       | 点击通知         | App 跳转到对应游戏便笺详情页           |

#### 属性测试配置

- 每个属性测试最少运行 **100 次迭代**
- 标签格式：`Feature: game-stamina-notification, Property {N}: {属性描述}`
- 每个正确性属性对应一个属性测试函数

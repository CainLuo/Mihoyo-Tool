# 实现计划：游戏体力通知提醒

## 概述

基于设计文档，将通知调度逻辑放在 `entry/src/main/ets/notification/` 目录，通过 `reminderAgentManager` 实现系统级代理提醒，App 被杀后系统仍会在时间到时触发通知。

## 任务

- [ ] 1. 声明权限与添加字符串资源
  - 在 `entry/src/main/module.json5` 的 `requestPermissions` 中添加 `ohos.permission.PUBLISH_AGENT_REMINDER` 权限声明，包含 `reason`、`usedScene.abilities`、`usedScene.when` 字段
  - 在 `entry/src/main/resources/base/element/string.json` 中添加 `permission_reason_agent_reminder` 字符串
  - 同步在 `zh_HK/element/string.json` 和 `en/element/string.json` 中添加对应翻译
  - _需求：1.1、1.2_

- [ ] 2. 创建数据模型与枚举
  - 新建 `entry/src/main/ets/notification/NotificationModels.ets`
  - 定义 `NotificationStyle` 枚举（`STYLE_A = 'styleA'`、`STYLE_B = 'styleB'`）
  - 定义 `NotificationSettings` 接口（`enabled`、`style`、`genshinEnabled`、`genshinThreshold`、`starRailEnabled`、`starRailThreshold`、`zzzEnabled`、`zzzThreshold`）
  - 定义 `NotificationStateEntry` 接口（`notificationId`、`recoveryTimeSnapshot`、`threshold`、`scheduledAt`）
  - 定义游戏常量对象（`gameId`、体力上限、每点恢复秒数、体力名称）
  - _需求：3.1、4.4、4.5、4.6_

- [ ] 3. 实现 StaminaThresholdCalculator 纯函数模块
  - 新建 `entry/src/main/ets/notification/StaminaThresholdCalculator.ets`
  - 实现 `calcDelaySeconds(recoveryTime, threshold, maxStamina): number`，公式：`recoveryTime - (maxStamina - threshold) * secondsPerUnit`，结果 ≤ 0 表示立即通知
  - 实现 `parseGenshinRecoveryTime(raw: string | number): number`，将原神 `resin_recovery_time` 字符串解析为整数秒
  - 实现 `shouldReschedule(oldSnapshot: number, newRecoveryTime: number): boolean`，两值不等时返回 true
  - 实现 `clampThreshold(value: number, gameId: string): number`，将阈值限制在各游戏合法范围内（原神 1-200，星铁 1-300，绝区零 1-240）
  - _需求：2.1、2.2、2.3、2.4、4.4、4.5、4.6、6.7_

  - [ ]\* 3.1 为 calcDelaySeconds 编写属性测试（属性 1）
    - 测试文件：`entry/src/test/NotificationThresholdTest.test.ets`
    - **属性 1：阈值剩余秒数计算正确性**
    - 对随机合法输入验证：recoveryTime=0 时结果 ≤ 0；threshold=maxStamina 时结果等于 recoveryTime；threshold < maxStamina 时结果 < recoveryTime
    - **验证：需求 2.1、2.3、6.7**

  - [ ]\* 3.2 为 shouldReschedule 编写属性测试（属性 2）
    - 测试文件：`entry/src/test/NotificationThresholdTest.test.ets`
    - **属性 2：Recovery_Time 变化检测正确性**
    - 对随机新旧值对验证：相等时返回 false，不等时返回 true
    - **验证：需求 2.2、2.4**

  - [ ]\* 3.3 为 clampThreshold 编写属性测试（属性 7）
    - 测试文件：`entry/src/test/NotificationThresholdTest.test.ets`
    - **属性 7：阈值范围 clamp 正确性**
    - 对随机输入值验证结果始终在各游戏合法范围内
    - **验证：需求 4.4、4.5、4.6**

  - [ ]\* 3.4 为多阈值独立计算编写属性测试（属性 8）
    - 测试文件：`entry/src/test/NotificationThresholdTest.test.ets`
    - **属性 8：多阈值独立计算**
    - 对随机阈值列表验证每个阈值独立调用 calcDelaySeconds 的结果互不影响，结果集合大小等于阈值列表大小
    - **验证：需求 2.6**

  - [ ]\* 3.5 为纯函数编写示例单元测试
    - 测试文件：`entry/src/test/NotificationThresholdTest.test.ets`
    - 覆盖：原神 resin_recovery_time 字符串解析、星铁/绝区零整数解析、体力已达阈值立即通知、体力未达阈值计算、Recovery_Time 变化/未变化场景
    - _需求：2.1、2.2、2.3、6.7_

- [ ] 4. 实现 NotificationSettingsStore 持久化
  - 新建 `entry/src/main/ets/notification/NotificationSettingsStore.ets`
  - 使用 `@kit.ArkData` 的 `preferences` 模块实现单例
  - 实现 `load(): Promise<NotificationSettings>`，读取失败时返回默认值
  - 实现 `save(settings: NotificationSettings): Promise<void>`，写入失败时记录日志不崩溃
  - 实现 `getDefaults(): NotificationSettings`，返回默认值（enabled=false、style=STYLE_A、genshinThreshold=160、starRailThreshold=230、zzzThreshold=200）
  - _需求：4.8_

  - [ ]\* 4.1 为 NotificationSettingsStore 编写属性测试（属性 3）
    - 测试文件：`entry/src/test/NotificationSettingsTest.test.ets`
    - **属性 3：通知设置持久化 round-trip**
    - 对任意合法 NotificationSettings 对象，写入后读取，验证字段完全一致
    - **验证：需求 4.8**

- [ ] 5. 实现 NotificationStateStore 持久化
  - 新建 `entry/src/main/ets/notification/NotificationStateStore.ets`
  - 使用 `preferences` 模块实现单例，key 格式：`"{accountId}_{roleUid}_{gameId}_{threshold}"`
  - 实现 `load(): Promise<Map<string, NotificationStateEntry>>`
  - 实现 `save(state: Map<string, NotificationStateEntry>): Promise<void>`
  - 实现 `getEntry(key: string): Promise<NotificationStateEntry | null>`
  - 实现 `setEntry(key: string, entry: NotificationStateEntry): Promise<void>`
  - 实现 `removeEntry(key: string): Promise<void>`
  - 实现 `clear(): Promise<void>`
  - 状态数据格式损坏时清空状态重新开始，不影响设置
  - _需求：2.5_

  - [ ]\* 5.1 为 NotificationStateStore 编写属性测试（属性 4）
    - 测试文件：`entry/src/test/NotificationSettingsTest.test.ets`
    - **属性 4：通知状态持久化 round-trip**
    - 对任意合法 NotificationStateEntry 集合，写入后读取，验证 key 和 value 均完全一致
    - **验证：需求 2.5**

- [ ] 6. 实现通知内容构建函数
  - 新建 `entry/src/main/ets/notification/NotificationContentBuilder.ets`
  - 实现 `buildStyleANotification(role: GameRoleInfo): StyleAContent`，标题格式「{游戏名} · {角色昵称}」，正文格式「{体力名称}已达 {当前值}/{上限值}，请及时消耗」，附加信息格式「{服务器名} · UID {角色UID}」
  - 实现 `buildStyleBNotification(roles: GameRoleInfo[]): StyleBContent`，折叠标题「米悠悠 · {N} 项体力提醒」，展开标题「游戏体力提醒」，每行「{游戏名}：{体力名称} {当前值}/{上限值} {状态描述}」，最多 3 行
  - 实现通知 ID 哈希生成：`hash(accountId + roleUid + gameId + threshold) % 100000 + 10000`
  - _需求：3.2、3.3_

  - [ ]\* 6.1 为 buildStyleANotification 编写属性测试（属性 5）
    - 测试文件：`entry/src/test/NotificationContentBuilderTest.test.ets`
    - **属性 5：Style_A 通知格式正确性**
    - 对随机 GameRoleInfo 数据验证：标题包含游戏名和角色昵称；正文包含体力名称、当前值和上限值；附加信息包含服务器名和角色 UID
    - **验证：需求 3.2**

  - [ ]\* 6.2 为 buildStyleBNotification 编写属性测试（属性 6）
    - 测试文件：`entry/src/test/NotificationContentBuilderTest.test.ets`
    - **属性 6：Style_B 通知行数限制**
    - 对任意长度 ≥ 1 的 GameRoleInfo 列表，验证展开后行数 ≤ 3
    - **验证：需求 3.3**

- [ ] 7. 检查点 — 确保所有测试通过
  - 确保所有测试通过，如有问题请向用户提问。

- [ ] 8. 实现 StaminaNotificationService 核心服务
  - 新建 `entry/src/main/ets/notification/StaminaNotificationService.ets`
  - 实现单例模式 `static readonly instance`
  - 实现 `init(context: common.UIAbilityContext): Promise<void>`，加载持久化状态
  - 实现 `requestPermission(context: common.UIAbilityContext): Promise<boolean>`，请求 `ohos.permission.PUBLISH_AGENT_REMINDER` 权限
  - 实现 `checkPermission(): Promise<boolean>`，检查当前权限状态
  - 实现私有方法 `scheduleReminder(key, triggerTimeInSeconds, title, content, notificationId): Promise<number>`，使用 `reminderAgentManager.ReminderRequestTimer` 注册倒计时代理提醒，`wantAgent` 指向 `EntryAbility`
  - 实现 `cancelAll(): Promise<void>`，取消所有已注册的代理提醒
  - 实现 `cancelByGame(gameId: string): Promise<void>`，取消指定游戏的所有提醒
  - `cancelReminder` 失败时记录日志继续执行，`publishReminder` 失败时记录日志不更新状态快照
  - _需求：1.1、1.3、1.4、1.5、2.2、4.2、6.4、6.5_

- [ ] 9. 实现 onDailyNotesSynced 阈值检查与调度逻辑
  - 在 `StaminaNotificationService` 中实现 `onDailyNotesSynced(): Promise<void>`
  - 遍历所有账号和游戏角色，读取 DB 中的 Recovery_Time 字段（原神 `resinRecoveryTime`、星铁 `staminaRecoverTime`、绝区零 `energyRecoverTime`）
  - 对每个启用通知的游戏角色，调用 `StaminaThresholdCalculator.calcDelaySeconds` 计算剩余秒数
  - 对比 `NotificationStateStore` 中的 Recovery_Time 快照，若变化则取消旧提醒并注册新提醒
  - 剩余秒数 ≤ 0 时立即发送通知（triggerTimeInSeconds 设为 1 秒）
  - 账号未登录、便笺数据同步失败、Cookie 过期时跳过对应角色，不修改已注册提醒
  - 更新 `NotificationStateStore` 快照（存储 reminderId + recoveryTimeSnapshot）
  - _需求：2.1、2.2、2.3、2.4、2.5、2.6、2.7、2.8、6.1、6.2、6.3、6.7_

- [ ] 10. 实现 NotificationSettingsViewModel
  - 新建 `entry/src/main/ets/viewmodel/NotificationSettingsViewModel.ets`
  - 使用 `@ObservedV2` 装饰类，`@Trace` 装饰所有状态字段
  - 实现 `loadSettings(): Promise<void>`，从 `NotificationSettingsStore` 加载设置，同时检查权限状态同步 `permissionDenied`
  - 实现 `onToggleEnabled(context: common.UIAbilityContext): Promise<void>`：开启时请求权限，权限被拒则回退为 false；关闭时调用 `StaminaNotificationService.cancelAll()`
  - 实现 `onStyleChange(style: NotificationStyle): Promise<void>`，保存样式设置
  - 实现 `onGameToggle(gameId: string, enabled: boolean): Promise<void>`：关闭时调用 `cancelByGame()`
  - 实现 `onThresholdChange(gameId: string, threshold: number): Promise<void>`：调用 `clampThreshold` 限制范围，取消旧提醒，保存设置
  - 实现 `onFullValueShortcut(): Promise<void>`，将三个游戏阈值设为满值（原神 200、星铁 300、绝区零 240）
  - _需求：1.1、1.3、1.4、1.5、1.6、4.2、4.3、4.7、4.8、4.9、6.4、6.6_

  - [ ]\* 10.1 为 NotificationSettingsViewModel 编写单元测试
    - 测试文件：`entry/src/test/NotificationSettingsViewModelTest.test.ets`
    - 覆盖：初始 enabled=false、初始 style=STYLE_A、初始各游戏默认阈值、满值快捷开关设置三个游戏阈值、阈值超出上限被 clamp、阈值低于下限被 clamp
    - _需求：4.4、4.5、4.6、4.7_

- [ ] 11. 实现 NotificationSection UI 组件
  - 新建 `entry/src/main/ets/components/my/NotificationSection.ets`
  - 使用 `@ComponentV2` 实现通知设置区域组件
  - 包含「通知提醒」总开关（Toggle），开启时触发权限申请流程
  - 权限被拒时显示提示信息，引导前往系统设置（`permissionDenied=true` 时显示）
  - 包含通知样式选择控件（样式 A / 样式 B），每个选项附带示例预览文字
  - 包含原神、星铁、绝区零各游戏的独立开关和阈值输入控件（TextInput，输入时调用 `onThresholdChange`）
  - 包含「满值时通知」快捷开关
  - 总开关关闭时，游戏配置区域不可交互（灰显）
  - 在组件文件末尾添加 `@Preview` 覆盖主要状态
  - _需求：4.1、4.2、4.3、4.4、4.5、4.6、4.7、4.8_

- [ ] 12. 将 NotificationSection 集成到 My 页面
  - 修改 `entry/src/main/ets/pages/My.ets`
  - 在「外观设置」区域下方插入 `SectionHeader`（标题「通知设置」）和 `NotificationSection` 组件
  - 在 `aboutToAppear` 中调用 `vm.loadSettings()` 加载通知设置
  - 在 `entry/src/main/resources/base/element/string.json` 中添加 `my_section_notification` 字符串，并同步到 `zh_HK` 和 `en` 资源文件
  - _需求：4.1_

- [ ] 13. 将通知服务集成到 EntryAbility 和 HomeViewModel
  - 修改 `entry/src/main/ets/entryability/EntryAbility.ets`，在 `CoreInitializer.initCore()` 完成后调用 `StaminaNotificationService.instance.init(this.context)`
  - 修改 `entry/src/main/ets/viewmodel/HomeViewModel.ets`，在 `syncAllDailyNotes()` 末尾调用 `StaminaNotificationService.instance.onDailyNotesSynced()`（捕获异常，不影响主流程）
  - 同样在 `syncIfNeeded()` 完成后调用 `onDailyNotesSynced()`（用于后台定时同步场景）
  - _需求：2.1、2.2_

- [ ] 14. 检查点 — 确保所有测试通过
  - 确保所有测试通过，如有问题请向用户提问。

- [ ] 15. 注册新测试文件
  - 在 `entry/src/test/List.test.ets` 中注册 `NotificationThresholdTest`、`NotificationSettingsTest`、`NotificationContentBuilderTest`、`NotificationSettingsViewModelTest`
  - _需求：测试策略_

## 备注

- 标有 `*` 的子任务为可选测试任务，可跳过以加快 MVP 进度
- 每个任务均引用了具体需求条款，便于追溯
- 属性测试标注了对应的属性编号（来自设计文档「正确性属性」章节）
- `reminderAgentManager` 开发阶段无需 AGC 审核，直接通过 DevEco Studio 安装调试包即可测试

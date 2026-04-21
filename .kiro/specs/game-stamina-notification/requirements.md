# 需求文档

## 简介

「游戏体力通知提醒」功能为米悠悠 HarmonyOS App 新增本地通知能力，在原神树脂、崩坏：星穹铁道开拓力、绝区零电量等体力值达到用户设定阈值时，向系统通知栏推送提醒。通知仅在本地触发，不涉及任何网络请求或数据上传。

各游戏的便笺 API 会返回体力值的恢复倒计时字段，字段含义为「距离体力满值还需要多少秒」（值为 0 表示已满）：

| 游戏   | API 字段               | 类型           | 说明                                   |
| ------ | ---------------------- | -------------- | -------------------------------------- |
| 原神   | `resin_recovery_time`  | 字符串（秒数） | 如 `"22825"` 表示还需 22825 秒恢复满值 |
| 星铁   | `stamina_recover_time` | 整数（秒数）   | 如 `0` 表示已满                        |
| 绝区零 | `energy.restore`       | 整数（秒数）   | 如 `0` 表示已满                        |

本功能基于上述恢复时间字段，在每次便笺数据同步后计算体力值是否达到阈值，并使用 HarmonyOS `notificationManager` 调度定时本地通知：当 API 返回新的恢复时间时，取消旧的定时通知并重新创建，确保通知时间始终与服务器数据保持一致。

---

## 词汇表

- **通知系统（Notification_System）**：负责权限申请、通知发送、通知状态持久化的功能模块
- **通知设置页（Notification_Settings）**：My 页面中「通知设置」区域，包含总开关、样式选择、各游戏阈值配置
- **阈值检查器（Threshold_Checker）**：在每次便笺数据同步完成后，根据恢复时间字段计算体力值并与阈值比对的逻辑单元
- **恢复时间（Recovery_Time）**：API 返回的体力恢复倒计时秒数，原神对应 `resin_recovery_time`，星铁对应 `stamina_recover_time`，绝区零对应 `energy.restore`
- **定时通知（Scheduled_Notification）**：基于 Recovery_Time 计算出的未来触发时间点，提前调度到系统通知队列的本地通知
- **通知状态记录（Notification_State）**：本地持久化存储，记录每个游戏角色当前已调度的定时通知 ID 及对应的恢复时间快照，用于检测数据变化并决定是否重新调度
- **游戏角色（Game_Role）**：由账号 ID、游戏 ID、角色 UID 三元组唯一标识的游戏角色实体
- **体力值（Stamina）**：各游戏的核心消耗资源，包括原神原粹树脂（上限 200）、星铁开拓力（上限 300）、绝区零电量（上限 240）
- **满值（Full_Value）**：体力值等于该游戏对应上限时的状态
- **通知样式 A（Style_A）**：每个游戏角色独立发送一条普通文本通知
- **通知样式 B（Style_B）**：将多个游戏角色的体力状态合并为一条多行文本通知（最多 3 行）
- **通知权限（Notification_Permission）**：HarmonyOS 系统权限 `ohos.permission.NOTIFICATION_CONTROLLER`，发送本地通知的前提条件

---

## 需求

### 需求 1：通知权限申请

**用户故事：** 作为用户，我希望在开启通知提醒时能清晰了解权限用途并完成授权，以便 App 能在体力值达到阈值时及时通知我。

#### 验收标准

1. WHEN 用户在通知设置页首次将「通知提醒」总开关切换为开启状态，THE Notification_System SHALL 向用户展示权限申请说明并触发系统权限申请弹窗。

2. THE Notification_System SHALL 在权限申请说明中包含以下三项内容：
   - 通知用于在原神树脂、星铁开拓力、绝区零电量等体力值达到用户设定阈值时，向系统通知栏推送提醒，帮助用户及时消耗体力、避免溢出浪费
   - 通知完全在本地触发，基于 App 已同步到本地的便笺数据计算，不会因此产生额外的网络请求或数据上传
   - 用户可随时在系统设置中关闭通知权限，关闭后 App 内的通知开关将自动同步为关闭状态

3. WHEN 用户在权限申请弹窗中拒绝授权，THE Notification_System SHALL 将「通知提醒」总开关自动回退到关闭状态，并向用户展示提示信息说明可在系统设置中手动开启。

4. WHEN 用户之前已拒绝权限申请且选择「不再询问」，THE Notification_System SHALL 引导用户前往系统设置页面手动开启通知权限，而非再次触发系统权限弹窗。

5. WHEN 用户授权通知权限成功，THE Notification_System SHALL 将「通知提醒」总开关保持为开启状态并开始执行通知逻辑。

6. WHEN 通知权限被系统撤销（如用户在系统设置中关闭），THE Notification_Settings SHALL 在下次进入通知设置页时将「通知提醒」总开关同步显示为关闭状态。

---

### 需求 2：通知触发逻辑

**用户故事：** 作为用户，我希望 App 根据便笺 API 返回的恢复时间精确调度通知，并在体力值达到阈值时收到提醒，以便我不错过消耗体力的时机。

#### 验收标准

1. WHEN 便笺数据同步完成（包括前台手动刷新和后台定时同步），THE Threshold_Checker SHALL 读取各游戏的恢复时间字段（原神 `resin_recovery_time`、星铁 `stamina_recover_time`、绝区零 `energy.restore`），计算体力值达到用户设定阈值所需的剩余秒数，并调度对应的 Scheduled_Notification。

2. WHEN 某个 Game_Role 的便笺数据更新后，Recovery_Time 与上次调度时记录的快照不同，THE Notification_System SHALL 取消该 Game_Role 已调度的旧 Scheduled_Notification，并基于新的 Recovery_Time 重新创建 Scheduled_Notification，确保通知触发时间与服务器数据保持一致。

3. WHEN 某个 Game_Role 的体力值当前已达到或超过阈值（Recovery_Time 对应的剩余秒数 ≤ 0），THE Notification_System SHALL 立即发送通知，而非调度定时通知。

4. WHEN 某个 Game_Role 的体力值下降后（Recovery_Time 增大），THE Notification_System SHALL 取消已发送的通知记录，并重新调度新的 Scheduled_Notification，以便体力再次达到阈值时重新通知。

5. THE Notification_State SHALL 持久化存储到本地，WHEN App 重启后，THE Notification_System SHALL 读取持久化的 Notification_State，恢复已调度的 Scheduled_Notification，不重复发送已通知过的阈值。

6. WHEN 用户为某个游戏同时设置了多个阈值（如 80% 和 100%），THE Threshold_Checker SHALL 对每个阈值独立计算剩余秒数并各自调度 Scheduled_Notification。

7. WHEN 某个 Game_Role 对应的账号未登录或便笺数据同步失败，THE Threshold_Checker SHALL 跳过该 Game_Role 的阈值检查，不调度或修改已有的 Scheduled_Notification。

8. WHEN 多账号场景下存在多个 Game_Role，THE Threshold_Checker SHALL 对每个 Game_Role 独立执行阈值检查，互不影响。

---

### 需求 3：通知样式

**用户故事：** 作为用户，我希望能选择通知的展示样式，以便通知内容符合我的使用习惯。

#### 验收标准

1. THE Notification_System SHALL 支持两种通知样式：Style_A（普通文本通知）和 Style_B（多行文本通知），用户在通知设置页选择其中一种。

2. WHEN 用户选择 Style_A 且触发通知条件，THE Notification_System SHALL 为每个满足条件的 Game_Role 发送一条独立通知，通知标题格式为「{游戏名} · {角色昵称}」，正文格式为「{体力名称}已达 {当前值}/{上限值}，请及时消耗」，附加信息格式为「{服务器名} · UID {角色UID}」。

3. WHEN 用户选择 Style_B 且触发通知条件，THE Notification_System SHALL 将所有满足条件的 Game_Role 合并为一条多行文本通知，折叠时标题格式为「米悠悠 · {N} 项体力提醒」，展开时标题为「游戏体力提醒」，每行格式为「{游戏名}：{体力名称} {当前值}/{上限值} {状态描述}」，最多展示 3 行。

4. THE Notification_Settings SHALL 在样式选择区域为每种样式提供示例预览，用户可在选择前查看效果。

---

### 需求 4：通知设置页面

**用户故事：** 作为用户，我希望在 My 页面中找到通知设置入口，并能方便地配置各游戏的通知阈值，以便精细控制通知行为。

#### 验收标准

1. THE Notification_Settings SHALL 作为独立区域显示在 My 页面「外观设置」区域的下方，区域标题为「通知设置」。

2. THE Notification_Settings SHALL 包含「通知提醒」总开关，WHEN 总开关关闭时，THE Notification_System SHALL 取消所有已调度的 Scheduled_Notification 并停止后续通知发送。

3. THE Notification_Settings SHALL 包含通知样式选择控件，提供「样式 A（普通文本）」和「样式 B（多行文本）」两个选项，每个选项附带示例预览。

4. THE Notification_Settings SHALL 包含原神树脂阈值配置项，默认值为 160，可配置范围为 1 至 200 的整数，并提供该游戏通知的独立开关。

5. THE Notification_Settings SHALL 包含星铁开拓力阈值配置项，默认值为 230，可配置范围为 1 至 300 的整数，并提供该游戏通知的独立开关。

6. THE Notification_Settings SHALL 包含绝区零电量阈值配置项，默认值为 200，可配置范围为 1 至 240 的整数，并提供该游戏通知的独立开关。

7. THE Notification_Settings SHALL 包含「满值时通知」快捷开关，WHEN 用户开启该快捷开关，THE Notification_Settings SHALL 将所有游戏的阈值同时设置为对应游戏的满值（原神 200、星铁 300、绝区零 240）。

8. WHEN 用户修改任意配置项，THE Notification_Settings SHALL 立即持久化保存该配置，App 重启后配置保持不变。

9. WHEN 用户修改某游戏的阈值，THE Notification_System SHALL 取消该游戏所有 Game_Role 已调度的旧 Scheduled_Notification，并在下次便笺数据同步时基于新阈值重新调度。

---

### 需求 5：通知点击行为

**用户故事：** 作为用户，我希望点击通知后能直接跳转到对应游戏的便笺详情页，以便快速查看当前体力状态。

#### 验收标准

1. WHEN 用户点击 Style_A 通知，THE Notification_System SHALL 打开 App 并跳转到该通知对应 Game_Role 所属游戏的便笺详情页。

2. WHEN 用户点击 Style_B 通知，THE Notification_System SHALL 打开 App 并跳转到 App 首页（Home Tab）。

3. WHEN App 已在前台运行时用户点击通知，THE Notification_System SHALL 直接在当前 App 内导航到对应页面，不重新启动 App。

4. WHEN App 在后台运行时用户点击通知，THE Notification_System SHALL 将 App 切换到前台并导航到对应页面。

---

### 需求 6：边界情况处理

**用户故事：** 作为用户，我希望通知功能在各种异常情况下能稳定运行，不出现误通知或崩溃。

#### 验收标准

1. WHEN 用户未登录任何账号，THE Threshold_Checker SHALL 跳过所有阈值检查，不调度任何 Scheduled_Notification。

2. WHEN 网络同步失败导致便笺数据未更新，THE Threshold_Checker SHALL 不修改已调度的 Scheduled_Notification，保持上次同步时的调度状态不变。

3. WHEN 多账号场景下某个账号的 Cookie 已过期，THE Threshold_Checker SHALL 跳过该账号下所有 Game_Role 的阈值检查，不影响其他账号的通知逻辑。

4. WHEN 某个游戏的独立通知开关关闭，THE Notification_System SHALL 取消该游戏所有 Game_Role 已调度的 Scheduled_Notification，并跳过后续该游戏的阈值检查。

5. IF 通知权限在 App 运行期间被系统撤销，THEN THE Notification_System SHALL 捕获发送失败的错误，不崩溃，并在下次进入通知设置页时将总开关同步为关闭状态。

6. WHEN 用户在通知设置页将某游戏阈值修改为新值，THE Notification_System SHALL 取消该游戏所有 Game_Role 在旧阈值上已调度的 Scheduled_Notification，以便新阈值生效后能正常调度新通知。

7. WHEN 便笺 API 返回的 Recovery_Time 为 0（体力已满），THE Threshold_Checker SHALL 判断当前体力值是否已达到阈值，若是则立即发送通知，不再调度定时通知。

---

## 测试策略

### 单元测试（`entry/src/test/`）

单元测试覆盖纯逻辑，不依赖设备或真实通知系统，在本地直接运行。

#### 阈值计算逻辑测试

测试文件：`NotificationThresholdTest.test.ets`

| 测试用例                              | 输入                                       | 预期结果                               |
| ------------------------------------- | ------------------------------------------ | -------------------------------------- |
| 原神 `resin_recovery_time` 字符串解析 | `"22825"`                                  | 解析为 22825 秒                        |
| 星铁 `stamina_recover_time` 整数解析  | `0`                                        | 解析为 0 秒（已满）                    |
| 绝区零 `energy.restore` 整数解析      | `3600`                                     | 解析为 3600 秒                         |
| 体力值已达阈值（Recovery_Time = 0）   | 当前值 200，阈值 160                       | 应立即通知，不调度定时通知             |
| 体力值未达阈值                        | 当前值 140，阈值 160，Recovery_Time = 2400 | 应调度 2400 秒后触发的定时通知         |
| 多阈值独立计算                        | 阈值 [160, 200]，当前值 180                | 160 阈值立即通知，200 阈值调度定时通知 |
| Recovery_Time 变化触发重新调度        | 旧快照 3600，新值 2400                     | 取消旧通知，调度新通知                 |
| Recovery_Time 未变化不重新调度        | 旧快照 3600，新值 3600                     | 不取消，不重新调度                     |
| 体力下降后重置通知状态                | 旧 Recovery_Time 0（已满），新值 7200      | 清除已通知记录，重新调度               |

#### 通知设置持久化测试

测试文件：`NotificationSettingsTest.test.ets`

| 测试用例         | 操作               | 预期结果                           |
| ---------------- | ------------------ | ---------------------------------- |
| 默认阈值正确     | 读取初始配置       | 原神 160，星铁 230，绝区零 200     |
| 阈值修改持久化   | 修改原神阈值为 180 | 重启后读取仍为 180                 |
| 总开关关闭持久化 | 关闭总开关         | 重启后总开关仍为关闭               |
| 满值快捷开关     | 开启「满值时通知」 | 三个游戏阈值分别变为 200、300、240 |

---

### Mock 环境测试（`entry/src/ohosTest/`）

Mock 环境测试在模拟器上运行，使用项目已有的 Mock 便笺数据（`core/src/mock/resources/rawfile/mock/`）验证完整通知流程，无需真实网络请求。

#### 如何在 Mock 环境下触发通知

由于通知依赖 Recovery_Time 计算触发时间，Mock 环境下需要修改 Mock JSON 文件中的恢复时间字段来模拟不同场景：

**场景 1：体力已满，立即通知**

修改 `core/src/mock/resources/rawfile/mock/182692936/109050292/game_record_app_genshin_api_dailyNote.json`：

```json
"current_resin": 200,
"resin_recovery_time": "0"
```

预期：同步后立即收到原神树脂满值通知。

**场景 2：体力接近阈值，调度短时定时通知**

修改原神 Mock JSON：

```json
"current_resin": 158,
"resin_recovery_time": "120"
```

预期：同步后 120 秒内收到通知（阈值设为 160 时，2 格树脂 = 2 × 8 分钟 = 480 秒，但此处 Recovery_Time 直接给出剩余秒数）。

**场景 3：Recovery_Time 更新触发重新调度**

第一次同步使用 `"resin_recovery_time": "3600"`，第二次同步改为 `"resin_recovery_time": "1800"`，预期：第二次同步后旧通知被取消，新通知被调度。

**场景 4：星铁开拓力满值**

修改 `core/src/mock/resources/rawfile/mock/182692936/102731382/game_record_app_hkrpg_api_note.json`：

```json
"current_stamina": 300,
"stamina_recover_time": 0
```

预期：同步后立即收到星铁开拓力满值通知。

**场景 5：绝区零电量满值**

修改 `core/src/mock/resources/rawfile/mock/182692936/37716744/event_game_record_zzz_api_zzz_note.json`：

```json
"energy": {
  "progress": { "max": 240, "current": 240 },
  "restore": 0
}
```

预期：同步后立即收到绝区零电量满值通知。

#### Mock 环境 UI 测试用例

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

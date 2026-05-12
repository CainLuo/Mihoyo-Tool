# Form Kit（服务卡片）技术调研笔记

调研日期：2026-04-27
适用版本：V1.1.0

---

## 一、核心概念

### 三个角色

| 角色                           | 说明                                    |
| ------------------------------ | --------------------------------------- |
| Widget Provider（卡片提供方）  | 本 App，负责卡片 UI、数据更新、点击响应 |
| Widget Host（卡片使用方）      | 桌面/锁屏等系统应用，负责展示卡片       |
| Widget Manager（卡片管理服务） | 系统服务，作为两者之间的桥梁            |

### 两个关键类

- `FormExtensionAbility`：卡片生命周期管理（`onAddForm`、`onUpdateForm`、`onRemoveForm` 等）
- `formProvider`：主动推送数据更新给卡片（`formProvider.updateForm(formId, data)`）

---

## 二、文件结构

```
entry/
  src/main/ets/
    entryformability/
      EntryFormAbility.ets      ← 继承 FormExtensionAbility，处理卡片生命周期
    widget/
      pages/
        WidgetCard.ets          ← 卡片 UI（ArkTS 声明式，受限子集）
  src/main/resources/
    base/profile/
      form_config.json          ← 卡片配置（尺寸、更新频率、是否动态等）
module.json5                    ← 注册 extensionAbilities（type: "form"）
```

---

## 三、卡片配置（form_config.json）关键字段

```json
{
  "forms": [
    {
      "name": "widget",
      "src": "./ets/widget/pages/WidgetCard.ets",
      "uiSyntax": "arkts",
      "isDynamic": true,
      "updateEnabled": true,
      "updateDuration": 1,
      "scheduledUpdateTime": "10:30",
      "defaultDimension": "2*2",
      "supportDimensions": ["2*2", "2*4", "4*4"],
      "colorMode": "auto"
    }
  ]
}
```

> `updateDuration` 单位是 30 分钟，`1` = 30 分钟，最小值为 1（即最快 30 分钟更新一次）

---

## 四、数据更新的三种方式

| 方式                                 | 触发时机                         | 适用场景         |
| ------------------------------------ | -------------------------------- | ---------------- |
| `onUpdateForm` 定时回调              | 系统按 `updateDuration` 定时触发 | 周期性刷新体力值 |
| `formProvider.updateForm()` 主动推送 | App 在前台或后台任务中主动调用   | 体力满时立即更新 |
| `postCardAction` message 事件        | 用户点击卡片触发                 | 用户手动刷新     |

**对于体力 Widget 的推荐方案**：结合已有的 `StaminaNotificationService`，在体力变化时同时调用 `formProvider.updateForm()` 推送最新数据。

---

## 五、卡片 UI 限制（重要）

ArkTS 卡片不是完整的 ArkUI，有以下限制：

**不支持：**

- `setTimeout` / `setInterval`
- 网络请求（不能在卡片内直接发请求）
- 数据库访问（不能在卡片内直接读 RDB）
- HSP 导入（只能导入 HAR）
- 即时预览、断点调试、热重载

**支持（相比 JS 卡片的优势）：**

- 属性动画、显式动画
- `Canvas` 自定义绘制
- 逻辑代码执行（可以在卡片内写业务逻辑）

**状态管理：**

- 用 `@LocalStorageProp` 接收来自 `formProvider` 推送的数据
- 不能用 `@State` 直接绑定外部数据源

---

## 六、与本项目的集成要点

1. **数据来源**：卡片不能直接访问 RDB，数据必须由 `EntryFormAbility.onUpdateForm` 从 `core` 层读取后通过 `formProvider.updateForm()` 推送
2. **多账号问题**：需要在卡片配置或用户设置中确定「显示哪个账号哪个游戏」的体力
3. **与通知服务协同**：`StaminaNotificationService` 已有定时检测逻辑，可以在同一个地方同时更新卡片
4. **打包注意**：不能用「Deploy Multi Hap Packages」方式打包，否则卡片不显示内容

---

## 七、卡片尺寸规格

官方文档：[配置ArkTS卡片的配置文件 - supportDimensions 字段](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-configuration)

### 7.1 FormDimension 枚举（官方 API 定义）

根据官方 API 参考 `FormDimension` 枚举，定义如下：

| 枚举值            | 尺寸   | 说明                             | 可用版本 |
| ----------------- | ------ | -------------------------------- | -------- |
| `Dimension_1_1`   | 1×1    | 一宫格，仅支持锁屏               | API 11+  |
| `Dimension_1_2`   | 1×2    | 二宫格                           | API 7+   |
| `Dimension_2_1`   | 2×1    | 二宫格（横向）                   | API 9+   |
| `Dimension_2_2`   | 2×2    | 四宫格                           | API 7+   |
| `Dimension_2_3`   | 2×3    | 六宫格，仅支持手表设备           | API 18+  |
| `Dimension_2_4`   | 2×4    | 八宫格                           | API 7+   |
| `Dimension_3_3`   | 3×3    | 九宫格，仅支持手表设备           | API 18+  |
| `Dimension_4_4`   | 4×4    | 十六宫格                         | API 7+   |
| `Dimension_6_4`   | 6×4    | 二十四宫格                       | API 12+  |

### 7.2 尺寸是网格单位，不是固定 vp

**关键**：卡片尺寸（如 `2*2`）是**网格单位**，实际渲染尺寸（vp）由系统根据设备屏幕大小和网格配置动态计算。

- 不同设备的相同尺寸卡片，实际 vp 可能不同
- 卡片 UI 应使用百分比布局（`width: '100%'`）或相对布局（`layoutWeight`）
- 不要硬编码具体的 vp 宽高值

### 7.3 卡片 UI 布局规范（官方推荐）

官方文档虽然没有提供具体的 vp 尺寸，但提供了以下布局原则：

**1. 使用 100% 宽高**

卡片根容器应使用 `width: '100%'` 和 `height: '100%'`，让系统自动填充实际渲染区域。

```typescript
Column() {
  // 内容
}
.width('100%')
.height('100%')
```

**2. 使用相对布局（layoutWeight）**

对于内部元素，使用 `layoutWeight` 分配剩余空间，而不是硬编码尺寸：

```typescript
Column() {
  // 固定高度的标题
  Row() { /* 标题 */ }
    .height(40)  // 固定值可以用于内部元素

  // 撑满剩余空间的内容
  Column() { /* 内容 */ }
    .layoutWeight(1)  // 相对布局
}
```

**3. 字体大小和间距的适配**

官方 FAQ 提到：**卡片字体大小、边距不会自动适配**，需要开发者自行调配。

推荐的适配策略：
- 字体大小：使用固定的 vp 值（如 `fontSize: 12`），在大多数设备上可读
- 间距：使用固定值（如 `padding: 12`），四周保留 12vp 安全间距
- 容器尺寸：使用百分比或 `layoutWeight`

**4. 四周保留 12vp 安全间距**

官方规范要求：服务卡片内请保留四周各 **12vp** 的安全间距，避免内容被圆角剪裁。

```typescript
Column() {
  // 内容
}
.padding(12)  // 四周 12vp 安全间距
.borderRadius(16)  // 圆角
```

**5. 不同尺寸的布局差异**

不同网格尺寸的卡片，应设计不同的布局，而不是简单缩放：

| 尺寸  | 布局策略                                   |
| ----- | ------------------------------------------ |
| 1×2   | 单行横向布局，体力环 + 数值 + 时间         |
| 2×2   | 纵向布局，体力环居中，下方数据行           |
| 2×4   | 左右分栏，体力环在左，数据在右             |
| 4×4   | 完整布局，接近 App 内 GameToolCard 的样式  |

**6. @Preview 中的尺寸仅供参考**

在 DevEco Studio 的 `@Preview` 中使用的尺寸（如 `width: 168`）只是预览参考值，实际渲染尺寸由系统决定。

### 7.2 X7 模拟器实测尺寸（API 18）

> 测试日期：2026-05-03
> 测试设备：X7 模拟器（Phone 模式）
> 测量方法：在组件 `onAreaChange` 回调中获取实际渲染区域

| 尺寸 | 内容区域尺寸 (vp) | 含 12vp padding 后 (vp) | 备注 |
|------|------------------|------------------------|------|
| **1×2** | 121.9 × 27.8 | 约 146 × 52 | 迷你卡片，单行布局 |
| **2×2** | 121.9 × 121.9 | 约 146 × 146 | 正方形 |
| **2×4** | 290.6 × 121.9 | 约 315 × 146 | 宽幅 |
| **4×4** | 290.6 × 309.8 | 约 315 × 334 | 大卡片 |

**重要说明**：
1. 内容区域尺寸 = `WidgetCardContent` / `Widget1x2Content` 组件的实际渲染尺寸
2. 含 padding 后尺寸 = 内容区域 + 外层 padding（左右各 12vp，上下可能不等）
3. **尺寸由系统动态计算**，不同设备、不同分辨率下可能略有差异
4. 设计时应使用 `width: '100%'` + `height: '100%'`，不要硬编码具体数值

### 7.2.1 官方字号规范（卡片内容设计）

> 来源：[服务卡片设计指南 - 卡片字体](https://developer.huawei.com/consumer/cn/doc/design-guides/system-features-service-widget-0000002087671904)

**桌面 1×2 卡片字号**：
- 主标题：14fp
- 副标题：12fp
- 数字：20fp

**桌面 2×2 卡片字号**：
- 主标题：14fp、18fp
- 副标题、辅助信息：12fp
- 数字：32fp、40fp

**关键原则**：
1. **卡片字体大小、边距等需自行调配，不会自动适配大小**
2. **四周各保留 12vp 安全间距**（圆角剪裁时避免内容被裁切）
3. **卡片内尽量避免使用大字号**
4. **使用百分比布局**：`width: '100%'` + `height: '100%'` + `layoutWeight`

**字号适配限制**：
- 超过 20fp 的字号不响应大字体和适老化
- 锁屏卡片的文字字号不响应大字体和适老化
- 卡片字体适配控制在最大 1.3 倍以下

### 7.3 手机/平板可用尺寸

| 尺寸  | 适用位置           | 本项目支持 |
| ----- | ------------------ | ---------- |
| `1*1` | 仅锁屏             | ❌ 不支持  |
| `1*2` | 桌面、负一屏、锁屏 | ✅ 支持    |
| `2*1` | 桌面、负一屏       | ❌ 不支持  |
| `2*2` | 桌面、负一屏       | ✅ 支持    |
| `2*4` | 桌面、负一屏       | ✅ 支持    |
| `4*4` | 桌面、负一屏       | ✅ 支持    |
| `6*4` | 桌面、负一屏       | ❌ 不支持  |
| `2*3` | 仅手表             | ❌ 不支持  |
| `3*3` | 仅手表             | ❌ 不支持  |

本项目 V1.1 支持：`1*2`、`2*2`、`2*4`、`4*4` 共 4 种尺寸。

---

## 八、设计决策（已确认）

### 核心模型

- **卡片模板**：`form_config.json` 里静态配置，上限 16 个，决定卡片的游戏类型和尺寸
- **卡片实例**：用户每次添加到桌面产生一个新 `formId`，同一模板可无限次添加
- **每个实例独立**：绑定 1 个账号 + 选定游戏，通过 Preferences 存储配置，互不干扰

**典型场景**：3 个账号都有原神，用户可以添加 3 张原神 1×2 卡片，桌面同时显示 3 个账号各自的原神体力数据。

**动态添加入口**：App 内「添加 Widget」页面根据已登录账号数量动态展示，每个账号一个入口，点击时通过 `openFormManager` 的 `want.parameters` 携带 `accountId`，`onAddForm` 读取后存入 Preferences。

---

### 决策 1：1×2 迷你（3 个独立模板）

每款游戏一个独立模板，布局针对该游戏定制：

| 模板名                | 显示内容                                          |
| --------------------- | ------------------------------------------------- |
| `widget_1x2_genshin`  | UID + 体力环 + 原粹树脂数值 + 回满时间            |
| `widget_1x2_starrail` | UID + 体力环 + 开拓力数值 + 后备开拓力 + 回满时间 |
| `widget_1x2_zzz`      | UID + 体力环 + 电量数值 + 回满时间                |

多账号：同一模板添加多张，每张绑定不同账号，桌面可同时显示多个账号的同款游戏数据。

---

### 决策 2：2×2 / 2×4 / 4×4（各 1 个模板，游戏数量自动切换布局）

**核心规律**：游戏数量决定显示密度，无需手动切换。

| 游戏数 | 布局模式           | 说明                                    |
| ------ | ------------------ | --------------------------------------- |
| 1 款   | 详细模式           | 基础信息 + 额外数据行，行数由尺寸决定   |
| 2-3 款 | 精简模式，纵向排列 | 基础信息为主，空间允许时加 1 行额外数据 |

**各尺寸详细模式（单游戏）的额外数据行数**：

| 尺寸  | 额外数据行数                      | 布局                   |
| ----- | --------------------------------- | ---------------------- |
| `2*2` | 2 行                              | 体力环居中，下方数据行 |
| `2*4` | 4-5 行                            | 左侧体力环，右侧数据行 |
| `4*4` | 全量（接近 Home 页 GameToolCard） | 左侧体力环，右侧数据行 |

**各游戏的额外数据内容（按尺寸）**：

**1×2 迷你**（基础信息）：

| 游戏   | 显示内容                                                                  |
| ------ | ------------------------------------------------------------------------- |
| 原神   | UID + 体力环 + 原粹树脂数值 + 回满时间                                    |
| 星铁   | UID + 体力环 + 开拓力数值 + **后备开拓力** + 回满时间（星铁特殊，多一项） |
| 绝区零 | UID + 体力环 + 电量数值 + 回满时间                                        |

**2×2 标准**（单游戏额外数据）：

| 游戏   | 额外数据                                      |
| ------ | --------------------------------------------- |
| 原神   | 探索派遣（x/5）、每日委托（x/4 + 是否已领取） |
| 星铁   | 每日实训（x/500）                             |
| 绝区零 | 今日活跃度（x/400）、刮刮卡/占卜状态          |

**2×4 宽幅**（单游戏额外数据，左右分栏，右侧约 4-5 行）：

| 游戏   | 额外数据                                                       |
| ------ | -------------------------------------------------------------- |
| 原神   | 洞天财瓮（x/2400）、每日委托（x/4）、参量质变仪（可用/倒计时） |
| 星铁   | 后备开拓力、每日实训（x/500）、历战余响（x/3）                 |
| 绝区零 | 今日活跃度（x/400）、刮刮卡/占卜状态、录像店经营状态           |

**4×4 大卡片**（单游戏完整数据）：

| 游戏   | 额外数据                                                                                             | 特殊说明                                                      |
| ------ | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| 原神   | 洞天财瓮、每日委托、参量质变仪                                                                       | 底部显示探索派遣 5 个角色头像（圆形，5等分，已完成有 ✓ 标记） |
| 星铁   | 后备开拓力（体力区显示）、每日实训、历战余响、货币战争本周积分（x/1000）、模拟宇宙本周积分（x/1000） | —                                                             |
| 绝区零 | 今日活跃度（x/400）、刮刮卡/占卜状态、录像店经营状态                                                 | —                                                             |

**精简模式（多游戏）的布局**：纵向排列，每款游戏一行。

- 2×4：2款游戏可加 1 行额外数据，3款游戏右侧显示第一条额外数据（内联在同一行）
- 4×4：2款游戏可加 3 行额外数据，3款游戏可加 2 行额外数据

---

### 决策 3：卡片模板数量规划

| 模板名                | 尺寸  | 说明                         |
| --------------------- | ----- | ---------------------------- |
| `widget_1x2_genshin`  | `1*2` | 原神迷你，桌面+负一屏+锁屏   |
| `widget_1x2_starrail` | `1*2` | 星铁迷你，桌面+负一屏+锁屏   |
| `widget_1x2_zzz`      | `1*2` | 绝区零迷你，桌面+负一屏+锁屏 |
| `widget_2x2`          | `2*2` | 标准，桌面+负一屏            |
| `widget_2x4`          | `2*4` | 宽幅，桌面+负一屏            |
| `widget_4x4`          | `4*4` | 大卡片，桌面+负一屏          |

共 6 个模板，远低于 16 的上限。锁屏使用 1×2 的三个模板（需配置 `renderingMode: autoColor`）。

---

### 决策 4：更新频率

- `updateDuration=1`（每 30 分钟定时刷新）作为兜底
- 同时在 `StaminaNotificationService` 检测到体力数据变化时，调用 `formProvider.updateForm()` 主动推送
- 在 `onAddForm` 时立即推送一次初始数据（避免第一次刷新最多 30 分钟偏差，见 12.19）

### 已确认的位置支持

- ✅ **桌面** — 标准卡片，无额外要求
- ✅ **负一屏** — 同一套代码，通过 `openFormManager` 让用户自选（见第十节）
- ✅ **锁屏** — 使用 1×2 三个模板，`renderingMode: autoColor`，同步申请 AppGallery Connect 开放能力

---

## 十、卡片添加位置说明

### 桌面 + 负一屏（同一套代码，无需额外配置）

官方文档：[应用内拉起卡片管理加桌（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-open-formmanager)

通过 `formProvider.openFormManager(want)` 拉起卡片管理页面后，用户可以自行选择：

- **添加至桌面**
- **添加至负一屏**

两者使用同一套卡片代码，**不需要任何额外配置**，只需在 App 内提供一个入口按钮调用 `openFormManager` 即可。

```typescript
// 在 My 页面或设置页面提供"添加卡片"入口
formProvider.openFormManager({
  bundleName: "com.cainluo.miyoyo.tools",
  abilityName: "EntryFormAbility",
  parameters: {
    "ohos.extra.param.key.form_dimension": 2, // 2*2
    "ohos.extra.param.key.form_name": "widget",
    "ohos.extra.param.key.module_name": "entry",
  },
});
```

### 锁屏（需要额外申请开放能力）

官方文档：[锁屏卡片开发指导（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-lockscreen-form-development)

锁屏卡片有以下**额外要求**：

1. **尺寸限制**：只支持 `1*1` 和 `1*2`，不支持其他尺寸
2. **渲染模式**：`renderingMode` 必须配置为 `"singleColor"` 或 `"autoColor"`，不能用 `"fullColor"`
3. **需要申请开放能力**：在 AppGallery Connect 的「开放能力接入」页面申请「锁屏卡片」能力，审批需 1-3 个工作日
4. **必须手动签名**：不能用自动签名，需要在申请 Profile 时勾选锁屏卡片能力

**结论**：锁屏卡片代码在 V1.1 一并实现，同时去 AppGallery Connect 申请开放能力（审批 1-3 个工作日）。能力审批通过后即可上线锁屏卡片功能。

### V1.1 目标位置

- ✅ **桌面** — 标准卡片，无额外要求
- ✅ **负一屏** — 同一套代码，通过 `openFormManager` 让用户自选
- ✅ **锁屏** — 代码在 V1.1 实现，同步申请开放能力；能力审批通过后生效

## 十二、重要补充（来自官方最佳实践和生命周期文档）

### 12.1 FormExtensionAbility 生命周期限制（关键）

官方文档：[管理ArkTS卡片生命周期（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-lifecycle)

> **FormExtensionAbility 进程不能常驻后台**，生命周期回调完成后会继续存在 **10 秒**，若 10 秒内未收到新的生命周期回调，进程将自动退出。

**影响**：在 `onUpdateForm` 里不能做超过 10 秒的操作（如网络请求）。如果需要从数据库读取体力数据，必须确保在 10 秒内完成，否则需要拉起主应用处理后再用 `updateForm` 通知卡片刷新。

对于本项目：体力数据已在本地 RDB 中，读取速度远小于 10 秒，**不受此限制影响**。

### 12.2 定时刷新每日上限（关键）

官方最佳实践文档：[卡片更新与数据交互（官方）](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-card-update-and-data-interaction)

> 每张卡片每天最多通过定时方式触发刷新 **50 次**，达到上限后无法再触发，次数在每天 0 点重置。

**影响**：`updateDuration=1`（30 分钟一次）× 24 小时 = 48 次/天，在上限内。但如果设置更短间隔（如 `updateDuration=0` + `setFormNextRefreshTime`），需注意不要超过 50 次。

### 12.3 卡片 ID 管理（重要）

从最佳实践文档得到的关键信息：

- **弹出卡片预览弹窗时**，所有卡片都会触发 `onAddForm()`
- **关闭弹窗或息屏时**，会触发所有卡片的 `onRemoveForm()`
- **点击「添加至桌面」时**，只有被添加的卡片保留，其他卡片触发 `onRemoveForm()`

**结论**：必须在 `onAddForm` 时保存 formId 到持久化存储（Preferences），在 `onRemoveForm` 时删除。从主应用调用 `formProvider.updateForm()` 时需要用到这些 formId。

### 12.4 从主应用更新卡片的正确方式

当体力数据在主应用（UIAbility）中更新时，需要：

1. 在 `onAddForm` 时将 formId 存入 Preferences
2. 在 `onRemoveForm` 时从 Preferences 删除 formId
3. 主应用更新数据后，从 Preferences 读取所有 formId，遍历调用 `formProvider.updateForm()`

这与本项目的 `StaminaNotificationService` 协同的方式完全一致。

### 12.5 定时刷新与定点刷新不能同时生效

> 当同时配置了 `updateDuration` 和 `scheduledUpdateTime` 时，`updateDuration` 优先级更高，`scheduledUpdateTime` 不生效。

要使用定点刷新，必须将 `updateDuration` 设为 0。

### 12.6 需要后台运行权限

使用 `call` 事件（从卡片拉起应用至后台）时，需要申请权限：

```json
{
  "name": "ohos.permission.KEEP_BACKGROUND_RUNNING"
}
```

本项目已在 `StaminaNotificationService` 中使用了后台任务，此权限应已申请。

### 12.7 卡片进程与主应用进程内存隔离（关键）

官方文档：[ArkTS卡片进程模型（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-process)

> 应用主进程（UIAbility）和卡片进程（FormExtensionAbility）**内存隔离**，但共享相同的文件沙箱。

**影响**：

- 卡片进程不能直接访问主进程的内存变量
- 两个进程之间共享文件沙箱，所以可以通过 **Preferences（首选项）** 共享数据
- 这就是为什么 formId 要存到 Preferences 而不是内存变量

### 12.8 卡片 UI 支持 V2 装饰器（重要）

官方 FAQ：[ArkTS卡片适配常见问题（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-adapt-faq)

> ArkTS卡片开发**支持 V2 装饰器**（如 `@ObservedV2`、`@ComponentV2`），建议使用 V2 替代 V1 以获得更优的渲染性能。

**影响**：本项目整体已使用 V2 装饰器，卡片 UI 也可以直接用 `@ComponentV2`，不需要降级到 V1。

### 12.9 FormExtensionAbility 不能导入特定模块（避坑）

官方 FAQ：[ArkTS卡片适配常见问题（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-adapt-faq)

> `FormExtensionAbility` **不支持**加载以下模块，强行导入会导致 JS crash：
>
> - `particleAbility`
> - `audio`
> - `camera`
> - `media`
> - `backgroundTaskManager`

**影响**：`EntryFormAbility.ets` 的导入链必须与主应用代码严格隔离，不能 import 任何使用了上述模块的文件。本项目的 `StaminaNotificationService` 使用了 `backgroundTaskManager`，**绝对不能在 EntryFormAbility 中 import 它**。

### 12.10 卡片深浅色适配

官方 FAQ 提到卡片支持深浅色适配，参考：[应用深浅色适配（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ui-dark-light-color-adaptation)

卡片 UI 中使用 `$r('app.color.xxx')` 引用颜色资源，配合 `dark/element/color.json` 即可自动适配深浅色，与主应用的 Theme 机制一致。

### 12.11 多尺寸 UI 适配方案（重要）

官方文档：[如何根据不同尺寸的卡片适配不同的UI（官方）](https://developer.huawei.com/consumer/cn/doc/architecture-guides/tools-v1_2-ts_386-0000002553335253)

在 `onAddForm` 中通过 `want.parameters[formInfo.FormParam.DIMENSION_KEY]` 获取卡片尺寸，传给卡片 UI，在 UI 中根据尺寸渲染不同布局：

```typescript
// EntryFormAbility.ets
onAddForm(want: Want) {
  const dimension = want.parameters?.[formInfo.FormParam.DIMENSION_KEY];
  return formBindingData.createFormBindingData({ dimension: String(dimension) });
}

// WidgetCard.ets
@LocalStorageProp('dimension') dimension: string = '';
// 根据 dimension 值渲染不同 UI
```

### 12.12 卡片四周必须保留 12vp 安全间距

> 服务卡片内请保留四周各 **12vp** 的安全间距，避免内容被圆角剪裁。

卡片字体大小、边距**不会自动适配**，需要开发者自行调配。

### 12.13 卡片尺寸不支持自定义，建议规划多尺寸

> Form Kit 不支持自定义卡片大小，卡片加桌后尺寸固定。建议在创建卡片时就规划多个尺寸，以支持用户选择不同大小的卡片。

**建议**：V1.1 至少支持 `2*2` 和 `2*4` 两种尺寸，让用户可以选择。

### 12.14 卡片五元组升级注意事项（关键）

来自配置文件文档的说明：

> 卡片五元组（bundleName + moduleName + abilityName + formName + formDimension）是确认卡片唯一的要素。**如果应用升级后五元组有改变，系统中对应的卡片会被删除，在屏幕上会消失。**

**影响**：

- 不要随意修改 `form_config.json` 中的 `name` 字段
- 不要修改 `EntryFormAbility` 的 `name`
- 不要修改 `module.json5` 中的 `name`（moduleName）
- 五元组字段**不建议使用资源文件引用**，因为资源文件新增字段会导致 ID 变化，被认为五元组改变

### 12.15 core 模块（HSP）不能在卡片中使用

来自 ArkTS 卡片约束（第五节已提到）：

> ArkTS 卡片可以导入 HAR，但**不能导入 HSP**。

本项目的 `core` 模块是 HSP（动态共享包），**卡片代码不能直接 import core 模块的任何内容**。

**影响**：

- 卡片 UI（`WidgetCard.ets`）不能 import core
- `EntryFormAbility.ets` 不能 import core（否则会通过 core 间接引入不支持的模块）
- 需要在 `entry` 模块内单独实现卡片所需的数据读取逻辑，或通过 Preferences 传递数据

### 12.16 卡片事件三种类型（重要）

官方文档：[ArkTS卡片页面交互概述（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-event-overview)

动态卡片通过 `postCardAction` 触发三种事件：

| 事件类型  | 触发目标                      | 适用场景                         |
| --------- | ----------------------------- | -------------------------------- |
| `router`  | 跳转到指定 UIAbility（前台）  | 点击卡片打开 App 对应页面        |
| `call`    | 拉起指定 UIAbility 到**后台** | 后台执行操作，不打开 App 界面    |
| `message` | 拉起 FormExtensionAbility     | 卡片内点击刷新按钮，触发数据更新 |

**对于体力 Widget**：

- 点击卡片跳转到 App 首页 → 用 `router` 事件
- 卡片内刷新按钮 → 用 `message` 事件触发 `onFormEvent`，在里面调用 `formProvider.updateForm()`

**注意**：非系统应用的 `router` 事件**只能跳转到自己应用内的 UIAbility**，不能跳转到其他应用。

### 12.17 卡片数据传递只能用 LocalStorageProp，且数据会转为 string（关键）

官方文档：[ArkTS卡片页面刷新概述（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-interaction-overview)

> 卡片提供方和卡片为相互独立的进程，两者间的数据共享**只能通过 `LocalStorageProp` 传递**，不能使用 `getContext` 方法。且**接收数据时，卡片数据会被转换成 string 类型**。

**影响**：所有传给卡片的数字（如体力值 160）都会变成字符串 `"160"`，需要在卡片 UI 里用 `parseInt()` 或 `Number()` 转换。

### 12.18 定时刷新只在卡片可见时触发

官方文档：[ArkTS卡片被动刷新（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-passive-refresh)

> 定时刷新和定点刷新**在卡片可见情况下才会触发**，在卡片不可见时仅会记录刷新动作和刷新数据，待可见时统一刷新布局。

**影响**：用户把卡片翻到看不见的屏幕时，定时刷新不会实时触发，等用户翻回来才会刷新。对于体力数据这是可以接受的。

### 12.19 定时刷新第一次有最多 30 分钟偏差

官方文档：[ArkTS卡片被动刷新（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-passive-refresh)

> 当前定时刷新使用同一个计时器进行计时，因此卡片定时刷新的**第一次刷新会有最多 30 分钟的偏差**。

**影响**：用户刚添加卡片时，可能需要等待最多 30 分钟才会第一次定时刷新。建议在 `onAddForm` 时立即推送一次初始数据。

### 12.20 setFormNextRefreshTime 最短 5 分钟

官方文档：[ArkTS卡片被动刷新（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-passive-refresh)

> `setFormNextRefreshTime` 接口设置下次刷新时间，**最短刷新时间为 5 分钟**。

**影响**：如果想在体力值变化时立即更新卡片，应该用主动刷新（`formProvider.updateForm()`），而不是 `setFormNextRefreshTime`。

### 12.21 多定点刷新（multiScheduledUpdateTime）

官方文档：[ArkTS卡片被动刷新（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-passive-refresh)

从 API 18 开始支持 `multiScheduledUpdateTime`，可以设置每天多个定点刷新时间（最多 24 个），用逗号分隔：

```json
"scheduledUpdateTime": "10:30",
"multiScheduledUpdateTime": "11:30,16:30",
"updateDuration": 0
```

**注意**：同时配置了单定点和多定点时，多定点生效，单定点不生效。但建议保留 `scheduledUpdateTime` 字段以向前兼容。

### 12.22 卡片刷新数据大小限制

官方文档：[ArkTS卡片页面刷新概述（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-interaction-overview)

> 从 API version 20 开始，刷新数据总大小不超过 **10MB**，刷新图片数量不超过 **20 张**。API version 19 及之前，图片文件数量上限为 **5 张**，每张限制内存 **2MB**。

**对于体力 Widget**：只传文字数据，远小于限制，不受影响。

### 12.23 卡片创建方式：共包（推荐）

官方文档：[创建ArkTS卡片（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-creation)

两种创建方式：

- **共包方式**（推荐，本项目使用）：卡片 UI 和应用代码在同一个 module（entry），编译产物在同一个 HAP 包内
- **独立包方式**（API 20+）：卡片 UI 在独立的 library module，应用代码在 entry module

在 DevEco Studio 中：右键 entry 目录 → New → Service Widget → Dynamic Widget

### 12.24 模拟器对卡片的支持限制

官方文档：[ArkTS卡片概述（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-form-overview)

模拟器与真机存在以下差异：

- 模拟器**不支持 1×1 卡片预览**
- 模拟器**不支持背板透明卡片预览**
- 模拟器**不支持互动卡片预览**

**影响**：开发时需要在真机上测试卡片效果，模拟器只能做基础功能验证。

### 12.25 卡片内不支持左右滑动控件

官方文档：[ArkTS卡片概述（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-form-overview)

> 卡片组件内容的事件处理和卡片使用方的事件处理是独立的，为防止手势冲突，**卡片内不支持左右滑动的控件**。

**影响**：体力 Widget 不要使用 Swiper、List 横向滑动等组件。

### 12.26 globalThis 在同一卡片提供方内共享

官方文档：[ArkTS卡片概述（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-form-overview)

> 相同卡片提供方的卡片 `globalThis` 对象是同一个，不同卡片提供方的卡片 `globalThis` 对象是不同的。

**影响**：本项目只有一个卡片提供方（米悠悠），所有卡片实例共享同一个 `globalThis`，使用时注意避免命名冲突。

### 12.27 设备重启后卡片数据不一致问题（关键）

官方 FAQ：[卡片数据同步异常（官方）](https://developer.huawei.com/consumer/cn/doc/architecture-guides/news-v1_2-ts_c80-0000002411768157)

> 卡片框架在重启时使用 `onAddForm()` 回调方法的返回值。若应用重启前调用 `updateForm()` 更新的数据和 `onAddForm()` 方法返回的数据不一致，会导致设备重启前后卡片数据不一致的现象。

**解决方案**：需要对数据做持久化处理。在 `onAddForm()` 中从 Preferences 或 RDB 读取最新数据返回，而不是返回固定的初始值。

**对于本项目**：`onAddForm()` 应该从 Preferences 读取最新的体力数据返回，而不是返回 `{ stamina: 0 }` 这样的初始值。

### 12.28 多尺寸卡片建议用独立 widget 文件管理（避坑）

官方 FAQ：[覆盖安装偶现卡片显示异常问题（官方）](https://developer.huawei.com/consumer/cn/doc/architecture-guides/traffic-v1_1-ts_65-0000002425634985)

> 使用一个 widget 文件同时管理多个尺寸卡片界面，依赖 `onAddForm` 读取 `cardDimension` 来区分，在应用升级与更新操作并发时，会偶现因为数据未同步导致页面尺寸显示异常问题。

**建议**：不同尺寸的卡片使用独立的 widget 文件管理，在 `form_config.json` 中为每个尺寸配置独立的 `src`，解除对 `cardDimension` 的强依赖。

### 12.29 卡片白屏问题排查

官方 FAQ：[卡片数据同步异常（官方）](https://developer.huawei.com/consumer/cn/doc/architecture-guides/news-v1_2-ts_c80-0000002411768157)

卡片白屏的常见原因：

1. **引入了不支持卡片的模块**（如 `backgroundTaskManager`）→ 检查 EntryFormAbility 的导入链
2. **abc 文件打包问题** → 执行 Build → Clean Project 后重新编译
3. **API 写法错误** → 查看日志中的 `Cannot read property xxx` 错误

### 12.30 自定义字体（本项目暂不需要）

官方文档：[ArkTS卡片使用自定义字体（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-load-custom-font)

- 从 API 22 开始支持通过 `text.FontCollection.getLocalInstance()` 为卡片加载自定义字体
- 所有字体合计最大内存限制 **20MB**
- 同一应用的所有卡片共用一个本地字体集实例

**对于本项目**：使用系统默认字体即可，不需要自定义字体。

## 十三、参考资料

- [Form Kit 简介（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/formkit-overview)
- [配置ArkTS卡片的配置文件（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-configuration)
- [创建ArkTS卡片（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-creation)
- [管理ArkTS卡片生命周期（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-lifecycle)
- [ArkTS卡片进程模型（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-process)
- [ArkTS卡片界面开发概述（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-page-overview)
- [ArkTS卡片适配常见问题（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-adapt-faq)
- [ArkTS卡片主动刷新（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-active-refresh)
- [应用内拉起卡片管理加桌（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-open-formmanager)
- [锁屏卡片开发指导（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-lockscreen-form-development)
- [卡片更新与数据交互 - 最佳实践（官方）](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-card-update-and-data-interaction)
- [如何根据不同尺寸的卡片适配不同的UI（官方）](https://developer.huawei.com/consumer/cn/doc/architecture-guides/tools-v1_2-ts_386-0000002553335253)
- [ArkTS卡片页面交互概述（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-event-overview)
- [ArkTS卡片页面刷新概述（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-interaction-overview)
- [ArkTS卡片被动刷新（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-passive-refresh)
- [刷新本地图片和网络图片（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-image-update)
- [ArkTS卡片概述（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-form-overview)
- [卡片数据同步异常（官方）](https://developer.huawei.com/consumer/cn/doc/architecture-guides/news-v1_2-ts_c80-0000002411768157)
- [覆盖安装偶现卡片显示异常问题（官方）](https://developer.huawei.com/consumer/cn/doc/architecture-guides/traffic-v1_1-ts_65-0000002425634985)
- [ArkTS卡片使用自定义字体（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-load-custom-font)


---

## 十四、Preferences 同步 API（解决黑屏问题的关键）

> **来源**：[@ohos.data.preferences API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-data-preferences)
>
> 调研日期：2026-05-11

### 14.1 为什么需要同步 API

根据第 12.1 节，FormExtension 进程在生命周期回调完成后只能存活 **10 秒**。

如果 `onAddForm()` 使用异步 API 读取 Preferences：
1. `onAddForm()` 立即返回占位数据
2. 异步回调可能在进程被杀前未执行
3. `formProvider.updateForm()` 不会执行
4. 卡片永久显示空数据（黑屏）

**解决方案**：使用同步 API 在 `onAddForm()` 中**同步**读取并返回真实数据。

### 14.2 可用的同步方法（API 10+）

| 方法 | 说明 | 可用版本 |
|-----|------|---------|
| `preferences.getPreferencesSync(context, name)` | 同步获取 Preferences 实例 | API 10+ |
| `prefs.getSync(key, defaultValue)` | 同步读取数据 | API 10+ |
| `prefs.getAllSync()` | 同步获取所有数据 | API 10+ |
| `prefs.putSync(key, value)` | 同步写入数据 | API 10+ |
| `prefs.hasSync(key)` | 同步检查 key 是否存在 | API 10+ |
| `prefs.deleteSync(key)` | 同步删除数据 | API 10+ |
| `prefs.flushSync()` | 同步刷新到磁盘 | API 14+ |
| `prefs.clearSync()` | 同步清空数据 | API 10+ |

### 14.3 代码示例

```typescript
import { preferences } from '@kit.ArkData';
import { formBindingData } from '@kit.FormKit';

onAddForm(want: Want): formBindingData.FormBindingData {
  const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string ?? '';
  
  // ✅ 同步读取数据
  try {
    const prefs = preferences.getPreferencesSync(this.context, 'widget_data_store');
    const json = prefs.getSync('global_data', '') as string;
    
    if (json.length > 0) {
      const data = JSON.parse(json);
      // 构建并返回真实数据
      return formBindingData.createFormBindingData({
        payload: json
      });
    }
  } catch (e) {
    hilog.error(DOMAIN, TAG, `sync read failed: ${JSON.stringify(e)}`);
  }
  
  // 兜底：返回空数据
  return formBindingData.createFormBindingData({
    payload: '{"version":1,"updatedAt":0,"accounts":[]}'
  });
}
```

### 14.4 注意事项

1. **多进程安全**：Preferences 不支持多进程并发写入。本项目主应用写入，FormExtension 只读取，风险可控。
2. **API 版本**：同步方法需要 API 10+，本项目目标 API 18，满足要求。
3. **错误处理**：同步方法可能抛异常，必须 try-catch 包裹。

---

## 十五、黑屏问题排查清单

当 Widget 出现黑屏时，按以下步骤排查：

### 15.1 检查 `onAddForm()` 返回值

- [ ] 是否返回了真实数据（而不是占位数据）？
- [ ] 是否使用了同步 API 读取 Preferences？
- [ ] payload JSON 结构是否正确？

### 15.2 检查 Widget 组件

- [ ] 是否正确处理空数据（`accounts: []`）？
- [ ] 是否有占位 UI 而不是黑屏？
- [ ] 是否正确使用 `@LocalStorageProp` 接收数据？

### 15.3 检查导入链

- [ ] `EntryFormAbility.ets` 是否导入了 HSP 模块（core）？
- [ ] 是否导入了不支持的模块（`backgroundTaskManager`、`audio` 等）？
- [ ] 使用 DevEco Studio 的 "Analyze Dependencies" 检查导入链

### 15.4 检查 .abc 文件

- [ ] HAP 包中是否存在对应的 .abc 文件？
- [ ] 执行 Build → Clean Project 后重新编译

### 15.5 检查日志

```bash
# 导出 Widget 日志
./export-widget-logs.sh

# 检查关键日志
grep "WIDGET_DEBUG" logs/widget_logs_*.txt
```

关键日志：
- `onAddForm: formId=xxx` — 确认 onAddForm 被调用
- `returning real data, accounts=N` — 确认返回了真实数据
- `sync read failed` — 同步读取失败

---

## 十六、Widget 预览空白问题分析（重要发现）

> **调研日期**：2026-05-12
> **问题现象**：长按 App icon 进入预览页显示空白，添加 Widget 到桌面也空白，运行 run.sh 后已添加的 Widget 能正常显示

### 16.1 问题分析

根据官方文档的多个关键发现：

#### 发现 1：ArkTS Widget 不支持即时预览

来自官方文档 [ArkTS卡片概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-form-overview)：

> ArkTS卡片还存在如下约束：
> - **不支持极速预览**
> - 不支持断点调试能力
> - 不支持Hot Reload热重载
> - 不支持setTimeout

**这意味着**：
- DevEco Studio 的预览器（Previewer）**无法预览 ArkTS Widget**
- 长按 App icon 进入的卡片预览页是由**卡片渲染服务**（Form Rendering Service）负责渲染的
- 卡片渲染服务运行 `widget.abc` 文件来渲染 Widget UI

#### 发现 2：Widget 组件必须使用 @Entry + new LocalStorage()

来自官方最佳实践文档 [音乐服务卡片](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-music-card)：

```typescript
// ✅ 官方示例的正确写法
let storageUpdateByMsg = new LocalStorage();

@Entry(storageUpdateByMsg)
@Component
struct PlayControlCard2x4 {
  @LocalStorageProp('formId') formId: string = '';
  @LocalStorageProp('isNeedRequestUpdate') isNeedRequestUpdate: boolean = false;
  // ...
}
```

**关键点**：
- Widget 组件**必须**使用 `let storage = new LocalStorage()` 创建 LocalStorage 实例
- Widget 组件**必须**使用 `@Entry(storage)` 装饰器
- 数据接收**必须**使用 `@LocalStorageProp('key')` 装饰器
- 这与普通页面使用 `@ComponentV2` 不同，Widget 只能使用 `@Component`（V1 体系）

**本项目之前的错误记录**：
> ~~方案 C 中说"Widget 组件不需要也不应该在 Widget 组件中创建 `LocalStorage` 实例"是**错误的**~~

**正确做法**：
```typescript
// ✅ 正确
let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct Widget1x2Genshin {
  @LocalStorageProp('payload') payloadJson: string = '';
  // ...
}
```

#### 发现 3：预览时 onAddForm 被调用但进程存活时间有限

来自 [Widget 生命周期管理](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-lifecycle)：

> The FormExtensionAbility cannot reside in the background. It persists for **10 seconds** after the lifecycle callback is completed and exits if no new lifecycle callback is invoked during this time frame.

来自最佳实践文档 [卡片更新与数据交互](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-card-update-and-data-interaction)：

> 弹出卡片预览弹窗时，所有卡片都会触发 `onAddForm()`
> 关闭弹窗或息屏时，会触发所有卡片的 `onRemoveForm()`

**这意味着**：
- 预览页打开时，`onAddForm()` **会被调用**
- 但 `onAddForm()` 必须在**方法返回前**准备好数据
- 如果使用异步 API（如 `await preferences.getPreferences()`），数据可能在进程被杀前未准备好
- **必须使用同步 API（`getPreferencesSync` + `getSync`）在 `onAddForm()` 中读取数据**

#### 发现 4：数据传递必须通过 LocalStorageProp

来自官方文档 [LocalStorage](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-localstorage)：

> This decorator can be used in **ArkTS widgets** since API version 9.

来自 [卡片更新与数据交互](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-card-update-and-data-interaction)：

> 卡片页面使用页面级的UI状态存储 `LocalStorage` 接收 `onAddForm()` 接口传递的数据。
> 使用装饰器 `@LocalStorageProp` 装饰的状态变量接收数据类的详细信息，装饰器 `@LocalStorageProp(key)` 中的key值需与数据类的键值一一对应。

**数据流**：
```
EntryFormAbility.onAddForm() 
  → formBindingData.createFormBindingData({ payload: jsonStr })
    → Widget 组件 @LocalStorageProp('payload') payloadJson: string
```

#### 发现 5：Widget 渲染服务独立运行

来自官方文档 [ArkTS卡片实现原理](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-form-overview)：

> 卡片渲染服务根据form_config.json配置的卡片信息运行widget.abc文件的卡片页面代码进行渲染，并将渲染后的数据发送至卡片使用方对应的卡片组件。

**关键点**：
- 卡片渲染服务运行 `widget.abc` 文件
- 卡片渲染服务由卡片管理服务管理
- 同一卡片提供方的渲染实例运行在同一个ArkTS虚拟机运行环境中
- **如果 `widget.abc` 文件有问题，Widget 就会空白**

### 16.2 根本原因推测

根据用户描述的问题现象：

| 现象 | 可能原因 |
|-----|---------|
| 长按 App icon 预览空白 | `onAddForm()` 返回的数据为空或格式错误，或 Widget 组件未正确处理空数据 |
| 添加到桌面空白 | 同上，`onAddForm()` 返回的数据有问题 |
| 运行 run.sh 后已添加的 Widget 正常显示 | `onUpdateForm()` 或 `formProvider.updateForm()` 正确推送了数据 |
| 长按预览始终空白 | Widget 渲染服务在预览时未正确初始化，或数据未同步保存到 Preferences |

### 16.3 解决方案

#### 方案 A：确保 onAddForm() 使用同步 API

在 `EntryFormAbility.ets` 中，**必须使用同步 API** 读取 Preferences：

```typescript
import { preferences } from '@kit.ArkData';

onAddForm(want: Want): formBindingData.FormBindingData {
  // ✅ 使用同步 API
  const prefs = preferences.getPreferencesSync(this.context, { name: 'widget_data_store' });
  const json = prefs.getSync('global_data', '') as string;
  
  if (json.length > 0) {
    return formBindingData.createFormBindingData({ payload: json });
  }
  
  // 兜底：返回空数据（但要有有效结构）
  return formBindingData.createFormBindingData({
    payload: '{"version":1,"updatedAt":0,"accounts":[]}'
  });
}
```

**错误做法**：
```typescript
// ❌ 异步 API - 数据可能在进程被杀前未准备好
const prefs = await preferences.getPreferences(this.context, 'widget_data_store');
const json = await prefs.get('global_data', '') as string;
```

#### 方案 B：主应用启动时保存数据到 Preferences

在 `EntryAbility.onCreate()` 中，确保调用数据保存：

```typescript
// EntryAbility.ets
async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
  // 初始化 Preferences
  await WidgetDataStoreManager.init(this.context);
  
  // 从 core 模块读取数据并保存到 Preferences
  const data = await this.buildWidgetData();
  await WidgetDataStoreManager.save(data);
}
```

#### 方案 C：检查 Widget 组件是否有有效 UI

即使数据为空，Widget 组件也应该显示占位 UI，而不是空白：

```typescript
build() {
  Column() {
    if (this.payloadJson.length === 0) {
      // 显示占位 UI
      Text("暂无数据")
        .fontColor(Color.Gray)
    } else {
      // 显示正常内容
      Widget1x2Content({ data: this.buildData() })
    }
  }
  .width('100%')
  .height('100%')
  .backgroundColor(Color.Blue) // 使用明显颜色方便调试
}
```escript
// ✅ 正确：同步读取并返回
onAddForm(want: Want): formBindingData.FormBindingData {
  try {
    const prefs = preferences.getPreferencesSync(this.context, 'widget_data_store');
    const json = prefs.getSync('global_data', '') as string;
    
    // 即使 json 为空，也要返回有效的 payload 结构
    const payload = json.length > 0 ? json : '{"version":1,"accounts":[]}';
    
    return formBindingData.createFormBindingData({
      payload: payload
    });
  } catch (e) {
    // 兜底：返回有效的空数据结构
    return formBindingData.createFormBindingData({
      payload: '{"version":1,"accounts":[]}'
    });
  }
}
```

#### 方案 B：检查 Widget 组件的数据接收

在 `Widget1x2Genshin.ets` 中确认：

1. 使用 `@LocalStorageProp('payload')` 接收数据
2. 在 `aboutToAppear()` 或直接使用时解析 payload
3. 必须处理 payload 为空字符串或无效 JSON 的情况

```typescript
@Component
struct Widget1x2Genshin {
  @LocalStorageProp('payload') payloadJson: string = '';
  
  // 直接在属性初始化时解析（Widget 不支持复杂初始化逻辑）
  // 或在 build() 方法中惰性解析
  
  build() {
    Column() {
      if (this.payloadJson.length === 0) {
        // 空数据占位 UI
        Text('暂无数据')
          .fontSize(12)
          .fontColor(Color.White)
      } else {
        // 正常渲染
        Widget1x2Content({ ... })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Blue)  // 使用 Color 枚举，不要用字符串
  }
}
```

#### 方案 C：确保 Widget 组件语法正确

**重要发现**：当前 `Widget1x2Genshin.ets` 文件有编译错误！

错误列表：
1. `Cannot find name 'LocalStorage'` — 未导入
2. `Cannot find name 'Entry'` — 未导入
3. `Cannot find name 'Component'` — 未导入
4. `Cannot find name 'LocalStorageProp'` — 未导入
5. `Cannot find name 'Column'` / `Text` / `Color` — 未导入
6. `Cannot find name 'postCardAction'` — 未导入

**原因**：Widget 文件**不能手动创建 LocalStorage 实例**！

根据官方文档：
- Widget 组件由卡片渲染服务加载
- `@LocalStorageProp` 的数据由 `formBindingData.createFormBindingData()` 提供
- **不需要也不应该**在 Widget 组件中创建 `LocalStorage` 实例

**正确写法**：

```typescript
// ❌ 错误：手动创建 LocalStorage
let storage: LocalStorage = new LocalStorage();
@Entry(storage)
@Component
struct Widget1x2Genshin { ... }

// ✅ 正确：直接使用 @Component，不需要 @Entry
@Component
struct Widget1x2Genshin {
  @LocalStorageProp('payload') payloadJson: string = '';
  
  build() { ... }
}
```

#### 方案 D：检查模块导入

Widget 组件只能导入标记为 **"supported in ArkTS widgets"** 的 API。

当前 `Widget1x2Genshin.ets` 导入了：
- `Widget1x2Content` — 需要确认该组件是否也使用正确的装饰器
- `WidgetGameData` / `WidgetSingleGameData` — 数据模型，应该没问题
- `parsePayload` / `ParsedRole` — 解析逻辑，需要确认是否有不支持的 API

#### 方案 E：检查模拟器限制

根据官方文档：

> 模拟器与真机存在以下差异：
> - 模拟器**不支持 1×1 卡片预览**
> - 模拟器**不支持背板透明卡片预览**
> - 模拟器**不支持互动卡片预览**

**建议**：在真机上测试 Widget 效果，模拟器可能无法正确渲染动态 Widget。

### 16.4 立即行动项

1. **修复 Widget 组件语法错误**：
   - 移除 `let storage = new LocalStorage()`
   - 移除 `@Entry(storage)`，只保留 `@Component`
   - 确保所有导入的模块都支持 ArkTS Widget

2. **验证 onAddForm() 返回值**：
   - 添加日志确认 `onAddForm()` 被调用
   - 确认返回的 `FormBindingData` 包含 `payload` 字段
   - 确认 `payload` 是有效的 JSON 字符串

3. **简化 Widget 组件**：
   - 先只渲染一个 `Text` 组件验证数据传递
   - 确认能显示后逐步添加复杂 UI

4. **在真机上测试**：
   - 模拟器的 Widget 渲染可能有 bug
   - 使用真机验证预览和添加流程

---

## 十七、最佳实践总结

### 16.1 `onAddForm()` 正确实现

```typescript
onAddForm(want: Want): formBindingData.FormBindingData {
  // 1. 解析参数
  const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string ?? '';
  const config = this.parseConfig(want);
  
  // 2. 同步读取数据并返回
  try {
    const prefs = preferences.getPreferencesSync(this.context, PREFS_NAME);
    const json = prefs.getSync(KEY_GLOBAL_DATA, '') as string;
    
    if (json.length > 0) {
      const dataStore = WidgetDataStore.fromJson(json);
      const payload = WidgetPayloadBuilder.buildPayload(config, dataStore);
      return formBindingData.createFormBindingData(payload.toLocalStorageRecord());
    }
  } catch (e) {
    // 记录错误日志
  }
  
  // 3. 兜底：返回空数据
  return formBindingData.createFormBindingData({
    payload: '{"version":1,"updatedAt":0,"accounts":[]}'
  });
  
  // 注意：不要在这里调用异步方法保存配置
  // 异步保存应该在后台任务或其他地方处理
}
```

### 16.2 Widget 组件正确实现

```typescript
@Component
export struct Widget2x2 {
  @LocalStorageProp('payload') payloadStr: string = '';
  private parsedPayload: ParsedPayload = new ParsedPayload();

  aboutToAppear(): void {
    if (this.payloadStr.length > 0) {
      try {
        this.parsedPayload = WidgetPayloadParser.parse(this.payloadStr);
      } catch (e) {
        // 解析失败，使用默认空数据
      }
    }
  }

  build() {
    Column() {
      if (this.parsedPayload.accounts.length === 0) {
        // 占位 UI
        this.buildEmptyState()
      } else {
        // 正常渲染
        this.buildContent()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.colorPageBg'))
  }

  @Builder
  buildEmptyState() {
    Column() {
      Text('暂无数据')
        .fontSize(12)
        .fontColor($r('app.color.colorTextSecondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildContent() {
    // 正常渲染逻辑
  }
}
```


---

## 十七、Widget 组件装饰器规范（重要修正）

### 17.1 官方推荐写法（来自音乐服务卡片最佳实践）

**经过查阅官方文档确认**：Widget 组件**必须**使用 `@Entry(storage)` + `new LocalStorage()`：

```typescript
// ✅ 官方示例的正确写法
let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct PlayControlCard2x4 {
  @LocalStorageProp('formId') formId: string = '';
  @LocalStorageProp('isNeedRequestUpdate') isNeedRequestUpdate: boolean = false;
  
  build() {
    Column() {
      // Widget UI
    }
  }
}
```

**来源**：[音乐服务卡片 - 官方最佳实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-music-card)

### 17.2 本项目之前的错误记录

> ~~方案 C 中说"Widget 组件不需要也不应该在 Widget 组件中创建 `LocalStorage` 实例"是**错误的**~~

**正确做法**：
```typescript
// ✅ 正确
let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct Widget1x2Genshin {
  @LocalStorageProp('payload') payloadJson: string = '';
  // ...
}
```

### 17.3 关键规则

| 规则 | 说明 |
|-----|------|
| 必须使用 `@Component` | Widget 只支持 V1 体系，不支持 `@ComponentV2` |
| 必须使用 `@Entry(storage)` | 必须手动创建 LocalStorage 实例并传入 |
| 必须使用 `@LocalStorageProp` | 用于接收来自 `formBindingData` 的数据 |
| 不能使用 `@State` | Widget 不支持 `@State`，只能用 `@LocalStorageProp` |

### 17.4 模拟器限制

来自官方文档 [ArkTS卡片概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-form-overview)：

| 模拟器限制 | 说明 |
|-----------|------|
| 不支持 1×1 卡片预览 | 模拟器无法预览 1×1 尺寸的卡片 |
| 不支持背板透明卡片预览 | 模拟器无法预览透明背景卡片 |
| 不支持互动卡片预览 | 模拟器无法预览互动卡片 |

**建议**：在真机上测试卡片效果，模拟器只能做基础功能验证。

---

## 十八、Widget 预览空白的真正原因

### 18.1 数据流分析

```
EntryFormAbility.onAddForm() 
  → formBindingData.createFormBindingData({ payload: jsonStr })
    → 卡片渲染服务运行 widget.abc
      → Widget 组件 @LocalStorageProp('payload') 接收数据
        → Widget UI 渲染
```

### 18.2 可能的问题点

| 问题点 | 检查方法 |
|-------|---------|
| `onAddForm()` 未被调用 | 检查日志 `[WIDGET_DEBUG] onAddForm` |
| `onAddForm()` 返回空数据 | 检查日志 `returning real data, payload len=N` |
| Preferences 中没有数据 | 检查主应用启动时是否调用 `WidgetDataStoreManager.save()` |
| Widget 组件有编译错误 | 执行 `hvigorw assembleHap` 检查 |
| 模拟器渲染问题 | 在真机上测试 |

### 18.3 调试步骤

1. **检查日志**：
   ```bash
   hilog | grep "WIDGET_DEBUG"
   ```

2. **确认数据流**：
   - 主应用启动 → `WidgetDataStoreManager.save()` → Preferences 有数据
   - 长按 App icon → `onAddForm()` → 读取 Preferences → 返回 FormBindingData
   - 卡片渲染服务 → 运行 `widget.abc` → 渲染 Widget UI

3. **简化 Widget UI**：
   - 先用最简单的 `Text("Hello")` 验证渲染
   - 确认能显示后逐步恢复复杂 UI

---

## 十九、白屏问题官方排查指南

> **来源**：[如何定位并解决卡片白屏展示的问题 - 官方行业常见问题](https://developer.huawei.com/consumer/cn/doc/architecture-guides/common-v1_26-ts_c227-0000002535499060)

### 19.1 白屏问题根因速查表

| 问题现象 | 关键日志 | 问题根因 | 解决方案 |
|:---|:---|:---|:---|
| 卡片白屏 | `setFormOpacity` | 卡片透明度被设置较低（如 0.005），导致内容不可见 | 将卡片的 `opacity` 属性设置为合理可见的值（如 1） |
| `Cannot get SourceMap info, dump raw stack` | 卡片页面直接/间接引入了不支持卡片的模块 | 只使用带有 `@form` 标签的 API |
| `Cannot get SourceMap info, dump raw stack` | 自定义业务逻辑错误（如访问空数组对象属性） | 添加边界值和空值条件判断 |
| `Get file size failed, errno is 0` | 图片还未完成加载就打开 fd | 确保图片完全下载并写入文件系统后再获取 fd |
| `load SharedMemoryImage timeout!` | 图片大小超过共享内存限制（API 20+ 总计 10MB，最多 20 张；API 19- 最多 5 张，每张 ≤2MB） | 对图片进行压缩，分批次更新 |

### 19.2 关键发现

1. **一个卡片报错会导致所有卡片白屏**：
   > 当卡片的页面功能复杂时，可能在卡片的实际运行时才崩溃报错，体现为卡片显示白屏。
   > **注意：一个卡片报错后会导致应用的所有卡片渲染全部挂掉成为白屏**

2. **模拟器限制**：
   - 不支持 1×1 卡片预览
   - 不支持背板透明卡片预览
   - 不支持互动卡片预览
   - **示例效果请以真机运行为准，当前不支持 DevEco Studio 预览器**

3. **预览时的生命周期**：
   - 用户长按桌面应用图标，桌面弹出卡片添加弹窗时，会触发 `onAddForm()`
   - 关闭弹窗或息屏时，会触发所有卡片的 `onRemoveForm()`
   - 点击「添加至桌面」时，只有被添加的卡片保留

### 19.3 调试方法

1. **查看卡片渲染服务日志**：
   在 IDE 中选择 `com.ohos.formrenderservice` 卡片渲染服务，查看 error 日志

2. **检查日志关键词**：
   - `setFormOpacity` — 透明度设置问题
   - `Cannot get SourceMap info, dump raw stack` — 模块导入或业务逻辑错误
   - `Get file size failed` — 图片加载问题
   - `load SharedMemoryImage timeout!` — 图片大小超限

3. **简化卡片代码定位问题**：
   - 暂时移除复杂组件，使用基础组件（`Text`、`Image`）测试
   - 确认能显示后逐步恢复复杂 UI

### 19.4 图片相关限制

| API 版本 | 共享内存总限制 | 图片数量限制 | 单张图片限制 |
|:---|:---|:---|:---|
| API 20+ | 10MB | 20 张 | 无明确单张限制 |
| API 19- | — | 5 张 | 2MB |

**建议**：
- 卡片加载的图片大小不超过 2MB
- 对图片进行压缩处理
- 分批次更新多张图片

---

## 二十、参考资料（2026-05-12 更新）

### 官方文档

- [ArkTS卡片概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-form-overview) — 卡片架构、实现原理、约束限制
- [创建ArkTS卡片](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-creation) — 工程结构、创建步骤
- [管理ArkTS卡片生命周期](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-lifecycle) — onAddForm、onUpdateForm 等
- [卡片更新与数据交互](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-card-update-and-data-interaction) — 数据初始化、更新机制
- [音乐服务卡片](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-music-card) — 完整示例代码，包含正确的 Widget 组件写法
- [如何定位并解决卡片白屏展示的问题](https://developer.huawei.com/consumer/cn/doc/architecture-guides/common-v1_26-ts_c227-0000002535499060) — 白屏问题排查指南
- [ArkTS卡片适配常见问题](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-adapt-faq) — V2 装饰器、白屏定位、深浅色适配

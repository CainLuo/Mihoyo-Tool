# Widget 技术设计文档

版本：V1.1.0
状态：草稿

---

## 一、架构概览

```
entry/
  src/main/ets/
    entryformability/
      EntryFormAbility.ets          ← FormExtensionAbility，处理生命周期
    widget/
      pages/
        Widget1x2Genshin.ets        ← 原神 1×2 卡片 UI
        Widget1x2StarRail.ets       ← 星铁 1×2 卡片 UI
        Widget1x2ZZZ.ets            ← 绝区零 1×2 卡片 UI
        Widget2x2.ets               ← 2×2 卡片 UI（游戏数量自动切换）
        Widget2x4.ets               ← 2×4 卡片 UI
        Widget4x4.ets               ← 4×4 卡片 UI
      models/
        WidgetData.ets              ← 卡片数据模型（LocalStorage key 常量）
      utils/
        WidgetFormIdStore.ets       ← formId Preferences 存取工具
        WidgetDataBuilder.ets       ← 从 DB 读取数据并构建推送 payload
  src/main/resources/
    base/profile/
      form_config.json              ← 6 个卡片模板配置
```

---

## 二、数据流

```
StaminaNotificationService（定时检测）
  └─ 体力数据变化
       └─ WidgetDataBuilder.buildAndPush(accountId)
            ├─ 从 RDB 读取体力数据（通过 CoreInitializer）
            ├─ 构建 FormBindingData
            └─ 遍历 WidgetFormIdStore.getFormIds(accountId)
                 └─ formProvider.updateForm(formId, data)

EntryFormAbility.onAddForm(want)
  ├─ 读取 want.parameters.accountId
  ├─ 读取 want.parameters.selectedGames
  ├─ WidgetFormIdStore.save(formId, config)
  └─ WidgetDataBuilder.buildAndPush(accountId)  ← 立即推送初始数据

EntryFormAbility.onRemoveForm(formId)
  └─ WidgetFormIdStore.remove(formId)
```

---

## 三、关键类设计

### 3.1 WidgetFormIdStore

```typescript
// entry/src/main/ets/widget/utils/WidgetFormIdStore.ets
interface WidgetConfig {
  accountId: string;
  selectedGames: string[]; // ['genshin', 'starrail', 'zzz']
  formName: string; // 'widget_1x2_genshin' 等
}

class WidgetFormIdStore {
  static save(formId: string, config: WidgetConfig): void;
  static remove(formId: string): void;
  static getConfig(formId: string): WidgetConfig | null;
  static getFormIdsByAccount(accountId: string): string[];
  static getAllFormIds(): string[];
}
```

存储格式：Preferences key = `form_${formId}`，value = JSON.stringify(config)

### 3.2 WidgetDataBuilder

```typescript
// entry/src/main/ets/widget/utils/WidgetDataBuilder.ets
// 注意：不能 import StaminaNotificationService（含 backgroundTaskManager，会导致卡片进程 crash）
class WidgetDataBuilder {
  // 构建并推送指定账号的所有卡片数据（在 UIAbility 进程中调用）
  static async buildAndPushForAccount(accountId: string): Promise<void>;

  // 构建单个 formId 的推送数据
  static async buildPayload(
    formId: string,
    config: WidgetConfig,
  ): Promise<formBindingData.FormBindingData>;
}
```

**数据推送方式**（API 18）：遍历 `WidgetFormIdStore.getFormIdsByAccount(accountId)` 获取所有相关 formId，逐一调用 `formProvider.updateForm(formId, formData)`。

> 注：API 22+ 新增 `formProvider.reloadForms()` 可批量触发 `onUpdateForm`，但本项目目标 API 18，暂不使用。

### 3.3 卡片数据模型（LocalStorage key 常量）

```typescript
// entry/src/main/ets/widget/models/WidgetData.ets
export class WidgetKeys {
  static readonly STAMINA_CURRENT = "staminaCurrent";
  static readonly STAMINA_MAX = "staminaMax";
  static readonly RECOVERY_DESC = "recoveryDesc";
  static readonly ACCOUNT_NAME = "accountName";
  static readonly ACCOUNT_UID = "accountUid";
  static readonly GAME_COUNT = "gameCount";
  // 多游戏时用 game0_*, game1_*, game2_* 前缀
  static readonly GAME_PREFIX = (idx: number) => `game${idx}_`;
  // 原神专属
  static readonly GENSHIN_EXPEDITION_COUNT = "expeditionCount";
  static readonly GENSHIN_EXPEDITION_FINISHED = "expeditionFinished"; // 逗号分隔的 bool 数组
  // 星铁专属
  static readonly SR_RESERVE_STAMINA = "reserveStamina";
  // ...
}
```

---

## 四、form_config.json 配置

```json
{
  "forms": [
    {
      "name": "widget_1x2_genshin",
      "displayName": "$string:widget_1x2_genshin_name",
      "src": "./ets/widget/pages/Widget1x2Genshin.ets",
      "uiSyntax": "arkts",
      "isDynamic": true,
      "updateEnabled": true,
      "updateDuration": 1,
      "defaultDimension": "1*2",
      "supportDimensions": ["1*2"],
      "renderingMode": "fullColor",
      "isDefault": false
    },
    {
      "name": "widget_1x2_starrail",
      "displayName": "$string:widget_1x2_starrail_name",
      "src": "./ets/widget/pages/Widget1x2StarRail.ets",
      "uiSyntax": "arkts",
      "isDynamic": true,
      "updateEnabled": true,
      "updateDuration": 1,
      "defaultDimension": "1*2",
      "supportDimensions": ["1*2"],
      "renderingMode": "fullColor",
      "isDefault": false
    },
    {
      "name": "widget_1x2_zzz",
      "displayName": "$string:widget_1x2_zzz_name",
      "src": "./ets/widget/pages/Widget1x2ZZZ.ets",
      "uiSyntax": "arkts",
      "isDynamic": true,
      "updateEnabled": true,
      "updateDuration": 1,
      "defaultDimension": "1*2",
      "supportDimensions": ["1*2"],
      "renderingMode": "fullColor",
      "isDefault": false
    },
    {
      "name": "widget_2x2",
      "displayName": "$string:widget_2x2_name",
      "src": "./ets/widget/pages/Widget2x2.ets",
      "uiSyntax": "arkts",
      "isDynamic": true,
      "updateEnabled": true,
      "updateDuration": 1,
      "defaultDimension": "2*2",
      "supportDimensions": ["2*2"],
      "renderingMode": "fullColor",
      "isDefault": true
    },
    {
      "name": "widget_2x4",
      "displayName": "$string:widget_2x4_name",
      "src": "./ets/widget/pages/Widget2x4.ets",
      "uiSyntax": "arkts",
      "isDynamic": true,
      "updateEnabled": true,
      "updateDuration": 1,
      "defaultDimension": "2*4",
      "supportDimensions": ["2*4"],
      "renderingMode": "fullColor",
      "isDefault": false
    },
    {
      "name": "widget_4x4",
      "displayName": "$string:widget_4x4_name",
      "src": "./ets/widget/pages/Widget4x4.ets",
      "uiSyntax": "arkts",
      "isDynamic": true,
      "updateEnabled": true,
      "updateDuration": 1,
      "defaultDimension": "4*4",
      "supportDimensions": ["4*4"],
      "renderingMode": "fullColor",
      "isDefault": false
    }
  ]
}
```

---

## 五、卡片 UI 实现规范

### 5.1 通用规范

- 使用 `@Component`（V1）+ `@LocalStorageProp` 接收数据（注意：不是 `@ComponentV2`）
- 背景色固定 `#2E3033`（官方设计规范）
- 四周保留 12vp 安全间距
- 不能 import `core` 模块（HSP 限制）
- 数值字段从 LocalStorage 接收时为字符串，需 `parseInt()` 转换
- **颜色**：使用 `$r('app.color.xxx')` 引用颜色资源（支持深浅色适配）✅
- **字符串**：使用 `$r('app.string.xxx')` 引用多语言资源 ✅
- **尺寸/字体大小**：必须硬编码数字 ❌（平台限制：`@Component` V1 不能持有 `@ObservedV2` 的 ThemeManager；且卡片不支持访问 `Font` 对象的 `.size`/`.weight` 属性）

### 5.2 卡片 UI 文件结构

**重要**：卡片 UI 使用 `@Component`（V1）+ `@LocalStorageProp`，不能用 `@ComponentV2`。原因：`@LocalStorageProp` 是 V1 装饰器，V2 体系下没有等价替代，官方所有示例均使用 V1 写法。

```typescript
// Widget1x2Genshin.ets 示例（官方标准写法）
let storage = new LocalStorage();

@Entry(storage)
@Component  // ← 必须用 @Component，不能用 @ComponentV2
struct Widget1x2Genshin {
  @LocalStorageProp('staminaCurrent') staminaCurrent: string = '0';
  @LocalStorageProp('staminaMax') staminaMax: string = '200';
  @LocalStorageProp('recoveryDesc') recoveryDesc: string = '';
  @LocalStorageProp('accountName') accountName: string = '';
  @LocalStorageProp('accountUid') accountUid: string = '';

  build() {
    // 卡片 UI，数值需要 parseInt() 转换
    Column() {
      Text(this.accountName)
      Text(parseInt(this.staminaCurrent) + '/' + parseInt(this.staminaMax))
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#2E3033')
    .padding(12)
  }
}

// @Preview 使用 @Component（与卡片 UI 保持一致）
@Preview
@Component
struct Widget1x2GenshinPreview {
  build() {
    Widget1x2Genshin()
  }
}
```

### 5.3 点击事件

- 点击卡片跳转到 App 首页：使用 `router` 事件
- 卡片内刷新按钮（如有）：使用 `message` 事件触发 `onFormEvent`

---

## 六、My 页面入口设计

在 My 页面的「外观设置」区域下方新增「Widget 卡片」区域：

```
Widget 卡片
  ├─ 旅行者（182692936）
  │    ├─ [添加原神卡片]
  │    ├─ [添加星铁卡片]
  │    └─ [添加绝区零卡片]（仅当账号有绝区零时显示）
  └─ 开拓者（109050292）
       ├─ [添加原神卡片]
       └─ [添加星铁卡片]
```

每个「添加」按钮调用 `formProvider.openFormManager(want)`，`want.parameters` 携带：

- `accountId`：账号 UID
- `formName`：对应的模板名（如 `widget_1x2_genshin`）

---

## 七、测试策略

### 7.1 单元测试（`entry/src/test/`）

- `WidgetFormIdStore`：save / remove / getConfig / getFormIdsByAccount
- `WidgetDataBuilder.buildPayload`：各游戏数据构建逻辑

### 7.2 设备端测试（`entry/src/ohosTest/`）

- `EntryFormAbility` 生命周期：onAddForm 存储 formId，onRemoveForm 删除 formId
- 数据推送：注入 MockService，验证 formProvider.updateForm 被调用

### 7.3 组件 @Preview

每个 widget 文件末尾必须有 `@Preview`，覆盖：

- 空态（无数据）
- 有数据（体力未满）
- 体力已满（红色警告）

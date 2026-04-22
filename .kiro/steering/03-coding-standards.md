# 编码规范

## 一、硬编码禁止规范

### 文字字符串

**禁止**在代码中直接写任何中文、英文或其他语言的字符串字面量用于展示，无论是否"用户可见"：

```typescript
// 错误 — 任何形式的硬编码文字
Text("战绩工具");
Text("Game Stats");
Text("UID " + uid); // 'UID ' 也是硬编码
Text(role.level + " 个游戏角色"); // ' 个游戏角色' 也是硬编码
```

```typescript
// 正确
Text($r("app.string.home_title"));
Text($r("app.string.my_account_role_count", role.level)); // 带参数用 %d/%s 占位
```

多语言文件位置：

- `entry/src/main/resources/base/element/string.json` — 简体中文（默认）
- `entry/src/main/resources/zh_HK/element/string.json` — 繁体中文
- `entry/src/main/resources/en/element/string.json` — 英文

新增 key 时，三个文件必须同步添加。

### 尺寸数值

所有尺寸、间距、圆角等数值必须从 `ThemeManager.current` 读取，**禁止** hard code：

```typescript
// 错误
.height(56).borderRadius(12)
// 正确
.height(this.tm.current.value56).borderRadius(this.tm.current.radius12)
```

**可用 token 速查（真相来源：`AppTheme.ets` + `DefaultTheme.ets`）：**

- 间距/尺寸：`value0` ~ `value600`，命名即数值（vp），只能用已有 token，不得写裸数字
- 圆角：`radius8`（8）、`radius12`（12）、`radius16`（16）
- 阴影：`shadowRadius`（8）、`shadowOffsetY`（2）、`shadowColor`
- 渐变角度：`a0`、`a90`、`a135`、`a150`、`a180`
- 透明度：`shimmerOpacityHigh`（1.0）、`shimmerOpacityLow`（0.3）
- 百分比：`full`（100%）、`pct90`、`pct80`、`pct45`、`pct40`、`pct35`

如需新增 token，在 `AppTheme.ets` 接口中声明，在 `DefaultTheme.ets` 中赋值。

例外：`layoutWeight(1)` 是 ArkUI flex 权重，允许直接写数字。

### 渐变角度

所有 `linearGradient` 的 `angle` 必须从 Theme Token 读取：

```typescript
// 错误
.linearGradient({ angle: 135, colors: [...] })
// 正确
.linearGradient({ angle: this.tm.current.a135, colors: [...] })
```

已有 angle token：`a0`（0°）、`a90`（90°）、`a135`（135°）、`a150`（150°）、`a180`（180°）。

---

## 二、枚举规范

**禁止**用字符串字面量做状态或类型判断，必须使用 `enum`。

### GameId 枚举

游戏 ID 必须使用 `core` 模块的 `GameId` enum，**禁止**直接写 `'genshin'`、`'starrail'`、`'zzz'` 字符串：

```typescript
import { GameId } from 'core';

// 正确
if (gameId === GameId.GENSHIN) { ... }
// 错误
if (gameId === 'genshin') { ... }
```

`gameId` 字段类型必须使用 `GameId`（enum 类型），不得用 `string`。

### 已有 enum 清单

| enum 名          | 文件                           | 用途                                     |
| ---------------- | ------------------------------ | ---------------------------------------- |
| `GameId`         | `core/constants/GameId.ets`    | 游戏 ID（GENSHIN/STARRAIL/ZZZ/HONKAI3）  |
| `ViewState`      | `constants/ViewStates.ets`     | 页面加载状态（LOADING/EMPTY/DATA/ERROR） |
| `GenshinElement` | `constants/GenshinElement.ets` | 原神元素类型                             |
| `HeroPanelMode`  | `constants/HeroPanelMode.ets`  | 角色立绘区布局模式                       |
| `LoginTab`       | `constants/LoginTabEnum.ets`   | 登录方式 Tab                             |
| `PhoneStep`      | `constants/LoginTabEnum.ets`   | 手机号登录步骤                           |
| `QRCodeStat`     | `constants/LoginTabEnum.ets`   | 二维码状态                               |

API 返回的字符串必须在边界处（Repository 或 ViewModel）转换为 enum，不得将原始字符串传入 UI 组件。

---

## 三、常量规范

| 常量类型                 | 放哪里              | 示例                             |
| ------------------------ | ------------------- | -------------------------------- |
| 跨组件复用的断点数组     | `AppConstants.ets`  | `GRID_BREAKPOINTS`               |
| 骨架屏占位索引等通用数组 | `AppConstants.ets`  | `SKELETON_CHARACTER_INDICES`     |
| 路由 path 字符串         | `AppRoutes.ets`     | `AppRoutes.LOGIN`                |
| API retcode 错误码       | `ApiErrorCodes.ets` | `ApiErrorCodes.GEETEST_REQUIRED` |
| 游戏业务阈值             | `XxxConstants.ets`  | `GenshinConstants.RESIN_MAX`     |

**禁止**在组件或 ViewModel 文件中直接写字面量。

注意：`GridRow` 的 `columns` 参数（`{ xs, sm, md, lg }`）因 ArkTS 严格模式限制，**必须在调用处直接内联**，不能抽成常量。

---

## 四、日志规范

**禁止**直接使用 `console.log` / `console.info` / `console.warn` / `console.error`。

必须使用项目统一的 `Logger`：

```typescript
import { Logger } from "core";

Logger.info("TagName", "message");
Logger.warn("TagName", "message");
Logger.error("TagName", "message");
```

---

## 五、UI 组件文件拆分规范

**禁止**在 page 或 component 文件中用 `@Builder` 函数替代独立组件。`@Builder` 只允许用于极简的布局片段（无状态、无逻辑、3 行以内），凡是有独立语义的 UI 块必须拆成独立的 `@ComponentV2` struct 文件：

```typescript
// 错误 — 用 @Builder 承载有语义的 UI 块
@Builder
private renderSkillItem(skill: SkillItem) {
  Row() { ... }  // 10+ 行逻辑
}

// 正确 — 独立文件 components/chardetail/SkillItem.ets
@ComponentV2
export struct SkillItem {
  @Param skill: SkillItem = new SkillItem()
  build() { Row() { ... } }
}
```

**每个 `.ets` 文件只允许有一个业务 `@ComponentV2` struct**，`@Preview` struct 不计入此限制。

```typescript
// 错误 — 一个文件两个业务组件
@ComponentV2 export struct NotificationSection { ... }
@ComponentV2 struct NotificationAccountBlock { ... }  // ❌ 必须拆到独立文件

// 正确 — 各自独立文件
// NotificationSection.ets
@ComponentV2 export struct NotificationSection { ... }
@Preview @ComponentV2 export struct NotificationSectionPreview { ... }  // ✅ Preview 不算

// NotificationAccountBlock.ets
@ComponentV2 export struct NotificationAccountBlock { ... }
```

**禁止**在 page 文件中内联定义 `@ComponentV2` struct，每个组件必须有独立的 `.ets` 文件：

- 只在一个页面使用的组件 → 放在 `components/<页面名>/` 子目录
- 跨多个页面复用的组件 → 放在 `components/` 根目录（如 `SettingRow`、`SnackbarContent`、`GeetestDialog`、`SplitPlaceholder`）
- 属于某个功能模块的组件 → 放在 `components/<功能名>/` 子目录（如 `components/notification/`、`components/chardetail/`）
- **禁止**把组件放错目录，例如通知相关组件放到 `components/my/` 下
- **判断依据**：组件的触发场景，而不是它第一次出现的位置。`GeetestDialog` 在登录和数据同步时都会触发，属于全局通用组件，不属于 `login/`

**当功能模块目录下文件超过 10 个时，必须按游戏/职责拆分子目录：**

```
components/<功能名>/
├── common/      ← 三游戏通用的原子组件
├── genshin/     ← 原神专用
├── starrail/    ← 星铁专用
└── zzz/         ← 绝区零专用
```

子目录命名规则：

- 三游戏通用 → `common/`
- 游戏专用 → 用游戏简称（`genshin/`、`starrail/`、`zzz/`）
- 按职责拆分时 → 用职责名（如 `hero/`、`relic/`、`skill/`）

**禁止**在同一目录下混放通用组件和游戏专用组件，新增组件时必须先判断归属再放入对应子目录。

**拆分触发条件**（满足任意一条就必须拆）：

- UI 块超过 **15 行**
- UI 块有独立的语义名称（如"账号卡片"、"通知设置区"、"关于区"）
- UI 块在多处出现或将来可能复用
- UI 块内部有自己的状态或事件处理逻辑
- **`ForEach` 内部的 item 渲染块超过 10 行**，必须拆成独立组件（如 `XxxItem.ets`、`XxxCard.ets`）

**拆分的正确方式：**

拆分不是把代码搬到另一个文件，而是识别出有独立语义的子结构，让每一层只负责组合，不负责渲染细节：

```typescript
// 错误 — 把整个卡片搬到 AccountRoleCard，内部仍然是一大块内联代码
@ComponentV2
export struct AccountRoleCard {
  build() {
    Column() {
      Row() { Image(...); Column() { Text(...); Text(...) }; Text(...) }  // 顶部行，20行
      Column() {
        Row() { Text(...); Text(...); Text(...) }  // 服务器行，15行
        GridRow() { ForEach(...) { GridCol() { Column() { ... } } } }  // 统计格子，20行
      }
    }
  }
}

// 正确 — 每一层只组合子组件，子组件各自负责自己的渲染
@ComponentV2
export struct AccountRoleCard {
  build() {
    Column() {
      AccountRoleCardHeader({ role: this.role })   // 顶部：logo + 游戏名 + 等级
      AccountRoleCardFooter({ role: this.role })   // 底部：服务器行 + 统计格子
    }
  }
}

@ComponentV2
export struct AccountRoleCardFooter {
  build() {
    Column() {
      AccountRoleServerRow({ server: ..., uid: ... })  // 服务器/UID 行
      AccountRoleStatGrid({ stats: ... })              // 统计数据格子
    }
  }
}
```

判断标准：**如果一个组件的 `build()` 里出现了超过 2 层嵌套的布局代码，就说明还需要继续拆**。

page 文件的 `build()` 方法应该只包含对各 Section/Card 组件的组合调用，**不应该出现大段的内联布局代码**。

### @Preview 规范

**每个 `@ComponentV2` 组件文件末尾必须有至少一个 `@Preview`**，页面（`pages/`）也不例外。

规则：

- `@Preview` struct 命名为 `<组件名>Preview`，放在同一文件末尾
- 背景色统一使用 `'#1a1a2e'`（对应 `colorPageBg`）
- **可以使用 `$r()`**，预览环境支持资源文件访问
- 用 `@Local` 字段存储预览数据，**禁止** IIFE 或复杂初始化逻辑
- 覆盖组件的主要状态（空态、有数据、加载中等）

```typescript
// 正确示例
@Preview
@ComponentV2
export struct SectionHeaderPreview {
  build() {
    Column({ space: 8 }) {
      SectionHeader({ title: $r('app.string.my_section_account') })
      SectionHeader({ title: $r('app.string.my_section_about') })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
```

---

## 五·一、Model 文件归属规范

**禁止**在 ViewModel 文件中声明数据模型 class / interface。Model 和 ViewModel 职责不同，必须分开：

| 类型                             | 放哪里                                          |
| -------------------------------- | ----------------------------------------------- |
| DB Row 模型（对应数据库表字段）  | `core/src/main/ets/models/XxxRow.ets`           |
| API 响应模型（对应接口返回结构） | `core/src/main/ets/models/XxxModels.ets`        |
| UI 展示模型（ViewModel 用的 VM） | `entry/src/main/ets/models/XxxModels.ets`       |
| ViewModel 状态类                 | `entry/src/main/ets/viewmodel/XxxViewModel.ets` |

```typescript
// 错误 — Model 混在 ViewModel 文件里
// HomeViewModel.ets
class AccountCardVM { ... }  // ❌
@ObservedV2 export class HomeViewModel { ... }

// 正确 — 分开放
// models/HomeModels.ets
export class AccountCardVM { ... }
// viewmodel/HomeViewModel.ets
import { AccountCardVM } from '../models/HomeModels';
@ObservedV2 export class HomeViewModel { ... }
```

---

## 六、@Monitor 路径字符串规范

`@Monitor` 路径字符串写错不会报编译错误，**禁止**直接写字符串字面量，必须通过 ViewModel 的 `static readonly KEYS` 引用：

```typescript
// 声明 KEYS 类型（与 ViewModel 放在同一文件）
export class HomeViewModelKeys {
  networkErrorMsg: string = 'vm.networkErrorMsg';
}

@ObservedV2
export class HomeViewModel {
  static readonly KEYS: HomeViewModelKeys = new HomeViewModelKeys();
  @Trace networkErrorMsg: string = '';
}

// View 层使用
@Monitor(HomeViewModel.KEYS.networkErrorMsg)
onNetworkErrorChanged(_monitor: IMonitor): void { ... }
```

路径格式固定为 `'vm.字段名'`（`vm` 是 View 层持有 ViewModel 的字段名）。

---

## 七、Button 字体设置

`ButtonAttribute` **没有** `.font()` 方法，必须拆开写：

```typescript
// 错误
Button(label).font(this.tm.current.body13);
// 正确
Button(label)
  .fontSize(this.tm.current.body13.size)
  .fontWeight(this.tm.current.body13.weight)
  .fontColor(this.tm.current.colorTextPrimary);
```

---

## 八、组件复用规范

多个地方出现结构相似的 UI 块时，**必须**抽成一个共用组件，通过参数或 enum 控制差异，**禁止**复制粘贴相似代码。

判断标准：两处 UI 结构相同、只有数据或样式细节不同 → 抽组件。

```typescript
// 错误 — 两个地方各写一遍相似的 Row
// 通知设置行
Row() { Text(...).layoutWeight(1); Text('›') }.height(50).padding(...)
// 导出日志行
Row() { Text(...).layoutWeight(1); Text('›') }.height(50).padding(...)

// 正确 — 抽成 SettingRow，通过参数传入差异
SettingRow({ label: $r('app.string.my_section_notification'), onTap: ... })
SettingRow({ label: $r('app.string.my_export_logs'), onTap: ... })
```

共用组件的样式变体优先用 enum 参数控制，**禁止**为每种变体单独创建一个组件文件：

```typescript
// 错误 — 为每种变体建文件
// PrimaryButton.ets / DangerButton.ets / GhostButton.ets

// 正确 — 一个组件 + enum 变体
enum ButtonVariant { PRIMARY, DANGER, GHOST }
@ComponentV2
export struct AppButton {
  @Param variant: ButtonVariant = ButtonVariant.PRIMARY
  ...
}
```

---

## 九、简单优先原则

**能用最简单的方式解决就不要过度设计。**

- 能在父容器加 `.backgroundColor()` 解决的，不要给子组件加 `standalone` 参数
- 能用一个 `Column` 包一层解决的，不要引入新的抽象
- 新增参数前先问：调用方真的需要控制这个吗？如果只有一种用法，不需要参数化

```typescript
// 错误 — 过度设计，给组件加 standalone 参数控制背景
SettingRow({ label: ..., standalone: false })

// 正确 — 父容器负责背景，组件保持简单
Column() {
  SettingRow({ label: ... })
}
.backgroundColor(this.tm.current.colorSurfaceCard)
.borderRadius(this.tm.current.radius12)
```

---

## 十、注释规范

### 文件头注释

每个 `.ets` 文件必须有文件头注释，说明文件职责和关键约束：

```typescript
/**
 * GenshinElement — 原神元素枚举
 *
 * API 返回的 element 字段为英文字符串（如 'Hydro'、'Pyro'）。
 * 禁止在任何组件或 ViewModel 中直接写元素字符串字面量。
 * 转换函数 genshinElementFromString() 在边界处（ViewModel）调用一次，之后全程使用 enum。
 */
```

### enum 枚举值注释

每个 enum 值必须有行内注释说明含义，尤其是数字类型的 enum：

```typescript
export enum StarRailPath {
  DESTRUCTION = 1, // 毁灭
  HUNT = 2, // 巡猎
  ERUDITION = 3, // 智识
  UNKNOWN = 0,
}
```

字符串类型的 enum 如果值本身已经自解释（如 `HYDRO = 'Hydro'`），可以省略行内注释，但非显而易见的值必须注释。

### 函数注释

公开函数（`export function`）必须有 JSDoc 注释，说明参数含义和返回值：

```typescript
/**
 * API element 字符串 → GenshinElement enum
 * 未知值返回 GenshinElement.UNKNOWN
 */
export function genshinElementFromString(s: string): GenshinElement { ... }
```

私有方法（`private`）如果逻辑不显而易见，也需要注释。

### 字段注释

Row 模型、ViewModel 的 `@Trace` 字段必须有注释说明含义和取值范围：

```typescript
/** 元素属性字符串（如 'Fire'、'Ice'），来自 API element 字段 */
element: string = "";

/** 命途类型数字（米游社内部字段），用 starRailPathFromNumber() 转换为 StarRailPath */
baseType: number = 0;
```

### 禁止无意义注释

**禁止**写重复代码本身的注释：

```typescript
// 错误 — 注释等于没有
// 设置 name
this.name = name;

// 正确 — 注释说明"为什么"，而不是"做了什么"
// nickname 为空时降级显示 username，保证列表行不出现空白
this.displayName = nickname !== "" ? nickname : username;
```

---

## 十一、代码格式规范

### 组件调用之间必须空行

同一 `build()` 或 `@ComponentV2` 文件中，**相邻的组件调用之间必须有一个空行**，禁止紧贴在一起。

```typescript
// 错误 — 组件之间没有空行，拥挤难读
Column() {
  CharDetailSectionLabel({ title: $r('app.string.zzz_char_detail_props_title') })
  Column() {
    ForEach(this.vm.properties, (prop: ZZZCharDetailProperty, idx: number) => {
      Row() {
        Text(prop.name)
        Text(prop.final)
      }
    }, ...)
  }
}

// 正确 — 组件之间有空行，层次清晰
Column() {
  CharDetailSectionLabel({ title: $r('app.string.zzz_char_detail_props_title') })

  Column() {
    ForEach(this.vm.properties, (prop: ZZZCharDetailProperty, idx: number) => {
      Row() {
        Text(prop.name)

        Text(prop.final)
      }
      ...
    }, ...)
  }
}
```

**适用范围：**

- `build()` 方法内相邻的子组件之间
- `ForEach` / `LazyForEach` 的 item 渲染块内，相邻的子组件之间
- `Column`、`Row`、`Stack` 等容器内，相邻的子组件之间

**例外：** 单行属性链（`.width()`、`.height()` 等修饰符）不需要空行，它们属于同一组件的一部分。

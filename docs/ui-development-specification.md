# HarmonyOS UI 组件与页面开发及重构规范

> **版本：** v1.0
> **生效日期：** 2026-11-08
> **适用范围：** entry module（含 Normal Page、Widget Component、ViewModel）
> **参考：** ArkTS/ArkUI API 文档 + 项目实际分析数据 + 鸿蒙官方最佳实践

---

## 一、核心原则

1. **单一职责**：每个 `@Component` / `@ComponentV2` / `@Entry` 只负责一个 UI 块或一条业务流。
2. **按需拆分**：不为"拆"而拆——简单组合（如 `<Row> { Text + Icon }`）不需要独立文件。
3. **最小改动**：先从超大组件开始，小页面保持现状优先。
4. **命名一致**：子组件统一 `UpperCamelCase`，放在对应的 `views/` 目录下。
5. **Component 版本隔离**：详见第三章。

---

## 二、组件拆分与合并阈值标准

### 2.1 build() 行数阈值（硬性指标）

| 层级 | 行数范围 | 动作 |
|------|----------|------|
| **< 50** | ✅ 无需拆分 | 保持单文件 |
| **50–100** | 🟡 评估拆分 | 若内部存在 ≥2 个独立 UI 块可提取，建议拆分 |
| **100–200** | 🟠 必须拆分 | 至少提取 1–2 个核心子组件，目标 ≤150 行 |
| **200–300** | 🔴 强制拆分 | 必须拆分为 ≤3 个子组件，总行数 ≤200 |
| **> 300** | ⛔ 必须拆分至 ≤300 | 当前违规文件：MainPage (478 行)、Widget4x4SingleGame (337 行)；此类文件应优先处理，不得新增同类超大组件 |

### 2.2 函数数量阈值

- 单个组件 `build()` 内直接写死的布局块超过 **5 段**时，必须提取为独立 @Builder 方法或子组件。
- 单个组件总方法数（含 @Builder、事件处理）超过 **15 个**时，需评估拆分可能性。

### 2.3 合并规则

- 两个相关 UI 块合并后 build() 不超过 **80 行**，允许合并到同一文件。
- Widget Component 与普通 Page **不可互相复用或合并**。
- ViewModel 与 UI Component **禁止合并**。

---

## 三、Component 版本选择规范（硬性隔离）

### 3.1 Normal Page / views → 必须使用 `@ComponentV2`

**适用范围：**
- `pages/` 目录下的所有页面组件（MainPage、LaunchPage、TestPage、Index 等）。
- `views/` 目录下的所有子组件。

```typescript
// ✅ 正确：Normal 组件使用 @ComponentV2
@ComponentV2
export struct MainPage { }

// ❌ 错误：Normal 组件不可使用 @Component（V1）
@Component
struct OldPage { }
```

### 3.2 Widget Component → 必须使用 `@Component`（V1）

**适用范围：**
- `widget/pages/` 下的所有 Widget 页面。
- `widget/views/` 下的所有 Widget 卡片组件。

**原因：** Widget 渲染引擎运行在 `FormExtensionAbility` 中，**不支持 @ComponentV2**。

```typescript
// ✅ 正确：Widget 组件使用 @Component（V1）
@Component
export struct Widget4x4SingleGame { }

// ❌ 错误：Widget 组件不可使用 @ComponentV2
@ComponentV2
struct BadWidget { }
```

### 3.3 版本隔离规则

| 维度 | Normal Page (`@ComponentV2`) | Widget Component (`@Component`) |
|------|-----------------------------|--------------------------------|
| **状态装饰器** | `@Local`（V2 主状态）、`@Trace`（子组件共享） | `@State`（V1 主状态）、`@Link`、`@Prop` |
| **父子通信** | `@Link`（V2 语义不同） | `@Prop` / `@Link`（V1 标准） |
| **不可复用对方文件** | Widget Component 不能出现在 Normal Page 的 import 中 | Normal Page 的子组件不能出现在 Widget 的 import 中 |
| **状态共享** | 通过 AppStorage / Provide | 通过 FormExtensionAbility → formBindingData 注入 |

> **关键原则：两类组件的代码库完全隔离，禁止交叉引用。**

---

## 四、状态变量使用规范（@State / @Prop / @Link / @Provide / @Consume）

### 4.1 @Local（Normal Page - @ComponentV2）

> **注意：** Normal Page（V2）的主状态装饰器是 `@Local`，不是 `@State`。`@State` 仅用于 Widget Component（V1）。

**允许使用的场景：**
- 组件内部独有、不需要跨组件共享的 UI 状态。
- 例如：按钮按下态 `isPressed: boolean = false`、输入框内容 `inputText: string = ''`。

**禁止使用的场景：**
- 父组件也需要读取的状态（应改为 @Prop / @Link）。
- ViewModel 中已有的数据（@Local 应只持有引用，不持有原始数据）。
- 超过 **3 个** @Local 变量时，必须审查是否有必要全部为响应式。

### 4.2 @State（Widget Component - @Component V1）

> **注意：** Widget Component 使用 `@State` 作为主状态装饰器（V1 语义）。Normal Page（V2）应使用 `@Local`。

**允许使用的场景：**
- Widget 组件内部独有、不需要跨组件共享的 UI 状态。
- 例如：刷新标记 `isRefreshing: boolean = false`、加载态 `isLoading: boolean = false`。

**禁止使用的场景：**
- Widget 进程内做网络请求后直接更新 @State（无网络权限）。
- 嵌套对象直接作为 @State（应改用 `@Observed` + `@ObjectLink`）。
- Widget Component 中 @State 变量超过 **5 个**时，必须审查是否有必要全部为响应式。

### 4.3 @Prop（单向传递）

**使用场景：**
- 父组件持有状态源，子组件仅用于展示/读取。
- 适用于：游戏数据对象、配置参数等不可变或低频更新的数据。

### 4.4 @Link（双向绑定）

**使用场景：**
- 父子组件需要共同修改同一状态。
- 仅用于：开关切换、输入框同步、Tab 选中态等明确的共享状态。
- **禁止滥用**：每对 @Link 必须有清晰的归属方定义谁为主数据源。
- V2 中 `@Link` 语义与 V1 不同，Normal Page（V2）中应优先使用 V2 的 `@Link` 绑定方式。

### 4.5 @Provide / @Consume（全局共享）

**使用场景：**
- 多层嵌套组件间共享的状态，避免 prop drilling。
- 适用于：主题切换 `appearanceTheme`、用户登录态、语言设置。

**限制：**
- 单个应用层最多 **5 个** @Provide 变量。
- @Provide 的键名必须使用常量定义（如 `const THEME_KEY = 'appearanceTheme'`）。

### 4.6 @Observed / @ObjectLink（对象级响应）

**Normal Page（V2）使用场景：**
- 复杂业务对象作为整体传入子组件，支持深嵌套变化检测。

**Widget Component（V1）使用场景：**
- Widget 中传递数组或对象数据时，必须用 `@Observed` + `@ObjectLink` 替代普通 @Prop。
- 适用于：Widget 接收 `GameRecord[]`、`StaminaData` 等复杂数据结构。

---

## 五、@Builder 抽离原则

### 5.1 @Builder 必须外置到独立文件（硬性规则）

**Component / Page 文件中禁止出现任何 `@Builder` 关键字。**

所有 @Builder 函数必须提取到单独的 `{组件名}Builders.ets` 文件中，然后由主文件 import 使用。

```typescript
// ❌ 错误：MainPage.ets 中直接写 @Builder
@ComponentV2
export struct MainPage {
  build() {
    // ...
  }
}

@Builder
function accountSwitchDialogBuilder(params: AccountSwitchDialogParams) {
  AccountSwitchDialog({ params })
}

// ✅ 正确：MainPage.ets（无 @Builder） + MainPageBuilders.ets
// MainPage.ets
import { accountSwitchDialogBuilder } from './MainPageBuilders'

@ComponentV2
export struct MainPage {
  build() {
    // ...
  }
}

// MainPageBuilders.ets
import { AccountSwitchDialog } from '../pages/AccountSwitchDialog'
import { AccountSwitchDialogParams } from '../models/AccountSwitchDialogParams'

@Builder
export function accountSwitchDialogBuilder(params: AccountSwitchDialogParams) {
  AccountSwitchDialog({ params })
}
```

### 5.2 @Builder 文件命名规范

| 主文件 | Builder 文件 |
|--------|-------------|
| `MainPage.ets` | `MainPageBuilders.ets` |
| `Widget2x2.ets` | `Widget2x2Builders.ets` |
| `GameCardView.ets` | `GameCardViewBuilders.ets` |

- 一个 Builder 文件只装载**单个组件/页面**的 @Builder。
- Builder 文件中的函数统一 `export`，主文件按需 import。

### 5.3 @Builder 组织建议

- Builder 函数超过 **5 个**时，用 `// --- 区块名称 ---` 注释分隔不同 UI 模块。
- 公共辅助逻辑（如通用样式计算）可抽取为普通函数，放在 Builder 文件底部。

### 5.4 何时应该创建独立子组件而非 @Builder

- @Builder 需要接收的参数超过 **3 个**。
- @Builder 内部包含复杂的事件处理逻辑或嵌套状态管理。
- @Builder 需要被另一个 `@Entry` 或其他模块引用（跨页面共享）。
- 该 UI 块未来可能在其他页面/组件中复用。

### 5.5 @BuilderMethod vs @BuilderParam

| 特性 | @Builder（方法） | @BuilderParam（参数） |
|------|------------------|-----------------------|
| 定义方 | 子组件 | 父组件 |
| 调用方 | 父组件传入构建函数 | 子组件内调用 |
| 适用场景 | 子组件定义 UI 结构，父组件传数据 | 父组件定义 UI 结构，子组件决定何时渲染 |
| 示例 | `@Builder showHeader()` | `@BuilderParam headerBuilder: () => void` |

---

## 六、文件命名规范

### 6.1 目录结构

```
entry/src/main/ets/
├── entryability/          # EntryAbility 入口
├── entryformability/      # FormAbility 入口
├── pages/                 # Normal Page（@Entry）
│   ├── MainPage.ets
│   └── GameDetailPage.ets
├── views/                 # 子组件（非 @Entry）
│   ├── GameCardView.ets
│   └── StatRow.ets
├── widget/                # Widget 专属模块（与 pages/ 完全隔离）
│   ├── pages/             # Widget 页面
│   │   ├── Widget2x2.ets
│   │   └── Widget4x4.ets
│   ├── views/             # Widget 组件
│   │   ├── Widget2x2SingleGame.ets
│   │   └── WidgetExtraDataRows.ets
│   └── viewmodel/         # ViewModel
│       └── Widget2x2ViewModel.ets
├── viewmodel/             # Normal Page ViewModel
├── utils/                 # 工具函数
└── constants/             # 常量定义
```

### 6.2 文件名规则

| 类型 | 命名格式 | 示例 |
|------|----------|------|
| Page（@Entry） | `XxxPage.ets` | `MainPage.ets`, `GameDetailPage.ets` |
| Widget Page | `Widget{Size}.ets` | `Widget2x2.ets`, `Widget4x4.ets` |
| 子组件 | `XxxView.ets` 或 `Xxx.ets` | `GameCardView.ets`, `StatRow.ets` |
| Widget 组件 | `Widget{Size}{Desc}.ets` | `Widget2x2SingleGame.ets` |
| ViewModel | `XxxViewModel.ets` | `GameViewModel.ets`, `Widget2x2ViewModel.ets` |
| 工具函数 | `xxxxUtils.ets` 或 `xxxUtil.ets` | `FormatUtil.ets`, `DateUtils.ets` |
| 常量 | `xxxxConstants.ets` | `ApiConstants.ets` |

### 6.3 组件类名与文件名必须一致

```typescript
// ✅ 正确：GameCardView.ets → export struct GameCardView
export struct GameCardView { }

// ❌ 错误：GameCardView.ets → export struct CardView
export struct CardView { }
```

---

## 七、Widget Component 特殊约束

### 7.1 独立运行环境

- Widget Component 运行在 `FormExtensionAbility` 进程中，与主 App **隔离**。
- Widget Component **不能导入 HAR/HSP** 中的非公开模块（需检查 `module.json5` 的 `requestPermissions`）。
- Widget Component **不支持调试特性**（如部分 console.log 行为可能受限）。

### 7.2 代码量限制

- Widget Component 的 build() 行数严格遵循第二章阈值，但建议更激进：
  - **Widget4x4SingleGame (337 行)** → 目标 ≤300 行（拆 1–2 个子组件）
  - **Widget2x4SingleGame (282 行)** → 目标 ≤250 行（提取独立逻辑块）
  - **Widget1x2ContentView (121 行)** → 已接近 100 行评估线，建议提前拆分 ≥30 行的嵌套区块
- 上述阈值低于通用标准的原因是：Widget 渲染在独立进程中，代码量直接影响内存占用和响应速度。

### 7.3 数据获取限制

- Widget Component **不能直接使用网络请求**（Widget 进程无网络权限）。
- 所有数据需通过 `FormExtensionAbility` 预加载后以 `formBindingData` 形式传入。
- ViewModel 只能在 `FormExtensionAbility` 中执行，不能放在 Widget Component 内部。

### 7.4 状态管理限制

- Widget Component **不支持 @State 的复杂嵌套对象响应**。
- 优先使用简单的原始类型（string, number, boolean）+ `@ObjectLink` 传递不可变数据。
- 避免在 Widget Component 中使用大量 @State 变量（建议 ≤5 个）。

---

## 八、重构优先级与执行流程

### 8.1 优先级映射（基于分析数据）

| 优先级 | 标准 | 当前实例 |
|--------|------|----------|
| **P0 / W-V1** | >300 行，立即重构 | MainPage (478) [Normal], Widget4x4SingleGame (337) [Widget] |
| **P1 / W-V2** | 100–300 行，本周内 | Widget2x4SingleGame (282) [Widget], Widget4x4 (113) [Widget Page], Widget2x4 (110) [Widget Page], Widget2x2 (109) [Widget Page], TestPage (105) [Normal], Widget1x2ContentView (121) [Widget], WidgetExtraDataRows (115) [Widget] |
| **P2 / W-V3** | 80–100 行，下迭代 | LaunchPage (91) [Normal], Widget1x2Genshin/StarRail/ZZZ (82) [Widget], Widget2x2StarRailStamina (91) [Widget], Widget2x2SingleGame (99) [Widget] |
| **P3** | <80 行但结构复杂，优化为主 | Index.ets (33) [Normal] |

### 8.2 重构执行步骤

1. **阅读组件完整代码**，识别所有 UI 区块。
2. **绘制组件依赖图**，确定父子关系和数据流向。
3. **提取 @Builder** 作为第一步，验证行为不变。
4. **创建子组件文件**，将 @Builder 提升为独立 `struct`。
5. **更新状态管理**：检查是否需要调整 @State/@Prop/@Link。
6. **编译并通过 hvigorw**，确保无新增警告。
7. **在模拟器运行验证**，UI 行为与原组件一致。

### 8.3 重构验收标准

- build() 行数降低到目标阈值以内。
- 无新增 lint/warning。
- 所有原有功能正常（通过手动测试或已有测试）。
- 文件命名符合五、六章规范（@Builder 外置 + 组件命名）；
- 每个子组件有清晰的单职责描述（写在文件头部注释中）。

---

## 九、新建 UI 组件检查清单

创建新页面或组件前，自查以下内容：

- [ ] build() 行数是否 ≤150 行？如超限，是否需要提前拆分？
- [ ] Component 版本是否正确？（Normal Page → `@ComponentV2`；Widget → `@Component`）
- [ ] @Local/@State 变量数量是否合理（Normal Page `@Local` ≤3 个，Widget Component `@State` ≤5 个）？
- [ ] 所有 @Builder 是否已外置到 `{组件名}Builders.ets` 文件（主文件中禁止出现 `@Builder` 关键字）？
- [ ] 文件名是否与组件类名一致？
- [ ] 是否在正确的目录下（pages/、widget/pages/、views/）？
- [ ] 状态变量是否正确选择了装饰器（@State/@Prop/@Link）？
- [ ] 如有网络请求，是否在合适的层次（EntryAbility/FormAbility，而非 Widget Component）？
- [ ] ViewModel 是否独立文件，不混入 UI 代码？

---

> **本规范自生效日起对所有新建和重构的 UI 组件/页面强制生效。**
> 已有违规组件按第八章优先级逐步修复。

【已核对代码一致性】

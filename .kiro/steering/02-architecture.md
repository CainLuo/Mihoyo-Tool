# 项目架构规范

## 一、多模块架构边界

本项目采用鸿蒙多模块架构，`core` 和 `entry` 有严格的物理边界。

### `core` 模块（底层基础设施）

- **职责**：网络请求、数据模型、JSON 解析、加密解密、本地持久化存储（KVStore/RDB）
- **禁区**：绝对不允许出现任何 ArkUI 组件（`@Component`、`Text`、`Column` 等）
- **暴露规范**：所有对外提供的类、接口、单例，必须统一在 `core/Index.ets` 中 `export`

### `entry` 模块（UI 与业务展示）

- **职责**：视图渲染、路由跳转、UI 状态管理
- **依赖调用**：需要网络或数据能力时，必须从 `core` 模块导入
- **禁区**：
  - 严禁直接操作数据库（`RdbManager`、DAO 类、`Row` 模型写入）
  - 严禁直接调用 `ApiService` 网络方法后自己写 DB
  - 严禁判断 `isMock`、`APP_RUNTIME_ENV` 等环境变量做业务分支
  - 唯一例外：`EntryAbility.onCreate` 负责从 `BuildProfile` 读取环境并通过 `CoreInitializer.initCore()` 传给 core

---

## 二、MVVM 分层架构

```
entry/src/main/ets/
├── pages/          # View 层 — 只负责渲染，不含业务逻辑
├── components/     # View 层 — 可复用 UI 组件
└── viewmodel/      # ViewModel 层 — UI 状态 + 业务逻辑调用

core/src/main/ets/
├── repository/     # Model 层 — 数据访问（网络 + 本地 DB）
├── network/        # 网络基础设施
└── database/       # 数据库基础设施
```

### ViewModel 规范

- 每个页面对应一个 ViewModel，命名：`XxxViewModel.ets`
- 用 `@ObservedV2` 装饰类，用 `@Trace` 装饰所有需要驱动 UI 更新的字段
- 不得包含任何 ArkUI 组件代码
- **ViewModel 负责把业务数据转换为 UI 直接可用的形式**，Component 只负责渲染，不做任何业务判断

### UI State 规范

**UI State 以页面为单位定义，不是以 Component 为单位。**

ViewModel 持有页面所需的全部 UI State，子 Component 直接接收父级传下来的 UI State 对象，不需要为每个 Component 单独定义新的数据类型：

```
MyViewModel
  └── accounts: MyAccountVM[]        ← 页面级 UI State
        └── roles: MyGameRoleVM[]    ← 嵌套的 UI State
              ├── gameName: Resource  ← 已转换，Component 直接用
              ├── logoResource: Resource
              └── ...

My.ets → AccountListSection({ accounts }) → AccountRoleCard({ role }) → AccountRoleCardHeader({ role })
         同一个 MyGameRoleVM 对象层层传递，不在中间层重新定义
```

UI State 类放在 `entry/src/main/ets/models/` 目录，命名后缀 `VM`（如 `MyGameRoleVM`）。它不是 Model 层的东西，是专门为 View 准备的展示数据结构，字段全是 View 直接能用的形式（`Resource`、`ResourceColor`、`ResourceStr` 等）。

**什么时候才需要新定义 UI State 类型？**

- 跨多个页面复用的通用组件（如 `SettingRow`）需要的参数和现有 UI State 差异很大时
- 现有 UI State 嵌套层级太深，传递路径过长时

**跨页面共用的 Component 处理方式：**

共用 Component **不得依赖任何具体页面的 UI State 类型**。字段少时可以直接声明原子参数，字段多时应该为这个 Component 定义一个专属的 UI State 类，放在 `entry/models/` 里。各页面的 ViewModel 负责把自己的数据映射成这个类型：

```typescript
// entry/models/RoleCardModels.ets
// 共用 Component 的专属 UI State，是这个 Component 的"数据契约"
export class RoleCardVM {
  logoResource: Resource = ...
  gameName: ResourceStr = ''
  gameColor: ResourceColor = ...
  level: number = 0
  server: ResourceStr = ''
  roleUid: string = ''
  bgImageUrl: string = ''
  stats: GameStatItem[] = []
}

// 共用 Component 只依赖自己的 UI State 类型
@ComponentV2
export struct AccountRoleCard {
  @Param role: RoleCardVM = new RoleCardVM()
}

// My 页的 ViewModel 映射
new RoleCardVM(role.logoResource, role.gameName, ...)

// Characters 页的 ViewModel 也映射成同一个类型
new RoleCardVM(character.logoResource, character.gameName, ...)
```

判断标准：

- **只在一个页面使用** → 直接传整个页面的 UI State 对象（如 `MyGameRoleVM`）
- **跨页面复用，字段少（≤3个）** → 直接声明原子参数
- **跨页面复用，字段多** → 为这个 Component 定义专属 UI State 类，放在 `entry/models/`

**禁止**在 Component 里出现以下逻辑，这些属于 ViewModel 的职责：

```typescript
// 错误 — Component 里根据 gameId 决定显示哪个 logo
private gameLogoResource(gameId: GameId): Resource {
  if (gameId === GameId.GENSHIN) { return $r('app.media.logo_genshin') }
  ...
}

// 正确 — ViewModel 在构建 UI State 时已经把 logo 资源算好，Component 直接用
// MyGameRoleVM.logoResource: Resource  ← ViewModel 填充
Image(this.role.logoResource)  // Component 只管渲染
```

同理，以下逻辑也不应该出现在 Component 里：

- 根据枚举值/状态决定显示什么颜色、图标、文字
- 根据数据计算显示格式（如时间格式化、数字格式化）
- 任何 `if (xxx === GameId.YYY)` 形式的业务判断

这些都应该在 ViewModel 或工具函数（`entry/utils/`）里完成，Component 接收的字段应该是**已经处理好的展示值**。

**允许留在 Component 里的运算（纯 UI 布局决策）：**

- 列表最后一项不显示分割线：`idx < list.length - 1 ? value1 : 0`
- 根据 index 决定圆角方向（首项/末项）
- 根据容器宽度决定列数（断点响应式）

这类运算的特征是：**只依赖 UI 结构本身（index、列表长度、容器尺寸），不依赖任何业务数据**，放在 View 层是正确的，不需要移到 ViewModel。

```typescript
@ObservedV2
export class HomeViewModel {
  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace accounts: MihoyoAccountVM[] = [];

  async loadData(): Promise<void> {
    // 调用 Repository，更新 @Trace 字段驱动 UI
  }
}
```

### View 层使用 ViewModel

```typescript
@ComponentV2
export struct Home {
  @Local private vm: HomeViewModel = new HomeViewModel()

  aboutToAppear(): void {
    this.vm.loadData()
  }
}
```

### 新增页面流程

1. 新建 `XxxViewModel.ets`
2. 新建 `Xxx.ets`（View 层，包含 `NavDestination`）
3. 在 `AppRoutes.ets` 添加路由常量
4. 新建 `XxxBuilder.ets`（只做透传）
5. 在 `custom_router_map.json` 注册
6. 在 `Main.ets` 的 `allDetailBuilder` 添加 `else if` 分支

---

## 三、路由规范

使用系统原生 `Navigation` + `NavPathStack`。**禁止**使用 `@hadss/hmrouter` 或系统 `router` 模块。

### 哪些页面需要 Builder

**需要 Builder**（通过 `pushPathByName` 跳转的页面）：Launch、Main、Login、GenshinDailyDetail、GenshinCharacterDetail、AccountDetail、NotificationSettings 等。

**不需要 Builder**（Tab 子页，由 Main 的 Navigation 直接渲染）：Home、Characters、My。

### 路由 Path 管理

所有路由 path 必须在 `entry/src/main/ets/constants/AppRoutes.ets` 中声明，**禁止**直接写字符串字面量。

### 页面 UI 标准

**全屏页**（Launch、Main）：`.hideTitleBar(true)` + `.ignoreLayoutSafeArea(...)`

**二级页**（push 跳转）：页面组件自身包含 `NavDestination`，Builder 只做透传：

```typescript
// Xxx.ets
build() {
  NavDestination() { /* 内容 */ }
    .title($r('app.string.xxx_title'))
    .hideTitleBar(false)
    .onReady((ctx: NavDestinationContext) => { this.localStack = ctx.pathStack })
}

// XxxBuilder.ets
@Builder
export function XxxBuilder(_name: string, _param: Object) { Xxx() }
```

---

## 四、多环境与 Mock 规范

项目有 `mock`、`debug`、`release` 三个环境，通过 `MihoyoApiServiceFactory` 按环境注入不同 Service，对 Repository 层完全透明。详见 `07-env-and-mock.md`。

核心约束：

- **禁止**在 ViewModel / Repository / 页面中判断 `isMock` 或 `APP_RUNTIME_ENV`
- 所有网络调用必须通过 Repository，不得直接 `new` Service 实例
- 唯一允许读取环境的地方：`EntryAbility.onCreate` 通过 `CoreInitializer.initCore()` 传入

---

## 五、游戏支持范围

当前支持：原神（`GameId.GENSHIN`）、崩坏：星穹铁道（`GameId.STARRAIL`）、绝区零（`GameId.ZZZ`）。崩坏3 暂不支持。

- **数据库层**：所有游戏数据全部写入，不过滤
- **读取层**：`BBSRepository.getGameRoles()` 只返回 `SUPPORTED_GAMES` 列表中的游戏
- **禁止**在 entry 层直接过滤 `gameId`，过滤逻辑统一在 `BBSRepository.getGameRoles()` 中

启用新游戏时，在 `core/src/main/ets/constants/GameId.ets` 的 `SUPPORTED_GAMES` 数组中添加对应枚举值。

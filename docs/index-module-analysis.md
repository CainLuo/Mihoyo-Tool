# Index 模块独立分析文档

> 生成时间：2026-10-24 | 作用 scope：`entry/src/main/ets/pages/Index.ets`（34 行）| **不修改代码**
> 代码版本：`105c8d3`（本文档分析基线，2026-10-24 复核）

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | 0 |

**整体评级：A**

> 口径：skills `harmonyos-review` 官方 A-F 评级（0 Critical + 0 High，Medium ≤ 5）。旧百分制已废弃，原分 95/100 仅作历史参考。
>
> 债务点数 0，密度 0（2026-10-27 复核前为 0/0/0/2、2 点、5.9）：原两条 Low 的前提经核对均不成立，见 §6。

---

## 1. 文件清单

| 文件 | 类型 | 行数 | 职责 |
|------|------|------|------|
| `Index.ets` | Entry / @ComponentV2 | 34 | 应用唯一入口——初始化路由栈 + 启动引导流程 |

**直接导入依赖**：AppRoutes（常量路由表）、RouterUtil（路由工具类）、Launch/PrivacyConsentPage/Main（页面组件）。

## 2. 架构分析（结构树）

```
Index (@Entry, @ComponentV2)
├── private pathStack: NavPathStack
├── aboutToAppear()
│   ├── RouterUtil.init(this.pathStack)
│   └── this.pathStack.pushPathByName(AppRoutes.LAUNCH, null)
│       → 启动后首屏为 LaunchPage.ets（启动闪屏；未同意隐私时由 Launch 再 replace 到隐私页）
├── build()
│   └── Navigation(pathStack)
│       ├── .navDestination(pageBuilder) — 动态路由分发
│       ├── .mode(NavigationMode.Auto) — 自动导航模式
│       └── .hideNavBar(true) — 隐藏 NavBar（Index 自身无首页内容，只作 NavDestination 宿主）
├── pageBuilder(name, param) — 条件分发三个入口页面
│   ├── AppRoutes.LAUNCH → Launch()
│   ├── AppRoutes.MAIN → Main()
│   └── AppRoutes.PRIVACY_CONSENT → PrivacyConsentPageBuilder(name, param)
└── (无 @Preview —— `@Entry` 页可直接在 Previewer 中预览，不需要)
```

**架构模式**：路由入口壳——Index 不处理任何业务逻辑，仅负责创建 NavPathStack、初始化 RouterUtil、并跳转到第一个页面。

## 3. ArkTS 合规性检查

| 检查项 | 状态 | 说明 |
|--------|------|------|
| `@Entry` + `@ComponentV2` + `struct` | ✅ 通过 | ArkUI V2 入口组件标准写法 |
| NavPathStack 初始化 | ✅ 通过 | 字段声明 L21 `new NavPathStack()`，`aboutToAppear` 中注入 `RouterUtil.init()`（非在 aboutToAppear 创建） |
| RouterUtil.init() 调用时机 | ✅ 通过 | 在 aboutToAppear 中初始化，时机正确 |
| hideNavBar(true) | ✅ 通过 | Index 无首页内容，隐藏 NavBar 后只显示栈顶 NavDestination |

**ArkTS 结论：通过**

## 4. 组件复用分析

- **pageBuilder 路由分发器**：只分发 Launch / Main / PrivacyConsent 三个不在 routerMap 的框架页；其余页面走 `custom_router_map.json`，新增页面不要加在这里（见 §7 不变量 3）
- **NavPathStack 实例**：应用的根路由栈由 Index 的实例字段持有并传入 Navigation（`RouterUtil` 操作的就是它）；Main 内层另有一个 4 Tab 共享的 `NavPathStack`（`MainPage.ets:60`），二级页都压在那个栈上。Index 本身是 @Entry 入口组件（应用生命周期内只创建一次）

## 5. 安全审查

| 风险 | 级别 | 说明 |
|------|------|------|
| 无异常捕获 | ✅ 无需 | `RouterUtil.init()` 只是赋值（`RouterUtil.ets:12-14`）；`pushPathByName` 对未知路由名不抛异常，且 `pageBuilder` 与跳转方用的是同一组 `AppRoutes` 常量（`Index.ets:9-13/25`），不存在拼写不一致；try/catch 不会改变任何结果 |

**安全结论：通过**

## 6. 风险清单

无计数条目。2026-10-27 复核撤回原两条 Low：

- ~~**低优先级**：RouterUtil.init() / pushPathByName 无 try-catch~~ —— 两个调用都不会因路由名错误而抛异常（见 §5），加 try/catch 不能防止白屏；两端共用 `AppRoutes` 常量，拼写不一致的前提不存在。
- ~~**低优先级**：Entry 页未提供 `@Preview`~~ —— `@Entry` 页面本身即可在 DevEco Previewer 中预览，「只能注释 `@Entry` 后预览」的说法不成立，不构成缺陷。

---

## 7. 重构执行备注（M15）

> 执行以 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) 为准。

**不变量**

1. **`Index` 是 main_pages.json 中唯一的 `@Entry` 页面**，页面名不可重命名；M15 只允许拆「入口壳内部逻辑」，不允许换入口文件名。
2. `aboutToAppear` 中「先 `RouterUtil.init(stack)`、再 `pushPathByName(AppRoutes.LAUNCH)`」的顺序是全局路由初始化契约，抽 helper 时必须保持同步初始化 + 首次跳转在同一生命周期内完成。
3. `pageBuilder` 的三个分支名（LAUNCH / MAIN / PRIVACY_CONSENT）必须与 `AppRoutes` 常量逐字一致；新增路由只能走 `custom_router_map.json`，不要在这里堆业务分支。

**测试**：无自动化测试；改动后手测冷启动 → Launch → Main 全链路，以及「清后台再启动」时的路由栈重建。

**拆分建议**：Index 保持 30 行左右，不抽 ViewModel；最多把 `RouterUtil.init + 首次跳转` 换成 `AppBootstrap.enter(pathStack)`，且需保证 `RouterUtil` 单例只初始化一次。

---

*本文档仅分析，不修改代码。*

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 结构） | Index.ets 34 行、pageBuilder 三分支、build() Navigation 配置、main_pages.json 唯一 @Entry | ✅ 全部精确匹配 |
| 第 2 轮（关键代码段） | aboutToAppear L23-26、RouterUtil.init L24、pushPathByName L25、AppRoutes 常量三值 | ✅ |
| 第 3 轮（全面复核） | NavPathStack 初始化位置修正、无测试声明、RouterUtil.init 签名 | ✅ 修正 1 处 |
| 第 4 轮（2026-10-27 逐条复核） | 两条 Low 的前提、`RouterUtil.ets`、结构树描述 | 撤回 2 条 Low；修正 Launch「引导/隐私同意页」与 `hideNavBar`「隐藏顶部导航栏」两处描述。计数 0/0/0/2 → **0/0/0/0**，评级 A 不变，债务 2 → 0 |

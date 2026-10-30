# TestPage 模块独立分析文档

> 生成时间：2026-10-24 | 作用 scope：`entry/src/main/ets/pages/TestPage.ets`（106 行）| **不修改代码**
> 代码版本：`105c8d3`（本文档分析基线，2026-10-24 复核）

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | 1 |

**整体评级：A**

> 口径：skills `harmonyos-review` 官方 A-F 评级（0 Critical + 0 High，Medium ≤ 5）。旧百分制已废弃，原分 93/100 仅作历史参考。
>
> 债务点数 = 1，密度 = 1 ÷ 1.06 = **0.9**（2026-10-27 复核前为 0/0/0/2、2 点、1.9）。

---

## 1. 文件清单

| 文件 | 类型 | 行数 | 职责 |
|------|------|------|------|
| `TestPage.ets` | Page / @ComponentV2 | 106 | 测试工具页（仅 `BuildProfile.DEBUG` 构建可见；mock / uat 以 debug 模式构建，见 `run.sh:84-97`）——Cookie 刷新/过期手动测试场景集中地 |

**直接导入依赖**：ThemeManager、CoreInitializer/FailedAccountInfo、CookieExpiredSignal、TestSectionHeader、TestRow。

## 2. 架构分析（结构树）

```
TestPage (@ComponentV2；由 TestPageBuilder 经 routerMap 渲染，压在 Main 的内层栈上)
├── @Local tm: ThemeManager = themeManager
├── build()
│   └── NavDestination (title=test_page_title + hideTitleBar(false))
│       └── Scroll → Column({space: value8})
│           ├── TestSectionHeader("Cookie 刷新 / 过期")
│           ├── TestRow(T1) → onTestT1() — 设置 update_time 为 8 天前（有 stoken）
│           ├── TestRow(T2) → onTestT2() — 直接触发 CookieExpiredSignal
│           └── TestRow(T3) → onTestT3() — 设置 update_time 为 8 天前（无 stoken）
├── onTestT1() — CoreInitializer.bbsRepository.setAllUpdateTimeTo8DaysAgo() + Toast
├── onTestT2() — FailedAccountInfo + CookieExpiredSignal.instance().push(fakeInfo)
└── onTestT3() — CoreInitializer.bbsRepository.setAllCookieWithoutStoken() + Toast

TestPageBuilder(_name, _param) — 路由 Builder（参数未使用）
```

**架构模式**：纯操作面板——无状态管理、无 ViewModel，直接操作服务层 + 信号类进行手动测试。

## 3. ArkTS 合规性检查

| 检查项 | 状态 | 说明 |
|--------|------|------|
| `@ComponentV2` + `struct` | ✅ 通过 | |
| TestRow / TestSectionHeader 复用 | ✅ 通过 | 通用测试组件，职责单一 |
| @Preview + @ComponentV2 Preview struct | ✅ 通过 | |

**ArkTS 结论：通过**

## 4. 组件复用分析

- **TestSectionHeader / TestRow**：独立测试子组件——可复用于其他测试页
- **CookieExpiredSignal.instance().push()**：标准信号触发模式——T2 直接复用此模式模拟过期场景
- **CoreInitializer.bbsRepository**：统一仓库入口——T1/T3 通过同一接口操作

## 5. 安全审查

| 风险 | 级别 | 说明 |
|------|------|------|
| 生产环境可见性依赖构建变体 | ⚠️ 低 | `build-profile.json5` **没有** `exclude` 配置，入口唯一开关是 `MainPage.ets:378` 的 `BuildProfile.DEBUG`。`BuildProfile.DEBUG` 跟随 buildMode 而非 product：`run.sh` 中 mock / uat 用 `debug`（`:86/94`）、release 用 `release`（`:102`），所以 **UAT / Mock 可见、release 不可见**。release 包内页面代码与 routerMap 条目（`custom_router_map.json:49-51`）仍在（见 L1） |
| 页面注释与实现一致 | ✅ | 文件头注释「UAT / Mock 可见，BuildProfile.DEBUG」（`TestPage.ets:2`）与上行构建事实一致；旧版判为不一致是误读了 UAT/Mock 的 buildMode |

**安全结论：通过（存在轻微瑕疵）**

## 6. 风险清单

- [ ] **低优先级 L1**（checklist COMPAT-005）：release 构建仍保留 debug-only 页面——`TestPage.ets` 被编译进包，`custom_router_map.json:49-51` 的 `TestPage` 路由也在，只有 `MainPage.ets:378` 的菜单入口被 `BuildProfile.DEBUG` 隐藏。该页的 T3 会把所有账号 Cookie 里的 stoken 删掉（`TestPage.ets:80-81` → `core/.../BBSRepository.ets:388-400`），任何 `pushPathByName('TestPage')` 都能到达。建议 release 用 target `source` 排除或去掉 routerMap 条目（属 Q-2 决策，本次不改）
- ~~原 L1：文件头注释「UAT / Mock 可见」与门控不符~~（2026-10-27 撤回）：UAT / Mock 以 debug 模式构建，注释正确，见 §5
- ~~原 L2：无 TAG 常量 + JSDoc~~（2026-10-27 撤回）：本页没有任何日志调用，TAG 常量无用武之地；文件头已有说明注释（`TestPage.ets:1-5`）

---

## 7. 重构执行备注（M15）

> 执行以 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) 为准。

**路由事实**：`TestPage` 在 `custom_router_map.json` 注册（`TestPageBuilder`），路由常量 `AppRoutes.TEST_PAGE`，入口是 Main 的 `currentMenuItems`（仅 `selectedTab === TAB_MY && BuildProfile.DEBUG`）。三处必须同步，缺一则死链。

**决策归属（Q-2）**：TestPage 是保留为长期手测面板、还是移出主包，属于产品/构建决策，不在 M15 拆分范围内。在决策前：

1. **不要**把 TestPage 迁移到新目录或改 Builder 名；
2. **不要**给它补依赖注入 / ViewModel——它故意直连 `CoreInitializer.bbsRepository` 与 `CookieExpiredSignal`；
3. 若要移出 release 包，应通过 `build-profile.json5` 的 target `source` / 条件编译实现，并同步删除 routerMap 条目，而不是只删 Main 的按钮。

**测试**：本身即测试工具，无自动化测试；改动后手测 T1/T2/T3 三个场景能正常触发对应信号，并确认 release 包内该入口不可见。

---

*本文档仅分析，不修改代码。*

### 复核记录（2026-10-26 第 4 轮）

| 检查项 | 结论 |
| --- | --- |
| 结构 | `TestPage.ets` 106 行；仅 `@Local tm` 一个状态字段（`:14`），无 `@Param` / `@Monitor` |
| 依赖 | `entry/src/main/ets/views/test/TestRow.ets`、`entry/src/main/ets/views/test/TestSectionHeader.ets` 均存在且仅被本页使用 |
| 路由 | `custom_router_map.json` 有 `TestPage` 条目；入口由 `MainPage.ets:378` 的 `BuildProfile.DEBUG` 控制可见性 |
| 结论 | 0 Critical / 0 High / 0 Medium / 2 Low，债务 2，评级 A，与 README 一致 |

### 复核记录（2026-10-27 第 5 轮）

| 检查项 | 结论 |
| --- | --- |
| 构建可见性 | 核对 `run.sh:84-107`：mock / uat 为 debug 模式，`BuildProfile.DEBUG` 为 true；原「UAT/Mock 不是 DEBUG 构建」错误，撤回原 L1 |
| 原 L2 | 全文件无 `Logger` 调用、已有文件头注释，撤回 |
| 新增 | COMPAT-005：release 包保留 debug-only 页面与 routerMap 条目，T3 为破坏性操作，记为 L1 |
| 结论 | 0 / 0 / 0 / **1**，债务 2 → 1，密度 1.9 → 0.9，评级 A 不变 |

【已核对代码一致性】

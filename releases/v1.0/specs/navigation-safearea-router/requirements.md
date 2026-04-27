# 需求文档：Navigation · NavDestination · SafeArea · Router 优化

> 参考来源：`Documents/Navigation-SafeArea-Router-Guide.md`（基于官方文档整理）
> 官方最佳实践页面（已通过 webFetch rendered 模式抓取）：
>
> - [窗口沉浸式最佳实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-device-window-immersive)（2026-03-12）
> - [多设备设置界面最佳实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-settings-application-page)（2026-03-12）
> - [安全区域 API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-expand-safe-area)（2026-04-20）

---

## 一、背景

通过对官方文档和最佳实践的系统整理，发现本项目在以下三个方面与官方推荐做法存在差距。

---

## 二、问题分析与官方推荐方案

### 问题 1：SafeArea 处理方式

**当前代码**（`EntryAbility.ets`）：

```typescript
// 获取状态栏高度并存入 AppStorage
const topArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
AppStorage.setOrCreate('topRectHeight', topArea.topRect.height);
const bottomArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
AppStorage.setOrCreate('bottomRectHeight', bottomArea.bottomRect.height);
win.on('avoidAreaChange', (data) => { ... });
```

**当前代码**（`Main.ets`）：

```typescript
NavDestination() { ... }
  .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
```

**官方最佳实践（窗口沉浸式）原文**：

官方给出了四种沉浸式方案，并明确说：

> 推荐使用方案一（`background()` 属性）和方案二（`ignoreLayoutSafeArea()`），相比窗口设置沉浸显示和安全区域拓展（`expandSafeArea`），这两种方案实现方式简单易理解，且自动适配不同窗口模式和方向。

四种方案对比（官方表格）：

| 方案                          | 级别   | 特点                         | 缺点                                         |
| ----------------------------- | ------ | ---------------------------- | -------------------------------------------- |
| `background()`                | 组件级 | 仅背景扩展，内容自动在安全区 | 滚动内容无法延伸至避让区                     |
| `ignoreLayoutSafeArea()`      | 组件级 | 背景与内容均扩展             | 内容易与避让区冲突，需手动处理避让           |
| `expandSafeArea`              | 组件级 | 支持指定延伸区域类型         | **滚动内容无法延伸；参数复杂，理解成本过高** |
| `setWindowLayoutFullScreen()` | 窗口级 | 全局统一                     | 需手动计算避让区高度，处理所有内容避让       |

**官方推荐方案一（最简单）**：

```typescript
// 只需设置 background()，背景自动延伸到状态栏/导航栏，内容自动在安全区内
// 完全不需要手动读取 topRectHeight / bottomRectHeight
Column() { ... }
  .background('#F1F3F5')
```

**官方推荐方案二（需要手动避让）**：

```typescript
// 用 ignoreLayoutSafeArea() 扩展布局，然后手动用 getWindowAvoidArea() 计算 padding
Column() { ... }
  .ignoreLayoutSafeArea()
  .height(LayoutPolicy.matchParent)
  .padding({
    top: avoidSystem.topRect.height + 'px',
    bottom: avoidNavigationIndicator.bottomRect.height + 'px'
  })
```

**项目现状分析**：

- `topRectHeight`：在整个项目中**没有任何地方被读取**，是完全冗余的代码
- `bottomRectHeight`：只在 `AccountSwitchDialog`（弹窗）中被读取，用于底部 padding
- `Main.ets` 用的是 `expandSafeArea`，官方说这个方案"参数复杂，理解成本过高"，且有滚动容器限制

**可选方案**：

**方案 A：保留现状**

- 优点：不改代码，稳定
- 缺点：`topRectHeight` 完全没用，是冗余代码；`expandSafeArea` 不是官方推荐的首选方案

**方案 B（官方推荐）：Main.ets 改用 `background()` + 删除 `topRectHeight`**

- `Main.ets` 的 `NavDestination` 改用 `background()` 属性替代 `expandSafeArea`
- 删除 `EntryAbility` 中 `topRectHeight` 的存储和监听（没有任何地方用到）
- 保留 `bottomRectHeight`（弹窗类组件 Navigation 不自动处理，需要手动）
- 官方说 `background()` 方案"一次配置适配不同窗口模式、窗口方向"，最简单

**方案 C：全部删除手动读取，弹窗改用系统 SafeArea**

- 删除所有手动读取（包括 `bottomRectHeight`）
- `AccountSwitchDialog` 改用 `expandSafeArea` 或 `safeAreaPadding` 处理底部
- 风险：弹窗类组件的 SafeArea 处理需要验证效果，官方文档说弹窗类组件的避让模式需要单独处理

---

### 问题 2：路由表混用

**当前状态**：

| 路由                    | 方式                                                      |
| ----------------------- | --------------------------------------------------------- |
| GenshinDailyDetail      | `allDetailBuilder`（自定义 if/else）                      |
| GenshinCharacterDetail  | `allDetailBuilder`（自定义 if/else）                      |
| AccountDetail           | `allDetailBuilder`（自定义 if/else）                      |
| Login                   | `allDetailBuilder`（自定义 if/else）                      |
| NotificationSettings    | `allDetailBuilder`（自定义 if/else）                      |
| TestPage                | 两种都有（`allDetailBuilder` + `custom_router_map.json`） |
| StarRailCharacterDetail | `custom_router_map.json`（系统路由表）                    |
| ZZZCharacterDetail      | `custom_router_map.json`（系统路由表）                    |
| StarRailDailyDetail     | `custom_router_map.json`（系统路由表）                    |
| ZZZDailyDetail          | `custom_router_map.json`（系统路由表）                    |
| WebView                 | `custom_router_map.json`（系统路由表）                    |

**官方最佳实践（多设备设置界面）做法**：

官方示例中，每个页面都有独立的 `@Builder` 导出函数（如 `WlanSettingBuilder`、`WlanMoreSettingBuilder`），通过系统路由表注册，**没有使用 `allDetailBuilder` 这种 if/else 分发方式**。

**可选方案**：

**方案 A：保留混用现状**

- 优点：不改代码
- 缺点：不一致，`allDetailBuilder` 中的页面都在主包中 import，包体积略大；TestPage 同时在两个地方注册

**方案 B（官方推荐）：全部迁移到系统路由表**

- 删除 `allDetailBuilder` 中的所有 `if/else` 分支
- 将 GenshinDailyDetail、GenshinCharacterDetail、AccountDetail、Login、NotificationSettings 都加入 `custom_router_map.json`
- 为每个页面添加 `@Builder` 导出函数
- 优点：统一、官方推荐、减少主包 import
- 缺点：需要为每个页面添加 `@Builder` 导出函数，改动量中等

**方案 C：全部迁移到自定义路由表（allDetailBuilder）**

- 将系统路由表中的页面也移到 `allDetailBuilder`
- 优点：统一，代码集中
- 缺点：与官方推荐相反，包体积更大

---

### 问题 3：Main.ets 的 expandSafeArea 只扩展了底部

**当前代码**：

```typescript
NavDestination() { ... }
  .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
```

**官方最佳实践说法**：

`expandSafeArea` 不是官方首选方案，官方推荐 `background()` 属性（方案一）。`background()` 的优点是"一次配置适配不同窗口模式、窗口方向"，且"自动适配"。

**可选方案**：

**方案 A：保留现状（只扩展 BOTTOM）**

- 当前效果：底部导航栏区域背景色正确延伸，顶部由 Navigation 系统处理
- 适合：不需要沉浸式顶部效果

**方案 B（官方推荐）：改用 `background()` 属性**

```typescript
NavDestination() { ... }
  .background(this.tm.current.colorPageBg)
  // 删除 expandSafeArea
```

- 官方说 `background()` 方案最简单，自动适配所有窗口模式和方向
- 背景色自动延伸到状态栏和导航栏，内容自动在安全区内

**方案 C：同时扩展 TOP + BOTTOM**

```typescript
.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
```

- 效果：背景色延伸到状态栏下方，完整沉浸式
- 但官方说 `expandSafeArea` 不是首选方案

---

## 三、不需要改动的部分

以下内容经过对比，当前实现已符合官方最佳实践，无需改动：

- **NavDestination 使用方式**：所有二级页面都正确使用 `NavDestination` 作为根容器，通过 `onReady` 获取 `NavPathStack` ✅
- **转场动画**：使用系统默认转场，当前场景不需要自定义 ✅
- **路由操作**：分栏用 `replacePath`，单栏用 `pushPathByName`，已正确区分 ✅
- **路由常量**：所有路由 path 通过 `AppRoutes` 常量引用，无字符串字面量 ✅
- **Launch 页沉浸式**：`expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])` 正确 ✅
- **AccountSwitchDialog 底部 padding**：弹窗类组件 Navigation 不自动处理，手动读取 `bottomRectHeight` 是正确的 ✅

---

## 四、决策请求

请针对以下三个问题选择方案：

| 问题                       | 方案 A                    | 方案 B（官方推荐）                                 | 方案 C                                  |
| -------------------------- | ------------------------- | -------------------------------------------------- | --------------------------------------- |
| 1. SafeArea 处理           | 保留现状                  | Main.ets 改用 `background()`，删除 `topRectHeight` | 全部删除手动读取，弹窗改用系统 SafeArea |
| 2. 路由表统一              | 保留混用                  | 全部迁移到系统路由表                               | 全部迁移到自定义路由表                  |
| 3. Main.ets expandSafeArea | 保留现状（只扩展 BOTTOM） | 改用 `background()` 属性                           | 同时扩展 TOP + BOTTOM                   |

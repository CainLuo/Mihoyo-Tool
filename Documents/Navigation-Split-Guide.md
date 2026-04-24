# HarmonyOS Navigation 分栏 · 多设备适配指南

> 适用版本：HarmonyOS NEXT API 18+（部分特性注明最低版本）
> 本文档基于以下官方文档整理，内容通过 `webFetch(mode="rendered")` 直接抓取，非推断：
>
> - [Navigation基础架构介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-navigation-architecture)（2026-04-20）
> - [Navigation分栏开发](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-navigation-split-mode)（2026-04-20）
> - [Navigation子页面](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-navigation-navdestination)（2026-04-20）
> - [Navigation页面路由](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-navigation-jump)（2026-04-24）
> - [多设备设置界面最佳实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-settings-application-page)（2026-03-12）
> - [折叠屏分栏模式适配](https://developer.huawei.com/consumer/cn/doc/architecture-guides/app_multiplier-0000002312850858)（2026-03-20）
> - [分屏模式不支持分栏显示（FAQ）](https://developer.huawei.com/consumer/cn/doc/architecture-guides/news-v1_2-ts_c160-0000002396788336)（2026-02-05）
> - [Navigation在分栏模式下页面有大量留白（FAQ）](https://developer.huawei.com/consumer/cn/doc/architecture-guides/educate-v1_1-ts_c56-0000002385171678)（2026-02-05）
> - [如何实现Navigation单栏与分栏模式动态切换（FAQ）](https://developer.huawei.com/consumer/cn/doc/architecture-guides/insurance-v1_2-ts_116-0000002406922585)（2026-02-11）
> - [Navigation如何隐藏导航栏（FAQ）](https://developer.huawei.com/consumer/cn/doc/harmonyos-faqs/faqs-arkui-149)（2026-03-10）

---

## 一、Navigation 整体架构（官方原文）

Navigation 组件结构包含以下关键概念：

- **Navigation**：导航根视图容器，所有导航页面都被此容器包裹，提供分栏显示能力，一般用作全局根容器
- **NavDestination**：子页面容器，导航的所有路由操作均针对 NavDestination，包含标题栏、菜单栏、内容区、工具栏
- **NavBar**：导航栏（主页面），单栏时是整个导航的首页，分栏时是固定的左侧导航栏
- **NavPathStack**：导航控制器，管理 NavDestination 页面栈，需与 Navigation 绑定使用

Navigation 提供两种布局模式：

- **单栏模式**：当 Navigation 容器宽度小于 600vp 时，建议使用单栏模式。发生路由跳转时，整个页面都会被替换
- **分栏模式**：当 Navigation 容器宽度大于等于 600vp 时，建议使用分栏模式。左侧为导航栏（NavBar），右侧为子页面（NavDestination），发生路由跳转时只有右边子页会被替换

> ⚠️ 注意：600vp 是官方"建议"使用分栏的容器宽度（设计建议），Auto 模式实际自动切换阈值是 **520vp**（见下文）

---

## 二、三种显示模式

| 模式                   | 行为                                                 | 适用场景             |
| ---------------------- | ---------------------------------------------------- | -------------------- |
| `NavigationMode.Stack` | 单栏：NavBar 和 NavDestination 叠加，NavBar 默认隐藏 | Phone 竖屏           |
| `NavigationMode.Split` | 分栏：NavBar（左）和 NavDestination（右）并排        | 平板、PC、折叠屏展开 |
| `NavigationMode.Auto`  | 自动：根据窗口宽度自动切换，**推荐**                 | 所有设备             |

**Auto 模式切换阈值（官方最佳实践原文）**：

> Auto 模式是指 Navigation 组件可以根据应用窗口尺寸，自动选择合适的模式：**窗口宽度小于 520vp 时，采用 Stack 模式显示；窗口宽度大于等于 520vp 时，采用 Split 模式显示**。当窗口尺寸发生改变时，Navigation 组件也会自动在 Stack 模式和 Split 模式之间切换。

---

## 三、分栏相关属性（官方 API 参考）

| 属性                        | 起始版本   | 说明                                                 |
| --------------------------- | ---------- | ---------------------------------------------------- |
| `mode`                      | API 9      | 控制显示模式（Stack/Split/Auto），**默认 Auto**      |
| `navBarPosition`            | API 9      | 控制导航栏位置（Start/End），受 RTL 语言影响         |
| `navBarWidth`               | API 9      | 控制导航栏宽度，**分栏模式默认 240vp**               |
| `navBarWidthRange`          | API 10     | 设置导航栏宽度可调整范围（用户可拖拽）               |
| `minContentWidth`           | API 10     | 控制分栏子页的最小宽度                               |
| `hideNavBar`                | API 9      | 控制导航栏显隐（Split + hideNavBar=true = 单栏效果） |
| `enableDragBar`             | API 14     | 控制是否显示分栏拖动按钮                             |
| `enableModeChangeAnimation` | API 15     | 控制单双栏切换动画，默认开启                         |
| `splitPlaceholder`          | **API 20** | 分栏模式下右侧无内容时的占位页                       |
| `onNavigationModeChange`    | API 11     | 监听单双栏切换                                       |

**splitPlaceholder 说明（官方原文）**：

> 用于设置分栏模式下内容区的默认占位页。分栏模式在默认情况下，栈中没有页面时内容区展示空白，可使用此接口设置此区域的 UI 布局。需要注意的是，占位页仅作为 UI 展示页，仅分栏模式空栈的情况下才展示，不受路由栈管理也不可获焦和响应事件。

**navBarWidth 陷阱（官方 FAQ 原文）**：

> 当设置主页宽度为 0% 时，**默认识别为 100%**。仅分栏模式下生效，且当设置主页宽度为 0% 时，默认识别为 100%。

---

## 四、分栏开发示例（官方代码）

```typescript
Navigation(this.stack) {
  NewsHome().width('100%').height('100%')
}
.mode(NavigationMode.Split)
.enableDragBar(true)
.hideNavBar(false)
.navBarWidthRange([100, 700])   // 指定 NavBar 区域的宽度范围
.minContentWidth(100)           // 指定子页区域的最小宽度
.hideTitleBar(true)
.hideToolBar(true)
.height('100%')
.width('100%')
```

---

## 五、NavPathStack 路由操作

### 5.1 获取 NavPathStack 的两种方式

**方式一：AppStorage 全局存储**

```typescript
// 存储
AppStorage.setOrCreate<NavPathStack>("basicNavigationStack", this.navStack);
// 获取
const stack = AppStorage.get<NavPathStack>("basicNavigationStack")!;
```

**方式二：onReady 回调（推荐，本项目用法）**

```typescript
NavDestination() { ... }
  .onReady((ctx: NavDestinationContext) => {
    this.navPathStack = ctx.pathStack;
  })
```

> 官方说明：NavPathStack 和 Navigation 一一对应，不可复用。NavPathStack 无法直接操作 NavBar，跳转回首页只能用 `clear()` 清空路由栈。

### 5.2 基础路由操作

**页面跳转（Push）**

```typescript
// 普通跳转
this.pageStack.pushPath({ name: 'pageOne', param: 'PageOne Param' });
this.pageStack.pushPathByName('pageTwo', 'PageTwo Param');

// 带返回回调的跳转
this.pageInfo.pushPathByName('pageTwo', 'PageTwo Param', (popInfo) => {
  const result = popInfo.result;
});

// 带错误码的跳转（async）
this.pageStack.pushDestination({ name: 'pageTwo', param: 'PageTwo Param' })
  .catch((error: BusinessError) => { ... });
```

**页面返回（Pop）**

```typescript
this.pathStack.pop(); // 返回上一页
this.pathStack.popToName("pageOne"); // 返回到指定名称页面
this.pathStack.popToIndex(0); // 返回到指定索引页面
this.pageStack.clear(); // 清空栈（回到 NavBar 首页）
```

**页面替换（Replace）— 分栏模式推荐**

```typescript
this.pageStack.replacePath({ name: "pageTwo", param: "PageTwo Param" });
this.pageStack.replacePathByName("pageTwo", "PageTwo Param");
// 带错误码（API 18+）
this.pageStack.replaceDestination({ name: "pageTwo", param: "PageTwo Param" });
```

**页面删除（Remove）**

```typescript
this.pageStack.removeByName("pageTwo"); // 删除栈中所有同名页面
this.pageStack.removeByIndexes([1]); // 删除指定索引页面
```

**移动页面（Move）**

```typescript
this.pageStack.moveToTop("pageTwo"); // 将指定名称页面移到栈顶
this.pageStack.moveIndexToTop(1); // 将指定索引页面移到栈顶
```

### 5.3 单例跳转（API 12+）

```typescript
// MOVE_TO_TOP_SINGLETON：找到同名页面移到栈顶（不新建）
// POP_TO_SINGLETON：找到同名页面，移除其上方所有页面
this.stack.pushPath({
  name: "NewsDetail",
  param: item,
  launchMode: LaunchMode.MOVE_TO_TOP_SINGLETON,
});
```

### 5.4 路由拦截（API 12+）

```typescript
this.pageStack.setInterception({
  willShow: (from, to, operation, animated) => {
    if (typeof to === "string") {
      return;
    } // 目标是 NavBar，不拦截
    const target = to as NavDestinationContext;
    if (target.pathInfo.name === "pageTwo") {
      target.pathStack.pop();
      target.pathStack.pushPathByName("pageOne", null);
    }
  },
});
```

> 官方说明：interception 回调时机比 willShow 更早，前者触发时不会创建被拦截的页面，willShow 触发时会创建被拦截的页面然后销毁。

---

## 六、NavDestination 类型与生命周期

### 6.1 两种显示类型

| 类型             | mode 值                       | 说明                                                     |
| ---------------- | ----------------------------- | -------------------------------------------------------- |
| 标准类型（默认） | `NavDestinationMode.STANDARD` | 普通页面，Navigation 中同时只显示一个                    |
| 弹窗类型         | `NavDestinationMode.DIALOG`   | 透明背景，不影响下层页面的显示和生命周期，两者可同时显示 |

### 6.2 生命周期顺序（官方原文）

```
aboutToAppear          ← 自定义组件生命周期，NavDestination 创建前
onWillAppear (API 12)  ← 挂载到组件树之前，此时改状态变量当帧生效
onAppear               ← 挂载到组件树时
onWillShow (API 12)    ← 布局显示之前，页面不可见
onShown (API 10)       ← 布局显示之后，页面已完成布局
onActive (API 17)      ← 处于栈顶可操作状态
  ↕ 页面切换
onInactive (API 17)    ← 处于非栈顶或被遮挡
onWillHide (API 12)    ← 隐藏之前
onHidden (API 10)      ← 隐藏后（被 push 压栈、pop 出栈、切到后台）
onWillDisappear (API 12) ← 即将销毁，转场动画前执行
onDisAppear            ← 从组件树卸载
aboutToDisappear       ← 自定义组件析构，不允许改状态变量
```

**两个特殊回调**：

- `onResult`：从其他 NavDestination 通过 pop 或侧滑返回时，触发**当前页面**的 onResult
- `onNewParam`：通过 `MOVE_TO_TOP_SINGLETON` / `POP_TO_SINGLETON` 将已有页面移到栈顶时触发

---

## 七、折叠屏适配（官方推荐方案）

### 7.1 监听 windowSizeChange（官方代码）

```typescript
// EntryAbility.ts
windowStage.getMainWindow().then((data: window.Window) => {
  this.windowObj = data;
  this.updateScreenDisplay(this.windowObj.getWindowProperties().windowRect.width);
  this.windowObj.on('windowSizeChange', (windowSize: window.Size) => {
    this.updateScreenDisplay(windowSize.width);
  });
});

private updateScreenDisplay(windowWidth: number): void {
  // densityPixels = 屏幕宽度像素 / 屏幕真实宽度(vp)
  let realWindowWidth = windowWidth / display.getDefaultDisplaySync().densityPixels;
  let curScreenSizeString: string = '';
  if (realWindowWidth < SCREEN_SIZE_BREAKPOINT) {
    curScreenSizeString = 'sm';
  } else {
    curScreenSizeString = 'lg';
  }
  AppStorage.setOrCreate('curScreenSizeString', curScreenSizeString);
}
```

```typescript
// 根据屏幕宽度设置 Navigation 显示模式
Navigation(this.pageInfo) { ... }
  .mode(this.curScreenSizeString === 'lg' ? NavigationMode.Split : NavigationMode.Stack)
```

---

## 八、分屏模式适配（官方 FAQ 完整方案）

**问题**：应用分屏时，不支持分栏显示。

**原因**：分屏时断点刚好适配的是单栏，所以分屏时才会单栏显示。

**官方修改建议（完整代码）**：

```typescript
// EntryAbility.ts
onWindowStageCreate(windowStage: window.WindowStage): void {
  AppStorage.setOrCreate('windowClass', windowStage.getMainWindowSync());
  windowStage.loadContent('pages/Index', ...);
}
```

```typescript
// Index.ets（Navigation 所在页面）
import { window } from '@kit.ArkUI';
import { display } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  windowClass: window.Window | undefined = AppStorage.get('windowClass');
  currentBreakPoint: WidthBreakpoint = this.getUIContext().getWindowWidthBreakpoint();
  currentWindowStatusType: WindowStatusType | undefined = this.windowClass?.getWindowStatus();
  @State currentMode: NavigationMode = NavigationMode.Stack;
  pathInfos: NavPathStack = new NavPathStack();

  setCurrentMode() {
    // 判断屏幕方向，横屏时分栏
    if (display.getDefaultDisplaySync().orientation === display.Orientation.LANDSCAPE ||
        display.getDefaultDisplaySync().orientation === display.Orientation.LANDSCAPE_INVERTED) {
      if (this.currentWindowStatusType === 4) {
        // WindowStatusType === 4 表示分屏模式，强制单栏
        this.currentMode = NavigationMode.Stack;
      } else {
        this.currentMode = NavigationMode.Split;
      }
    } else {
      // 纵向时根据横向断点适配分栏
      this.currentMode = this.currentBreakPoint <= 2 ? NavigationMode.Stack : NavigationMode.Split;
    }
  }

  aboutToAppear(): void {
    this.setCurrentMode();
    this.windowClass?.on('windowSizeChange', () => {
      this.currentBreakPoint = this.getUIContext().getWindowWidthBreakpoint();
      this.setCurrentMode();
    });
    this.windowClass?.on('windowStatusChange', (WindowStatusType) => {
      this.currentWindowStatusType = WindowStatusType;
    });
  }

  build() {
    Navigation(this.pathInfos) { ... }
      .mode(this.currentMode);
  }
}
```

> 关键点：`WindowStatusType === 4` 表示分屏模式，此时强制 `NavigationMode.Stack`

---

## 九、最佳实践总结（官方）

### 9.1 始终用 NavigationMode.Auto，不手动判断设备

```typescript
// ✅ 推荐
.mode(NavigationMode.Auto)

// ❌ 不推荐（官方最佳实践也不推荐）
.mode(this.curBp !== 'sm' ? NavigationMode.Split : NavigationMode.Stack)
```

> 官方说明：Auto 模式会基于 Navigation 组件的宽度自动在 Stack 和 Split 中切换，开发者不用关心单栏和双栏场景的差异而更关注于应用本身，极大减少开发工作量及提高开发效率。

### 9.2 分栏导航用 replacePath，不用 push

分栏模式下 push 会在右侧出现返回按钮，语义不清晰。`replacePath` 替换右侧内容，保持左侧导航栏不变。

### 9.3 splitPlaceholder 必须设置（API 20+）

不设置时分栏右侧为空白，体验差。

```typescript
@Builder
function PlaceholderPage() {
  Column() {
    Text("分栏模式占位页").fontSize(22).margin({ top: 200 });
  }.width("100%").height("100%");
}

// 在 Navigation 所在组件的 aboutToAppear 中
this.placeholder = new ComponentContent(this.getUIContext(), wrapBuilder(PlaceholderPage));

Navigation() { ... }
  .splitPlaceholder(this.placeholder)
```

### 9.4 navBarWidth 不要设置为 0%

官方说明：`navBarWidth` 设置为 `0%` 时，**默认识别为 100%**，不会隐藏导航栏。要隐藏导航栏应使用 `hideNavBar(true)`。

### 9.5 不要用 navBarWidth/navBarWidthRange 实现子页放大

官方 FAQ 明确说明：不建议通过 `navBarWidth` 和 `navBarWidthRange` 实现子页放大功能，该方式存在宽度限制。推荐使用 `mode` 属性动态切换，或分栏模式下设置 `hideNavBar(true)`。

### 9.6 NavDestination 不要手动加 statusBarHeight padding

Navigation 从 API 11 开始默认支持安全区域避让，不需要手动处理。

### 9.7 隐藏导航栏需同时设置 Navigation 和 NavDestination

官方 FAQ 原文：需同时设置 Navigation 组件及其 NavDestination 子组件的 `hideTitleBar` 属性为 true 才能完全隐藏导航栏。

### 9.8 三折屏/PC 宽屏下限制 navBarWidth 最大值

固定百分比（如 45%）在 1200vp 下左侧 = 540vp，在 1440vp 下 = 648vp，远超合理范围。推荐配合 `navBarWidthRange` 限制最大宽度：

```typescript
.navBarWidth('45%')
.navBarWidthRange([240, 400])   // 最大 400vp，支持用户拖拽
.minContentWidth(320)           // 右侧内容区最小 320vp
```

### 9.9 分栏模式下点击导航栏多次出现重复页面

官方 FAQ 方案：推送页面时采用单例模式（`LaunchMode.MOVE_TO_TOP_SINGLETON` 或 `POP_TO_SINGLETON`），或使用路由拦截 `setInterception` 判断是否已在栈中。

### 9.10 获取分栏右侧宽度

官方 FAQ 原文：目前没有直接接口获取分栏的宽度，可以参考 NavigationMode 为 Split 时 navBarWidth（左分屏宽度）计算规则实现自动计算分栏宽度。

---

## 十、FAQ 汇总

**Q：Auto 模式的切换阈值是多少？**

A：官方最佳实践文档明确说明是 **520vp**（窗口宽度 < 520vp 用 Stack，≥ 520vp 用 Split）。注意与官方架构介绍中"建议 600vp 使用分栏"的设计建议区分。

**Q：分栏模式下底部 Tab 栏会消失吗？**

A：不会。`toolbarConfiguration` 在 Split 模式下仍显示在底部。

**Q：splitPlaceholder 在 API 18 能用吗？**

A：不能，`splitPlaceholder` 是 API 20+ 的属性。

**Q：为什么分栏时要用 replacePath 而不是 push？**

A：`push` 会在右侧 NavDestination 里新增一层导航栈，导致右侧出现返回按钮，用户会误以为可以返回到某个页面。`replacePath` 直接替换右侧内容，语义更清晰。

**Q：分屏模式下不想显示分栏怎么办？**

A：监听 `windowStatusChange` 事件，`WindowStatusType === 4` 表示分屏模式，此时将 `mode` 设置为 `NavigationMode.Stack`。详见第八节。

**Q：Navigation 在分栏模式下页面有大量留白怎么办？**

A：官方 FAQ 原文：应用在分栏模式下，未使用 `splitPlaceholder` 设置右侧默认占位页，也没有使用 `pushPath` 给右侧内容区域推送默认页面路由，导致刚进应用时，右侧显示空白。API 20+ 推荐使用 `splitPlaceholder` 接口。

**Q：如何隐藏 Navigation 的导航栏（标题栏）？**

A：需要**同时**设置 Navigation 组件和其 NavDestination 子组件的 `hideTitleBar(true)` 才能完全隐藏。

**Q：navBarWidth 设置为 0% 能隐藏导航栏吗？**

A：不能。官方说明：`navBarWidth` 设置为 `0%` 时，默认识别为 100%。要隐藏导航栏应使用 `hideNavBar(true)`。

**Q：通过状态管理动态切换 mode 属性是否会造成性能问题？**

A：官方 FAQ 原文：Navigation 的 mode 属性虽然作用于整个容器，但是 mode 的改变只会调整容器的布局模式。由于 ArkUI 的 UI 开发模式属于 MVVM 模式，其组件更新机制是局部刷新，只有受影响的部分会重新渲染。

---

## 十一、本项目（米悠悠）适配方案

### 11.1 现状分析

| 功能点             | 当前状态                                    | 问题               |
| ------------------ | ------------------------------------------- | ------------------ |
| Navigation 分栏    | ✅ `NavigationMode.Auto`                    | —                  |
| navBarWidth        | ✅ `'45%'`                                  | 三折屏/PC 左侧过宽 |
| navBarWidthRange   | ✅ `[240, 400]`                             | 已修复             |
| minContentWidth    | ✅ `320`                                    | 已修复             |
| splitPlaceholder   | ✅ `SplitPlaceholder`（API 20+）            | —                  |
| isSplit 传递       | ✅ Home/Characters/My 均已接收              | —                  |
| 分栏导航           | ✅ `replacePath` vs `pushPathByName`        | —                  |
| 分屏模式适配       | ✅ `windowStatusType === 4` 强制 Stack      | 已修复             |
| 原神角色详情布局   | ✅ Portrait/Landscape/Wide 三套             | —                  |
| 星铁角色详情宽屏   | ✅ `StarRailCharDetailWideLayout`（≥600vp） | 已修复             |
| 绝区零角色详情宽屏 | ✅ `ZZZCharDetailWideLayout`（≥600vp）      | 已修复             |
| 登录页宽屏         | ✅ `LoginWideLayout`                        | —                  |

### 11.2 已完成的代码改动

**Main.ets**：

```typescript
Navigation(this.stack) { ... }
  .mode(this.windowStatusType === 4 ? NavigationMode.Stack : NavigationMode.Auto)
  .navBarWidth(this.tm.current.pct45)
  .navBarWidthRange([240, 400])
  .minContentWidth(320)
  .splitPlaceholder(this.placeholder!)
  .onNavigationModeChange((mode: NavigationMode) => {
    this.isSplit = mode === NavigationMode.Split
  })

@StorageLink('windowStatusType') private windowStatusType: number = 0
```

**EntryAbility.ets**：

```typescript
win.on("windowStatusChange", (statusType: window.WindowStatusType) => {
  AppStorage.setOrCreate("windowStatusType", statusType as number);
});
```

**星铁/绝区零角色详情页**：加入 `onAreaChange` 断点检测，`md`（≥600vp）及以上使用宽屏两栏布局。

# HarmonyOS Navigation · NavDestination · SafeArea · Router 指南

> 适用版本：HarmonyOS NEXT API 18+
> 内容通过 `webFetch(mode="rendered")` 直接抓取官方文档，非推断。
> 抓取日期：2026-04-25

---

## 一、NavDestination

### 1.1 两种显示类型

| 类型             | mode 值                       | 说明                                                     |
| ---------------- | ----------------------------- | -------------------------------------------------------- |
| 标准类型（默认） | `NavDestinationMode.STANDARD` | 普通页面，Navigation 中同时只显示一个                    |
| 弹窗类型         | `NavDestinationMode.DIALOG`   | 透明背景，不影响下层页面的显示和生命周期，两者可同时显示 |

弹窗类型从 API 13 开始默认有系统转场动画（API 12 及以前无动画）。

### 1.2 完整生命周期顺序

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

### 1.3 页面信息查询

NavDestination 内部的自定义组件可以通过 `queryNavDestinationInfo()` 查询当前所属页面信息：

```typescript
import { uiObserver } from '@kit.ArkUI';

@Component
struct MyComponent {
  navDesInfo: uiObserver.NavDestinationInfo | undefined;

  aboutToAppear() {
    this.navDesInfo = this.queryNavDestinationInfo();
  }
}
```

### 1.4 获取 NavPathStack 的推荐方式

**推荐：onReady 回调**（本项目已用）

```typescript
NavDestination() { ... }
  .onReady((ctx: NavDestinationContext) => {
    this.localStack = ctx.pathStack;
  })
```

---

## 二、转场动画

### 2.1 系统默认转场

- 默认使用**弹簧曲线**，时长不可控，不建议与业务逻辑耦合
- 不同设备上的默认动画不同
- 若需要监听动画结束，必须使用自定义转场

**关闭转场的两种方式**：

```typescript
// 全局关闭
this.pageStack.disableAnimation(true);

// 单次关闭（animated 参数）
this.pageStack.pushPath({ name: "pageOne" }, false);
this.pageStack.pop(undefined, false);
```

### 2.2 自定义转场

两种级别：

- **Navigation 级**：`customNavContentTransition` — 控制所有页面的转场，优先级更高
- **NavDestination 级**：`customTransition` (API 15+) — 控制单个页面的转场

> 两者同时设置时，`customNavContentTransition` 优先级更高。

### 2.3 共享元素转场

两个 NavDestination 之间的组件共享动画：

```typescript
// 起始页
Image($r("app.media.icon")).geometryTransition("sharedId");

// 目的页
Image($r("app.media.icon")).geometryTransition("sharedId");

// 跳转时包在 animateTo 里，并关闭系统默认转场
this.getUIContext()?.animateTo({ duration: 1000 }, () => {
  this.navPathStack.pushPath({ name: "ToPage" }, false); // false = 关闭系统转场
});
```

---

## 三、SafeArea 安全区域

### 3.1 核心概念

安全区域是页面的显示区域，默认情况下界面布局在安全区域内，不与状态栏、导航栏等系统避让区重叠。

**两个关键属性**：

| 属性                   | 起始版本 | 说明                                           |
| ---------------------- | -------- | ---------------------------------------------- |
| `expandSafeArea`       | API 10   | 扩展组件**绘制区域**至安全区外，不改变布局     |
| `ignoreLayoutSafeArea` | API 20   | 扩展组件**布局区域**至安全区外，会改变组件位置 |

**区别（官方示例 10 说明）**：

- `expandSafeArea`：自身绘制区域上抬，**子组件相对屏幕位置不变**
- `ignoreLayoutSafeArea`：自身布局区域上抬，**子组件相对容器位置不变**（子组件会跟着移动）

### 3.2 expandSafeArea 参数

```typescript
expandSafeArea(
  types?: Array<SafeAreaType>,   // 默认：[SYSTEM, CUTOUT, KEYBOARD]
  edges?: Array<SafeAreaEdge>    // 默认：[TOP, BOTTOM, START, END]
)
```

**SafeAreaType 枚举**：

- `SYSTEM`（0）：状态栏、导航栏
- `CUTOUT`（1）：刘海屏/挖孔屏
- `KEYBOARD`（2）：软键盘

**SafeAreaEdge 枚举**：

- `TOP`（0）、`BOTTOM`（1）、`START`（2）、`END`（3）

**重要限制（官方说明）**：

- 设置固定宽高时，扩展方向只支持 `TOP` 和 `START`，扩展后尺寸不变
- 滚动类容器内的组件不建议设置 `expandSafeArea`，如果设置，需要从当前节点到滚动祖先容器间所有直接节点都设置
- `expandSafeArea` 仅作用于当前组件，不向父/子组件传递
- 设置 `expandSafeArea([],[])` 相当于无效（空数组）

### 3.3 键盘避让模式

```typescript
// 在 EntryAbility 或页面中设置
this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.OFFSET); // 默认：上抬
this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE); // 压缩页面
this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE); // 不避让
```

> `RESIZE` 模式下，`expandSafeArea([SafeAreaType.KEYBOARD],[SafeAreaEdge.BOTTOM])` 不生效。

### 3.4 Navigation 与 SafeArea 的关系

**官方说明（来自 Navigation 指南）**：

> Navigation 从 API 11 开始默认支持安全区域避让，不需要手动处理。

这意味着：

- Navigation 内的 NavDestination 页面**不需要**手动加 `statusBarHeight` padding
- 不需要手动读取 `topRectHeight` / `bottomRectHeight` 来做 padding
- 只有在需要**沉浸式效果**（内容延伸到状态栏/导航栏下方）时，才需要 `expandSafeArea`

### 3.5 沉浸式效果实现（官方示例）

```typescript
// 背景图延伸到状态栏和导航栏
Column()
  .backgroundImage($r("app.media.bg"))
  .backgroundImageSize(ImageSize.Cover)
  .expandSafeArea(
    [SafeAreaType.SYSTEM],
    [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM],
  );
```

---

## 四、路由（Router）

### 4.1 路由表配置（系统路由表 vs 自定义路由表）

**系统路由表**（推荐）：在 `resources/base/profile/router_map.json` 中配置，在 `module.json5` 中注册 `"routerMap": "$profile:router_map"`。

```json
{
  "routerMap": [
    {
      "name": "PageOne",
      "pageSourceFile": "src/main/ets/pages/PageOne.ets",
      "buildFunction": "PageOneBuilder"
    }
  ]
}
```

**自定义路由表**：通过 `Navigation.navDestination()` 传入 `@Builder` 函数，在函数内用 `if/else` 分发。

**两种方式的区别**：

- 系统路由表：按需加载，页面文件不需要在主包中 import，适合大型应用
- 自定义路由表：所有页面在 `allDetailBuilder` 中 import，适合小型应用

### 4.2 NavPathStack 完整操作

| 操作 | 方法                                                            | 说明                             |
| ---- | --------------------------------------------------------------- | -------------------------------- |
| 跳转 | `pushPath(info)`                                                | 普通入栈                         |
| 跳转 | `pushPathByName(name, param)`                                   | 按名称入栈                       |
| 跳转 | `pushPathByName(name, param, onPop)`                            | 入栈 + pop 回调                  |
| 跳转 | `pushDestination(info)`                                         | 入栈 + 错误码回调（async）       |
| 替换 | `replacePath(info)`                                             | 替换栈顶（分栏推荐）             |
| 替换 | `replacePathByName(name, param)`                                | 按名称替换栈顶                   |
| 替换 | `replaceDestination(info)`                                      | 替换 + 错误码回调（API 18+）     |
| 返回 | `pop()`                                                         | 出栈                             |
| 返回 | `popToName(name)`                                               | 返回到指定名称页面               |
| 返回 | `popToIndex(idx)`                                               | 返回到指定索引页面               |
| 清空 | `clear()`                                                       | 清空栈（回到 NavBar 首页）       |
| 删除 | `removeByName(name)`                                            | 删除栈中所有同名页面             |
| 删除 | `removeByIndexes([idx])`                                        | 删除指定索引页面                 |
| 移动 | `moveToTop(name)`                                               | 将指定名称页面移到栈顶           |
| 移动 | `moveIndexToTop(idx)`                                           | 将指定索引页面移到栈顶           |
| 单例 | `pushPath({..., launchMode: LaunchMode.MOVE_TO_TOP_SINGLETON})` | 找到同名页面移到栈顶             |
| 单例 | `pushPath({..., launchMode: LaunchMode.POP_TO_SINGLETON})`      | 找到同名页面，移除其上方所有页面 |
| 拦截 | `setInterception({willShow: ...})`                              | 路由拦截（API 12+）              |
| 动画 | `disableAnimation(bool)`                                        | 全局关闭/开启转场动画            |

### 4.3 路由拦截

```typescript
this.pageStack.setInterception({
  willShow: (from, to, operation, animated) => {
    if (typeof to === "string") {
      return;
    } // 目标是 NavBar，不拦截
    const target = to as NavDestinationContext;
    if (target.pathInfo.name === "ProtectedPage" && !isLoggedIn) {
      target.pathStack.pop();
      target.pathStack.pushPathByName("Login", null);
    }
  },
});
```

> `interception` 回调时机比 `willShow` 更早，前者触发时不会创建被拦截的页面。

---

## 五、FAQ

**Q：NavDestination 需要手动处理状态栏高度吗？**

A：不需要。Navigation 从 API 11 开始默认支持安全区域避让。手动读取 `topRectHeight` 并加 padding 是多余的，可能导致双重避让。

**Q：什么时候需要 expandSafeArea？**

A：只有需要沉浸式效果时（背景图/颜色延伸到状态栏/导航栏下方）才需要。普通页面不需要。

**Q：expandSafeArea 和 ignoreLayoutSafeArea 的区别？**

A：`expandSafeArea` 只扩展绘制区域，子组件位置不变；`ignoreLayoutSafeArea` 扩展布局区域，子组件会跟着移动。

**Q：系统路由表和自定义路由表哪个更好？**

A：官方推荐系统路由表，支持按需加载，减少主包体积。自定义路由表（`allDetailBuilder` 方式）需要在主包中 import 所有页面，不利于包体积优化。

**Q：默认转场动画时长是多少？**

A：使用弹簧曲线，时长不固定，不同设备不同。不建议与业务逻辑耦合，需要监听动画结束时使用自定义转场。

**Q：Dialog 类型的 NavDestination 有转场动画吗？**

A：API 12 及以前无动画，API 13 开始默认有系统转场动画。

---

## 六、本项目（米悠悠）现状分析

### 6.1 SafeArea 使用情况

| 位置                      | 当前写法                                                                          | 问题                                          |
| ------------------------- | --------------------------------------------------------------------------------- | --------------------------------------------- |
| `Main.ets` NavDestination | `.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])`                   | 只扩展底部，顶部未扩展                        |
| `Launch.ets`              | `.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])` | 正确，启动页沉浸式                            |
| `EntryAbility.ets`        | 手动读取 `topRectHeight` / `bottomRectHeight` 存入 AppStorage                     | 多余，Navigation 已自动处理                   |
| `AccountSwitchDialog.ets` | 手动读取 `bottomRectHeight` 作为底部 padding                                      | 弹窗类组件需要手动处理（Navigation 不管弹窗） |

### 6.2 路由表使用情况

| 路由                                                                                                | 当前方式                               | 问题                    |
| --------------------------------------------------------------------------------------------------- | -------------------------------------- | ----------------------- |
| GenshinDailyDetail、GenshinCharacterDetail、AccountDetail、Login、TestPage、NotificationSettings    | `allDetailBuilder`（自定义路由表）     | 所有页面在主包中 import |
| StarRailCharacterDetail、ZZZCharacterDetail、StarRailDailyDetail、ZZZDailyDetail、TestPage、WebView | `custom_router_map.json`（系统路由表） | 正确                    |

**混用问题**：部分页面用系统路由表，部分用自定义路由表，不一致。

### 6.3 NavDestination 使用情况

- 所有二级页面都正确使用了 `NavDestination` 作为根容器 ✅
- 都通过 `onReady` 获取 `NavPathStack` ✅
- 没有使用 `onResult` / `onNewParam` 回调（目前没有需要的场景）✅
- 没有使用路由拦截（目前没有需要的场景）✅

### 6.4 转场动画

- 使用系统默认转场，没有自定义 ✅
- 没有使用共享元素转场（目前没有需要的场景）✅

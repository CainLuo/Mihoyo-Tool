# 设计文档：Navigation 多设备适配（navigation-multi-device）

> 详细知识点整理见 `Documents/Navigation-Split-Guide.md`

## 已完成的改动

### 1. Main.ets — navBarWidthRange + minContentWidth

限制左侧导航栏最大宽度，防止三折屏/PC 下左侧过宽；设置右侧内容区最小宽度保护。

```typescript
.navBarWidthRange([240, 400])   // 最大 400 vp，支持用户拖拽
.minContentWidth(320)           // 右侧内容区最小 320 vp
```

### 2. Main.ets — 分屏模式适配

分屏时（`windowStatusType === 4`）强制 Stack 模式，避免分屏场景下仍显示分栏。

```typescript
.mode(this.windowStatusType === 4 ? NavigationMode.Stack : NavigationMode.Auto)
@StorageLink('windowStatusType') private windowStatusType: number = 0
```

### 3. EntryAbility.ets — windowStatusChange 监听

监听窗口状态变化，将 `windowStatusType` 写入 `AppStorage`，供 `Main.ets` 读取。

```typescript
win.on("windowStatusChange", (statusType: window.WindowStatusType) => {
  AppStorage.setOrCreate("windowStatusType", statusType as number);
});
```

### 4. 星铁/绝区零角色详情宽屏布局

新建两栏宽屏布局组件：

- `StarRailCharDetailWideLayout.ets`：左栏立绘+行迹，右栏光锥+属性+遗器
- `ZZZCharDetailWideLayout.ets`：左栏立绘+技能，右栏音擎+属性+驱动盘

两个页面均加入 `onAreaChange` 断点检测，`md`（≥600vp）及以上使用宽屏布局。

## 未改动（保持现状）

- `NavigationMode.Auto`：系统自动处理 520 vp 阈值，无需手动判断
- `isSplit` 传递机制：已完整实现
- 分栏导航（`replacePath` vs `push`）：已正确实现
- 登录页宽屏布局：已有 `LoginWideLayout`
- `splitPlaceholder`：已有 `SplitPlaceholder`（纯色背景）

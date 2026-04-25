# 需求文档：Navigation 多设备适配（navigation-multi-device）

> 参考来源：`Documents/Navigation-Split-Guide.md`（基于官方文档整理）
> 官方最佳实践页面：[多设备设置界面](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-settings-application-page)
> 官方 FAQ：[分屏模式不支持分栏显示](https://developer.huawei.com/consumer/cn/doc/architecture-guides/news-v1_2-ts_c160-0000002396788336)

---

## 一、背景与目标

本项目（米悠悠）需要在 Phone、折叠屏、三折屏、平板、2in1/PC 等多种设备上正确显示分栏/单栏布局。当前实现存在以下问题，需按官方最佳实践优化：

| 问题                | 当前状态                            | 官方推荐                                   |
| ------------------- | ----------------------------------- | ------------------------------------------ |
| 分屏模式判断        | 只判断 `windowStatusType === 4`     | 结合屏幕方向 + 窗口状态综合判断            |
| navBarWidth         | 固定 `'45%'`，宽屏下过宽            | 动态计算 `0.4 * windowWidth`               |
| 模式切换逻辑        | 仅在 Main.ets 通过 StorageLink 读取 | 在页面内直接持有 windowClass，监听两个事件 |
| 星铁/绝区零宽屏布局 | 无宽屏布局                          | 需要两栏布局                               |

---

## 二、功能需求

### 2.1 Navigation 模式动态切换（官方 FAQ 完整方案）

**来源**：[分屏模式不支持分栏显示](https://developer.huawei.com/consumer/cn/doc/architecture-guides/news-v1_2-ts_c160-0000002396788336)

Navigation 的显示模式必须综合以下两个维度判断：

**维度 1：屏幕方向**

- 横屏（`LANDSCAPE` 或 `LANDSCAPE_INVERTED`）：默认分栏，除非处于分屏模式
- 竖屏：根据窗口宽度断点决定（断点 ≤ 2 = 单栏，断点 > 2 = 分栏）

**维度 2：窗口状态**

- `WindowStatusType === 4`（分屏模式）：强制单栏（`NavigationMode.Stack`）
- 其他状态：按维度 1 的规则决定

**判断逻辑（官方代码）**：

```typescript
setCurrentMode() {
  if (display.getDefaultDisplaySync().orientation === display.Orientation.LANDSCAPE ||
      display.getDefaultDisplaySync().orientation === display.Orientation.LANDSCAPE_INVERTED) {
    // 横屏：分屏时单栏，否则分栏
    this.currentMode = (this.currentWindowStatusType === 4)
      ? NavigationMode.Stack
      : NavigationMode.Split;
  } else {
    // 竖屏：按断点决定
    this.currentMode = this.currentBreakPoint <= 2
      ? NavigationMode.Stack
      : NavigationMode.Split;
  }
}
```

**触发时机**：

- `aboutToAppear` 时初始化一次
- 监听 `windowSizeChange`：更新 `currentBreakPoint`，重新计算模式
- 监听 `windowStatusChange`：更新 `currentWindowStatusType`，重新计算模式

### 2.2 navBarWidth 动态计算

**来源**：[多设备设置界面最佳实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-settings-application-page)

官方示例使用窗口宽度的固定比例动态计算，而非固定百分比字符串：

```typescript
.navBarWidth(0.4 * this.windowWidth)
```

同时配合 `navBarWidthRange` 和 `minContentWidth` 限制极端情况：

```typescript
.navBarWidth(0.4 * this.windowWidthVp)
.navBarWidthRange([240, 400])
.minContentWidth(320)
```

需要在 `EntryAbility` 监听 `windowSizeChange` 时同步更新 `windowWidthVp`（vp 单位），供 `Main.ets` 读取。

### 2.3 windowClass 持有方式

**来源**：[分屏模式不支持分栏显示](https://developer.huawei.com/consumer/cn/doc/architecture-guides/news-v1_2-ts_c160-0000002396788336)

官方方案在 `EntryAbility.onWindowStageCreate` 中将 `windowClass` 存入 `AppStorage`，页面直接读取并注册监听：

```typescript
// EntryAbility.ts
AppStorage.setOrCreate('windowClass', windowStage.getMainWindowSync());

// Main.ets（页面内）
windowClass: window.Window | undefined = AppStorage.get('windowClass');
// 在 aboutToAppear 中注册监听
this.windowClass?.on('windowSizeChange', () => { ... });
this.windowClass?.on('windowStatusChange', (statusType) => { ... });
```

这样 Main.ets 直接持有 windowClass 引用，不需要通过 AppStorage 中转 `windowStatusType` 这个中间值。

### 2.4 星铁/绝区零角色详情宽屏布局

宽屏（容器宽度 ≥ 600vp）时，星铁和绝区零角色详情页应切换为两栏布局：

- **星铁**：左栏（立绘 + 行迹），右栏（光锥 + 属性 + 遗器，可滚动）
- **绝区零**：左栏（立绘 + 技能），右栏（音擎 + 属性 + 驱动盘，可滚动）

通过 `onAreaChange` 监听容器宽度变化，动态切换布局。

### 2.5 SplitPlaceholder 引导文字（可选）

当前 `SplitPlaceholder` 是纯色背景，分栏右侧无内容时显示空白。可以加上引导文字提升首次使用体验，但不是必须的。

---

## 三、非功能需求

- **不改变现有路由逻辑**：`replacePath`（分栏）vs `pushPathByName`（单栏）的判断逻辑保持不变
- **不影响 Phone 竖屏体验**：Phone 竖屏下必须保持单栏，不能因为适配宽屏而影响主要使用场景
- **向后兼容**：`splitPlaceholder` 是 API 20+，本项目 targetSdkVersion = API 22，可以使用
- **ArkTS 严格模式**：所有新增代码必须通过 hvigor 编译，不能有 `any`/`unknown` 类型

---

## 四、当前实现与目标的差距

| 需求                          | 当前状态                                                         | 是否需要改动 |
| ----------------------------- | ---------------------------------------------------------------- | ------------ |
| 2.1 Navigation 模式动态切换   | 只判断 `windowStatusType === 4`，未结合屏幕方向                  | ✅ 需要改    |
| 2.2 navBarWidth 动态计算      | 固定 `'45%'` + `navBarWidthRange([240,400])`                     | ✅ 需要改    |
| 2.3 windowClass 持有方式      | 通过 AppStorage 中转 `windowStatusType`                          | ✅ 需要改    |
| 2.4 星铁/绝区零宽屏布局       | 已有 `StarRailCharDetailWideLayout` 和 `ZZZCharDetailWideLayout` | ✅ 已完成    |
| 2.5 SplitPlaceholder 引导文字 | 纯色背景                                                         | ⬜ 可选      |

---

## 五、不在本次范围内

- 折叠屏悬停态（`FolderStack` / `FoldSplitContainer`）：本项目无视频/全屏场景，暂不需要
- 三折屏三栏布局：Navigation 原生只支持两栏，三栏需要额外嵌套，复杂度高，暂不做
- 自定义转场动画：现有默认转场已满足需求

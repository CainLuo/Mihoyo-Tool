# 设计文档：全局操作反馈（Global Operation Feedback）

## 概述

本功能为米悠悠 App 引入统一的操作反馈机制。通过一个共享的 `showFeedback` 工具函数和自定义 Snackbar 组件，为首页刷新、角色页刷新、清理缓存、导出日志等用户触发的异步操作提供轻量、一致的 UI 反馈。

### 设计目标

- **简单**：各页面/组件直接调用工具函数，按需显示，用完即走，无全局状态
- **轻量**：Snackbar 显示在底部，自动消失，不打断用户操作流
- **统一**：所有反馈使用同一套 Snackbar 组件，视觉风格一致

### 技术约束

- 不使用 `@kit.UIDesignKit` 中的 Hds 系列组件
- 使用 `promptAction.openCustomDialog` 实现自定义 Snackbar
- 所有颜色/间距/圆角必须使用 `ThemeManager` token，禁止硬编码

---

## 架构

### 整体数据流

```
Operation_Caller                    showFeedback()              Snackbar UI
(Home.ets /                         (工具函数)
 Characters.ets /
 AboutSection.ets)
       │                                  │
       │  showFeedback(ctx, type, text)   │
       │─────────────────────────────────▶│
       │                                  │  promptAction.openCustomDialog
       │                                  │──────────────────────────────▶ Snackbar 显示
       │                                  │
       │                                  │  3000ms / 4000ms 后自动关闭
       │                                  │◀──────────────────────────────
```

### 与现有错误处理机制的边界

```
用户操作
    │
    ├─ 需要用户决策（Cookie 过期、Geetest 验证）
    │       └─▶ 现有 Dialog 机制（CookieExpiredSignal / GeetestDialog）
    │
    └─ 操作结果通知（成功/失败/信息）
            └─▶ showFeedback() → Snackbar（本功能）
```

---

## 组件与接口

### 1. FeedbackType 枚举

**文件**：`entry/src/main/ets/constants/FeedbackType.ets`

```typescript
export enum FeedbackType {
  SUCCESS = "SUCCESS",
  ERROR = "ERROR",
  INFO = "INFO",
}
```

### 2. showFeedback 工具函数

**文件**：`entry/src/main/ets/utils/FeedbackUtil.ets`

各页面/组件直接调用，传入当前 `UIContext`、类型和文案即可：

```typescript
import { FeedbackType } from "../constants/FeedbackType";
import { ComponentContent, wrapBuilder } from "@kit.ArkUI";
import { snackbarBuilder, SnackbarParams } from "../components/SnackbarContent";

export function showFeedback(
  ctx: UIContext,
  type: FeedbackType,
  text: ResourceStr,
): void {
  const params = new SnackbarParams();
  params.type = type;
  params.text = text;

  const content = new ComponentContent(
    ctx,
    wrapBuilder(snackbarBuilder),
    params,
  );
  params.onDismiss = () => {
    ctx.getPromptAction().closeCustomDialog(content);
  };

  ctx
    .getPromptAction()
    .openCustomDialog(content, {
      alignment: DialogAlignment.Bottom,
      offset: { dx: 0, dy: -80 }, // 底部 Tab 栏高度，使用 value80 token
      maskColor: Color.Transparent,
      isModal: false,
      autoCancel: true,
    })
    .catch((_: Error | object) => {});
}
```

**关键设计决策**：

- 调用方传入自己的 `UIContext`，无需全局状态
- `isModal: false` + `maskColor: Color.Transparent`：不阻断用户操作
- `autoCancel: true`：点击外部立即关闭
- 每次调用独立创建 `ComponentContent`，用完即销毁

### 3. SnackbarContent 组件

**文件**：`entry/src/main/ets/components/SnackbarContent.ets`

```typescript
export class SnackbarParams {
  type: FeedbackType = FeedbackType.INFO;
  text: ResourceStr = "";
  onDismiss: () => void = () => {};
}

@Builder
export function snackbarBuilder(params: SnackbarParams) {
  SnackbarContent({ params: params })
}

@ComponentV2
export struct SnackbarContent {
  @Param params: SnackbarParams = new SnackbarParams()
  @Local private tm: ThemeManager = themeManager

  aboutToAppear(): void {
    const duration = this.params.type === FeedbackType.ERROR ? 4000 : 3000;
    setTimeout(() => {
      this.params.onDismiss();
    }, duration);
  }

  build() {
    Row({ space: this.tm.current.value8 }) {
      // 图标
      SymbolGlyph(this.iconForType())
        .fontSize(this.tm.current.value20)
        .fontColor([this.colorForType()])
      // 文案
      Text(this.params.text)
        .font(this.tm.current.body14)
        .fontColor(this.tm.current.colorTextPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .padding({
      left: this.tm.current.value16,
      right: this.tm.current.value16,
      top: this.tm.current.value12,
      bottom: this.tm.current.value12,
    })
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
  }

  private iconForType(): Resource {
    if (this.params.type === FeedbackType.SUCCESS) {
      return $r('sys.symbol.checkmark_circle');
    }
    if (this.params.type === FeedbackType.ERROR) {
      return $r('sys.symbol.xmark_circle');
    }
    return $r('sys.symbol.info_circle');
  }

  private colorForType(): ResourceColor {
    if (this.params.type === FeedbackType.ERROR) {
      return this.tm.current.colorDanger;
    }
    return this.tm.current.colorPrimary;
  }
}
```

---

## 数据模型

### FeedbackType 与视觉映射

| FeedbackType | 图标                          | 图标颜色 token | 自动消失时长 |
| ------------ | ----------------------------- | -------------- | ------------ |
| `SUCCESS`    | `sys.symbol.checkmark_circle` | `colorPrimary` | 3000ms       |
| `ERROR`      | `sys.symbol.xmark_circle`     | `colorDanger`  | 4000ms       |
| `INFO`       | `sys.symbol.info_circle`      | `colorPrimary` | 3000ms       |

---

## 视觉规范

### Snackbar 布局

```
┌─────────────────────────────────────────────────────┐
│  [图标]  反馈文案（单行截断）                        │
└─────────────────────────────────────────────────────┘
```

### Token 使用规范

| 属性           | Token              |
| -------------- | ------------------ |
| 背景色         | `colorSurfaceCard` |
| 文案颜色       | `colorTextPrimary` |
| 圆角           | `radius12`         |
| 水平内边距     | `value16`          |
| 垂直内边距     | `value12`          |
| 图标尺寸       | `value20`          |
| 图标与文案间距 | `value8`           |
| 底部偏移       | `value80`          |

### 设备适配

- `DialogAlignment.Bottom` + `offset.dy = -value80`，确保显示在底部 Tab 栏上方
- Snackbar 左右 padding 使用 `value16`，宽度由内容自适应

---

## 各调用方集成方案

### Home.ets 集成

`HomeViewModel` 不持有 `UIContext`，由 `Home.ets` 在 `@Monitor` 回调里调用：

新增 `@Trace refreshFeedback` 字段作为信号，`Home.ets` 监听后调用 `showFeedback`：

```typescript
// HomeViewModel.ets 新增
@Trace refreshResult: 'success' | 'error' | '' = ''
@Trace refreshErrorMsg: string = ''

async refresh(): Promise<void> {
  // ...
  try {
    await this.syncAllDailyNotes()
    this.refreshResult = 'success'
  } catch (error) {
    this.refreshErrorMsg = error instanceof Error ? error.message : `${error}`
    this.refreshResult = 'error'
  } finally {
    this.isRefreshing = false
  }
}
```

```typescript
// Home.ets 新增 @Monitor
@Monitor('vm.refreshResult')
onRefreshResult(_monitor: IMonitor): void {
  const result = this.vm.refreshResult
  if (result === '') { return }
  this.vm.refreshResult = ''
  const ctx = this.uiCtx
  if (ctx === null) { return }
  if (result === 'success') {
    showFeedback(ctx, FeedbackType.SUCCESS, $r('app.string.feedback_home_refresh_success'))
  } else {
    showFeedback(ctx, FeedbackType.ERROR, $r('app.string.feedback_refresh_error'))
  }
}
```

**不显示反馈的场景**：

- 冷却拦截（`refreshCoolingDown` 触发，由现有 Dialog 处理）
- `autoRefreshTimer` 触发的后台同步（不设置 `refreshResult`）
- Geetest 验证触发

### Characters.ets 集成

与 `Home.ets` 模式相同，`CharactersViewModel` 新增 `refreshResult` 信号，`Characters.ets` 监听后调用 `showFeedback`。

### AboutSection.ets 集成

`AboutSection` 自身持有 `UIContext`，直接调用：

```typescript
// 清理缓存成功
showFeedback(
  this.getUIContext(),
  FeedbackType.SUCCESS,
  $r("app.string.my_clear_cache_success", freed),
);

// 清理缓存部分失败
showFeedback(
  this.getUIContext(),
  FeedbackType.ERROR,
  $r("app.string.my_clear_cache_failed", deleteResult.failedCount),
);

// 导出日志失败
showFeedback(
  this.getUIContext(),
  FeedbackType.ERROR,
  $r("app.string.my_export_logs_failed"),
);
```

---

## 正确性属性

### Property 1：FeedbackType 与图标/颜色的映射一致性

_对于任意_ `FeedbackType` 枚举值，`iconForType()` 和 `colorForType()` 应返回非空的资源引用，且不同类型返回不同的图标资源。

**Validates: Requirements 2.3**

### Property 2：HomeViewModel 成功刷新后 refreshResult 为 'success'

_对于任意_ 账号/角色组合，当 `HomeViewModel.refresh()` 成功完成时，`refreshResult` 应被设置为 `'success'`。

**Validates: Requirements 3.1**

### Property 3：HomeViewModel 网络错误后 refreshResult 为 'error'

_对于任意_ 错误情况，当 `HomeViewModel.refresh()` 因网络错误失败时，`refreshResult` 应被设置为 `'error'`。

**Validates: Requirements 3.2**

### Property 4：FeedbackType 枚举完整性

`FeedbackType` 枚举应包含且仅包含 `SUCCESS`、`ERROR`、`INFO` 三个值。

**Validates: Requirements 9.4**

---

## 测试策略

### 单元测试（entry/src/test/）

在现有 `HomeViewModel.test.ets` 中补充：

| 测试用例                                  | 类型    | 说明                |
| ----------------------------------------- | ------- | ------------------- |
| refresh 成功后 refreshResult 为 'success' | EXAMPLE | 见 Property 2       |
| refresh 失败后 refreshResult 为 'error'   | EXAMPLE | 见 Property 3       |
| 冷却拦截时 refreshResult 不变             | EXAMPLE | 见 Requirements 3.3 |
| autoRefresh 触发时 refreshResult 不变     | EXAMPLE | 见 Requirements 3.4 |
| FeedbackType 枚举包含 SUCCESS/ERROR/INFO  | EXAMPLE | 见 Property 4       |

### 设备端 UI 测试（entry/src/ohosTest/）

在 `HomePageTest.test.ets` 中补充：

| 测试用例                           | 说明               |
| ---------------------------------- | ------------------ |
| 触发刷新成功后 Snackbar 出现在底部 | 验证 Snackbar 渲染 |
| Snackbar 3 秒后自动消失            | 验证自动消失       |
| SUCCESS 类型显示正确图标           | 验证视觉映射       |
| ERROR 类型 4 秒后消失              | 验证不同时长       |

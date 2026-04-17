# 实现计划：全局操作反馈（Global Operation Feedback）

## 概述

按设计文档，依次创建 `FeedbackType` 枚举、`SnackbarContent` 组件、`showFeedback` 工具函数，再集成到 `HomeViewModel`、`CharactersViewModel` 和 `AboutSection`。

## 任务列表

- [x] 1. 创建 FeedbackType 枚举
  - 在 `entry/src/main/ets/constants/FeedbackType.ets` 新建文件
  - 定义 `SUCCESS`、`ERROR`、`INFO` 三个枚举值
  - _需求：1.4, 9.4_

- [x] 2. 创建 SnackbarContent 组件
  - [x] 2.1 实现 SnackbarParams 类和 snackbarBuilder 函数
    - 在 `entry/src/main/ets/components/SnackbarContent.ets` 新建文件
    - 定义 `SnackbarParams` 类（type、text、onDismiss 字段）
    - 定义 `@Builder snackbarBuilder(params: SnackbarParams)` 函数
    - _需求：2.1, 2.3, 2.4_
  - [x] 2.2 实现 SnackbarContent 组件 UI
    - 用 `@ComponentV2` 实现 `SnackbarContent` struct
    - `aboutToAppear` 中根据 type 设置 3000ms/4000ms 定时器调用 `onDismiss`
    - `build()` 中用 `Row` 排列 `SymbolGlyph` 图标和 `Text` 文案
    - 背景 `colorSurfaceCard`、圆角 `radius12`、padding `value16`/`value12`
    - 图标尺寸 `value20`，图标与文案间距 `value8`
    - 在文件末尾添加 `@Preview` 覆盖 SUCCESS/ERROR/INFO 三种状态
    - _需求：2.3, 2.4, 2.6, 7.1, 7.2, 7.3_
  - [ ]\* 2.3 为 SnackbarContent 编写属性测试（Property 1）
    - **Property 1：FeedbackType 与图标/颜色的映射一致性**
    - 验证 `iconForType()` 对三种 FeedbackType 均返回非空资源引用
    - 验证不同类型返回不同图标资源
    - **Validates: Requirements 2.3**

- [x] 3. 创建 showFeedback 工具函数
  - 在 `entry/src/main/ets/utils/FeedbackUtil.ets` 新建文件
  - 实现 `showFeedback(ctx: UIContext, type: FeedbackType, text: ResourceStr): void`
  - 使用 `ComponentContent` + `wrapBuilder(snackbarBuilder)` 创建内容
  - 调用 `ctx.getPromptAction().openCustomDialog` 配置 `DialogAlignment.Bottom`、`offset.dy = -80`、`isModal: false`、`maskColor: Color.Transparent`、`autoCancel: true`
  - _需求：2.1, 2.2, 2.8_

- [x] 4. 集成到 HomeViewModel
  - [x] 4.1 修改 HomeViewModel.refresh() 和 forceRefresh()
    - 在 `entry/src/main/ets/viewmodel/HomeViewModel.ets` 新增 `@Trace refreshResult: 'success' | 'error' | ''` 和 `@Trace refreshErrorMsg: string` 字段
    - 在 `HomeViewModelKeys` 中新增 `refreshResult` 路径常量
    - `refresh()` 成功后设置 `refreshResult = 'success'`，网络错误时设置 `refreshResult = 'error'`
    - `forceRefresh()` 同上
    - 冷却拦截和 autoRefreshTimer 触发的同步不设置 `refreshResult`
    - _需求：3.1, 3.2, 3.3, 3.4_
  - [ ]\* 4.2 为 HomeViewModel 编写属性测试（Property 2 & 3）
    - **Property 2：refresh 成功后 refreshResult 为 'success'**
    - **Property 3：refresh 网络错误后 refreshResult 为 'error'**
    - **Validates: Requirements 3.1, 3.2**

- [x] 5. 集成到 Home.ets
  - 在 `entry/src/main/ets/pages/Home.ets` 中 import `showFeedback` 和 `FeedbackType`
  - 新增 `@Monitor(HomeViewModel.KEYS.refreshResult)` 回调 `onRefreshResult`
  - 回调中读取 `vm.refreshResult`，为空则返回；否则清空后调用 `showFeedback`
  - SUCCESS 使用 `$r('app.string.feedback_home_refresh_success')`，ERROR 使用 `$r('app.string.feedback_refresh_error')`
  - 在三个多语言文件中添加对应字符串 key
  - _需求：3.1, 3.2_

- [x] 6. 集成到 CharactersViewModel
  - [x] 6.1 修改 CharactersViewModel.refresh() 和 forceRefresh()
    - 在 `entry/src/main/ets/viewmodel/CharactersViewModel.ets` 新增 `@Trace refreshResult: 'success' | 'error' | ''` 字段
    - 在 `CharactersViewModelKeys` 中新增 `refreshResult` 路径常量
    - `refresh()` 成功后设置 `refreshResult = 'success'`，错误时设置 `refreshResult = 'error'`
    - `forceRefresh()` 同上
    - 冷却拦截和 `autoSyncCharacters` 不设置 `refreshResult`
    - _需求：4.1, 4.2, 4.3, 4.4_
  - [x] 6.2 集成到 Characters.ets
    - 在 `entry/src/main/ets/pages/Characters.ets` 中 import `showFeedback` 和 `FeedbackType`
    - 新增 `@Monitor(CharactersViewModel.KEYS.refreshResult)` 回调
    - SUCCESS 使用 `$r('app.string.feedback_characters_refresh_success')`，ERROR 使用 `$r('app.string.feedback_refresh_error')`
    - 在三个多语言文件中添加对应字符串 key
    - _需求：4.1, 4.2_

- [ ] 7. 检查点 — 确保所有测试通过
  - 确保所有测试通过，如有问题请告知。

- [x] 8. 集成到 AboutSection
  - 在 `entry/src/main/ets/components/my/AboutSection.ets` 中 import `showFeedback` 和 `FeedbackType`
  - 删除 `showSnackBar` 私有方法
  - `onClearCache` 成功时调用 `showFeedback(this.getUIContext(), FeedbackType.SUCCESS, $r('app.string.my_clear_cache_success', freed))`
  - `onClearCache` 部分失败时调用 `showFeedback(this.getUIContext(), FeedbackType.ERROR, $r('app.string.my_clear_cache_failed', deleteResult.failedCount))`
  - `onExportLogs` 失败时调用 `showFeedback(this.getUIContext(), FeedbackType.ERROR, $r('app.string.my_export_logs_failed'))`
  - _需求：5.1, 5.2, 5.4, 6.1, 6.3_

- [x] 9. 补充多语言字符串资源
  - 确认 `base/element/string.json`、`zh_HK/element/string.json`、`en/element/string.json` 中包含以下 key：
    - `feedback_home_refresh_success`
    - `feedback_characters_refresh_success`
    - `feedback_refresh_error`
  - 以上 key 若在任务 5/6 中已添加则跳过
  - _需求：3.1, 3.2, 4.1, 4.2_

- [x] 10. 最终检查点 — 确保所有测试通过
  - 确保所有测试通过，如有问题请告知。

## 备注

- 标有 `*` 的子任务为可选测试任务，可跳过以加快 MVP 进度
- 每个任务均引用了具体需求条款，便于追溯
- Property 测试验证设计文档中定义的正确性属性
- `showFeedback` 每次调用独立创建 `ComponentContent`，无全局状态，用完即销毁

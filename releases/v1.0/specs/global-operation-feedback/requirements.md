# 需求文档：全局操作反馈（Global Operation Feedback）

## 简介

米悠悠 App 中存在多处用户触发的异步操作（如首页刷新战绩数据、角色页面刷新角色列表、清理缓存等），这些操作在成功或失败时目前没有任何 UI 反馈，用户无法判断操作是否已完成、是否成功。

本功能设计一套统一的全局操作反馈机制，通过轻量的 Toast 或自定义 Snackbar 向用户呈现操作结果，覆盖成功、失败、进行中三种状态。

**技术约束：**

- 不使用 `@kit.UIDesignKit` 中的 Hds 系列组件（如 `HdsSnackBar`）
- 系统原生 Toast（`promptAction.showToast`）仅支持纯文字，适用于简单反馈
- 需要带图标或带操作按钮的富文本反馈，需自定义实现（`promptAction.openCustomDialog`）
- 项目使用 ArkUI MVVM 架构，全局信号通过 `AppStorageV2` 共享（参考 `AccountSignal`、`CookieExpiredSignal` 的实现模式）

---

## 词汇表

- **Feedback_Signal**：全局操作反馈信号，通过 `AppStorageV2` 共享，任意模块均可写入，`Main.ets` 统一监听并渲染
- **Toast**：系统原生 `promptAction.showToast`，纯文字，自动消失，适用于简单成功/失败提示
- **Snackbar**：自定义轻量通知条，支持图标和可选操作按钮，通过 `promptAction.openCustomDialog` 实现，显示在屏幕底部，自动消失
- **FeedbackMessage**：单条反馈消息的数据模型，包含类型（成功/失败/信息）、文案、可选操作按钮
- **FeedbackType**：反馈类型枚举，包含 `SUCCESS`（成功）、`ERROR`（失败）、`INFO`（信息）三种
- **Operation_Caller**：触发操作并需要反馈的调用方，包括 `HomeViewModel`、`CharactersViewModel`、`AboutSection` 等
- **Main_Listener**：`Main.ets` 中监听 `Feedback_Signal` 并渲染 Snackbar 的逻辑
- **Auto_Dismiss**：Snackbar 在指定时间后自动消失，无需用户手动关闭

---

## 需求列表

### 需求 1：全局反馈信号机制

**用户故事：** 作为一名开发者，我希望有一套统一的全局信号机制，使任意 ViewModel 或组件都能以相同方式发出操作反馈，以便 UI 层统一处理，不需要每个页面各自实现 Toast 逻辑。

#### 验收标准

1. THE Feedback_Signal SHALL 通过 `AppStorageV2.connect` 实现跨组件共享，与 `AccountSignal`、`CookieExpiredSignal` 保持一致的实现模式。

2. THE Feedback_Signal SHALL 提供静态方法 `FeedbackSignal.show(message: FeedbackMessage)` 供任意调用方发出反馈，调用方无需持有 `UIContext` 或任何 UI 引用。

3. THE FeedbackMessage SHALL 包含以下字段：
   - `type: FeedbackType`（SUCCESS / ERROR / INFO）
   - `text: ResourceStr`（反馈文案，支持多语言资源引用）
   - `actionLabel?: ResourceStr`（可选操作按钮文案）
   - `onAction?: () => void`（可选操作按钮回调）

4. THE FeedbackType SHALL 为枚举类型，包含 `SUCCESS`、`ERROR`、`INFO` 三个值，存放于 `entry/src/main/ets/constants/FeedbackType.ets`。

5. WHEN 多条反馈消息在短时间内连续发出，THE Feedback_Signal SHALL 将消息存入队列，由 `Main_Listener` 逐条处理，不丢失任何消息。

6. WHEN 队列中的消息被 `Main_Listener` 消费后，THE Feedback_Signal SHALL 从队列中移除该消息，保持队列整洁。

---

### 需求 2：Snackbar 渲染与自动消失

**用户故事：** 作为一名用户，我希望操作反馈以轻量的通知条形式出现在屏幕底部，短暂显示后自动消失，不遮挡主要内容，以便我能感知操作结果而不被打断。

#### 验收标准

1. WHEN `Feedback_Signal` 队列中有新消息，THE Main_Listener SHALL 通过 `promptAction.openCustomDialog` 在屏幕底部渲染一个 Snackbar 组件。

2. THE Snackbar SHALL 显示在屏幕底部，位于底部 Tab 栏上方，不遮挡 Tab 栏。

3. THE Snackbar SHALL 根据 `FeedbackType` 显示对应的图标：
   - `SUCCESS`：✓ 图标，颜色为 `colorSuccess`（绿色系）
   - `ERROR`：✗ 图标，颜色为 `colorDanger`（红色系）
   - `INFO`：ℹ 图标，颜色为 `colorPrimary`（主色）

4. THE Snackbar SHALL 显示 `FeedbackMessage.text` 文案，单行截断，不换行。

5. WHERE `FeedbackMessage.actionLabel` 非空，THE Snackbar SHALL 在文案右侧显示操作按钮，点击后执行 `FeedbackMessage.onAction` 回调并关闭 Snackbar。

6. WHEN Snackbar 显示后经过 3000 毫秒（SUCCESS/INFO 类型）或 4000 毫秒（ERROR 类型），THE Snackbar SHALL 自动关闭，无需用户操作。

7. WHEN Snackbar 正在显示时又有新消息进入队列，THE Main_Listener SHALL 等待当前 Snackbar 关闭后再显示下一条，不同时显示多个 Snackbar。

8. WHEN 用户点击 Snackbar 区域外的任意位置，THE Snackbar SHALL 立即关闭（`autoCancel: true`）。

---

### 需求 3：首页刷新战绩数据的操作反馈

**用户故事：** 作为一名用户，我希望在首页点击刷新按钮后，能看到刷新成功或失败的提示，以便我知道数据是否已更新。

#### 验收标准

1. WHEN `HomeViewModel.refresh()` 或 `HomeViewModel.forceRefresh()` 执行成功（所有角色便笺同步完成），THE HomeViewModel SHALL 通过 `FeedbackSignal.show` 发出一条 `SUCCESS` 类型的反馈，文案为「战绩数据已更新」。

2. WHEN `HomeViewModel.refresh()` 或 `HomeViewModel.forceRefresh()` 执行过程中发生网络错误，THE HomeViewModel SHALL 通过 `FeedbackSignal.show` 发出一条 `ERROR` 类型的反馈，文案包含错误描述。

3. WHEN `HomeViewModel.refresh()` 因冷却时间未到而被拦截（`refreshCoolingDown` 信号触发），THE HomeViewModel SHALL 不发出任何 `FeedbackSignal`，冷却提示由现有的 Dialog 机制处理。

4. WHEN `HomeViewModel` 的自动刷新定时器（`autoRefreshTimer`）触发后台同步，THE HomeViewModel SHALL 不发出任何 `FeedbackSignal`，后台静默同步不打扰用户。

---

### 需求 4：角色页面刷新角色列表的操作反馈

**用户故事：** 作为一名用户，我希望在角色页面点击刷新按钮后，能看到刷新成功或失败的提示，以便我知道角色数据是否已更新。

#### 验收标准

1. WHEN `CharactersViewModel.refresh()` 或 `CharactersViewModel.forceRefresh()` 执行成功，THE CharactersViewModel SHALL 通过 `FeedbackSignal.show` 发出一条 `SUCCESS` 类型的反馈，文案为「角色数据已更新」。

2. WHEN `CharactersViewModel.refresh()` 或 `CharactersViewModel.forceRefresh()` 执行过程中发生网络错误，THE CharactersViewModel SHALL 通过 `FeedbackSignal.show` 发出一条 `ERROR` 类型的反馈，文案包含错误描述。

3. WHEN `CharactersViewModel.refresh()` 因冷却时间未到而被拦截，THE CharactersViewModel SHALL 不发出任何 `FeedbackSignal`，冷却提示由现有的 Dialog 机制处理。

4. WHEN `CharactersViewModel.autoSyncCharacters()` 在后台静默同步时，THE CharactersViewModel SHALL 不发出任何 `FeedbackSignal`，后台静默同步不打扰用户。

---

### 需求 5：清理缓存操作的反馈

**用户故事：** 作为一名用户，我希望在「我的」页面执行清理缓存操作后，能看到清理成功或失败的提示，以便我确认缓存已被清除。

#### 验收标准

1. WHEN `AboutSection.onClearCache()` 中用户确认清理且操作成功（`failedCount === 0`），THE AboutSection SHALL 通过 `FeedbackSignal.show` 发出一条 `SUCCESS` 类型的反馈，文案为「已释放 X MB 缓存」（X 为实际释放的字节数格式化后的值）。

2. WHEN `AboutSection.onClearCache()` 中操作部分失败（`failedCount > 0`），THE AboutSection SHALL 通过 `FeedbackSignal.show` 发出一条 `ERROR` 类型的反馈，文案为「清理缓存失败，X 个文件未能删除」。

3. WHEN `AboutSection.onClearCache()` 中用户点击取消（Dialog 取消按钮），THE AboutSection SHALL 不发出任何 `FeedbackSignal`。

4. WHEN `AboutSection.onClearCache()` 中操作成功，THE AboutSection SHALL 将现有的 `showSnackBar` 调用替换为 `FeedbackSignal.show`，不再直接调用 `promptAction.showToast`。

---

### 需求 6：导出日志操作的反馈

**用户故事：** 作为一名用户，我希望在导出日志失败时能看到错误提示，以便我知道导出未成功。

#### 验收标准

1. WHEN `AboutSection.onExportLogs()` 执行失败（`LogExporter.export` 抛出异常），THE AboutSection SHALL 通过 `FeedbackSignal.show` 发出一条 `ERROR` 类型的反馈，文案为「导出日志失败」。

2. WHEN `AboutSection.onExportLogs()` 执行成功或用户取消文件选择器，THE AboutSection SHALL 不发出任何 `FeedbackSignal`（成功和取消均无需提示）。

3. WHEN `AboutSection.onExportLogs()` 中操作失败，THE AboutSection SHALL 将现有的 `showSnackBar` 调用替换为 `FeedbackSignal.show`，不再直接调用 `promptAction.showToast`。

---

### 需求 7：反馈组件的视觉规范

**用户故事：** 作为一名用户，我希望操作反馈的视觉风格与 App 整体设计保持一致，以便获得统一的视觉体验。

#### 验收标准

1. THE Snackbar 组件 SHALL 使用 `ThemeManager.current` 中的 token 获取所有颜色、间距、圆角值，禁止硬编码任何数值。

2. THE Snackbar 组件 SHALL 使用 `colorSurfaceCard` 作为背景色，`colorTextPrimary` 作为文案颜色。

3. THE Snackbar 组件 SHALL 使用 `radius12` 作为圆角，`value16` 作为水平内边距，`value12` 作为垂直内边距。

4. THE Snackbar 组件 SHALL 在显示和消失时应用淡入淡出动画（`opacity` 从 0 到 1，持续 200ms）。

5. THE Snackbar 组件 SHALL 适配深色和浅色主题，颜色 token 切换时自动更新，无需重启。

6. THE Snackbar 组件 SHALL 在 Phone 竖屏、Phone 横屏、平板、折叠屏展开等不同设备形态下均正确显示在底部，不超出安全区域。

---

### 需求 8：与现有错误处理机制的边界划分

**用户故事：** 作为一名开发者，我希望全局操作反馈与现有的 Cookie 过期 Dialog、Geetest 验证 Dialog 等机制有清晰的边界，以便各机制职责明确，不产生重复提示。

#### 验收标准

1. THE Feedback_Signal 机制 SHALL 仅处理操作结果反馈（成功/失败/信息），不处理需要用户主动决策的场景（如 Cookie 过期需要重新登录、Geetest 验证需要用户操作）。

2. WHEN `HomeViewModel` 检测到 Geetest 验证需求（`geetestTrigger` 非 null），THE HomeViewModel SHALL 不通过 `FeedbackSignal` 发出任何消息，Geetest 流程由现有的 `GeetestDialog` 机制处理。

3. WHEN `CookieExpiredSignal` 触发登录过期 Dialog，THE Main_Listener SHALL 不同时显示 Snackbar，两种通知机制互不干扰。

4. WHEN `HomeViewModel.networkErrorMsg` 被设置（现有机制），THE HomeViewModel SHALL 同时通过 `FeedbackSignal.show` 发出 `ERROR` 类型反馈，逐步将 `networkErrorMsg` 的 Alert 替换为 Snackbar，但在本 Spec 实现阶段两者可并存。

---

### 需求 9：可测试性设计

**用户故事：** 作为一名开发者，我希望全局操作反馈机制有完整的单元测试覆盖，以便在不依赖真实 UI 的情况下验证信号传递逻辑。

#### 验收标准

1. THE FeedbackSignal SHALL 提供 `FeedbackSignal.instance()` 静态方法返回单例，以便在测试中通过 `AppStorageV2` 注入 mock 实例。

2. THE FeedbackSignal.show 方法 SHALL 将消息追加到 `queue` 数组，以便在单元测试中直接检查 `queue` 内容，验证消息是否正确发出。

3. FOR ALL 有效的 `FeedbackMessage` 对象，THE FeedbackSignal.show 方法 SHALL 保证 `queue.length` 在调用后恰好增加 1，不丢失消息（幂等性：连续调用 N 次，queue 长度增加 N）。

4. THE FeedbackType 枚举 SHALL 包含且仅包含 `SUCCESS`、`ERROR`、`INFO` 三个值，以便测试中枚举值与字符串一致性验证。

5. THE Snackbar 自动消失计时器 SHALL 通过可注入的延迟函数实现，以便在单元测试中替换为同步执行，不依赖真实计时器。

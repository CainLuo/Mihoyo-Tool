# Requirements Document

## Introduction

当前 My 页的「外观设置」区域使用 `AppearanceSection` 组件，内联三个 `ThemeChip` 按钮（浅色 / 深色 / 跟随系统）。在分栏模式下（左侧约 360vp），三个按钮挤在一行，「跟随系统」按钮容易被截断或换行，影响可用性。

本功能将「外观设置」区域改为 `SettingRow` 样式：右侧显示当前选中值，点击跳转独立二级页。二级页参考系统设置「显示和亮度」的交互：列表形式，每项有图标、标题、描述、选中勾。改动后任何屏幕宽度下均不会出现截断问题。

涉及变更：

- `My.ets` — 将 `AppearanceSection` 替换为 `SettingRow`
- `AppearanceSection.ets` — 重写为新的 `SettingRow` 样式（或废弃）
- `ThemeChip.ets` — 废弃
- 新增 `AppearanceSettingsPage.ets` — 外观设置二级页
- `AppRoutes.ets` — 新增路由常量
- `custom_router_map.json` — 注册新路由

## Glossary

- **AppearanceSection**：My 页中负责渲染外观设置区域的组件，当前实现为内联 ThemeChip 按钮组，本功能将其替换为 SettingRow 样式。
- **AppearanceSettingsPage**：新增的外观设置二级页，以列表形式展示三种主题模式供用户选择。
- **ThemeMode**：主题模式，对应 `ConfigurationConstant.ColorMode` 枚举，取值为 `COLOR_MODE_LIGHT`（浅色）、`COLOR_MODE_DARK`（深色）、`COLOR_MODE_NOT_SET`（跟随系统）。
- **ThemeModeLabel**：ThemeMode 对应的本地化显示标签，由 `AppearanceSection` 或工具函数将枚举值映射为 `ResourceStr`。
- **SettingRow**：已有的通用设置行组件（`components/SettingRow.ets`），左侧标签 + 可选右侧值文字 + 箭头。
- **AppearanceManager**：已有的外观管理工具类，负责主题模式的持久化和应用（`utils/AppearanceManager.ets`）。
- **My_Page**：「我的」页面（`pages/My.ets`），包含账号管理、外观设置、通知设置、关于等区域。
- **NavPathStack**：HarmonyOS Navigation 路由栈，用于页面跳转和返回。

## Requirements

### Requirement 1：My 页外观设置区域改为 SettingRow

**User Story:** As a 用户, I want 在 My 页看到外观设置以 SettingRow 形式展示当前主题, so that 在任何屏幕宽度下都能清晰看到当前选中的主题模式，不会出现按钮截断问题。

#### Acceptance Criteria

1. THE **AppearanceSection** SHALL 以 `SettingRow` 组件渲染外观设置行，左侧显示「主题」标签（`$r('app.string.my_theme_label')`），右侧显示当前 ThemeMode 对应的 ThemeModeLabel。
2. WHEN **ThemeMode** 为 `COLOR_MODE_LIGHT`，THE **AppearanceSection** SHALL 在 SettingRow 右侧显示「浅色」（`$r('app.string.my_theme_light')`）。
3. WHEN **ThemeMode** 为 `COLOR_MODE_DARK`，THE **AppearanceSection** SHALL 在 SettingRow 右侧显示「深色」（`$r('app.string.my_theme_dark')`）。
4. WHEN **ThemeMode** 为 `COLOR_MODE_NOT_SET`，THE **AppearanceSection** SHALL 在 SettingRow 右侧显示「跟随系统」（`$r('app.string.my_theme_system')`）。
5. THE **AppearanceSection** SHALL 在 SettingRow 右侧显示箭头（`›`），表示可点击跳转。
6. WHEN 用户点击 SettingRow，THE **AppearanceSection** SHALL 通过 `onTap` 回调通知 **My_Page** 执行跳转。
7. THE **AppearanceSection** SHALL 在宽度不足 360vp 的容器内正常渲染，不出现文字截断或换行。

### Requirement 2：My 页跳转外观设置二级页

**User Story:** As a 用户, I want 点击外观设置行后跳转到独立的二级页, so that 有足够空间展示所有主题选项及其说明。

#### Acceptance Criteria

1. WHEN 用户点击外观设置 SettingRow，THE **My_Page** SHALL 调用 `NavPathStack.pushPathByName`（普通模式）或 `NavPathStack.replacePath`（分栏模式）跳转到 `AppRoutes.APPEARANCE_SETTINGS` 路由，并将当前 `themeMode` 作为路由参数传入。
2. THE **My_Page** SHALL 在分栏模式（`isSplit === true`）下使用 `replacePath` 跳转，在普通模式下使用 `pushPathByName` 跳转，与现有通知设置跳转逻辑保持一致。
3. THE **AppRoutes** SHALL 包含常量 `APPEARANCE_SETTINGS`，值为 `'AppearanceSettings'`。
4. THE **custom_router_map** SHALL 包含名称为 `'AppearanceSettings'` 的路由条目，指向 `AppearanceSettingsPage.ets` 及其 Builder 函数。

### Requirement 3：外观设置二级页展示主题选项列表

**User Story:** As a 用户, I want 在外观设置二级页看到所有主题模式选项及其说明, so that 能够了解每种模式的效果并做出选择。

#### Acceptance Criteria

1. THE **AppearanceSettingsPage** SHALL 以 `NavDestination` 为根容器，标题显示「外观设置」（`$r('app.string.appearance_settings_title')`）。
2. THE **AppearanceSettingsPage** SHALL 展示三个主题模式选项：浅色、深色、跟随系统，顺序固定。
3. WHEN 渲染浅色选项，THE **AppearanceSettingsPage** SHALL 显示图标（`$r('app.media.ic_theme_light')` 或等效 emoji 占位）、标题「浅色」（`$r('app.string.my_theme_light')`）、描述「始终使用浅色界面」（`$r('app.string.appearance_theme_light_desc')`）。
4. WHEN 渲染深色选项，THE **AppearanceSettingsPage** SHALL 显示图标、标题「深色」（`$r('app.string.my_theme_dark')`）、描述「始终使用深色界面」（`$r('app.string.appearance_theme_dark_desc')`）。
5. WHEN 渲染跟随系统选项，THE **AppearanceSettingsPage** SHALL 显示图标、标题「跟随系统」（`$r('app.string.my_theme_system')`）、描述「跟随系统深色/浅色模式自动切换」（`$r('app.string.appearance_theme_system_desc')`）。
6. THE **AppearanceSettingsPage** SHALL 在选项列表下方显示说明文字：「选择"跟随系统"时，应用会根据系统设置自动切换深色/浅色模式。」（`$r('app.string.appearance_settings_hint')`）。

### Requirement 4：外观设置二级页选中状态

**User Story:** As a 用户, I want 在外观设置二级页清晰看到当前选中的主题模式, so that 知道当前生效的是哪种模式。

#### Acceptance Criteria

1. WHEN **AppearanceSettingsPage** 渲染时，THE **AppearanceSettingsPage** SHALL 将与当前 ThemeMode 匹配的选项行显示选中勾（实心圆 + 白色 ✓），其余选项行显示空心圆。
2. THE **AppearanceSettingsPage** SHALL 在任意时刻有且仅有一个选项处于选中状态。
3. WHEN **ThemeMode** 为 `COLOR_MODE_NOT_SET`，THE **AppearanceSettingsPage** SHALL 将「跟随系统」选项标记为选中。
4. WHEN **ThemeMode** 为 `COLOR_MODE_LIGHT`，THE **AppearanceSettingsPage** SHALL 将「浅色」选项标记为选中。
5. WHEN **ThemeMode** 为 `COLOR_MODE_DARK`，THE **AppearanceSettingsPage** SHALL 将「深色」选项标记为选中。

### Requirement 5：外观设置二级页主题切换

**User Story:** As a 用户, I want 在外观设置二级页点击选项后立即切换主题并返回, so that 能快速完成主题设置并看到效果。

#### Acceptance Criteria

1. WHEN 用户点击某个主题选项，THE **AppearanceSettingsPage** SHALL 调用 `AppearanceManager.applyColorMode` 应用所选 ThemeMode（立即生效并持久化）。
2. WHEN 用户点击某个主题选项，THE **AppearanceSettingsPage** SHALL 通过 `onThemeChange` 回调将新的 ThemeMode 传回 **My_Page**，使 My 页的 SettingRow 右侧值同步更新。
3. WHEN 用户点击某个主题选项，THE **AppearanceSettingsPage** SHALL 调用 `NavPathStack.pop()` 返回 My 页。
4. IF `AppearanceManager.applyColorMode` 调用失败，THEN THE **AppearanceSettingsPage** SHALL 记录错误日志（`Logger.error`），不崩溃，不阻止返回。

### Requirement 6：字符串资源

**User Story:** As a 开发者, I want 所有新增文字均通过字符串资源引用, so that 支持多语言且符合项目编码规范。

#### Acceptance Criteria

1. THE **string.json**（简体中文）SHALL 包含以下新增 key：`appearance_settings_title`（外观设置）、`appearance_theme_light_desc`（始终使用浅色界面）、`appearance_theme_dark_desc`（始终使用深色界面）、`appearance_theme_system_desc`（跟随系统深色/浅色模式自动切换）、`appearance_settings_hint`（选择"跟随系统"时，应用会根据系统设置自动切换深色/浅色模式。）。
2. THE **string.json**（繁体中文 `zh_HK`）SHALL 同步添加上述所有 key 的繁体中文译文。
3. THE **string.json**（英文 `en`）SHALL 同步添加上述所有 key 的英文译文。
4. THE **AppearanceSettingsPage** SHALL 使用 `$r('app.string.xxx')` 引用所有文字，禁止硬编码字符串字面量。

### Requirement 7：组件 @Preview 覆盖

**User Story:** As a 开发者, I want 新增组件有完整的 @Preview 覆盖, so that 能在 DevEco Studio 预览器中直接验证各状态的视觉效果。

#### Acceptance Criteria

1. THE **AppearanceSection**（重写后）SHALL 在文件末尾包含 `@Preview` struct `AppearanceSectionPreview`，覆盖三种 ThemeMode 状态（浅色选中、深色选中、跟随系统选中）。
2. THE **AppearanceSettingsPage** SHALL 在文件末尾包含 `@Preview` struct `AppearanceSettingsPagePreview`，覆盖默认状态（跟随系统选中）。
3. 所有 `@Preview` struct 背景色统一使用 `'#1a1a2e'`，不得硬编码其他颜色值。

### Requirement 8：ViewModel 单元测试

**User Story:** As a 开发者, I want AppearanceSettingsViewModel 的纯逻辑有单元测试覆盖, so that 能在不依赖设备的情况下验证状态初始化和标签映射逻辑。

#### Acceptance Criteria

1. THE **AppearanceSettingsViewModel.test.ets**（`entry/src/test/`）SHALL 验证初始 `themeMode` 为路由参数传入的值。
2. THE **AppearanceSettingsViewModel.test.ets** SHALL 验证 `themeModeLabel` 在三种 ThemeMode 下分别返回正确的 ResourceStr（浅色/深色/跟随系统）。
3. THE **AppearanceSettingsViewModel.test.ets** SHALL 在 `entry/src/test/List.test.ets` 中注册。

### Requirement 9：页面 UI 测试

**User Story:** As a 开发者, I want 外观设置页面的关键交互流程有设备端 UI 测试覆盖, so that 能在真机/模拟器上验证跳转、选中状态和主题切换行为。

#### Acceptance Criteria

1. THE **AppearanceSettingsPageTest.test.ets**（`entry/src/ohosTest/ets/test/`）SHALL 验证页面加载后三个选项均可见。
2. THE **AppearanceSettingsPageTest.test.ets** SHALL 验证当前选中的 ThemeMode 对应选项显示选中勾，其余选项显示空心圆。
3. THE **AppearanceSettingsPageTest.test.ets** SHALL 验证点击某个选项后页面返回 My 页。
4. THE **AppearanceSettingsPageTest.test.ets** SHALL 在 `entry/src/ohosTest/ets/test/List.test.ets` 中注册。

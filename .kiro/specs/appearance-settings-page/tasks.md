# Implementation Plan: Appearance Settings Page

## Overview

将 My 页「外观设置」区域从内联 ThemeChip 按钮组改为 SettingRow 样式，新增独立二级页 AppearanceSettingsPage。实现顺序：字符串资源 → 路由基础设施 → ViewModel → AppearanceSettingsPage → AppearanceSection 重写 → My.ets 修改 → 测试 → ThemeChip 废弃。

## Tasks

- [x] 1. 新增字符串资源（三语言同步）
  - 在 `entry/src/main/resources/base/element/string.json` 新增 5 个 key：`appearance_settings_title`、`appearance_theme_light_desc`、`appearance_theme_dark_desc`、`appearance_theme_system_desc`、`appearance_settings_hint`
  - 在 `entry/src/main/resources/zh_HK/element/string.json` 同步添加繁体中文译文
  - 在 `entry/src/main/resources/en/element/string.json` 同步添加英文译文
  - _Requirements: 6.1, 6.2, 6.3_

- [x] 2. 新增路由常量和路由注册
  - [x] 2.1 在 `entry/src/main/ets/constants/AppRoutes.ets` 新增 `APPEARANCE_SETTINGS = 'AppearanceSettings'` 常量
    - _Requirements: 2.3_
  - [x] 2.2 在 `entry/src/main/resources/base/profile/custom_router_map.json` 新增 `AppearanceSettings` 路由条目，指向 `AppearanceSettingsPage.ets` 和 `AppearanceSettingsBuilder`
    - _Requirements: 2.4_

- [x] 3. 新增 AppearanceSettingsViewModel
  - 新建 `entry/src/main/ets/viewmodel/AppearanceSettingsViewModel.ets`
  - 定义 `ThemeModeItem` 数据模型（mode、icon emoji、label、desc）
  - 实现 `@Trace themeMode` 字段，默认值为 `COLOR_MODE_NOT_SET`
  - 实现 `init(mode: number)` 方法，从路由参数初始化 themeMode
  - 实现 `themeModeLabel(mode: number): ResourceStr` 纯函数，映射三种 ThemeMode 到对应 ResourceStr
  - 实现 `themeItems(): ThemeModeItem[]` 方法，返回固定顺序（浅色/深色/跟随系统）的三个选项
  - _Requirements: 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 4. 补充 AppearanceSettingsViewModel 单元测试
  - [ ]\* 4.1 新建 `entry/src/test/AppearanceSettingsViewModel.test.ets`
    - 验证初始 `themeMode` 为 `COLOR_MODE_NOT_SET`
    - 验证 `init(COLOR_MODE_DARK)` 后 `themeMode === COLOR_MODE_DARK`
    - 验证 `themeModeLabel(COLOR_MODE_LIGHT)` 返回 `$r('app.string.my_theme_light')`
    - 验证 `themeModeLabel(COLOR_MODE_DARK)` 返回 `$r('app.string.my_theme_dark')`
    - 验证 `themeModeLabel(COLOR_MODE_NOT_SET)` 返回 `$r('app.string.my_theme_system')`
    - 验证 `themeItems()` 返回长度为 3 的数组
    - 验证 `themeItems()` 顺序依次为 LIGHT / DARK / NOT_SET
    - _Requirements: 8.1, 8.2_
  - [ ]\* 4.2 在 `entry/src/test/List.test.ets` 中注册 `appearanceSettingsViewModelTest`
    - _Requirements: 8.3_

- [x] 5. 新增 AppearanceSettingsPage
  - 新建 `entry/src/main/ets/pages/AppearanceSettingsPage.ets`
  - 定义 `AppearanceSettingsParam` 类（`themeMode: number`、`onThemeChange: (mode: number) => void`）
  - 实现 `NavDestination` 根容器，标题使用 `$r('app.string.appearance_settings_title')`
  - 在 `onReady` 中从 `NavDestinationContext` 获取路由参数，调用 `vm.init(param.themeMode)`
  - 用内联 `@Builder` 实现 `ThemeModeRow`（emoji 图标 + 标题 + 描述 + 选中圆圈）
  - 实现三个选项列表（Column + Divider），选中项显示实心圆+✓，未选中项显示空心圆
  - 在列表下方显示 `$r('app.string.appearance_settings_hint')` 说明文字
  - 点击选项时：调用 `AppearanceManager.applyColorMode`、触发 `onThemeChange` 回调、调用 `NavPathStack.pop()`
  - `applyColorMode` 失败时记录 `Logger.error`，不阻止返回
  - 实现 `AppearanceSettingsBuilder` Router Builder 函数
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 4.1, 4.2, 4.3, 4.4, 4.5, 5.1, 5.2, 5.3, 5.4, 6.4_

- [x] 6. 为 AppearanceSettingsPage 添加 @Preview
  - [x]\* 6.1 在 `AppearanceSettingsPage.ets` 文件末尾添加 `@Preview` struct `AppearanceSettingsPagePreview`
    - 默认状态：`themeMode = COLOR_MODE_NOT_SET`（跟随系统选中）
    - 背景色使用 `'#1a1a2e'`
    - _Requirements: 7.2, 7.3_

- [x] 7. 重写 AppearanceSection 为 SettingRow 样式
  - 修改 `entry/src/main/ets/components/my/AppearanceSection.ets`
  - 移除 `ThemeChip` 依赖和 `onThemeChange` 回调参数
  - 新增 `onTap: () => void` 参数
  - 实现 `themeModeLabel(mode: number): ResourceStr` 纯函数（COLOR_MODE_LIGHT/DARK/NOT_SET 映射）
  - 用 `SettingRow` 组件渲染：左侧 `$r('app.string.my_theme_label')`，右侧显示当前 ThemeModeLabel，带箭头
  - 外层 Column 保持 `colorSurfaceCard` 背景和 `radius12` 圆角
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 6.4_

- [x] 8. 为重写后的 AppearanceSection 更新 @Preview
  - [x]\* 8.1 更新 `AppearanceSection.ets` 文件末尾的 `@Preview` struct `AppearanceSectionPreview`
    - 覆盖三种 ThemeMode 状态（浅色选中、深色选中、跟随系统选中各一行）
    - 背景色使用 `'#1a1a2e'`
    - _Requirements: 7.1, 7.3_

- [x] 9. 修改 My.ets 接入新跳转逻辑
  - 修改 `entry/src/main/ets/pages/My.ets`
  - 导入 `AppearanceSettingsParam`、`AppRoutes.APPEARANCE_SETTINGS`
  - 将 `AppearanceSection` 的 `onThemeChange` 回调替换为 `onTap` 回调
  - 移除 My.ets 中直接调用 `AppearanceManager.applyColorMode` 的逻辑
  - `onTap` 回调中构造 `AppearanceSettingsParam`，设置 `themeMode` 和 `onThemeChange`（更新 `this.themeMode`）
  - 分栏模式（`isSplit === true`）使用 `detailStack.replacePath`，普通模式使用 `detailStack.pushPathByName`
  - 清理不再使用的 import（`AppearanceManager` 等）
  - _Requirements: 2.1, 2.2_

- [x] 10. Checkpoint — 确认基础功能可用
  - 确认所有测试通过，ask the user if questions arise.

- [ ] 11. 补充 AppearanceSettingsPage UI 测试
  - [ ]\* 11.1 新建 `entry/src/ohosTest/ets/test/AppearanceSettingsPageTest.test.ets`
    - 验证页面加载后浅色/深色/跟随系统三个选项均可见
    - 验证 `themeMode=NOT_SET` 时「跟随系统」选项显示选中勾（实心圆）
    - 验证非选中项显示空心圆
    - 验证点击某个选项后页面返回 My 页
    - 验证 `appearance_settings_hint` 说明文字可见
    - _Requirements: 9.1, 9.2, 9.3_
  - [ ]\* 11.2 在 `entry/src/ohosTest/ets/test/List.test.ets` 中注册 `appearanceSettingsPageTest`
    - _Requirements: 9.4_

- [x] 12. 废弃 ThemeChip.ets
  - 在 `entry/src/main/ets/components/my/ThemeChip.ets` 文件头注释中添加 `@deprecated` 标注
  - 说明废弃原因：已被 AppearanceSettingsPage 替代，保留文件以维护 git history
  - _Requirements: （设计文档 ThemeChip 废弃章节）_

- [x] 13. Final Checkpoint — 确认所有测试通过
  - 确认所有测试通过，ask the user if questions arise.

## Notes

- 任务 4、6、8、11 中标 `*` 的子任务为可选测试任务，可跳过以加快 MVP 进度
- 任务顺序严格遵循：字符串资源 → 路由 → ViewModel → 页面 → 组件 → My 页 → 测试 → 废弃
- 设计文档无 Correctness Properties 章节，不需要 Property-Based Test 任务
- AppearanceSettingsPage 不需要单独的 ViewModel 文件拆分，ThemeModeItem 定义在 ViewModel 文件中
- My.ets 修改后需清理不再使用的 `AppearanceManager` import（如 applyColorMode 调用已移至二级页）

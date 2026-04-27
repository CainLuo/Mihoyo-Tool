# Design Document

## Overview

将 My 页「外观设置」区域从内联 ThemeChip 按钮组改为 `SettingRow` 样式，点击跳转独立二级页 `AppearanceSettingsPage`。二级页以列表形式展示三种主题模式（浅色/深色/跟随系统），每项含图标、标题、描述和选中勾，选中后立即应用并返回。

## Architecture

本功能完全在 `entry` 模块内，不涉及 `core` 模块。遵循 MVVM 分层：

```
My.ets (View)
  └── AppearanceSection.ets (Component) — 重写为 SettingRow 样式
  └── 跳转 → AppearanceSettingsPage.ets (View)
                └── AppearanceSettingsViewModel.ets (ViewModel)
                      └── AppearanceManager (工具类，已有)
```

## Component Design

### 1. AppearanceSection（重写）

**文件**：`entry/src/main/ets/components/my/AppearanceSection.ets`

**职责**：展示当前主题模式的 SettingRow，点击触发跳转回调。

**接口变更**：

| 参数        | 类型         | 说明                                                       |
| ----------- | ------------ | ---------------------------------------------------------- |
| `themeMode` | `number`     | 当前 ThemeMode（`ConfigurationConstant.ColorMode` 枚举值） |
| `onTap`     | `() => void` | 点击时触发，由 My.ets 负责跳转                             |

移除原有的 `onThemeChange` 回调（主题切换逻辑移至二级页）。

**ThemeModeLabel 映射**（纯函数，在组件内实现）：

```
COLOR_MODE_LIGHT   → $r('app.string.my_theme_light')
COLOR_MODE_DARK    → $r('app.string.my_theme_dark')
COLOR_MODE_NOT_SET → $r('app.string.my_theme_system')
```

**@Preview 覆盖**：

```
AppearanceSectionPreview — 展示三种 themeMode 状态（浅色/深色/跟随系统各一行）
```

---

### 2. AppearanceSettingsViewModel（新增）

**文件**：`entry/src/main/ets/viewmodel/AppearanceSettingsViewModel.ets`

**职责**：持有当前 themeMode 状态，提供 ThemeModeItem 列表供 View 渲染。

**字段**：

| 字段               | 类型     | 说明                 |
| ------------------ | -------- | -------------------- |
| `@Trace themeMode` | `number` | 当前选中的 ThemeMode |

**方法**：

| 方法                                        | 说明                            |
| ------------------------------------------- | ------------------------------- |
| `init(mode: number)`                        | 从路由参数初始化 themeMode      |
| `themeModeLabel(mode: number): ResourceStr` | 返回 ThemeMode 对应的本地化标签 |
| `themeItems(): ThemeModeItem[]`             | 返回三个选项的数据列表          |

**ThemeModeItem 数据模型**（定义在同文件）：

```typescript
class ThemeModeItem {
  mode: number = 0;
  icon: ResourceStr = ""; // emoji 字符串（☀️ / 🌙 / ⚙️）
  label: ResourceStr = ""; // $r('app.string.my_theme_xxx')
  desc: ResourceStr = ""; // $r('app.string.appearance_theme_xxx_desc')
}
```

---

### 3. AppearanceSettingsPage（新增）

**文件**：`entry/src/main/ets/pages/AppearanceSettingsPage.ets`

**职责**：外观设置二级页，展示主题选项列表，处理选中和切换逻辑。

**结构**：

```
NavDestination
  └── Scroll
        └── Column
              ├── Column（选项卡片）
              │     ├── ThemeModeRow（浅色）
              │     ├── Divider
              │     ├── ThemeModeRow（深色）
              │     ├── Divider
              │     └── ThemeModeRow（跟随系统）
              └── Text（说明文字）
```

**ThemeModeRow 内联 @Builder**（行内简单结构，不超过 15 行，不单独拆文件）：

```
Row
  ├── Text（emoji 图标，20sp）
  ├── Column（flex:1）
  │     ├── Text（标题，body16）
  │     └── Text（描述，body13，colorTextSecondary）
  └── 选中圆圈（实心圆+✓ 或 空心圆）
```

**路由参数**：接收 `number` 类型的 themeMode，通过 `onReady` 的 `NavDestinationContext` 获取。

**回调机制**：通过路由参数传入 `onThemeChange: (mode: number) => void` 回调，切换后调用以同步 My 页的显示值。

> 注意：HarmonyOS 路由参数为 `Object` 类型，需要定义专用参数类 `AppearanceSettingsParam`。

**AppearanceSettingsParam**（定义在页面文件）：

```typescript
export class AppearanceSettingsParam {
  themeMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
  onThemeChange: (mode: number) => void = (_m: number) => {};
}
```

**@Preview 覆盖**：

```
AppearanceSettingsPagePreview — 默认状态（跟随系统选中）
```

---

### 4. My.ets（修改）

**变更点**：

1. 将 `AppearanceSection` 的调用从传 `onThemeChange` 改为传 `onTap`
2. `onTap` 回调中构造 `AppearanceSettingsParam` 并跳转
3. `AppearanceSettingsParam.onThemeChange` 回调中更新 `this.themeMode`

**跳转逻辑**（与通知设置保持一致）：

```typescript
onTap: () => {
  const param = new AppearanceSettingsParam();
  param.themeMode = this.themeMode;
  param.onThemeChange = (mode: number) => {
    this.themeMode = mode;
  };
  if (this.isSplit) {
    this.detailStack.replacePath({
      name: AppRoutes.APPEARANCE_SETTINGS,
      param: param,
    });
  } else {
    this.detailStack.pushPathByName(AppRoutes.APPEARANCE_SETTINGS, param);
  }
};
```

---

### 5. ThemeChip.ets（废弃）

`ThemeChip.ets` 不再被任何文件引用，保留文件但在文件头注释标注 `@deprecated`，不删除（避免影响 git history）。

---

## Routing

### AppRoutes.ets

新增常量：

```typescript
/** 外观设置页 */
static readonly APPEARANCE_SETTINGS = 'AppearanceSettings'
```

### custom_router_map.json

新增条目：

```json
{
  "name": "AppearanceSettings",
  "pageSourceFile": "src/main/ets/pages/AppearanceSettingsPage.ets",
  "buildFunction": "AppearanceSettingsBuilder"
}
```

---

## String Resources

### 新增 key（三语言同步）

| key                            | 简体中文                                                    | 繁体中文                                                          | 英文                                                                                                                   |
| ------------------------------ | ----------------------------------------------------------- | ----------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `appearance_settings_title`    | 外观设置                                                    | 外觀設定                                                          | Appearance                                                                                                             |
| `appearance_theme_light_desc`  | 始终使用浅色界面                                            | 始終使用淺色介面                                                  | Always use light mode                                                                                                  |
| `appearance_theme_dark_desc`   | 始终使用深色界面                                            | 始終使用深色介面                                                  | Always use dark mode                                                                                                   |
| `appearance_theme_system_desc` | 跟随系统深色/浅色模式自动切换                               | 跟隨系統深色/淺色模式自動切換                                     | Follow system dark/light mode                                                                                          |
| `appearance_settings_hint`     | 选择"跟随系统"时，应用会根据系统设置自动切换深色/浅色模式。 | 選擇「跟隨系統」時，應用程式會根據系統設定自動切換深色/淺色模式。 | When "Follow System" is selected, the app automatically switches between dark and light mode based on system settings. |

**文件路径**：

- `entry/src/main/resources/base/element/string.json`（简体中文，默认）
- `entry/src/main/resources/zh_HK/element/string.json`（繁体中文）
- `entry/src/main/resources/en/element/string.json`（英文）

---

## Testing Strategy

### 一、单元测试（`entry/src/test/`）

**文件**：`entry/src/test/AppearanceSettingsViewModel.test.ets`

| 测试用例                             | 前置条件 | 操作                                    | 预期结果                                |
| ------------------------------------ | -------- | --------------------------------------- | --------------------------------------- |
| 初始 themeMode 为 COLOR_MODE_NOT_SET | 新建实例 | `new AppearanceSettingsViewModel()`     | `themeMode === COLOR_MODE_NOT_SET`      |
| init 设置 themeMode                  | 新建实例 | `vm.init(COLOR_MODE_DARK)`              | `themeMode === COLOR_MODE_DARK`         |
| themeModeLabel 浅色                  | —        | `vm.themeModeLabel(COLOR_MODE_LIGHT)`   | 返回 `$r('app.string.my_theme_light')`  |
| themeModeLabel 深色                  | —        | `vm.themeModeLabel(COLOR_MODE_DARK)`    | 返回 `$r('app.string.my_theme_dark')`   |
| themeModeLabel 跟随系统              | —        | `vm.themeModeLabel(COLOR_MODE_NOT_SET)` | 返回 `$r('app.string.my_theme_system')` |
| themeItems 返回 3 个选项             | —        | `vm.themeItems()`                       | `length === 3`                          |
| themeItems 顺序固定                  | —        | `vm.themeItems()`                       | 依次为 LIGHT / DARK / NOT_SET           |

**注册**：在 `entry/src/test/List.test.ets` 中添加 `import appearanceSettingsViewModelTest` 并调用。

---

### 二、@Preview / Snapshot 测试（组件文件末尾）

**AppearanceSection**（重写后）：

| Preview 名称               | 数据状态                              | 说明                           |
| -------------------------- | ------------------------------------- | ------------------------------ |
| `AppearanceSectionPreview` | themeMode=LIGHT / DARK / NOT_SET 三行 | 验证三种状态下右侧标签显示正确 |

**AppearanceSettingsPage**：

| Preview 名称                    | 数据状态                          | 说明                   |
| ------------------------------- | --------------------------------- | ---------------------- |
| `AppearanceSettingsPagePreview` | themeMode=NOT_SET（跟随系统选中） | 验证列表布局和选中状态 |

---

### 三、设备端 UI 测试（`entry/src/ohosTest/ets/test/`）

**文件**：`entry/src/ohosTest/ets/test/AppearanceSettingsPageTest.test.ets`

| 测试用例             | 前置条件          | 操作             | 预期结果                                    |
| -------------------- | ----------------- | ---------------- | ------------------------------------------- |
| 三个选项均可见       | 进入外观设置页    | 查看列表         | 浅色/深色/跟随系统文字均可见                |
| 当前选中项显示选中勾 | themeMode=NOT_SET | 查看跟随系统行   | 选中圆圈可见（实心）                        |
| 非选中项显示空心圆   | themeMode=NOT_SET | 查看浅色/深色行  | 空心圆可见，无 ✓                            |
| 点击选项后返回 My 页 | 进入外观设置页    | 点击「深色」选项 | 页面返回，My 页 SettingRow 右侧显示「深色」 |
| 说明文字可见         | 进入外观设置页    | 查看列表底部     | `appearance_settings_hint` 文字可见         |

**注册**：在 `entry/src/ohosTest/ets/test/List.test.ets` 中添加 `import appearanceSettingsPageTest` 并调用。

---

## File Change Summary

| 文件                                                              | 变更类型 | 说明                                          |
| ----------------------------------------------------------------- | -------- | --------------------------------------------- |
| `entry/src/main/ets/components/my/AppearanceSection.ets`          | 修改     | 重写为 SettingRow 样式，移除 ThemeChip 依赖   |
| `entry/src/main/ets/components/my/ThemeChip.ets`                  | 废弃     | 添加 @deprecated 注释，不删除                 |
| `entry/src/main/ets/pages/My.ets`                                 | 修改     | 更新 AppearanceSection 调用方式，添加跳转逻辑 |
| `entry/src/main/ets/pages/AppearanceSettingsPage.ets`             | 新增     | 外观设置二级页                                |
| `entry/src/main/ets/viewmodel/AppearanceSettingsViewModel.ets`    | 新增     | 外观设置 ViewModel                            |
| `entry/src/main/ets/constants/AppRoutes.ets`                      | 修改     | 新增 APPEARANCE_SETTINGS 常量                 |
| `entry/src/main/resources/base/profile/custom_router_map.json`    | 修改     | 注册 AppearanceSettings 路由                  |
| `entry/src/main/resources/base/element/string.json`               | 修改     | 新增 5 个字符串 key                           |
| `entry/src/main/resources/zh_HK/element/string.json`              | 修改     | 同步繁体中文                                  |
| `entry/src/main/resources/en/element/string.json`                 | 修改     | 同步英文                                      |
| `entry/src/test/AppearanceSettingsViewModel.test.ets`             | 新增     | ViewModel 单元测试                            |
| `entry/src/test/List.test.ets`                                    | 修改     | 注册新测试套件                                |
| `entry/src/ohosTest/ets/test/AppearanceSettingsPageTest.test.ets` | 新增     | 页面 UI 测试                                  |
| `entry/src/ohosTest/ets/test/List.test.ets`                       | 修改     | 注册新测试套件                                |

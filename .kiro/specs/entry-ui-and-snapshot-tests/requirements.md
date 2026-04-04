# Requirements Document

## Introduction

本 Spec 覆盖 `entry` 模块中尚未被 `unit-and-viewmodel-tests` Spec 覆盖的测试范围，分为两大部分：

1. **页面级 UI 测试**（`entry/src/ohosTest/`）：使用 Hypium + `@ohos/uitest` 在模拟器上测试页面交互，包括 Main、Home、Characters、My、Login、AccountDetail、GenshinDailyDetail、GenshinCharacterDetail 共 8 个页面。
2. **组件截图测试**（`entry/src/ohosTest/`）：使用 `componentSnapshot` API 对关键页面的各状态进行截图，首次运行生成基准图，后续运行对比像素差异。

## Glossary

- **Driver**：`@ohos/uitest` 提供的设备驱动实例，通过 `Driver.create()` 获取
- **Component**：`@ohos/uitest` 提供的 UI 组件句柄，通过 `Driver.findComponent(ON.xxx)` 获取
- **ON**：`@ohos/uitest` 提供的组件查找条件构造器
- **componentSnapshot**：`@ohos.arkui.componentSnapshot` 提供的组件截图 API，通过组件 `id` 截取指定组件的 `PixelMap`
- **PixelMap**：HarmonyOS 图像数据类型，表示一张位图
- **Baseline**：截图测试的基准图，首次运行时生成，存放于 `entry/src/ohosTest/snapshots/baseline/`
- **SnapshotHelper**：本 Spec 新建的截图工具类，封装截图、保存、对比逻辑
- **Mock 环境**：通过 `product=mock` 构建，使用本地 rawfile 数据，确保测试数据可预测
- **ViewState**：页面加载状态枚举（LOADING / EMPTY / DATA / ERROR）
- **ohosTest**：HarmonyOS 设备端测试，需要在模拟器（127.0.0.1:5555）上运行

## Requirements

### Requirement 1：Main 页 UI 测试

**User Story:** As a 测试工程师, I want 验证 Main 页的 Tab 切换和导航栏显示, so that 确保主框架在不同设备形态下正确渲染。

#### Acceptance Criteria

1. WHEN 应用启动, THE Driver SHALL 验证 Home Tab 默认高亮显示
2. WHEN 点击 Characters Tab, THE Driver SHALL 验证 Characters 内容区可见
3. WHEN 点击 My Tab, THE Driver SHALL 验证 My 内容区可见
4. WHEN 在 Home Tab 进入详情页后切换到 My Tab 再切回, THE Driver SHALL 验证 Home Tab 导航栈未被清空
5. WHILE 运行在 Phone 设备, THE Driver SHALL 验证底部 Tab 栏可见
6. WHILE 运行在宽屏设备, THE Driver SHALL 验证侧边导航可见
7. WHEN 在 Home Tab 且有账号数据时, THE Driver SHALL 验证右上角刷新按钮可见
8. WHEN 切换到非 Home Tab, THE Driver SHALL 验证刷新按钮不可见
9. WHEN 快速连续切换 Tab, THE Driver SHALL 验证应用不崩溃且最终停在最后点击的 Tab
10. WHEN 应用冷启动且无账号数据, THE Driver SHALL 验证 Home/Characters/My 均显示空态

---

### Requirement 2：Home 页 UI 测试

**User Story:** As a 测试工程师, I want 验证 Home 页的空态、骨架屏、账号卡片和刷新功能, so that 确保首页在各种数据状态下正确渲染。

#### Acceptance Criteria

1. WHEN Mock 环境无账号数据时进入 Home Tab, THE Driver SHALL 验证 `home_placeholder_title` 文字可见
2. WHEN Mock 环境无账号数据时进入 Home Tab, THE Driver SHALL 验证 `home_placeholder_button` 按钮可见
3. WHEN Mock 环境有账号数据时立即截图, THE Driver SHALL 验证 HomeSkeletonView 骨架块可见
4. WHEN Mock 环境有账号数据且等待 1 秒后, THE Driver SHALL 验证 UserGameSection 可见
5. WHEN 有账号数据且加载完成时, THE Driver SHALL 验证刷新按钮可见
6. WHEN 点击刷新按钮, THE Driver SHALL 验证按钮进入禁用状态（isRefreshing=true）
7. WHEN 有原神账号数据且点击原神卡片, THE Driver SHALL 验证跳转到 GenshinDailyDetail 页
8. WHEN Mock 文件 retcode=-100 时触发同步, THE Driver SHALL 验证弹出错误 Dialog
9. IF 账号存在但 game_role_table 为空, THEN THE Driver SHALL 验证显示账号标题行且无游戏卡片且不崩溃
10. WHEN 30 分钟内重复刷新, THE Driver SHALL 验证弹出冷却 Dialog

---

### Requirement 3：Characters 页 UI 测试

**User Story:** As a 测试工程师, I want 验证 Characters 页的空态、骨架屏、角色网格和 Tab 切换, so that 确保角色列表页在各种数据状态下正确渲染。

#### Acceptance Criteria

1. WHEN Mock 环境无账号数据时进入 Characters Tab, THE Driver SHALL 验证 HomePlaceholderView 可见
2. WHEN Mock 环境有账号但无角色数据时进入 Characters Tab, THE Driver SHALL 验证 CharactersSkeleton 可见
3. WHEN Mock 环境有原神角色数据且等待 1 秒后, THE Driver SHALL 验证 CharacterCard 可见
4. WHEN Mock 环境有原神+星铁数据时, THE Driver SHALL 验证 GameTabBar 可见
5. WHEN 点击星铁 Tab, THE Driver SHALL 验证显示星铁角色数据
6. WHEN 点击角色卡片, THE Driver SHALL 验证跳转到 GenshinCharacterDetail 页
7. WHEN 30 分钟内已同步时点击刷新, THE Driver SHALL 验证弹出冷却 Dialog
8. WHEN 冷却 Dialog 弹出后点击立即同步按钮, THE Driver SHALL 验证触发 forceRefresh
9. WHEN 快速连续切换账号, THE Driver SHALL 验证不崩溃且最终显示最后选中账号的数据
10. IF 后台同步抛出错误, THEN THE Driver SHALL 验证 viewState 变为 EMPTY 且不崩溃

---

### Requirement 4：My 页 UI 测试

**User Story:** As a 测试工程师, I want 验证 My 页的账号列表、添加账号按钮和外观设置, so that 确保我的页面在各种账号状态下正确渲染。

#### Acceptance Criteria

1. WHEN Mock 环境无账号数据时进入 My Tab, THE Driver SHALL 验证 `my_account_empty` 文字可见
2. WHEN Mock 环境有账号数据时进入 My Tab, THE Driver SHALL 验证账号行可见
3. WHEN Mock 账号有昵称时, THE Driver SHALL 验证昵称文字可见
4. WHEN 点击账号行, THE Driver SHALL 验证跳转到 AccountDetail 页
5. THE Driver SHALL 验证 `my_account_add` 按钮可见
6. WHEN 点击添加账号按钮, THE Driver SHALL 验证跳转到 Login 页
7. THE Driver SHALL 验证 AppearanceSection 可见
8. THE Driver SHALL 验证 AboutSection 可见
9. WHEN 点击深色模式按钮, THE Driver SHALL 验证深色按钮高亮且主题切换
10. WHEN 只有 1 个账号且删除并确认后, THE Driver SHALL 验证账号列表变为空态显示 `my_account_empty`

---

### Requirement 5：Login 页 UI 测试

**User Story:** As a 测试工程师, I want 验证 Login 页的 Tab 切换、Cookie 输入和二维码状态, so that 确保登录页各登录方式的交互流程正确。

#### Acceptance Criteria

1. WHEN 进入 Login 页, THE Driver SHALL 验证手机号 Tab 默认高亮
2. WHEN 点击二维码 Tab, THE Driver SHALL 验证二维码内容区可见
3. WHEN 点击 Cookie Tab, THE Driver SHALL 验证 Cookie 输入框可见
4. WHEN Cookie Tab 激活且输入 'account_id=1', THE Driver SHALL 验证输入框内容更新
5. WHEN Cookie Tab 激活且输入框为空, THE Driver SHALL 验证登录按钮不可点击
6. WHEN Cookie Tab 激活且输入框有内容, THE Driver SHALL 验证登录按钮可点击
7. WHEN 切换到二维码 Tab 立即截图, THE Driver SHALL 验证 LoadingProgress 可见
8. WHEN 切换到二维码 Tab 等待 1 秒后, THE Driver SHALL 验证 QRCode 组件可见
9. WHEN Cookie 登录成功后, THE Driver SHALL 验证跳转到 AccountDetail 页
10. WHEN 快速连续点击登录按钮, THE Driver SHALL 验证只触发一次登录请求（isLoading 防重）
11. IF Cookie 输入框只有空格, THEN THE Driver SHALL 验证登录按钮禁用（trim 后为空）

---

### Requirement 6：AccountDetail 页 UI 测试

**User Story:** As a 测试工程师, I want 验证 AccountDetail 页的账号信息展示和删除功能, so that 确保账号详情页正确渲染并支持删除操作。

#### Acceptance Criteria

1. WHEN 传入有昵称的账号进入 AccountDetail 页, THE Driver SHALL 验证昵称文字可见
2. WHEN 传入无昵称的账号进入 AccountDetail 页, THE Driver SHALL 验证 username 文字可见
3. WHEN 账号有游戏角色时, THE Driver SHALL 验证 AccountRolesSection 可见
4. WHEN 账号无游戏角色时, THE Driver SHALL 验证 `my_account_empty` 文字可见
5. THE Driver SHALL 验证 `account_detail_delete` 按钮可见
6. WHEN 点击删除按钮, THE Driver SHALL 验证确认 Dialog 弹出
7. WHEN 确认 Dialog 弹出后点击确认, THE Driver SHALL 验证返回 My 页且账号消失
8. IF deleteAccount 抛出错误, THEN THE Driver SHALL 验证 errorMsg 更新且不跳转且不崩溃
9. WHEN 快速连续点击删除按钮, THE Driver SHALL 验证只弹出一次确认 Dialog

---

### Requirement 7：GenshinDailyDetail 页 UI 测试

**User Story:** As a 测试工程师, I want 验证 GenshinDailyDetail 页的加载状态和便笺数据展示, so that 确保原神便笺详情页在各种数据状态下正确渲染。

#### Acceptance Criteria

1. WHEN 进入页面立即截图, THE Driver SHALL 验证 LoadingProgress 可见
2. WHEN DB 无对应数据且等待加载完成, THE Driver SHALL 验证 `home_no_data_hint` 文字可见
3. WHEN Mock 环境有原神便笺数据且等待加载完成, THE Driver SHALL 验证 DailyNoteGenshin 可见
4. WHEN 有便笺数据时查看树脂行, THE Driver SHALL 验证树脂数值文字可见
5. WHEN 有派遣数据时查看派遣区域, THE Driver SHALL 验证 ExpeditionItem 可见
6. WHEN 有便笺数据时查看页面顶部, THE Driver SHALL 验证 `genshin_daily_data_delay_hint` 文字可见
7. IF DB 中 rawJson 为空字符串, THEN THE Driver SHALL 验证 Parser 返回默认值显示全 0 数据且不崩溃
8. WHEN 快速进入退出页面 5 次, THE Driver SHALL 验证不内存泄漏且不崩溃

---

### Requirement 8：GenshinCharacterDetail 页 UI 测试

**User Story:** As a 测试工程师, I want 验证 GenshinCharacterDetail 页的加载状态和角色详情展示, so that 确保原神角色详情页在各种数据状态和设备形态下正确渲染。

#### Acceptance Criteria

1. WHEN 进入页面立即截图, THE Driver SHALL 验证 LoadingProgress 可见
2. WHEN DB 无对应数据且等待加载完成, THE Driver SHALL 验证 `char_detail_no_data` 文字可见
3. WHEN 有角色详情数据且在 Phone 竖屏时等待加载完成, THE Driver SHALL 验证 CharDetailPortraitLayout 可见
4. WHEN 有角色详情数据且在宽屏时等待加载完成, THE Driver SHALL 验证 CharDetailWideLayout 可见
5. WHEN 有角色详情数据时查看立绘区, THE Driver SHALL 验证角色名文字可见
6. WHEN 有角色详情数据时查看属性区, THE Driver SHALL 验证武器名文字可见
7. WHEN 有角色详情数据时查看圣遗物区, THE Driver SHALL 验证 CharDetailRelicsPanel 可见
8. IF DB 中 rawJson 为空字符串, THEN THE Driver SHALL 验证显示 CharDetailEmptyView 且不崩溃
9. WHEN 快速进入退出页面 5 次, THE Driver SHALL 验证不内存泄漏且不崩溃

---

### Requirement 9：截图测试基础设施（SnapshotHelper）

**User Story:** As a 测试工程师, I want 一个封装好的截图工具类, so that 各截图测试文件可以复用截图、保存、对比逻辑。

#### Acceptance Criteria

1. THE SnapshotHelper SHALL 通过 `componentSnapshot.get(componentId)` 截取指定组件的 PixelMap
2. THE SnapshotHelper SHALL 将 PixelMap 保存为 PNG 文件到指定路径
3. WHEN 基准图不存在时, THE SnapshotHelper SHALL 将当前截图保存为基准图并返回通过
4. WHEN 基准图存在时, THE SnapshotHelper SHALL 对比当前截图与基准图的像素差异
5. IF 像素差异超过 1%（抗锯齿/字体渲染容忍度）, THEN THE SnapshotHelper SHALL 返回失败并输出差异百分比
6. THE SnapshotHelper SHALL 支持通过 `Driver.delayMs(500)` 等待渲染后再截图
7. THE SnapshotHelper SHALL 将基准图存放在 `entry/src/ohosTest/snapshots/baseline/` 目录

---

### Requirement 10：Home 页截图测试

**User Story:** As a 测试工程师, I want 对 Home 页各状态进行截图回归测试, so that 确保 UI 视觉不发生意外变化。

#### Acceptance Criteria

1. WHEN Mock 环境无账号数据时, THE SnapshotHelper SHALL 对 Home 页空态截图并与基准图对比
2. WHEN Mock 环境有账号数据且处于加载中时, THE SnapshotHelper SHALL 对骨架屏状态截图并与基准图对比
3. WHEN Mock 环境有账号数据且加载完成时, THE SnapshotHelper SHALL 对有数据状态截图并与基准图对比
4. IF 像素差异超过 1%, THEN THE SnapshotHelper SHALL 测试失败并输出差异信息

---

### Requirement 11：Characters 页截图测试

**User Story:** As a 测试工程师, I want 对 Characters 页各状态进行截图回归测试, so that 确保角色列表页 UI 视觉不发生意外变化。

#### Acceptance Criteria

1. WHEN Mock 环境无账号数据时, THE SnapshotHelper SHALL 对 Characters 页空态截图并与基准图对比
2. WHEN Mock 环境有账号但无角色数据时, THE SnapshotHelper SHALL 对骨架屏状态截图并与基准图对比
3. WHEN Mock 环境有原神角色数据且加载完成时, THE SnapshotHelper SHALL 对有数据状态截图并与基准图对比

---

### Requirement 12：Login 页截图测试

**User Story:** As a 测试工程师, I want 对 Login 页各 Tab 状态进行截图回归测试, so that 确保登录页 UI 视觉不发生意外变化。

#### Acceptance Criteria

1. WHEN 进入 Login 页默认手机号 Tab 时, THE SnapshotHelper SHALL 截图并与基准图对比
2. WHEN 切换到二维码 Tab 时, THE SnapshotHelper SHALL 截图并与基准图对比
3. WHEN 切换到 Cookie Tab 时, THE SnapshotHelper SHALL 截图并与基准图对比

---

### Requirement 13：GenshinCharacterDetail 页截图测试

**User Story:** As a 测试工程师, I want 对 GenshinCharacterDetail 页进行截图回归测试, so that 确保角色详情页 UI 视觉不发生意外变化。

#### Acceptance Criteria

1. WHEN 有角色详情数据且加载完成时, THE SnapshotHelper SHALL 对 Phone 竖屏布局截图并与基准图对比
2. WHEN 有角色详情数据且在宽屏时, THE SnapshotHelper SHALL 对宽屏布局截图并与基准图对比
3. WHEN DB 无对应数据时, THE SnapshotHelper SHALL 对空态截图并与基准图对比

---

### Requirement 14：测试文件注册

**User Story:** As a 测试工程师, I want 所有测试套件统一注册到 List.test.ets, so that 可以通过单一入口运行所有测试。

#### Acceptance Criteria

1. THE `entry/src/ohosTest/ets/test/List.test.ets` SHALL import 并注册所有 8 个页面 UI 测试套件
2. THE `entry/src/ohosTest/ets/test/List.test.ets` SHALL import 并注册所有 4 个截图测试套件
3. THE List.test.ets SHALL 在注册截图测试前先注册 UI 测试，保持执行顺序稳定

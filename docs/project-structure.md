# 工程目录结构

> **更新日期**：2026-10-29（工程结构迁移阶段 0–2 及收尾完成后）
> **生成方式**：目录树、依赖、路由、测试和资源数量均按当前实际文件生成；每个文件后的注释取自文件头说明，缺失或不准确的已人工补写。
> **范围**：`entry`、`common/*`、`features/*`。`core` 不在本次重构范围，只列位置。
> **相关文档**：迁移过程见 [structure-migration-plan.md](./structure-migration-plan.md)；命名规则见 [naming-conventions.md](./naming-conventions.md)。

---

## 1. 总览

```
Mihoyo-Tool/
├── AppScope/          # 应用级配置与资源（应用名、图标）
├── core/              # 核心库（HAR）：网络、数据库、Repository、解析器。不在本次重构范围
├── entry/             # 入口模块（HAP）：Ability、应用框架页、桌面卡片 UI
├── common/            # 公共层：只被 features 和 entry 依赖
│   ├── basic/         # 主题、通用组件、工具、常量、全局信号、共用资源
│   └── widgetbase/    # 桌面卡片页面能用的纯代码（卡片进程限制）
└── features/          # 功能层：每个功能一个 HAR
    ├── home/          # 首页
    ├── dailynote/     # 实时便笺详情
    ├── characters/    # 角色列表
    ├── chardetail/    # 角色详情
    ├── material/      # 工具页、材料计算
    ├── account/       # 登录、我的、账号详情
    ├── settings/      # 外观设置
    ├── notification/  # 体力提醒
    ├── widget/        # 桌面卡片数据与小组件设置页
    ├── legal/         # 隐私同意、协议 WebView
    └── verification/  # 人机验证、设备指纹
```

每个模块的标准结构（以 `features/home` 为例）：

```
features/home/
├── Index.ets            # 对外导出：只导出其他模块实际用到的内容
├── oh-package.json5     # 模块名与依赖（HAR 不支持依赖传递，用到的模块都要直接声明）
├── build-profile.json5  # 构建配置（以 core 为模板）
├── hvigorfile.ts
└── src/
    ├── main/
    │   ├── module.json5   # type: har；有页面的模块在这里声明 routerMap
    │   ├── ets/           # 代码，按下面第 3 节的目录约定分层
    │   └── resources/     # 只有路由表（base/profile/<模块>_router_map.json）；共用资源在 common/basic
    └── test/              # 本地单元测试 + List.test.ets
```

## 2. 模块依赖关系

依赖方向：`entry → features → common`。common 不依赖上层；features 之间可以横向依赖，但不能成环（当前无环）。

```
entry ──→ 除 chardetail、dailynote 外的 9 个 feature，以及 basic、widgetbase、core

account ────→ legal、settings、verification、widget
home ───────→ dailynote、notification
characters ─→ chardetail ─→ material

所有 feature ─→ basic、core；用到卡片颜色 / 工具的再依赖 widgetbase
basic ──────→ core、widgetbase
widgetbase ─→ （无）
```

| 模块 | 直接依赖（oh-package.json5） |
| --- | --- |
| `entry` | core、widgetbase、basic、characters、home、account、legal、settings、verification、material、notification、widget |
| `common/basic` | core、widgetbase |
| `common/widgetbase` | 无 |
| `features/home` | core、widgetbase、basic、dailynote、notification |
| `features/dailynote` | core、widgetbase、basic |
| `features/characters` | core、widgetbase、basic、chardetail |
| `features/chardetail` | core、widgetbase、basic、material |
| `features/material` | core、basic |
| `features/account` | core、widgetbase、basic、settings、legal、widget、verification |
| `features/settings` | core、basic |
| `features/notification` | core、widgetbase、basic |
| `features/widget` | core、widgetbase、basic |
| `features/legal` | core、basic |
| `features/verification` | core、basic |

## 3. 模块内目录约定

| 目录 | 放什么 | 命名 |
| --- | --- | --- |
| `pages/` | 页面（被路由表或 Tab 引用的顶层组件），页面的路由 Builder 写在页面文件末尾 | `XxxPage.ets` |
| `views/` | 只在本模块页面里用的 UI 组件；按游戏分子目录 `common/`、`genshin/`、`starrail/`、`zzz/` | 与组件同名 |
| `viewmodel/` | ViewModel；LazyForEach 数据源也放这里（同官方 codelab） | `XxxViewModel.ets`、`XxxDataSource.ets` |
| `model/` | 数据模型（UI 状态、数据类） | `XxxModels.ets` / `XxxModel.ets` |
| `model/service/` | 有状态或访问存储 / 网络的服务类（Store、Manager、Builder、Service 等） | 与类同名 |
| `utils/` | 工具函数集合；日志类也放这里（同官方 codelab） | `XxxUtil.ets`、`XxxLogger.ets` |
| `constants/` | 常量与枚举 | `XxxConstants.ets`，单个枚举与枚举同名 |
| `shares/` | 跨功能共用的 UI 组件（只在 common/basic） | 与组件同名 |
| `signals/` | 全局信号（AppStorageV2） | `XxxSignal.ets` |
| `theme/`、`config/` | 主题、运行配置（只在 common） | 与主类型同名 |

## 4. 各模块详情

### 4.1 `entry` — 入口模块（HAP，`type: entry`）

应用唯一入口，面向手机 / 平板 / 2in1。放 4 个 Ability、应用框架页（Index / Launch / Main / Test）和桌面卡片 UI。其他功能都以模块依赖的方式接进来。**模块名必须保持 `entry`**：账号、Cookie、卡片配置等数据的存储路径按模块名区分，改名会让老用户数据"丢失"。

| 项 | 内容 |
| --- | --- |
| 代码文件 | 32 个 `.ets` |
| 依赖 | core、widgetbase、basic、characters、home、account、legal、settings、verification、material、notification、widget |
| 设备 | phone、tablet、2in1 |
| 路由 | 路由表只有 `TestPage`；启动页、主页、隐私同意页由 `pages/Index.ets` 的 Navigation 直接承载 |
| 本地测试 | LocalUnit、Widget2x2ViewModel |
| 资源 | `base/color` 1、`base/string` 23、`base/media` 4、`base/profile` 4、`dark/media` 1、`en/string` 13、`zh_HK/string` 13、`rawfile` 8 |

```
entry/src/main/ets/
├── entryability/                         # 主 Ability
│   └── EntryAbility.ets                  # 主 Ability：启动初始化、恢复颜色模式、注册卡片推送
├── entrybackupability/                   # 备份恢复
│   └── EntryBackupAbility.ets            # 系统备份恢复扩展
├── entryformability/                     # 服务卡片扩展
│   └── EntryFormAbility.ets              # 服务卡片扩展：卡片添加 / 更新 / 删除
├── pages/                                # 页面
│   ├── Index.ets                         # 应用根页面：创建根 Navigation，先进入启动页；承载启动页、主页、隐私同意页
│   ├── LaunchPage.ets                    # 启动页：Logo 动画、等待 core 初始化；未同意隐私则转到隐私同意页，否则进入主页
│   ├── MainPage.ets                      # 主框架：底部 Tab、分栏、全局弹窗与路由
│   └── TestPage.ets                      # 测试工具页（仅 UAT / Mock）
├── utils/                                # 工具与配置
│   ├── MainDialogLabels.ets              # 主页弹窗文案映射
│   └── MainNavigationMode.ets            # 主页面导航模式枚举
├── views/                                # 页面内组件
│   └── test/                             # 测试页组件
│       ├── TestRow.ets                   # 测试页操作行（仅 Debug 环境使用）
│       └── TestSectionHeader.ets         # 测试页分区标题（仅 Debug 环境使用）
├── widget/                               # 桌面卡片 UI（运行在卡片进程）
│   ├── pages/                            # 6 个卡片入口（form_config.json 引用）
│   │   ├── Widget1x2Genshin.ets          # 原神 1×2 迷你卡片
│   │   ├── Widget1x2StarRail.ets         # 星铁 1×2 迷你卡片
│   │   ├── Widget1x2ZZZ.ets              # 绝区零 1×2 迷你卡片
│   │   ├── Widget2x2.ets                 # 2×2 标准卡片入口
│   │   ├── Widget2x4.ets                 # 2×4 宽幅卡片入口
│   │   └── Widget4x4.ets                 # 4×4 大卡片入口
│   ├── viewmodel/                        # 卡片 ViewModel
│   │   ├── Widget1x2ViewModel.ets        # 1×2 卡片 ViewModel
│   │   ├── Widget2x2ViewModel.ets        # 2×2 卡片 ViewModel
│   │   ├── Widget2x4ViewModel.ets        # 2×4 卡片 ViewModel
│   │   └── Widget4x4ViewModel.ets        # 4×4 卡片 ViewModel
│   └── views/                            # 卡片组件
│       ├── Widget1x2ContentView.ets      # 1×2 迷你卡片内容组件
│       ├── Widget2x2Header.ets           # 2×2 Widget 头部组件
│       ├── Widget2x2SingleGame.ets       # 2×2 单游戏详细布局
│       ├── Widget2x2StaminaBlock.ets     # 2×2 Widget 体力区块组件
│       ├── Widget2x2StandardStamina.ets  # 2×2 Widget 标准体力区块组件
│       ├── Widget2x2StarRailStamina.ets  # 2×2 Widget 星铁体力区块组件
│       ├── Widget2x4InfoColumn.ets       # 2×4 左侧角色信息列
│       ├── Widget2x4SingleGame.ets       # 2×4 单游戏水平布局
│       ├── Widget4x4ExpeditionBlock.ets  # 4×4 原神派遣头像区
│       ├── Widget4x4ExtraRowsGroup.ets   # 4×4 额外数据行分组
│       ├── Widget4x4Header.ets           # 4×4 顶部标题行
│       ├── Widget4x4SingleGame.ets       # 4×4 单游戏垂直分块布局（组装 4 个子组件）
│       ├── Widget4x4StaminaBlock.ets     # 4×4 体力区块
│       ├── WidgetDataRow.ets             # 额外数据行（2×4 / 4×4 共享）
│       ├── WidgetEmptyContent.ets        # Widget 空态内容组件
│       ├── WidgetExpeditionAvatar.ets    # 派遣角色头像（2×4 / 4×4 共享）
│       └── WidgetExtraDataRows.ets       # Widget 额外数据行组件
└── widgetsyncability/                    # 卡片数据同步
    └── WidgetSyncAbility.ets             # 卡片数据同步 Ability
```

### 4.2 `common/basic` — 公共模块（HAR）

各功能共用的代码与资源：主题、通用组件、工具函数、常量、全局信号、账号角色数据。共用的字符串 / 颜色 / 图片也放在这里。

| 项 | 内容 |
| --- | --- |
| 代码文件 | 36 个 `.ets` |
| 依赖 | core、widgetbase |
| 对外导出 | 71 个（`Index.ets`），全部导出 |
| 路由 | 无（由其他页面直接嵌入或调用） |
| 本地测试 | 无 |
| 资源 | `base/color` 31、`base/string` 479、`base/media` 44、`dark/color` 2、`dark/media` 1、`en/string` 471、`zh_HK/string` 470 |

```
common/basic/src/main/ets/
├── config/                        # 运行配置
│   └── RuntimeConfig.ets          # 运行环境（mock / uat / release），读 BuildProfile.APP_ENV
├── constants/                     # 常量与枚举
│   ├── AppConstants.ets           # 跨组件复用的固定值
│   ├── AppRoutes.ets              # 全局路由 Path 常量
│   ├── FeedbackType.ets           # Snackbar 反馈类型（决定图标和颜色）
│   ├── HeroPanelMode.ets          # 角色详情立绘区布局模式（wide / portrait / landscape）
│   ├── SignalStorageKey.ets       # 全局信号在 AppStorageV2 中的 key
│   └── ViewState.ets              # 页面 ViewModel 状态枚举
├── model/                         # 数据模型
│   ├── AccountOptionModel.ets     # 账号切换 Menu 的选项数据
│   ├── AccountRoleModels.ets      # 账号与游戏角色卡片数据（首页、小组件设置共用）
│   ├── SegmentedTabItemModel.ets  # SegmentedTabBar 的数据模型
│   └── SnackbarParamsModel.ets    # Snackbar 展示参数
├── shares/                        # 跨功能共用组件
│   ├── AccountSwitchDialog.ets    # 账号切换弹窗（主框架、选角页共用）
│   ├── PlaceholderView.ets        # 空态占位视图
│   ├── SegmentedTabBar.ets        # 通用分段 Tab 选择器
│   ├── SnackbarContent.ets        # 操作反馈 Snackbar 组件
│   ├── SplitPlaceholder.ets       # 分栏模式右侧无内容时的占位
│   ├── UserGameSection.ets        # 单个米游社账号的游戏角色区块（账号标题行 + 可折叠的角色列表）
│   └── UserGameSectionHeader.ets  # 账号区块标题行（头像 + 昵称 + 游戏数 + 折叠箭头）
├── signals/                       # 全局信号
│   ├── AccountSignal.ets          # 账号变更信号（登录、删除、养成目标保存后通知各页刷新）
│   ├── CookieExpiredSignal.ets    # Cookie 过期全局信号
│   ├── SyncRetrySignal.ets        # 人机验证 / 设备指纹处理完成后通知各页重试同步
│   └── WidgetSyncHook.ets         # 便笺同步后刷新桌面卡片的登记点（让 notification 不直接依赖 widget）
├── theme/                         # 主题
│   ├── PrimaryButtonModifier.ets  # 主按钮样式
│   ├── ThemeFonts.ets             # 字体预设
│   └── ThemeManager.ets           # 全局主题单例（深浅色切换）
└── utils/                         # 工具函数
    ├── CharacterSortUtil.ets      # 角色列表统一排序（角色页 / 材料计算角色选择页共用）
    ├── ColorUtil.ets              # 生成带透明度的颜色
    ├── DialogDedupUtil.ets        # 弹框 / Snackbar 全局去重
    ├── FeedbackUtil.ets           # 在屏幕底部显示 Snackbar 反馈
    ├── GameIdUtil.ets             # 游戏 ID 工具函数
    ├── GenshinElementUtil.ets     # 原神元素枚举（从 core 重新导出）+ 图标/颜色/标签工具函数
    ├── RouterUtil.ets             # 全局路由栈（Index 创建 Navigation 后注入）
    ├── ServerNameUtil.ets         # 服务器标识符 → 国际化资源映射
    ├── StarRailElementUtil.ets    # 星铁属性/命途枚举（从 core 重新导出）+ 图标工具函数
    ├── TimeFormatUtil.ets         # 时间格式化工具
    └── ZZZElementUtil.ets         # 绝区零属性/职业枚举（从 core 重新导出）+ 图标/颜色工具函数
```

### 4.3 `common/widgetbase` — 公共模块（HAR）

桌面卡片页面用到的纯代码（主题取值、卡片数据模型与工具）。桌面卡片运行在系统的卡片进程，官方规定只能导入"支持在卡片中使用"的 API，所以这部分单独成模块，**只能放卡片能用的代码**。目前不依赖任何模块；以后如果要依赖，被依赖的模块也必须只含卡片能用的代码。

| 项 | 内容 |
| --- | --- |
| 代码文件 | 9 个 `.ets` |
| 依赖 | 无 |
| 对外导出 | 57 个（`Index.ets`），全部导出 |
| 路由 | 无（由其他页面直接嵌入或调用） |
| 本地测试 | WidgetDataUtil、WidgetDataUtilExtraRows、WidgetExtraRowConstants、WidgetExtraRowType、WidgetPayloadUtil |
| 资源 | `base/color` 94、`base/string` 23、`dark/color` 19、`en/string` 23、`zh_HK/string` 23 |

```
common/widgetbase/src/main/ets/
├── constants/                       # 常量与枚举
│   ├── WidgetExtraRowConstants.ets  # 额外信息行的显示优先级（原神、星铁）
│   └── WidgetExtraRowType.ets       # 额外信息行类型枚举
├── model/                           # 数据模型
│   └── WidgetUIStateModels.ets      # 卡片 UI 状态模型
├── theme/                           # 主题
│   ├── AppTheme.ets                 # UI Token 类型定义（颜色、字号、间距、圆角等）
│   └── DefaultTheme.ets             # 默认主题取值
└── utils/                           # 工具函数
    ├── WidgetDataUtil.ets           # 卡片数据解析公共方法
    ├── WidgetLogger.ets             # Widget 模块专用日志工具
    ├── WidgetPayloadUtil.ets        # 卡片推送数据（payload）解析
    └── WidgetUtil.ets               # 卡片通用工具函数、映射和常量
```

### 4.4 `features/home` — 功能模块（HAR）

"首页"：各账号的游戏体力与便笺概览。

| 项 | 内容 |
| --- | --- |
| 代码文件 | 10 个 `.ets` |
| 依赖 | core、widgetbase、basic、dailynote、notification |
| 对外导出 | 1 个（`Index.ets`） |
| 路由 | 无（由其他页面直接嵌入或调用） |
| 本地测试 | HomeViewModel |
| 资源 | 无 |

```
features/home/src/main/ets/
├── pages/                       # 页面
│   └── HomePage.ets             # 首页（Tab）
├── viewmodel/                   # ViewModel
│   └── HomeViewModel.ets        # 首页 ViewModel
└── views/                       # 页面内组件
    ├── AccountSkeletonCard.ets  # 骨架屏中的账号卡片
    ├── GameDataRow.ets          # 游戏数据行（标签 + 值）
    ├── GameStaminaBlock.ets     # 游戏主体力区块（大数字 + 环形进度 + 恢复描述）
    ├── GameToolCard.ets         # 游戏战绩工具卡片（首页）
    ├── GameToolCardContent.ets  # 游戏战绩卡片内容区（四个游戏通用）
    ├── GameToolCardHeader.ets   # 游戏战绩卡片头部（Logo + 游戏名/服务器/昵称 + 同步时间）
    ├── HomeSkeletonView.ets     # 首页骨架屏
    └── SkeletonBlock.ets        # 骨架色块（呼吸动画）
```

### 4.5 `features/dailynote` — 功能模块（HAR）

三个游戏的实时便笺详情页。

| 项 | 内容 |
| --- | --- |
| 代码文件 | 23 个 `.ets` |
| 依赖 | core、widgetbase、basic |
| 对外导出 | 3 个（`Index.ets`） |
| 路由 | `GenshinDailyDetail`、`StarRailDailyDetail`、`ZZZDailyDetail` |
| 本地测试 | GenshinDailyDetailViewModel |
| 资源 | `base/profile` 1 |

```
features/dailynote/src/main/ets/
├── model/                                # 数据模型
│   └── DailyNoteModels.ets               # 便笺数据类
├── pages/                                # 页面
│   ├── GenshinDailyDetailPage.ets        # 原神便笺详情页
│   ├── StarRailDailyDetailPage.ets       # 星铁便笺详情页
│   └── ZZZDailyDetailPage.ets            # 绝区零便笺详情页
├── viewmodel/                            # ViewModel
│   ├── GenshinDailyDetailViewModel.ets   # 原神便笺 ViewModel
│   ├── StarRailDailyDetailViewModel.ets  # 星铁便笺 ViewModel
│   └── ZZZDailyDetailViewModel.ets       # 绝区零便笺 ViewModel
└── views/                                # 页面内组件
    ├── common/                           # 三个游戏共用
    │   ├── DailyNoteCard.ets             # 便笺通用卡片行（图标 + 标题 + 值）
    │   ├── DailyNoteDataRow.ets          # 便笺数据行（标签 + 值）
    │   ├── DailyNoteEmptyView.ets        # 无数据
    │   ├── DailyNoteLoadingView.ets      # 加载中
    │   ├── DailyNoteSectionLabel.ets     # 便笺分组标题
    │   └── ExpeditionItem.ets            # 派遣条目（原神、星铁共用）
    ├── genshin/                          # 原神
    │   ├── DailyNoteGenshin.ets          # 原神便笺内容
    │   ├── GenshinDailyTaskContent.ets   # 原神每日委托内容区（勾选格子 + 领取状态）
    │   └── GenshinExpeditionSection.ets  # 原神派遣列表区（标题行 + 派遣条目列表）
    ├── starrail/                         # 星铁
    │   ├── DailyNoteStarRail.ets         # 星铁便笺内容
    │   ├── StarRailStaminaCard.ets       # 星铁日常卡片（开拓力 + 后备 + 派遣 + 实训 + 历战）
    │   └── StarRailUniverseCard.ets      # 星铁宇宙卡片（模拟宇宙 + 差分宇宙 + 黄金与机械）
    └── zzz/                              # 绝区零
        ├── DailyNoteZZZ.ets              # 绝区零便笺内容
        ├── ZZZDailyCard.ets              # 绝区零日常卡片（电量 + 活跃度）
        ├── ZZZOtherCard.ets              # 绝区零其他卡片（式舆防卫战 + 会员卡 + 咖啡厅）
        └── ZZZShopCard.ets               # 绝区零商店卡片（录像店 + 刮刮卡）
```

### 4.6 `features/characters` — 功能模块（HAR）

"角色"页：按游戏展示角色网格，点击进入角色详情。

| 项 | 内容 |
| --- | --- |
| 代码文件 | 12 个 `.ets` |
| 依赖 | core、widgetbase、basic、chardetail |
| 对外导出 | 1 个（`Index.ets`） |
| 路由 | 无（由其他页面直接嵌入或调用） |
| 本地测试 | CharactersViewModel |
| 资源 | 无 |

```
features/characters/src/main/ets/
├── pages/                            # 页面
│   └── CharactersPage.ets            # 角色页（Tab）
├── viewmodel/                        # ViewModel
│   ├── CharacterDataSource.ets       # LazyForEach 数据源
│   └── CharactersViewModel.ets       # 角色页 ViewModel
└── views/                            # 页面内组件
    ├── CharacterCard.ets             # 角色卡片（按游戏切换样式）
    ├── CharactersContent.ets         # 角色页内容（骨架屏 / 空态 / 网格）
    ├── CharactersSkeleton.ets        # 角色页骨架屏
    ├── genshin/                      # 原神
    │   ├── GenshinBottomBar.ets      # 原神角色卡片底部信息栏
    │   └── GenshinTopLeftBadge.ets   # 原神角色卡片左上角元素图标
    ├── starrail/                     # 星铁
    │   ├── StarRailBottomBar.ets     # 星铁角色卡片底部信息栏
    │   └── StarRailTopLeftBadge.ets  # 星铁角色卡片左上角属性 + 命途
    └── zzz/                          # 绝区零
        ├── ZZZBottomBar.ets          # 绝区零角色卡片底部信息栏（等级 + 阵营）
        └── ZZZTopLeftBadge.ets       # 绝区零角色卡片左上角稀有度 + 属性 + 特性
```

### 4.7 `features/chardetail` — 功能模块（HAR）

三个游戏的角色详情页（立绘、技能、武器 / 光锥 / 音擎、圣遗物 / 遗器 / 驱动盘、属性），含宽屏 / 竖屏 / 横屏布局。

| 项 | 内容 |
| --- | --- |
| 代码文件 | 69 个 `.ets` |
| 依赖 | core、widgetbase、basic、material |
| 对外导出 | 1 个（`Index.ets`） |
| 路由 | `GenshinCharacterDetail`、`StarRailCharacterDetail`、`ZZZCharacterDetail` |
| 本地测试 | GenshinCharacterDetailViewModel |
| 资源 | `base/profile` 1 |

```
features/chardetail/src/main/ets/
├── model/                                       # 数据模型
│   └── CharDetailModels.ets                     # 角色详情 UI 数据结构
├── pages/                                       # 页面
│   ├── GenshinCharacterDetailPage.ets           # 原神角色详情页
│   ├── StarRailCharacterDetailPage.ets          # 星铁角色详情页
│   └── ZZZCharacterDetailPage.ets               # 绝区零角色详情页
├── utils/                                       # 工具函数
│   ├── GenshinElementBgUtil.ets                 # 原神立绘区元素背景色
│   ├── GenshinPropertyUtil.ets                  # 原神属性类型 → 多语言文本
│   └── StarRailPropertyUtil.ets                 # 星铁属性类型 → 多语言文本
├── viewmodel/                                   # ViewModel
│   ├── GenshinCharacterDetailViewModel.ets      # 原神角色详情 ViewModel
│   ├── StarRailCharacterDetailViewModel.ets     # 星铁角色详情 ViewModel
│   └── ZZZCharacterDetailViewModel.ets          # 绝区零角色详情 ViewModel
└── views/                                       # 页面内组件
    ├── common/                                  # 三个游戏共用
    │   ├── CharDetailConsColumn.ets             # 命座/星魂/影画纵列组件（三个游戏通用）
    │   ├── CharDetailEmptyView.ets              # 角色详情空态/错误视图
    │   ├── CharDetailHeroNameOverlay.ets        # 立绘区左下角名字+等级信息叠加层（星铁/绝区零通用）
    │   ├── CharDetailLoadingView.ets            # 加载中
    │   ├── CharDetailMaterialCalcEntry.ets      # 材料计算入口
    │   ├── CharDetailRelicPlaceholder.ets       # 遗器/驱动盘未装备占位格
    │   ├── CharDetailSectionLabel.ets           # 角色详情各 Section 的标题标签
    │   ├── CharDetailSkillItem.ets              # 技能图标+等级单项（宽屏纵列和横屏横行通用）
    │   └── CharDetailStatRow.ets                # 属性列表单行（标签 + 值）
    ├── genshin/                                 # 原神
    │   ├── CharDetailHeroInfoOverlay.ets        # 立绘区左下角信息叠加层（原神通用）
    │   ├── CharDetailHeroPanel.ets              # 原神立绘区（按布局模式分发）
    │   ├── CharDetailHeroPanelLandscape.ets     # 原神立绘区：手机横屏
    │   ├── CharDetailHeroPanelPortrait.ets      # 原神立绘区：手机竖屏
    │   ├── CharDetailHeroPanelWide.ets          # 原神立绘区：宽屏
    │   ├── CharDetailLandscapeLayout.ets        # 角色详情 Phone 横屏布局
    │   ├── CharDetailLandscapeSkillItem.ets     # 横屏立绘区技能图标+等级单项
    │   ├── CharDetailLevelAndFetterRow.ets      # 等级与好感行
    │   ├── CharDetailPortraitLayout.ets         # 角色详情 Phone 竖屏布局
    │   ├── CharDetailPortraitRelicsSection.ets  # 圣遗物区 Section
    │   ├── CharDetailPortraitSkillItem.ets      # 竖屏技能单项
    │   ├── CharDetailPortraitSkillsSection.ets  # 技能区 Section
    │   ├── CharDetailPortraitStatsSection.ets   # 属性区 Section
    │   ├── CharDetailPortraitWeaponCard.ets     # 竖屏武器卡片
    │   ├── CharDetailPortraitWeaponSection.ets  # 武器区 Section
    │   ├── CharDetailRelicCard.ets              # 圣遗物 Phone 卡片（2列网格中的单个卡片）
    │   ├── CharDetailRelicPair.ets              # 圣遗物对（Phone 模式）
    │   ├── CharDetailRelicRow.ets               # 圣遗物宽屏行（左侧图标+主词条，右侧副词条网格）
    │   ├── CharDetailRelicsPanel.ets            # 宽屏圣遗物栏
    │   ├── CharDetailSkillsColumn.ets           # 技能纵列组件（宽屏用）
    │   ├── CharDetailStatsGrid.ets              # 属性网格（Phone 模式）
    │   ├── CharDetailStatsList.ets              # 属性列表（宽屏模式）
    │   ├── CharDetailStatsPanel.ets             # 武器 + 属性列表区
    │   ├── CharDetailWeaponCard.ets             # 原神武器卡片（宽屏样式）
    │   ├── CharDetailWeaponRow.ets              # 原神武器行（Phone 紧凑样式）
    │   └── CharDetailWideLayout.ets             # 原神宽屏三栏布局
    ├── starrail/                                # 星铁
    │   ├── StarRailCharDetailContent.ets        # 星铁详情内容（行迹、光锥、属性、遗器）
    │   ├── StarRailCharDetailHero.ets           # 星铁立绘区
    │   ├── StarRailCharDetailHeroProfile.ets    # 星铁英雄区左下角等级+星魂行
    │   ├── StarRailCharDetailWideLayout.ets     # 星铁宽屏布局
    │   ├── StarRailEquipCard.ets                # 星铁光锥卡片
    │   ├── StarRailEquipSection.ets             # 星铁光锥区（有光锥/无光锥两种状态）
    │   ├── StarRailPropsSection.ets             # 星铁属性面板
    │   ├── StarRailRelicCard.ets                # 星铁遗器/饰品卡片
    │   ├── StarRailRelicsSection.ets            # 星铁遗器/饰品区（2列网格 + 占位）
    │   ├── StarRailSkillNode.ets                # 星铁行迹单个技能节点（图标+激活状态+等级+类型标签）
    │   └── StarRailSkillsSection.ets            # 星铁行迹区（主技能/额外能力/属性加成）
    └── zzz/                                     # 绝区零
        ├── ZZZCharDetailContent.ets             # 绝区零详情内容（技能、音擎、属性、驱动盘）
        ├── ZZZCharDetailHero.ets                # 绝区零立绘区
        ├── ZZZCharDetailHeroProfile.ets         # 绝区零立绘区信息行（全名、等级、稀有度、影画）
        ├── ZZZCharDetailWideLayout.ets          # 绝区零宽屏布局
        ├── ZZZEquipCard.ets                     # 驱动盘卡片
        ├── ZZZEquipCardHeader.ets               # 绝区零驱动盘卡片头部（图标 + 套装名 + 强化等级）
        ├── ZZZEquipSection.ets                  # 绝区零驱动盘区（套装摘要 + 6件网格）
        ├── ZZZPropsSection.ets                  # 绝区零属性面板
        ├── ZZZSkillItem.ets                     # 绝区零技能列表单行（色块 + 技能名 + 等级标签）
        ├── ZZZSkillsSection.ets                 # 绝区零技能区
        ├── ZZZSuitSummaryRow.ets                # 驱动盘套装摘要行
        ├── ZZZWeaponCard.ets                    # 绝区零音擎（武器）卡片
        └── ZZZWeaponSection.ets                 # 绝区零音擎区（有音擎/无音擎两种状态）
```

### 4.8 `features/material` — 功能模块（HAR）

"工具"页与材料计算：选角、养成目标配置、材料汇总（三个游戏）。

| 项 | 内容 |
| --- | --- |
| 代码文件 | 51 个 `.ets` |
| 依赖 | core、basic |
| 对外导出 | 2 个（`Index.ets`） |
| 路由 | `ZZZMaterialList`、`GenshinMaterialTargetConfig`、`StarRailMaterialTargetConfig`、`ZZZMaterialTargetConfig`、`GenshinMaterialList`、`StarRailMaterialList`、`MaterialCharacterSelect` |
| 本地测试 | 15 个测试文件：材料计算 / 汇总 / 目标配置 / 选角 / 工具页 ViewModel、`MaterialListAggregator`、`MaterialAmountUtil`、`MaterialComputeUtils`、路由与模型 |
| 资源 | `base/profile` 1 |

```
features/material/src/main/ets/
├── model/                                         # 数据模型
│   ├── MaterialCalcModels.ets                     # 材料计算页 UI 模型
│   ├── MaterialListModels.ets                     # 材料汇总页 UI 模型
│   ├── MaterialTargetConfigModels.ets             # 养成目标配置页 UI 模型
│   ├── MaterialTargetModels.ets                   # 养成目标领域模型（技能槽位 / 目标等级 / 路由参数）
│   ├── ToolsModels.ets                            # 工具页 UI 模型
│   └── service/                                   # 数据 / 业务服务（存储、网络、计算）
│       ├── GenshinMaterialCompute.ets             # 原神养成材料计算（facade 按 gameId 分派）
│       ├── MaterialComputeResult.ets              # 计算服务返回结果（避免循环依赖）
│       ├── MaterialComputeService.ets             # 材料计算服务 facade（选角、汇总、目标配置页共用）
│       ├── MaterialComputeUtils.ets               # 计算服务共用工具
│       ├── StarRailMaterialCompute.ets            # 星穹铁道养成材料计算
│       └── ZZZMaterialCompute.ets                 # 绝区零养成材料计算
├── pages/                                         # 页面
│   ├── GenshinMaterialListPage.ets                # 原神材料汇总页
│   ├── GenshinMaterialTargetConfigPage.ets        # 原神养成目标配置页
│   ├── MaterialCalcPage.ets                       # 单角色材料计算页（路由未注册，见已知缺陷）
│   ├── MaterialCharacterSelectPage.ets            # 选角页（多选，最多 4 个）
│   ├── StarRailMaterialListPage.ets               # 星铁材料汇总页
│   ├── StarRailMaterialTargetConfigPage.ets       # 星铁养成目标配置页
│   ├── ToolsPage.ets                              # 工具页（Tab，三个游戏的材料汇总入口）
│   ├── ZZZMaterialListPage.ets                    # 绝区零材料汇总页
│   └── ZZZMaterialTargetConfigPage.ets            # 绝区零养成目标配置页
├── utils/                                         # 工具函数
│   ├── MaterialAmountUtil.ets                     # 货币类材料数量「万 / 亿」格式化
│   └── MaterialRouteUtil.ets                      # 材料计算相关页面的路由名（按游戏）
├── viewmodel/                                     # ViewModel
│   ├── GenshinMaterialListViewModel.ets           # 原神材料汇总页 ViewModel
│   ├── GenshinMaterialTargetConfigViewModel.ets   # 原神养成目标配置 ViewModel
│   ├── MaterialCalcViewModel.ets                  # 材料计算页 ViewModel
│   ├── MaterialCharacterSelectViewModel.ets       # 角色选择页 ViewModel
│   ├── MaterialListAggregator.ets                 # 三游戏材料汇总页共用纯函数聚合器（排序 / 汇总 / 分组 / 材料项转换）
│   ├── StarRailMaterialListViewModel.ets          # 星穹铁道材料汇总页 ViewModel
│   ├── StarRailMaterialTargetConfigViewModel.ets  # 星穹铁道养成目标配置 ViewModel
│   ├── ToolsViewModel.ets                         # 工具页 ViewModel
│   ├── ZZZMaterialListViewModel.ets               # 绝区零材料汇总页 ViewModel
│   └── ZZZMaterialTargetConfigViewModel.ets       # 绝区零养成目标配置 ViewModel
└── views/                                         # 页面内组件
    ├── CharacterMaterialCard.ets                  # 角色材料卡片组件（按角色视图）
    ├── CharacterMaterialSections.ets              # 单个角色的材料分组
    ├── CharacterSelectCard.ets                    # 选角页网格卡片（头像 + 等级 + 选中标记）
    ├── GameEntryCard.ets                          # 工具页游戏入口卡片
    ├── LevelConfigRow.ets                         # 目标配置页等级行（三游戏共用）
    ├── MaterialCalcCharacter.ets                  # 计算页角色信息 + 等级目标
    ├── MaterialCalcContentView.ets                # 计算页内容
    ├── MaterialCalcEmptyView.ets                  # 计算页空态
    ├── MaterialCalcItem.ets                       # 材料单项（图标、名称、进度、数量）
    ├── MaterialCalcLevelPicker.ets                # 计算页等级选择器弹窗
    ├── MaterialCalcLoadingView.ets                # 计算页加载中
    ├── MaterialCalcSection.ets                    # 材料 Section 组件
    ├── MaterialCalcSkills.ets                     # 技能目标等级
    ├── MaterialGridCard.ets                       # 材料网格卡片组件（按材料视图）
    ├── MaterialGridItem.ets                       # 材料网格单项（图标 + 缺口数量）
    ├── MaterialListContentView.ets                # 汇总页内容（按角色 / 按材料）
    ├── MaterialListScaffold.ets                   # 三游戏材料汇总页共用骨架（标题栏 / 菜单 / Tab / 三态）
    ├── MaterialSectionView.ets                    # 材料分组（标题 + 网格）
    └── TargetConfigTipCard.ets                    # 目标配置页顶部提示卡片（三游戏共用）
```

### 4.9 `features/account` — 功能模块（HAR）

登录（手机号 / 二维码 / Cookie）、"我的"页、账号详情。

| 项 | 内容 |
| --- | --- |
| 代码文件 | 38 个 `.ets` |
| 依赖 | core、widgetbase、basic、settings、legal、widget、verification |
| 对外导出 | 1 个（`Index.ets`） |
| 路由 | `AccountDetail`、`Login` |
| 本地测试 | AccountDetailViewModel、LoginViewModel、MyViewModel |
| 资源 | `base/profile` 1 |

```
features/account/src/main/ets/
├── constants/                      # 常量与枚举
│   └── LoginConstants.ets          # 登录 Tab / 步骤 / 二维码状态枚举
├── model/                          # 数据模型
│   └── MyModels.ets                # 我的页数据类
├── pages/                          # 页面
│   ├── AccountDetailPage.ets       # 账号详情页
│   ├── LoginPage.ets               # 登录页
│   └── MyPage.ets                  # 我的页（Tab）
├── viewmodel/                      # ViewModel
│   ├── AccountDetailViewModel.ets  # 账号详情页 ViewModel
│   ├── LoginViewModel.ets          # 登录 ViewModel（手机号 / 二维码 / Cookie）
│   └── MyViewModel.ets             # 我的页面 ViewModel
└── views/                          # 页面内组件
    ├── AboutSection.ets            # 关于区（版本号、导出日志、清缓存）
    ├── AccountActionsSection.ets   # 账号操作区（重新登录、刷新 Cookie、重置设备指纹、删除）
    ├── AccountHeaderCard.ets       # 账号头部卡片（头像、昵称、UID、角色数）
    ├── AccountListItem.ets         # 账号列表单行
    ├── AccountListSection.ets      # 账号列表 Section
    ├── AccountRoleCard.ets         # 账号下单个游戏角色卡片
    ├── AccountRoleCardHeader.ets   # 角色卡片头部（游戏 logo、名称、昵称、等级）
    ├── AccountRoleServerRow.ets    # 服务器/UID 信息行
    ├── AccountRoleStatItem.ets     # 角色卡片统计项（数值 + 标签）
    ├── AccountRolesSection.ets     # 账号的角色卡片列表
    ├── AppearanceSection.ets       # 外观设置入口区
    ├── LoginAgreement.ets          # 用户协议 / 隐私政策勾选
    ├── LoginCard.ets               # 登录卡片（Tab 栏 + Tab 内容）
    ├── LoginCodeInput.ets          # 验证码输入步骤 UI
    ├── LoginCookie.ets             # 手动输入 Cookie 登录组件
    ├── LoginFeatureItem.ets        # 登录页品牌特性条目
    ├── LoginLogoSection.ets        # 登录页 Logo 区
    ├── LoginNarrowLayout.ets       # 登录页 Phone 单栏布局
    ├── LoginPhone.ets              # 手机号 + 短信验证码登录组件
    ├── LoginPhoneInput.ets         # 手机号输入步骤 UI
    ├── LoginQRCode.ets             # 二维码登录
    ├── LoginQRCodeConfirmed.ets    # 二维码：已确认
    ├── LoginQRCodeExpired.ets      # 二维码：已过期
    ├── LoginQRCodeLoading.ets      # 二维码：加载中
    ├── LoginQRCodeReady.ets        # 二维码：就绪 / 已扫码
    ├── LoginTabBar.ets             # 登录方式 Tab 栏（手机号 / 二维码 / Cookie）
    ├── LoginTabContent.ets         # 登录 Tab 内容区（手机号 / 二维码 / Cookie）
    ├── LoginTabItem.ets            # 登录 Tab 切换项
    ├── LoginWideLayout.ets         # 登录页宽屏两栏布局
    └── SectionHeader.ets           # 我的页分区标题
```

### 4.10 `features/settings` — 功能模块（HAR）

外观设置（浅色 / 深色 / 跟随系统）。

| 项 | 内容 |
| --- | --- |
| 代码文件 | 4 个 `.ets` |
| 依赖 | core、basic |
| 对外导出 | 2 个（`Index.ets`） |
| 路由 | `AppearanceSettings` |
| 本地测试 | 无 |
| 资源 | `base/profile` 1 |

```
features/settings/src/main/ets/
├── model/                               # 数据模型
│   └── service/                         # 数据 / 业务服务（存储、网络、计算）
│       └── AppearanceManager.ets        # 外观模式（浅色 / 深色 / 跟随系统）管理
├── pages/                               # 页面
│   └── AppearanceSettingsPage.ets       # 外观设置页
├── viewmodel/                           # ViewModel
│   └── AppearanceSettingsViewModel.ets  # 外观设置 ViewModel
└── views/                               # 页面内组件
    └── ThemeModeRow.ets                 # 主题模式选项行
```

### 4.11 `features/notification` — 功能模块（HAR）

体力提醒：通知调度服务和通知设置页。

| 项 | 内容 |
| --- | --- |
| 代码文件 | 22 个 `.ets` |
| 依赖 | core、widgetbase、basic |
| 对外导出 | 1 个（`Index.ets`） |
| 路由 | `NotificationSettings` |
| 本地测试 | StaminaNotificationService、StaminaThresholdCalculator |
| 资源 | `base/profile` 1 |

```
features/notification/src/main/ets/
├── model/                                  # 数据模型
│   ├── NotificationModels.ets              # 通知设置与状态数据模型
│   └── service/                            # 数据 / 业务服务（存储、网络、计算）
│       ├── NotificationSettingsStore.ets   # 通知设置持久化（preferences）
│       ├── NotificationStateStore.ets      # 通知状态持久化（preferences）
│       ├── StaminaNotificationService.ets  # 体力通知调度核心服务（单例）
│       └── StaminaThresholdCalculator.ets  # 阈值计算（纯函数）
├── pages/                                  # 页面
│   └── NotificationSettingsPage.ets        # 通知设置页
├── viewmodel/                              # ViewModel
│   └── NotificationSettingsViewModel.ets   # 通知设置页 ViewModel
└── views/                                  # 页面内组件
    ├── NotificationAccountBlock.ets        # 账号折叠区块
    ├── NotificationAccountHeader.ets       # 账号折叠区块的标题行（头像 + 昵称 + 展开箭头）
    ├── NotificationBubbleCollapsed.ets     # 样式 B 折叠状态气泡
    ├── NotificationBubbleExpanded.ets      # 样式 B 展开状态气泡
    ├── NotificationBubbleHeader.ets        # 通知气泡顶部（App 图标 + 名称 + 时间）
    ├── NotificationFullValueRow.ets        # 快捷设置满值行
    ├── NotificationGameRow.ets             # 单个游戏的体力阈值设置行
    ├── NotificationMasterToggle.ets        # 通知总开关
    ├── NotificationPermissionWarning.ets   # 通知权限被拒绝提示
    ├── NotificationSection.ets             # 通知设置内容区
    ├── NotificationSlotUsage.ets           # 代理提醒槽位用量
    ├── NotificationStyleAPreview.ets       # 样式 A 通知气泡预览
    ├── NotificationStyleBLine.ets          # 样式 B 展开状态中的单游戏行
    ├── NotificationStyleBPreview.ets       # 样式 B 通知气泡预览（折叠 + 展开）
    └── NotificationStyleCard.ets           # 通知样式选择卡片
```

### 4.12 `features/widget` — 功能模块（HAR）

桌面卡片的数据准备与推送、卡片配置存储，以及"小组件设置"页。卡片 UI 本身在 entry 的 `widget/`。

| 项 | 内容 |
| --- | --- |
| 代码文件 | 42 个 `.ets` |
| 依赖 | core、widgetbase、basic |
| 对外导出 | 12 个（`Index.ets`） |
| 路由 | `WidgetSettings` |
| 本地测试 | 无 |
| 资源 | `base/profile` 1 |

```
features/widget/src/main/ets/
├── model/                               # 数据模型
│   ├── WidgetConfigModels.ets           # Widget 配置存储模型
│   ├── WidgetDataStoreModels.ets        # Widget 全局数据存储模型（v2）
│   ├── WidgetGameSnapshotModel.ets      # 卡片推送用的单游戏快照模型
│   ├── WidgetPreviewModels.ets          # Widget 预览组件数据模型
│   ├── WidgetSettingsModels.ets         # Widget 配置页的 UI State 模型
│   └── service/                         # 数据 / 业务服务（存储、网络、计算）
│       ├── WidgetConfigStore.ets        # Widget 配置存储管理器
│       ├── WidgetDataBuilder.ets        # 从 DB 读体力数据，构建并推送卡片 payload
│       ├── WidgetDataStoreBuilder.ets   # Widget 数据构建器（v2）
│       ├── WidgetDataStoreManager.ets   # Widget 全局数据存储管理器（v2）
│       ├── WidgetFormIdStore.ets        # formId 持久化存储工具
│       ├── WidgetImageDownloader.ets    # Widget 网络图片下载器
│       ├── WidgetMockPayload.ets        # Widget Mock 数据
│       ├── WidgetPayloadBuilder.ets     # Widget Payload 构建器
│       ├── WidgetSyncHandlerImpl.ets    # WidgetSyncHook 的 widget 功能实现
│       └── WidgetUpdateNotifier.ets     # Widget 更新通知器
├── pages/                               # 页面
│   └── WidgetSettingsPage.ets           # 小组件设置页
├── utils/                               # 工具函数
│   ├── WidgetLog.ets                    # 卡片日志（与 widgetbase 的 WidgetLogger 重复，待 M14 合并）
│   └── WidgetPreviewUtil.ets            # Widget 预览组件工具函数
├── viewmodel/                           # ViewModel
│   └── WidgetSettingsViewModel.ets      # 小组件设置 ViewModel
└── views/                               # 页面内组件
    ├── WidgetConfigDone.ets             # 配置完成步骤
    ├── WidgetConfigPreview.ets          # Widget 配置页卡片预览组件
    ├── WidgetGameTypeOption.ets         # 1×2 卡片的游戏类型选项
    ├── WidgetSettingsBottomButtons.ets  # Widget 配置页底部按钮组件
    ├── WidgetSettingsGameStep.ets       # Widget 配置步骤 2（仅 1x2 卡片）：游戏类型选择
    ├── WidgetSettingsLoading.ets        # Widget 配置页加载状态组件
    ├── WidgetSettingsMainContent.ets    # Widget 配置页主要内容区域
    ├── WidgetSettingsSizeStep.ets       # Widget 配置步骤 1：卡片尺寸选择
    ├── WidgetSettingsSlotStep.ets       # Widget 配置步骤 3：角色 Slot 选择
    ├── WidgetSizeOption.ets             # 尺寸选项
    ├── WidgetSizeThumbs.ets             # 各尺寸缩略图
    ├── WidgetSlotOption.ets             # 角色槽位选项
    ├── WidgetStepIndicator.ets          # 步骤指示器
    └── preview/                         # 设置页里的卡片预览
        ├── Preview1x2Card.ets           # Widget 配置预览 1x2 卡片
        ├── Preview1x2Content.ets        # Widget 配置预览 1x2 内容组件
        ├── Preview2x2MultiSlot.ets      # Widget 配置预览 2x2 多游戏布局
        ├── Preview2x2SingleGame.ets     # Widget 配置预览 2x2 单游戏内容
        ├── Preview2x4MultiSlot.ets      # Widget 配置预览 2x4 多游戏布局
        ├── Preview2x4SingleGame.ets     # Widget 配置预览 2x4 单游戏水平布局
        ├── Preview4x4MultiSlot.ets      # Widget 配置预览 4x4 多游戏布局
        ├── Preview4x4SingleGame.ets     # Widget 配置预览 4x4 单游戏内容
        ├── PreviewEmptyContent.ets      # Widget 配置预览空态内容
        ├── PreviewExpeditionAvatar.ets  # Widget 配置预览派遣头像（2x4 / 4x4 共享）
        └── PreviewExtraDataRow.ets      # Widget 配置预览额外数据行（2x2 / 2x4 / 4x4 共享）
```

### 4.13 `features/legal` — 功能模块（HAR）

首次启动的隐私同意流程，以及展示用户协议 / 隐私政策的 WebView 页。协议 HTML 放在 entry 的 `rawfile/legal/`。

| 项 | 内容 |
| --- | --- |
| 代码文件 | 7 个 `.ets` |
| 依赖 | core、basic |
| 对外导出 | 3 个（`Index.ets`） |
| 路由 | `WebView` |
| 本地测试 | PrivacyConsentViewModel |
| 资源 | `base/profile` 1 |

```
features/legal/src/main/ets/
├── model/                           # 数据模型
│   └── service/                     # 数据 / 业务服务（存储、网络、计算）
│       └── LegalPreferences.ets     # 隐私同意状态持久化
├── pages/                           # 页面
│   ├── PrivacyConsentPage.ets       # 首次启动隐私同意页
│   └── WebViewPage.ets              # 通用 WebView 页（协议、隐私政策）
├── utils/                           # 工具函数
│   └── LegalI18nUtil.ets            # 按系统语言返回协议 HTML 路径
├── viewmodel/                       # ViewModel
│   └── PrivacyConsentViewModel.ets  # 隐私同意 ViewModel（两步阅读）
└── views/                           # 页面内组件
    ├── PrivacyConsentFooter.ets     # 隐私页底部按钮
    └── PrivacyConsentWebView.ets    # 隐私页 Web 内容区
```

### 4.14 `features/verification` — 功能模块（HAR）

人机验证（Geetest）与设备指纹异常的统一处理，以及验证弹窗。

| 项 | 内容 |
| --- | --- |
| 代码文件 | 9 个 `.ets` |
| 依赖 | core、basic |
| 对外导出 | 6 个（`Index.ets`） |
| 路由 | 无（由其他页面直接嵌入或调用） |
| 本地测试 | 无 |
| 资源 | 无 |

```
features/verification/src/main/ets/
├── model/                         # 数据模型
│   ├── GeetestTriggerModel.ets    # Geetest 人机验证触发数据
│   └── service/                   # 数据 / 业务服务（存储、网络、计算）
│       ├── DeviceFpCenter.ets     # 设备指纹失效 / 账号异常统一处理（retcode 5003 / 10041）
│       ├── GeetestBridge.ets      # 注入 Web 页的 JS Bridge
│       └── GeetestCenter.ets      # 人机验证统一处理（retcode 1034 / 10035）
├── signals/                       # 全局信号
│   └── GeetestSignal.ets          # 人机验证全局信号
├── utils/                         # 工具函数
│   ├── GeetestDialogUtil.ets      # 弹出人机验证弹窗（showGeetestDialog）
│   └── GeetestHtmlUtil.ets        # 生成人机验证内嵌 HTML
└── views/                         # 页面内组件
    ├── GeetestDialog.ets          # 人机验证弹窗
    └── GeetestDialogTitleBar.ets  # Geetest 弹窗标题栏（标题 + 进度 + 关闭按钮）
```

## 5. 资源分布

- **entry**：只留配置文件要用的（Ability / 卡片名称与说明、权限说明、应用图标 `ic_app_logo`、`layered_image`）和协议 HTML（`rawfile/legal/`）。
- **common/widgetbase**：卡片页面用到的颜色（含深色）和字符串。
- **common/basic**：其余所有共用资源。功能模块目前没有自己的字符串 / 颜色 / 图片，只有路由表；按功能细拆放在 M1–M15 各模块重构时做。
- `ic_app_logo`、`black` 在 entry 和 basic 各有一份（entry 的给配置文件用，basic 的给功能代码用，内容相同）；`app_name` 的默认值在 AppScope 与 basic 各有一份。
- 2026-10-29 已删除所有未被引用的资源；`material_target_config_level_suffix` 暂未使用但保留（见第 6 节）。

## 6. 尚未解决的结构问题

| 问题 | 位置 | 处理时机 |
| --- | --- | --- |
| 6 个页面直接调用数据层服务（官方 MVVM 不允许）：LaunchPage、MainPage、TestPage、MyPage、PrivacyConsentPage、AppearanceSettingsPage；另有 material 4 个页面从服务文件导入枚举 `MaterialComputeResult`，枚举应移到 `model/` | entry / account / legal / settings / material | M1–M15（要改逻辑） |
| 两个重复的卡片日志类 `WidgetLog` 与 `WidgetLogger` | features/widget、common/widgetbase | M14（要改逻辑） |
| 4 组同名不同定义的类型（如 material 的 `MaterialItemRaw`） | material / widget / chardetail | M1–M15 |
| `MaterialCalcPage` 没有注册路由，页面不可达 | features/material | 已知 High 缺陷 |
| 星铁养成目标配置页把"级"写死为中文，预留的 `material_target_config_level_suffix` 未接入 | features/material | M1–M15 |
| 通知服务把包名写死为正式包，uat / mock 包上可能指向错误的应用 | features/notification | 复核 notification 文档时定级 |
| 资源未按功能拆分 | common/basic | M1–M15 |
| `entry/src/ohosTest` 里是 core 的测试 | entry | 不在本次范围 |

## 7. 新增文件放哪里

1. 只有一个功能用 → 放该功能模块，按第 3 节选目录。
2. 两个以上功能用 → 放 `common/basic`，并在它的 `Index.ets` 导出。
3. 桌面卡片页面要用 → 放 `common/widgetbase`，且只能用卡片支持的 API。
4. Ability、应用框架页、卡片页面 → 放 `entry`。
5. 一个模块要用另一个模块的内容 → 在自己的 `oh-package.json5` 直接声明依赖，并在对方 `Index.ets` 导出；不能形成循环依赖。
6. 新增模块 → 在工程级 `build-profile.json5` 的 `modules` 登记（四个 target 与 core 相同）。命令行构建用 `run.sh`，它会先执行 `ohpm install --all`。

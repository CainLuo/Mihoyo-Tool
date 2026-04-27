# 实现计划：char-detail-pages

## 概述

基于已确认的需求文档和设计文档，将原神角色详情页重构，并新增星穹铁道、绝区零角色详情页。三个页面共享英雄区布局规范，各自拥有独立的内容区结构和数据模型。所有实现遵循 MVVM 架构、HarmonyOS 开发规范和项目测试策略。

## 任务

- [x] 1. 扩展 CharDetailModels.ets，新增星铁/绝区零展示模型和路由参数
  - 在 `entry/src/main/ets/components/chardetail/CharDetailModels.ets` 中新增：
    - `CharDetailRouterParam`（accountId / roleUid / entityId）
    - `CharDetailRankItem`（pos / name / iconUrl / isActived）
    - `CharDetailHeroInfo`（charName / level）
    - 星铁专用：`StarRailCharDetailSkillMain`、`StarRailCharDetailSkillNode`、`StarRailCharDetailRelic`、`StarRailCharDetailEquip`、`StarRailCharDetailProperty`
    - 绝区零专用：`ZZZCharDetailSkill`、`ZZZCharDetailWeapon`、`ZZZSubStat`、`ZZZCharDetailEquip`、`ZZZSuitSummary`、`ZZZCharDetailProperty`
  - _需求：1.11、3.3、3.5、3.6、3.7、4.3、4.5、4.6、4.7_

- [x] 2. 新增路由常量并完成路由注册
  - [x] 2.1 在 `AppRoutes.ets` 中新增 `STARRAIL_CHARACTER_DETAIL` 和 `ZZZ_CHARACTER_DETAIL` 常量
    - _需求：3.14、4.15_
  - [x] 2.2 在 `custom_router_map.json` 中注册两个新路由条目
    - pageSourceFile 分别指向 `StarRailCharacterDetailBuilder.ets` 和 `ZZZCharacterDetailBuilder.ets`
    - _需求：3.14、4.15_
  - [x] 2.3 在 `entry/src/main/ets/pages/Index.ets` 中添加两个新路由的 `else if` 分支和对应 import
    - _需求：3.14、4.15_

- [x] 3. 重构 GenshinCharacterDetailViewModel
  - [x] 3.1 将 `GenshinCharacterDetailParam` 替换为 `CharDetailRouterParam`，更新 `init()` 方法签名
    - 确保 `init(accountId, roleUid, entityId)` 正确设置三个内部参数
    - _需求：2.1、2.2、2.3、2.4、2.5、2.6_
  - [ ]\* 3.2 为 GenshinCharacterDetailViewModel 编写属性测试（Property 1、3、5）
    - **Property 1：原神命座解析不丢失**（constellations_detail 数组长度不变）
    - **Property 3：原神武器解析 round-trip**（name/level/affix/rarity 与输入一致）
    - **Property 5：原神 viewState 状态不变式**（始终为合法枚举值）
    - 测试文件：`entry/src/test/GenshinCharDetailParser.test.ets`
    - **Validates: Requirements 2.2, 2.4, 2.12, 5.1, 5.2, 5.10**

- [x] 4. 新增 StarRailCharacterDetailViewModel
  - [x] 4.1 创建 `entry/src/main/ets/viewmodel/StarRailCharacterDetailViewModel.ets`
    - 实现 `init(accountId, roleUid, entityId)` 方法
    - 实现 `loadData()` 方法，从 `StarRailRepository.getAvatarDetail()` 读取 rawJson
    - 实现 `parseRawJson()` 方法，解析 ranks / skills / equip / relics / ornaments / properties
    - 容错：rawJson 为空 → EMPTY，JSON 解析失败 → ERROR
    - _需求：3.1、3.2、3.3、3.4、3.5、3.6、3.7、5.3、5.4_
  - [ ]\* 4.2 为 StarRailCharacterDetailViewModel 编写单元测试
    - 验证初始 viewState 为 LOADING
    - 验证 `init()` 正确设置三个参数
    - 验证 rawJson 为空字符串时 viewState=EMPTY
    - 验证 rawJson 为无效 JSON 时 viewState=ERROR
    - 测试文件：`entry/src/test/StarRailCharacterDetailViewModel.test.ets`
    - **Validates: Requirements 3.1, 5.3, 5.4, 6.3, 6.4**
  - [ ]\* 4.3 为 StarRailCharacterDetailViewModel 编写属性测试（Property 6、7）
    - **Property 6：星铁行迹分组不丢失**（type1+type2+type3 总数 === skills 数组长度）
    - **Property 7：星铁 viewState 状态不变式**
    - 测试文件：`entry/src/test/StarRailCharDetailParser.test.ets`
    - **Validates: Requirements 3.3, 3.15, 5.3, 5.4**

- [x] 5. 新增 ZZZCharacterDetailViewModel
  - [x] 5.1 创建 `entry/src/main/ets/viewmodel/ZZZCharacterDetailViewModel.ets`
    - 实现 `init(accountId, roleUid, entityId)` 方法
    - 实现 `loadData()` 方法，从 `ZZZRepository.getAvatarDetail()` 读取 rawJson
    - 实现 `parseRawJson()` 方法，解析 ranks / skills / weapon / equip / properties
    - 实现套装摘要统计（按 suitName 分组，统计件数和 suitOwn）
    - 容错：rawJson 为空 → EMPTY，JSON 解析失败 → ERROR
    - _需求：4.1、4.2、4.3、4.4、4.5、4.6、4.7、5.5、5.6_
  - [ ]\* 5.2 为 ZZZCharacterDetailViewModel 编写单元测试
    - 验证初始 viewState 为 LOADING
    - 验证 `init()` 正确设置三个参数
    - 验证 rawJson 为空字符串时 viewState=EMPTY
    - 验证 rawJson 为无效 JSON 时 viewState=ERROR
    - 测试文件：`entry/src/test/ZZZCharacterDetailViewModel.test.ets`
    - **Validates: Requirements 4.1, 5.5, 5.6, 6.5, 6.6**
  - [ ]\* 5.3 为 ZZZCharacterDetailViewModel 编写属性测试（Property 8、9）
    - **Property 8：绝区零套装统计不丢失**（套装摘要件数之和 === equip 中 suitName 非空的元素数量）
    - **Property 9：绝区零 viewState 状态不变式**
    - 测试文件：`entry/src/test/ZZZCharDetailParser.test.ets`
    - **Validates: Requirements 4.6, 4.16, 5.5, 5.6**

- [x] 6. 检查点 — 确保所有测试通过
  - 确保所有测试通过，如有问题请向用户反馈。

- [x] 7. 新增共用英雄区组件 CharDetailHeroPanel
  - [x] 7.1 创建 `entry/src/main/ets/components/chardetail/CharDetailHeroPanel.ets`
    - 接收 `mode: HeroPanelMode`、`imageUrl`、`rankList: CharDetailRankItem[]`、`heroInfo: CharDetailHeroInfo`、`accentColor`
    - 实现 PORTRAIT / LANDSCAPE / WIDE 三种布局模式
    - 立绘以 `ImageFit.Cover` 铺满英雄区背景
    - 左侧叠加从左到右的强渐变遮罩（使用 `gradientAngle90` token）
    - 底部叠加从下到上的渐变遮罩（使用 `gradientAngle0` token）
    - 命座/影画列渲染在左侧，顶部对齐，纵向排列，共 6 个图标
    - 已激活：高亮样式（带色彩背景和发光阴影）；未激活：低透明度背景 + SVG 锁图标
    - 角色名、等级等基础信息渲染在左下角
    - _需求：1.1、1.2、1.3、1.4、1.5、1.6、1.7、1.8_

- [x] 8. 新增 CharDetailLoadingView 组件
  - 创建 `entry/src/main/ets/components/chardetail/CharDetailLoadingView.ets`
  - 显示居中的 `LoadingProgress` 组件
  - 添加 `@Preview` 预览状态
  - _需求：1.12_

- [x] 9. 重构原神角色详情页
  - [x] 9.1 重构 `entry/src/main/ets/pages/GenshinCharacterDetail.ets`
    - 使用 `CharDetailRouterParam` 替换旧路由参数
    - 根据窗口宽高比和断点自动选择 `HeroPanelMode`（宽≤高→PORTRAIT，宽>高且xs→LANDSCAPE，sm+→WIDE）
    - 集成 `CharDetailHeroPanel`、`CharDetailLoadingView`、`CharDetailEmptyView`
    - 英雄区左下角显示角色名、等级、好感度
    - _需求：1.9、1.10、1.11、1.12、1.13、2.7、2.11_
  - [x] 9.2 创建 `entry/src/main/ets/components/chardetail/GenshinCharDetailContent.ets`
    - 内容区按顺序渲染：技能 → 武器 → 属性 → 圣遗物
    - 圣遗物以 2 列网格布局渲染，每件显示图标、套装名、等级、主词条、副词条
    - 武器为空时显示"未装备武器"占位卡片（虚线边框 + 锁图标）
    - 圣遗物为空时为每个位置显示对应位置名称的占位卡片
    - _需求：2.7、2.8、2.9、2.10、5.7、5.8、5.9_
  - [x] 9.3 更新 `GenshinCharacterDetailBuilder.ets`，使用 `CharDetailRouterParam` 接收路由参数
    - _需求：1.10_

- [x] 10. 新增星穹铁道角色详情页
  - [x] 10.1 创建 `entry/src/main/ets/pages/StarRailCharacterDetail.ets`
    - 使用 `HdsNavDestination` 作为根容器，系统 TitleBar 显示页面标题
    - 根据窗口宽高比和断点自动选择 `HeroPanelMode`
    - 集成 `CharDetailHeroPanel`（命座列）、`CharDetailLoadingView`、`CharDetailEmptyView`
    - 英雄区左下角显示角色名、等级、命座数、稀有度（★数）
    - _需求：1.9、1.10、1.11、1.12、1.13、3.8、3.13_
  - [x] 10.2 创建 `entry/src/main/ets/components/chardetail/StarRailCharDetailContent.ets`
    - 内容区按顺序渲染：行迹 → 光锥 → 属性 → 遗器
    - 行迹分三组：主技能（type2，大图标+等级+名称）、额外能力（type3，中图标激活状态）、属性加成（type1，小图标激活状态），均使用 flex-wrap 自动换行
    - 遗器（4件）和饰品（2件）分两组以 2 列网格渲染
    - 光锥为空时显示"未装备光锥"占位卡片
    - 遗器/饰品为空时为各位置显示对应位置名称的占位卡片
    - **section 标题在卡片外面**；卡片格式：图标+名称+强化等级 / 主词条名（高亮色）+值（粗体）/ 副词条列表（名称左，值右）
    - _需求：3.8、3.9、3.10、3.11、3.12、5.7、5.8、5.9_
  - [x] 10.3 创建 `entry/src/main/ets/pages/router/StarRailCharacterDetailBuilder.ets`
    - 使用 `HdsNavDestination` + `.titleBar()` 渲染系统标题栏
    - 接收 `CharDetailRouterParam` 路由参数
    - _需求：3.14_

- [x] 11. 新增绝区零角色详情页
  - [x] 11.1 创建 `entry/src/main/ets/pages/ZZZCharacterDetail.ets`
    - 使用 `HdsNavDestination` 作为根容器，系统 TitleBar 显示页面标题
    - 根据窗口宽高比和断点自动选择 `HeroPanelMode`
    - 集成 `CharDetailHeroPanel`（影画列，方形图标）、`CharDetailLoadingView`、`CharDetailEmptyView`
    - 英雄区左下角显示代理人名称、全名、等级、稀有度、影画数
    - _需求：1.9、1.10、1.11、1.12、1.13、4.8、4.14_
  - [x] 11.2 创建 `entry/src/main/ets/components/chardetail/ZZZCharDetailContent.ets`
    - 内容区按顺序渲染：技能 → 音擎 → 属性 → 驱动盘
    - 技能按 skill_type 分组渲染：有 iconUrl 时显示圆形图标，无 iconUrl 时显示对应 skill_type 颜色的彩色圆点
    - 驱动盘区块顶部渲染套装摘要卡片（套装名、实际件数/套装总件数、2件/4件激活状态高亮）
    - 6 件驱动盘以 2 列网格渲染；副词条 `valid=true` 时以高亮样式（金色边框背景）渲染
    - 音擎为空时显示"未装备音擎"占位卡片
    - 驱动盘为空时为 6 个位置各显示对应位置编号的占位卡片
    - _需求：4.8、4.9、4.10、4.11、4.12、4.13、5.7、5.8、5.9_
  - [x] 11.3 创建 `entry/src/main/ets/pages/router/ZZZCharacterDetailBuilder.ets`
    - 使用 `HdsNavDestination` + `.titleBar()` 渲染系统标题栏
    - 接收 `CharDetailRouterParam` 路由参数
    - _需求：4.15_

- [x] 12. 更新 Characters 页，接入三个详情页路由
  - 在 `entry/src/main/ets/pages/Characters.ets` 中，点击角色卡片时根据 `GameDataSummary.gameId` 字段分发路由：
    - `gameId === 'genshin'` → `RouterUtil.push(AppRoutes.GENSHIN_CHARACTER_DETAIL, param)`
    - `gameId === 'starrail'` → `RouterUtil.push(AppRoutes.STARRAIL_CHARACTER_DETAIL, param)`
    - `gameId === 'zzz'` → `RouterUtil.push(AppRoutes.ZZZ_CHARACTER_DETAIL, param)`
    - 其他 gameId（如 honkai3）→ 暂不跳转，静默忽略
  - 传递 `CharDetailRouterParam`（accountId / roleUid / entityId），其中 entityId 取 `GameDataSummary.entityId`（即 avatarId）
  - 禁止将 gameId 直接写成字符串字面量，必须使用 `GAME_GENSHIN`、`GAME_STARRAIL`、`GAME_ZZZ` 常量
  - _需求：1.11_

- [x] 13. 检查点 — 确保所有测试通过
  - 确保所有测试通过，如有问题请向用户反馈。

- [ ] 14. 更新测试注册文件
  - [ ] 14.1 更新 `entry/src/test/List.test.ets`，注册新增的单元测试和属性测试
    - 新增：`StarRailCharacterDetailViewModel.test`、`ZZZCharacterDetailViewModel.test`
    - 新增：`GenshinCharDetailParser.test`、`StarRailCharDetailParser.test`、`ZZZCharDetailParser.test`
    - _需求：6.1、6.2、6.3、6.4、6.5、6.6_
  - [ ] 14.2 更新 `entry/src/ohosTest/ets/test/List.test.ets`，注册新增的 UI 测试
    - 新增：`StarRailCharacterDetailPageTest.test`、`ZZZCharacterDetailPageTest.test`
    - _需求：6.7_
  - [ ]\* 14.3 更新 `.kiro/steering/testing-entry-pages.md`，补充 StarRailCharacterDetail 和 ZZZCharacterDetail 的 ViewModel 单元测试用例和 UI 测试用例
    - _需求：6.7_

- [x] 15. 最终检查点 — 确保所有测试通过
  - 确保所有测试通过，如有问题请向用户反馈。

## 备注

- 标有 `*` 的子任务为可选测试任务，可跳过以加快 MVP 进度
- 每个任务均引用具体需求条目，确保可追溯性
- 检查点任务确保增量验证，避免积累问题
- 属性测试验证设计文档中定义的正确性属性（Property 1-9）
- 单元测试验证 ViewModel 状态初始化和纯函数逻辑

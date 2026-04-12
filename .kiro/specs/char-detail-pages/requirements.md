# 需求文档

## 简介

基于 v1.0 原型重构原神角色详情页，并新增星穹铁道、绝区零角色详情页。三个页面共享英雄区布局规范（立绘铺满、命座/影画列左侧竖排、角色信息左下角、左侧强渐变），各自拥有独立的内容区结构和数据模型。所有页面遵循 MVVM 架构，使用 HdsNavDestination + 系统 TitleBar，颜色/间距从 ThemeManager.current 读取，字符串用 `$r('app.string.xxx')`。

---

## 词汇表

- **CharDetailPage**：角色详情页（泛指三个游戏的详情页）
- **HeroPanel**：英雄区，包含立绘背景、命座/影画列、角色基础信息
- **ContentArea**：内容区，可垂直滚动，包含技能/行迹、武器/光锥/音擎、属性、圣遗物/遗器/驱动盘
- **GenshinCharacterDetail**：原神角色详情页（已有实现，本次重构）
- **StarRailCharacterDetail**：星穹铁道角色详情页（新增）
- **ZZZCharacterDetail**：绝区零角色详情页（新增）
- **GenshinCharacterDetailViewModel**：原神角色详情 ViewModel（已有，本次重构）
- **StarRailCharacterDetailViewModel**：星穹铁道角色详情 ViewModel（新增）
- **ZZZCharacterDetailViewModel**：绝区零角色详情 ViewModel（新增）
- **GenshinRepository**：原神数据仓库，提供 `getAvatarDetail(accountId, roleUid, avatarId)` 方法
- **StarRailRepository**：星穹铁道数据仓库，提供 `getAvatarDetail(accountId, roleUid, avatarId)` 方法
- **ZZZRepository**：绝区零数据仓库，提供 `getAvatarDetail(accountId, roleUid, avatarId)` 方法
- **rawJson**：DB 中存储的完整 API 响应 JSON 字符串
- **ThemeManager**：主题管理器，所有颜色/间距 token 的来源
- **ViewState**：页面加载状态枚举（LOADING / EMPTY / DATA / ERROR）
- **AppRoutes**：全局路由常量类
- **HeroPanelMode**：英雄区布局模式枚举（WIDE / PORTRAIT / LANDSCAPE）
- **point_type**：星穹铁道行迹节点类型（1=属性加成，2=主技能，3=额外能力）
- **skill_type**：绝区零技能分组类型（0=普攻，1=特殊技，2=闪避，3=连携技，5=核心被动，6=支援技）
- **valid**：绝区零驱动盘副词条有效性标记，`true` 时高亮显示

---

## 需求

### 需求 1：三游戏共同英雄区布局

**用户故事：** 作为玩家，我希望在任意游戏的角色详情页都能看到立绘铺满英雄区、命座/影画列在左侧竖排、角色名等信息在左下角，以便快速识别角色。

#### 验收标准

1. **HeroPanel** 应将角色立绘以 `background-size: cover` 方式铺满英雄区背景。
2. **HeroPanel** 应在英雄区左侧叠加从左到右的强渐变遮罩，确保左侧文字和图标可读。
3. **HeroPanel** 应在英雄区底部叠加从下到上的渐变遮罩，确保底部文字可读。
4. **HeroPanel** 应将命座列（原神/星穹铁道）或影画列（绝区零）渲染在英雄区左侧，顶部对齐，纵向排列，共 6 个图标。
5. **HeroPanel** 应将角色名、等级等基础信息渲染在英雄区左下角。
6. 当命座/影画已激活时，**HeroPanel** 应以高亮样式（带色彩背景和发光阴影）渲染对应图标。
7. 当命座/影画未激活时，**HeroPanel** 应以灰暗样式（低透明度背景）渲染对应图标，并叠加 SVG 锁图标。
8. **HeroPanel** 应支持 PORTRAIT（手机竖屏）、LANDSCAPE（手机横屏）、WIDE（平板/PC）三种布局模式，通过 **HeroPanelMode** 枚举切换。
9. **CharDetailPage** 应根据当前窗口宽高比和断点自动选择 HeroPanelMode：宽度 ≤ 高度时使用 PORTRAIT，宽度 > 高度且断点为 xs 时使用 LANDSCAPE，断点为 sm 及以上时使用 WIDE。
10. **CharDetailPage** 应使用 **HdsNavDestination** 作为根容器，并通过系统 TitleBar 显示页面标题。
11. **CharDetailPage** 应从 **Characters** 页接收 `accountId`、`roleUid`、`entityId`（avatarId）三个参数。
12. **Characters** 页点击角色卡片时，应根据 `GameDataSummary.gameId` 字段分发路由：`gameId === 'genshin'` 跳转到 **GenshinCharacterDetail**，`gameId === 'starrail'` 跳转到 **StarRailCharacterDetail**，`gameId === 'zzz'` 跳转到 **ZZZCharacterDetail**，其他 gameId 静默忽略，不跳转。
13. 当数据加载中时，**CharDetailPage** 应显示 **CharDetailLoadingView**。
14. 当数据为空或加载失败时，**CharDetailPage** 应显示 **CharDetailEmptyView**。

---

### 需求 2：原神角色详情页重构

**用户故事：** 作为原神玩家，我希望角色详情页按照 v1.0 原型重构，展示技能、武器、属性、圣遗物，并支持命座切换控制，以便准确查看角色配装。

#### 验收标准

1. **GenshinCharacterDetailViewModel** 应从 **GenshinRepository** 的 `getAvatarDetail(accountId, roleUid, avatarId)` 方法读取 **rawJson**，解析为展示模型。
2. **GenshinCharacterDetailViewModel** 应解析 rawJson 中的 `constellations` 字段，生成包含 `pos`、`name`、`iconUrl`、`effect`、`isActived` 的命座列表（共 6 个）。
3. **GenshinCharacterDetailViewModel** 应解析 rawJson 中的 `skills` 字段，取 skill_type=1 的前 3 个技能（普攻/战技/爆发），生成包含 `iconUrl`、`level`、`name` 的技能列表。
4. **GenshinCharacterDetailViewModel** 应解析 rawJson 中的 `weapon` 字段，生成包含 `name`、`iconUrl`、`level`、`affix`、`rarity`、`baseAtk`、`subLabel`、`subVal` 的武器模型；当 `weapon` 为 null 时，应将武器模型置为空状态。
5. **GenshinCharacterDetailViewModel** 应解析 rawJson 中的 `relics` 字段，生成最多 5 件圣遗物，每件包含 `pos`、`iconUrl`、`setName`、`level`、`rarity`、`mainStatLabel`、`mainStatValue`、`subStats`（最多 4 条副词条）。
6. **GenshinCharacterDetailViewModel** 应解析 rawJson 中的 `selected_properties` 字段，按 HP → ATK → DEF → EM → 暴击率 → 暴击伤害 → 充能效率 → 治疗加成的顺序生成属性列表，暴击率和暴击伤害标记为高亮。
7. **GenshinCharacterDetail** 应在内容区按以下顺序渲染各区块：技能 → 武器 → 属性 → 圣遗物。
8. **GenshinCharacterDetail** 应将圣遗物以 2 列网格布局渲染，每件显示图标、套装名、等级、主词条、副词条。
9. 当武器数据为空时，**GenshinCharacterDetail** 应显示"未装备武器"占位卡片（虚线边框 + 锁图标）。
10. 当圣遗物数据为空时，**GenshinCharacterDetail** 应为每个位置显示对应位置名称的占位卡片（虚线边框 + 锁图标）。
11. **GenshinCharacterDetail** 应在英雄区左下角显示角色名、等级、好感度。
12. 对于所有有效的 rawJson 字符串，**GenshinCharacterDetailViewModel** 解析武器和圣遗物数据后，应能生成与原始数据等价的展示模型（数据不丢失）。

---

### 需求 3：星穹铁道角色详情页（新增）

**用户故事：** 作为星穹铁道玩家，我希望能查看角色的行迹、光锥、属性、遗器，并支持命座和遗器切换控制，以便了解角色的完整配装。

#### 验收标准

1. **StarRailCharacterDetailViewModel** 应从 **StarRailRepository** 的 `getAvatarDetail(accountId, roleUid, avatarId)` 方法读取 **rawJson**，解析为展示模型。
2. **StarRailCharacterDetailViewModel** 应解析 rawJson 中的 `ranks` 字段，生成包含 `pos`、`name`、`iconUrl`、`isActived`（pos ≤ 当前命座数时为 true）的命座列表（共 6 个）。
3. **StarRailCharacterDetailViewModel** 应解析 rawJson 中的 `skills` 字段，按 `point_type` 分三组：`type2`（主技能，含 `name`、`level`、`iconUrl`）、`type3`（额外能力，含 `iconUrl`、`activated`）、`type1`（属性加成，含 `iconUrl`、`activated`）。
4. **StarRailCharacterDetailViewModel** 应解析 rawJson 中的 `equip` 字段，生成包含 `name`、`iconUrl`、`level`、`rank`、`rarity` 的光锥模型；当 `equip` 为 null 时，应将光锥模型置为空状态。
5. **StarRailCharacterDetailViewModel** 应解析 rawJson 中的 `relics` 字段（4 件：头/手/躯/脚），每件包含 `pos`、`name`、`iconUrl`、`level`、`rarity`、`main`（name+value）、`subs`（最多 4 条）。
6. **StarRailCharacterDetailViewModel** 应解析 rawJson 中的 `ornaments` 字段（2 件：位面球/连结绳），数据结构与 relics 相同。
7. **StarRailCharacterDetailViewModel** 应解析 rawJson 中的 `properties` 字段，生成属性列表，每条包含 `name` 和 `final`。
8. **StarRailCharacterDetail** 应在内容区按以下顺序渲染各区块：行迹 → 光锥 → 属性 → 遗器。
9. **StarRailCharacterDetail** 应将行迹区块分三组渲染：主技能（type2）以大图标 + 等级 + 名称展示，额外能力（type3）以中图标展示激活/未激活状态，属性加成（type1）以小图标展示激活/未激活状态，三组均使用 flex-wrap 自动换行，不限制节点数量。
10. **StarRailCharacterDetail** 应将遗器（4 件）和饰品（2 件）分两组以 2 列网格渲染，每件显示图标、名称、等级、主词条、副词条。
11. 当光锥数据为空时，**StarRailCharacterDetail** 应显示"未装备光锥"占位卡片。
12. 当遗器数据为空时，**StarRailCharacterDetail** 应为头/手/躯/脚四个位置各显示对应位置名称的占位卡片；当饰品数据为空时，应为位面球/连结绳两个位置各显示对应位置名称的占位卡片。
13. **StarRailCharacterDetail** 应在英雄区左下角显示角色名、等级、命座数、稀有度（★数）。
14. **StarRailCharacterDetail** 应新增路由常量 `AppRoutes.STARRAIL_CHARACTER_DETAIL`，并在 `custom_router_map.json` 和 `Index.ets` 中完成注册。
15. 对于所有有效的 rawJson 字符串，**StarRailCharacterDetailViewModel** 解析 skills 字段后，type1/type2/type3 三组节点的总数量应等于原始 skills 数组的长度（不丢失行迹节点）。

---

### 需求 4：绝区零角色详情页（新增）

**用户故事：** 作为绝区零玩家，我希望能查看代理人的技能、音擎、属性、驱动盘，并支持影画和驱动盘切换控制，以便了解代理人的完整配装。

#### 验收标准

1. **ZZZCharacterDetailViewModel** 应从 **ZZZRepository** 的 `getAvatarDetail(accountId, roleUid, avatarId)` 方法读取 **rawJson**，解析为展示模型。
2. **ZZZCharacterDetailViewModel** 应解析 rawJson 中的 `ranks` 字段，生成包含 `pos`、`name`、`isActived`（pos ≤ 当前影画数时为 true）的影画列表（共 6 个，方形图标）。
3. **ZZZCharacterDetailViewModel** 应解析 rawJson 中的 `skills` 字段，按 `skill_type` 分组，每组包含 `type`（skill_type 值）、`name`（取 `items[0].title`）、`level`、`iconUrl`（有 icon 字段时使用，无则为空字符串）。
4. **ZZZCharacterDetailViewModel** 应解析 rawJson 中的 `weapon` 字段，生成包含 `name`、`iconUrl`、`level`、`star`（精炼等级）、`rarity`、`mainProp`（name+value）、`subProp`（name+value）、`talentTitle` 的音擎模型；当 `weapon` 为 null 时，应将音擎模型置为空状态。
5. **ZZZCharacterDetailViewModel** 应解析 rawJson 中的 `equip` 字段（6 件驱动盘），每件包含 `pos`、`name`、`iconUrl`、`level`、`rarity`、`suitName`、`suitOwn`（套装总件数）、`main`（name+value）、`subs`（最多 4 条，每条含 `name`、`value`、`valid` 布尔值）。
6. **ZZZCharacterDetailViewModel** 应从 `equip` 字段统计套装摘要，按套装名分组，记录每个套装的实际装备件数和套装总件数（suitOwn）。
7. **ZZZCharacterDetailViewModel** 应解析 rawJson 中的 `properties` 字段，生成属性列表，每条包含 `name` 和 `final`。
8. **ZZZCharacterDetail** 应在内容区按以下顺序渲染各区块：技能 → 音擎 → 属性 → 驱动盘。
9. **ZZZCharacterDetail** 应将技能按 skill_type 分组渲染：当技能有 iconUrl 时显示圆形图标，当技能无 iconUrl 时显示对应 skill_type 颜色的彩色圆点；每条技能显示名称和等级。
10. **ZZZCharacterDetail** 应在驱动盘区块顶部渲染套装摘要卡片，显示每个套装名称、实际件数/套装总件数，以及 2 件和 4 件激活状态（激活时高亮）。
11. **ZZZCharacterDetail** 应将 6 件驱动盘以 2 列网格渲染，每件显示图标、名称、等级、主词条、副词条；当副词条的 `valid` 为 true 时，应以高亮样式（金色边框背景）渲染该副词条。
12. 当音擎数据为空时，**ZZZCharacterDetail** 应显示"未装备音擎"占位卡片。
13. 当驱动盘数据为空时，**ZZZCharacterDetail** 应为 6 个位置各显示对应位置编号的占位卡片。
14. **ZZZCharacterDetail** 应在英雄区左下角显示代理人名称、全名、等级、稀有度、影画数。
15. **ZZZCharacterDetail** 应新增路由常量 `AppRoutes.ZZZ_CHARACTER_DETAIL`，并在 `custom_router_map.json` 和 `Index.ets` 中完成注册。
16. 对于所有有效的 rawJson 字符串，**ZZZCharacterDetailViewModel** 解析 equip 字段后，套装摘要中所有套装的件数之和应等于 equip 数组中 suitName 非空的元素数量（套装统计不丢失）。

---

### 需求 5：ViewModel 数据解析容错

**用户故事：** 作为开发者，我希望三个 ViewModel 在 rawJson 为空或格式异常时能优雅降级，不崩溃，以便保证应用稳定性。

#### 验收标准

1. 当 rawJson 为空字符串时，**GenshinCharacterDetailViewModel** 应将 viewState 设置为 ViewState.EMPTY，不抛出异常。
2. 当 rawJson 为无效 JSON 时，**GenshinCharacterDetailViewModel** 应将 viewState 设置为 ViewState.ERROR，不抛出异常。
3. 当 rawJson 为空字符串时，**StarRailCharacterDetailViewModel** 应将 viewState 设置为 ViewState.EMPTY，不抛出异常。
4. 当 rawJson 为无效 JSON 时，**StarRailCharacterDetailViewModel** 应将 viewState 设置为 ViewState.ERROR，不抛出异常。
5. 当 rawJson 为空字符串时，**ZZZCharacterDetailViewModel** 应将 viewState 设置为 ViewState.EMPTY，不抛出异常。
6. 当 rawJson 为无效 JSON 时，**ZZZCharacterDetailViewModel** 应将 viewState 设置为 ViewState.ERROR，不抛出异常。
7. 当圣遗物/遗器/驱动盘数量不足预期时，**CharDetailPage** 应只渲染实际存在的件数，不崩溃。
8. 当技能/行迹数量为 0 时，**CharDetailPage** 应显示空的技能区块，不崩溃。
9. 当武器/光锥/音擎图标 URL 为空字符串时，**CharDetailPage** 应显示占位色块，不崩溃。
10. 对于所有 rawJson 输入，**GenshinCharacterDetailViewModel** 的 viewState 应始终为 LOADING、EMPTY、DATA、ERROR 之一（状态不变式）。

---

### 需求 6：测试覆盖

**用户故事：** 作为开发者，我希望三个 ViewModel 的核心解析逻辑有单元测试覆盖，以便在重构时快速发现回归问题。

#### 验收标准

1. **GenshinCharacterDetailViewModel** 测试套件应验证 `init(accountId, roleUid, avatarId)` 能正确设置三个内部参数。
2. **GenshinCharacterDetailViewModel** 测试套件应验证 `propertyTypeToResource` 对已知属性类型返回正确的 Resource，对未知类型返回 null。
3. **StarRailCharacterDetailViewModel** 测试套件应验证初始 viewState 为 ViewState.LOADING。
4. **StarRailCharacterDetailViewModel** 测试套件应验证 `init(accountId, roleUid, avatarId)` 能正确设置三个内部参数。
5. **ZZZCharacterDetailViewModel** 测试套件应验证初始 viewState 为 ViewState.LOADING。
6. **ZZZCharacterDetailViewModel** 测试套件应验证 `init(accountId, roleUid, avatarId)` 能正确设置三个内部参数。
7. **testing-entry-pages.md** 指导文档应更新，补充 StarRailCharacterDetail 和 ZZZCharacterDetail 页面的 ViewModel 单元测试用例和 UI 测试用例。

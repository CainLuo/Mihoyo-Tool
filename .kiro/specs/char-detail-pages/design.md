# 技术设计文档：char-detail-pages

## 概述

基于 v1.0 原型重构原神角色详情页，并新增星穹铁道、绝区零角色详情页。三个页面共享英雄区布局规范（立绘铺满、命座/影画列左侧竖排、角色信息左下角、左侧强渐变），各自拥有独立的内容区结构和数据模型。

所有页面遵循 MVVM 架构，使用 `HdsNavDestination` + 系统 TitleBar，颜色/间距从 `ThemeManager.current` 读取，字符串用 `$r('app.string.xxx')`。

---

## 架构

### 整体数据流

```
Characters 页
  └─ RouterUtil.push(AppRoutes.GENSHIN_CHARACTER_DETAIL, param)
       └─ GenshinCharacterDetailBuilder
            └─ HdsNavDestination
                 └─ GenshinCharacterDetail (View)
                      └─ GenshinCharacterDetailViewModel
                           └─ CoreInitializer.genshinRepository.getAvatarDetail()
                                └─ GenshinCharacterDetailRow.rawJson
                                     └─ parseRawJson() → GenshinCharDetailData
```

星铁/绝区零路径相同，分别对应各自的 Repository 和 ViewModel。

### MVVM 分层

```
View 层（pages/ + components/chardetail/）
  ├── GenshinCharacterDetail.ets          ← 原神详情页（重构）
  ├── StarRailCharacterDetail.ets         ← 星铁详情页（新增）
  ├── ZZZCharacterDetail.ets              ← 绝区零详情页（新增）
  └── components/chardetail/
       ├── CharDetailHeroPanel.ets        ← 三游戏共用英雄区
       ├── GenshinCharDetailContent.ets   ← 原神内容区
       ├── StarRailCharDetailContent.ets  ← 星铁内容区
       ├── ZZZCharDetailContent.ets       ← 绝区零内容区
       ├── CharDetailEmptyView.ets        ← 空态（已有）
       └── CharDetailLoadingView.ets      ← 加载态（已有或新增）

ViewModel 层（viewmodel/）
  ├── GenshinCharacterDetailViewModel.ets  ← 重构
  ├── StarRailCharacterDetailViewModel.ets ← 新增
  └── ZZZCharacterDetailViewModel.ets      ← 新增

路由层（pages/router/）
  ├── GenshinCharacterDetailBuilder.ets    ← 已有，可能需更新
  ├── StarRailCharacterDetailBuilder.ets   ← 新增
  └── ZZZCharacterDetailBuilder.ets        ← 新增

Model 层（core，已有）
  ├── GenshinRepository.getAvatarDetail()
  ├── StarRailRepository.getAvatarDetail()
  └── ZZZRepository.getAvatarDetail()
```

---

## 组件与接口

### 组件树

```
GenshinCharacterDetail
├── CharDetailHeroPanel
│   ├── [背景立绘 div]
│   ├── [左侧渐变遮罩]
│   ├── [底部渐变遮罩]
│   ├── [命座列 Column × 6]
│   └── [角色信息 Column（左下角）]
├── CharDetailLoadingView（viewState=LOADING）
├── CharDetailEmptyView（viewState=EMPTY/ERROR）
└── GenshinCharDetailContent（viewState=DATA）
    ├── [技能区块]
    ├── [武器区块]
    ├── [属性区块]
    └── [圣遗物区块（2列网格）]

StarRailCharacterDetail
├── CharDetailHeroPanel（同上）
├── CharDetailLoadingView
├── CharDetailEmptyView
└── StarRailCharDetailContent
    ├── [行迹区块（三组：主技能/额外能力/属性加成）]
    ├── [光锥区块]
    ├── [属性区块]
    └── [遗器区块（4件）+ 饰品区块（2件）]

> **UI 规范（2026-04-11 更新）**：三游戏 section 标题均在卡片外面。遗器/驱动盘/圣遗物卡片格式统一：顶部图标+名称+强化等级标签，主词条名（高亮色）+主词条值（粗体）+分割线，副词条列表（名称左对齐，数值右对齐）。

ZZZCharacterDetail
├── CharDetailHeroPanel（影画列，方形图标）
├── CharDetailLoadingView
├── CharDetailEmptyView
└── ZZZCharDetailContent
    ├── [技能区块（按 skill_type 分组）]
    ├── [音擎区块]
    ├── [属性区块]
    └── [驱动盘区块（套装摘要 + 6件2列网格）]
```

### CharDetailHeroPanel 接口

```typescript
@ComponentV2
struct CharDetailHeroPanel {
  @Param mode: HeroPanelMode = HeroPanelMode.PORTRAIT
  @Param imageUrl: string = ''
  @Param rankList: CharDetailRankItem[] = []
  @Param heroInfo: CharDetailHeroInfo = new CharDetailHeroInfo()
  @Param accentColor: Resource = $r('app.color.accent_primary')
}
```

`HeroPanelMode` 枚举（已有，位于 `entry/src/main/ets/constants/HeroPanelMode.ets`）：

- `PORTRAIT`：手机竖屏，英雄区占页面高度约 42%，内容区垂直滚动
- `LANDSCAPE`：手机横屏，英雄区固定宽度（约 200vp）在左侧，内容区在右侧滚动
- `WIDE`：平板/PC，英雄区占左侧约 40%，内容区在右侧滚动

### 路由参数

```typescript
// CharDetailModels.ets 中新增
export class CharDetailRouterParam {
  accountId: number = 0;
  roleUid: string = "";
  entityId: string = ""; // avatarId
}
```

### ViewModel 公共接口

三个 ViewModel 均遵循以下模式：

```typescript
@ObservedV2
export class XxxCharacterDetailViewModel {
  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace data: XxxCharDetailData | null = null;

  private accountId: number = 0;
  private roleUid: string = "";
  private entityId: string = "";

  init(accountId: number, roleUid: string, entityId: string): void;
  async loadData(): Promise<void>;
  private parseRawJson(rawJson: string): void;
}
```

---

## 数据模型

### CharDetailModels.ets 扩展

在现有模型基础上新增以下类型：

```typescript
// ── 路由参数 ──────────────────────────────────────────────────
export class CharDetailRouterParam {
  accountId: number = 0;
  roleUid: string = "";
  entityId: string = "";
}

// ── 英雄区共用模型 ────────────────────────────────────────────
export class CharDetailRankItem {
  pos: number = 0;
  name: string = "";
  iconUrl: string = "";
  isActived: boolean = false;
}

export class CharDetailHeroInfo {
  charName: string = "";
  level: number = 0;
  // 游戏特定字段通过子类扩展或直接在 HeroPanel 中用 @Param 传入
}

// ── 星铁专用模型 ──────────────────────────────────────────────
export class StarRailCharDetailSkillMain {
  name: string = "";
  level: number = 0;
  iconUrl: string = "";
}

export class StarRailCharDetailSkillNode {
  iconUrl: string = "";
  activated: boolean = false;
}

export class StarRailCharDetailRelic {
  pos: number = 0;
  name: string = "";
  iconUrl: string = "";
  level: number = 0;
  rarity: number = 5;
  mainName: string = "";
  mainValue: string = "";
  subs: RelicSubStat[] = [];
}

export class StarRailCharDetailEquip {
  name: string = "";
  iconUrl: string = "";
  level: number = 0;
  rank: number = 1;
  rarity: number = 4;
}

export class StarRailCharDetailProperty {
  name: string = "";
  final: string = "";
}

// ── 绝区零专用模型 ────────────────────────────────────────────
export class ZZZCharDetailSkill {
  skillType: number = 0;
  name: string = "";
  level: number = 0;
  iconUrl: string = "";
}

export class ZZZCharDetailWeapon {
  name: string = "";
  iconUrl: string = "";
  level: number = 0;
  star: number = 1;
  rarity: string = "A";
  mainPropName: string = "";
  mainPropValue: string = "";
  subPropName: string = "";
  subPropValue: string = "";
  talentTitle: string = "";
}

export class ZZZSubStat {
  name: string = "";
  value: string = "";
  valid: boolean = false;
}

export class ZZZCharDetailEquip {
  pos: number = 0;
  name: string = "";
  iconUrl: string = "";
  level: number = 0;
  rarity: string = "A";
  suitName: string = "";
  suitOwn: number = 2;
  mainName: string = "";
  mainValue: string = "";
  subs: ZZZSubStat[] = [];
}

export class ZZZSuitSummary {
  suitName: string = "";
  count: number = 0;
  suitOwn: number = 2;
}

export class ZZZCharDetailProperty {
  name: string = "";
  final: string = "";
}
```

### rawJson 字段映射

**原神 rawJson（来自 GenshinCharacterDetailRow）**

| 展示字段 | rawJson 路径                                                                                             | 说明       |
| -------- | -------------------------------------------------------------------------------------------------------- | ---------- |
| 命座列表 | `constellations_detail[].{pos,name,icon,effect,is_actived}`                                              | 6 个       |
| 技能列表 | `skill_icons[]` + `skill_levels[]`                                                                       | 前 3 个    |
| 武器     | `weapon.{name,icon,level,affix_level,rarity}` + `weapon_base_atk` + `weapon_sub_type` + `weapon_sub_val` |            |
| 圣遗物   | `relics_detail[].{pos,icon,set_name,level,rarity,main_property_type,main_property_value,sub_stats}`      | 最多 5 件  |
| 属性     | `selected_properties[].{property_type,final}`                                                            | 按固定顺序 |

**星铁 rawJson（来自 StarRailAvatarInfoRow）**

| 展示字段         | rawJson 路径                                                               | 说明      |
| ---------------- | -------------------------------------------------------------------------- | --------- |
| 命座列表         | `ranks[].{pos,name,icon,is_unlocked}`                                      | 6 个      |
| 行迹（主技能）   | `skills[point_type=2].{item_url,level,remake}`                             | type2     |
| 行迹（额外能力） | `skills[point_type=3].{item_url,is_activated}`                             | type3     |
| 行迹（属性加成） | `skills[point_type=1].{item_url,is_activated}`                             | type1     |
| 光锥             | `equip.{name,icon,level,rank,rarity}`                                      | 可为 null |
| 遗器             | `relics[pos=1-4].{pos,name,icon,level,rarity,main_property,properties}`    | 4 件      |
| 饰品             | `ornaments[pos=5-6].{pos,name,icon,level,rarity,main_property,properties}` | 2 件      |
| 属性             | `properties[].{property_type,final}`                                       | 直接展示  |

**绝区零 rawJson（来自 ZZZAvatarInfoRow）**

| 展示字段 | rawJson 路径                                                                                 | 说明               |
| -------- | -------------------------------------------------------------------------------------------- | ------------------ |
| 影画列表 | `ranks[].{pos,name,is_unlocked}`                                                             | 6 个，方形图标     |
| 技能     | `skills[].{skill_type,items[0].title,level}`                                                 | 按 skill_type 分组 |
| 音擎     | `weapon.{name,icon,level,star,rarity,main_properties[0],properties[0],talent_title}`         | 可为 null          |
| 驱动盘   | `equip[].{equipment_type,name,icon,level,rarity,equip_suit,main_properties[0],properties[]}` | 6 件               |
| 属性     | `properties[].{property_name,final}`                                                         | 直接展示           |

---

## Mock 数据路由

### 现有 Mock 文件

| 游戏   | Mock 文件路径                                                         | 说明                           |
| ------ | --------------------------------------------------------------------- | ------------------------------ |
| 原神   | `mock/account1/game_record_app_genshin_api_character_detail.json`     | 单角色详情                     |
| 原神   | `mock/account2/game_record_app_genshin_api_character_detail_all.json` | 批量详情                       |
| 星铁   | `mock/hkrpgAvatar/hkrpgAllAvatar.json`                                | 含完整 skills/relics/ornaments |
| 绝区零 | `mock/zzzAvatar/1171.json`                                            | 柏妮思（火/异常）              |
| 绝区零 | `mock/zzzAvatar/1281.json`                                            | 另一角色                       |
| 绝区零 | `mock/zzzAvatar/1151.json`                                            | 另一角色                       |

### ViewModel 数据来源

三个 ViewModel 均从对应 Repository 的 `getAvatarDetail(accountId, roleUid, avatarId)` 方法读取 `rawJson`，该方法返回 DB 中存储的完整 API 响应 JSON 字符串。

Mock 环境下，数据已在角色列表同步时写入 DB，详情页直接读取 DB，无需额外 Mock 路由。

---

## 正确性属性

_属性是在系统所有有效执行中都应成立的特征或行为——本质上是关于系统应该做什么的形式化陈述。属性是人类可读规范与机器可验证正确性保证之间的桥梁。_

### Property 1：原神命座解析不丢失

_对任意_ 包含 `constellations_detail` 数组的有效 rawJson，解析后命座列表的长度应等于原始数组的长度。

**Validates: Requirements 2.2**

### Property 2：原神技能解析数量上限

_对任意_ 包含 `skill_icons` 数组的有效 rawJson，解析后技能列表的长度应 ≤ 3。

**Validates: Requirements 2.3**

### Property 3：原神武器解析 round-trip

_对任意_ 包含有效 `weapon` 字段的 rawJson，解析后武器的 `name`、`level`、`affix`、`rarity` 字段应与原始数据一致。

**Validates: Requirements 2.4, 2.12**

### Property 4：原神圣遗物解析数量上限

_对任意_ 包含 `relics_detail` 数组的有效 rawJson，解析后圣遗物列表的长度应 ≤ 5。

**Validates: Requirements 2.5**

### Property 5：原神 viewState 状态不变式

_对任意_ rawJson 输入（包括空字符串、无效 JSON、有效 JSON），`GenshinCharacterDetailViewModel` 的 `viewState` 在 `loadData()` 完成后应始终为 `LOADING`、`EMPTY`、`DATA`、`ERROR` 之一，不应为 `undefined` 或其他值。

**Validates: Requirements 5.1, 5.2, 5.10**

### Property 6：星铁行迹分组不丢失

_对任意_ 包含 `skills` 数组的有效 rawJson，解析后 `type1 + type2 + type3` 三组节点的总数量应等于原始 `skills` 数组的长度。

**Validates: Requirements 3.3, 3.15**

### Property 7：星铁 viewState 状态不变式

_对任意_ rawJson 输入，`StarRailCharacterDetailViewModel` 的 `viewState` 在 `loadData()` 完成后应始终为合法的 `ViewState` 枚举值。

**Validates: Requirements 5.3, 5.4**

### Property 8：绝区零套装统计不丢失

_对任意_ 包含 `equip` 数组的有效 rawJson，解析后套装摘要中所有套装的件数之和应等于 `equip` 数组中 `suitName`（即 `equip_suit.name`）非空的元素数量。

**Validates: Requirements 4.6, 4.16**

### Property 9：绝区零 viewState 状态不变式

_对任意_ rawJson 输入，`ZZZCharacterDetailViewModel` 的 `viewState` 在 `loadData()` 完成后应始终为合法的 `ViewState` 枚举值。

**Validates: Requirements 5.5, 5.6**

---

## 错误处理

### ViewModel 容错策略

所有三个 ViewModel 遵循统一的容错策略：

```
loadData()
  ├── Repository 返回 null 或 rawJson='' → viewState = EMPTY
  ├── JSON.parse 抛出异常 → viewState = ERROR，Logger.error 记录
  ├── Repository 抛出异常 → viewState = ERROR，Logger.error 记录
  └── 解析成功 → viewState = DATA
```

`parseRawJson()` 内部使用 `try/catch`，解析失败时记录日志并保持 `viewState = ERROR`，不向上抛出异常。

### 字段缺失容错

- 武器/光锥/音擎为 `null` 时：展示"未装备"占位卡片（虚线边框 + 锁图标）
- 圣遗物/遗器/驱动盘数量不足时：只渲染实际存在的件数，不补充占位
- 图标 URL 为空字符串时：`Image` 组件显示占位色块（`onError` 回调处理）
- 技能/行迹数量为 0 时：显示空的技能区块，不崩溃

---

## 测试策略

### 单元测试（entry/src/test/）

**StarRailCharacterDetailViewModel.test.ets**

| 测试用例                               | 前置条件 | 操作                                     | 预期结果                          |
| -------------------------------------- | -------- | ---------------------------------------- | --------------------------------- |
| 初始 viewState 为 LOADING              | 新建实例 | `new StarRailCharacterDetailViewModel()` | `viewState === ViewState.LOADING` |
| init 设置三个参数                      | 新建实例 | `vm.init(1, 'uid1', 'avatarId1')`        | 内部参数正确设置                  |
| rawJson 为空字符串时 viewState=EMPTY   | 新建实例 | 调用 parseRawJson('')                    | `viewState === ViewState.EMPTY`   |
| rawJson 为无效 JSON 时 viewState=ERROR | 新建实例 | 调用 parseRawJson('invalid')             | `viewState === ViewState.ERROR`   |

**ZZZCharacterDetailViewModel.test.ets**

| 测试用例                               | 前置条件 | 操作                                | 预期结果                          |
| -------------------------------------- | -------- | ----------------------------------- | --------------------------------- |
| 初始 viewState 为 LOADING              | 新建实例 | `new ZZZCharacterDetailViewModel()` | `viewState === ViewState.LOADING` |
| init 设置三个参数                      | 新建实例 | `vm.init(1, 'uid1', 'avatarId1')`   | 内部参数正确设置                  |
| rawJson 为空字符串时 viewState=EMPTY   | 新建实例 | 调用 parseRawJson('')               | `viewState === ViewState.EMPTY`   |
| rawJson 为无效 JSON 时 viewState=ERROR | 新建实例 | 调用 parseRawJson('invalid')        | `viewState === ViewState.ERROR`   |

### 属性测试（entry/src/test/）

使用 `@ohos/hypium` 框架，每个属性测试最少运行 100 次迭代。

**GenshinCharDetailParserTest.test.ets**

```typescript
// Property 1: 命座解析不丢失
// Feature: char-detail-pages, Property 1: 原神命座解析不丢失
it("genshin_constellations_parse_preserves_count", 0, () => {
  // 生成随机 1-6 个命座的 rawJson
  // 验证解析后 constellations.length === 原始数组长度
});

// Property 3: 武器解析 round-trip
// Feature: char-detail-pages, Property 3: 原神武器解析 round-trip
it("genshin_weapon_parse_roundtrip", 0, () => {
  // 生成随机武器数据
  // 验证解析后 name/level/affix/rarity 与输入一致
});

// Property 5: viewState 状态不变式
// Feature: char-detail-pages, Property 5: 原神 viewState 状态不变式
it("genshin_viewstate_invariant", 0, () => {
  // 生成各种 rawJson 输入（空/无效/有效）
  // 验证 viewState 始终为合法枚举值
});
```

**StarRailCharDetailParserTest.test.ets**

```typescript
// Property 6: 行迹分组不丢失
// Feature: char-detail-pages, Property 6: 星铁行迹分组不丢失
it("starrail_skills_grouping_preserves_count", 0, () => {
  // 生成随机 skills 数组（混合 point_type 1/2/3）
  // 验证 type1.length + type2.length + type3.length === skills.length
});
```

**ZZZCharDetailParserTest.test.ets**

```typescript
// Property 8: 套装统计不丢失
// Feature: char-detail-pages, Property 8: 绝区零套装统计不丢失
it("zzz_suit_summary_count_invariant", 0, () => {
  // 生成随机 equip 数组（含不同套装名）
  // 验证套装摘要件数之和 === equip 中 suitName 非空的元素数量
});
```

### UI 测试（entry/src/ohosTest/）

**StarRailCharacterDetailPageTest.test.ets**

| 用例                             | 前置条件                   | 操作         | 预期结果                       |
| -------------------------------- | -------------------------- | ------------ | ------------------------------ |
| 加载中显示 CharDetailLoadingView | 进入页面，立即截图         | 查看内容区   | LoadingProgress 可见           |
| 无数据时显示 CharDetailEmptyView | DB 无对应数据              | 等待加载完成 | `char_detail_no_data` 文字可见 |
| 有数据时显示 Portrait 布局       | 有角色详情数据，Phone 竖屏 | 等待加载完成 | 英雄区和内容区可见             |
| 角色名显示                       | 有角色详情数据             | 查看立绘区   | 角色名文字可见                 |
| 行迹区域可见                     | 有角色详情数据             | 查看内容区   | 行迹区块可见                   |
| 光锥区域可见                     | 有角色详情数据             | 查看内容区   | 光锥区块可见                   |
| 遗器区域可见                     | 有角色详情数据             | 查看内容区   | 遗器区块可见                   |

**ZZZCharacterDetailPageTest.test.ets**

| 用例                             | 前置条件                   | 操作           | 预期结果                       |
| -------------------------------- | -------------------------- | -------------- | ------------------------------ |
| 加载中显示 CharDetailLoadingView | 进入页面，立即截图         | 查看内容区     | LoadingProgress 可见           |
| 无数据时显示 CharDetailEmptyView | DB 无对应数据              | 等待加载完成   | `char_detail_no_data` 文字可见 |
| 有数据时显示 Portrait 布局       | 有角色详情数据，Phone 竖屏 | 等待加载完成   | 英雄区和内容区可见             |
| 代理人名称显示                   | 有角色详情数据             | 查看立绘区     | 代理人名称文字可见             |
| 技能区域可见                     | 有角色详情数据             | 查看内容区     | 技能区块可见                   |
| 音擎区域可见                     | 有角色详情数据             | 查看内容区     | 音擎区块可见                   |
| 驱动盘套装摘要可见               | 有角色详情数据             | 查看驱动盘区   | 套装摘要卡片可见               |
| 驱动盘 valid 副词条高亮          | 有 valid=true 的副词条     | 查看驱动盘卡片 | 高亮样式可见                   |

### 测试文件注册更新

**entry/src/test/List.test.ets** 需新增：

```typescript
import starRailCharDetailViewModelTest from "./StarRailCharacterDetailViewModel.test";
import zzzCharDetailViewModelTest from "./ZZZCharacterDetailViewModel.test";
import genshinCharDetailParserTest from "./GenshinCharDetailParser.test";
import starRailCharDetailParserTest from "./StarRailCharDetailParser.test";
import zzzCharDetailParserTest from "./ZZZCharDetailParser.test";
```

**entry/src/ohosTest/ets/test/List.test.ets** 需新增：

```typescript
import starRailCharDetailPageTest from "./StarRailCharacterDetailPageTest.test";
import zzzCharDetailPageTest from "./ZZZCharacterDetailPageTest.test";
```

**testing-entry-pages.md** 需补充 StarRailCharacterDetail 和 ZZZCharacterDetail 的 ViewModel 单元测试用例和 UI 测试用例（见上方表格）。

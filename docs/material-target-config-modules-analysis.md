# MaterialTargetConfig 家族模块分析

> **作用范围：** `GenshinMaterialTargetConfig` / `StarRailMaterialTargetConfig` / `ZZZMaterialTargetConfig` 三文件  
> **分析方式：** 合并分析（结构高度相似，游戏差异体现在目标配置项种类上）  
> **分析日期：** 2026-10-24（重构备注同日复核）
> 代码版本：`105c8d3`（本文档分析基线，2026-10-24 复核）

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 2 |
| Low | 3 |

**整体评级：A**

> 口径：skills `harmonyos-review` 官方 A-F 评级（0 Critical + 0 High，Medium ≤ 5）。旧百分制已废弃，原分 87/100 仅作历史参考。
>
> **债务点数**：2×2 + 3×1 = 7；密度 7 ÷ (1098/100) ≈ 0.6（源行数为三页合计 342+346+410）。

---

## 1. 文件基本信息

| 文件 | 行数 | @Component 版本 | 主要依赖 |
|------|------|-----------------|----------|
| `features/material/src/main/ets/pages/GenshinMaterialTargetConfigPage.ets` | 261 | `@ComponentV2` | GenshinMaterialTargetConfigViewModel |
| `features/material/src/main/ets/pages/StarRailMaterialTargetConfigPage.ets` | 265 | `@ComponentV2` | StarRailMaterialTargetConfigViewModel |
| `features/material/src/main/ets/pages/ZZZMaterialTargetConfigPage.ets` | 266 | `@ComponentV2` | ZZZMaterialTargetConfigViewModel |
| `features/material/src/main/ets/views/LevelConfigRow.ets` | 76 | `@ComponentV2` | 三页共用的等级行（当前 / 目标两列） |
| `features/material/src/main/ets/views/TargetConfigTipCard.ets` | 32 | `@ComponentV2` | 三页共用的顶部提示卡片 |

> 上表为 M7 重构后现状（原 342 / 346 / 410 行）；§2 / §3 / §4 保留重构前基线，便于对照。

> ZZZ 版本多出 68 行，主要是多了一个 `@Builder SkillLevelRow`（L298-358，与 `LevelRow` 逐行同构，只是把 key 拼接移到了 onClick 内），其余是 `getLabelResource` 的 6 个技能 case。三页配置项都是"角色 + 技能 + 武器/光锥"三类，只是顺序与技能数不同。
>
> 配套 ViewModel：`features/material/src/main/ets/viewmodel/GenshinMaterialTargetConfigViewModel.ets` 226 行 / `features/material/src/main/ets/viewmodel/StarRailMaterialTargetConfigViewModel.ets` 235 行 / `features/material/src/main/ets/viewmodel/ZZZMaterialTargetConfigViewModel.ets` 259 行；共享模型 `features/material/src/main/ets/model/MaterialTargetConfigModels.ets`、`features/material/src/main/ets/model/ToolsModels.ets`（135 行）。

---

## 2. 代码结构分析

### 2.1 整体布局（通用模板）

```
@ComponentV2 export struct GenshinMaterialTargetConfig
├── @Local vm: GenshinMaterialTargetConfigViewModel = new GenshinMaterialTargetConfigViewModel()
├── @Local tm: ThemeManager = themeManager
├── @Local buttonModifier: PrimaryButtonModifier = new PrimaryButtonModifier(true)
├── @Param private param: MaterialTargetConfigParam | null（L28）
├── private localStack（onReady 赋值）
├── private pickerConfigKey / pickerStep / pickerValue（L32-34，普通实例字段，非 @Local）
├── type PickerStep = 'current' | 'target'（L20，页面内定义）
├── aboutToAppear() → vm.init(accountId, roleUid)（未 await；先填默认值再异步从 DB 恢复）
├── build() → NavDestination（title = `*_material_list_title`）→ Column → Scroll + 底部"开始计算"按钮
│   ├── this.TipCard(tip) — 提示卡片 @Builder TipCard（L216）
│   ├── this.LevelRow('avatar', vm.avatarLevel) — 角色等级
│   ├── Text("技能等级标题") → ForEach vm.skills → this.LevelRow(...)
│   └── this.LevelRow('weapon', vm.weaponLevel) — 武器等级
│       └── @Builder LevelRow(key, config)（L237），含当前/目标两列 + onClick showLevelPicker
├── private startCalculation()（L100）
│   ├── param 为空或无选中角色 → vm.saveConfig() → toast → 成功则 pop()
│   └── 否则 vm.computeSelected(selection) → SUCCESS: removeByName(GENSHIN_MATERIAL_LIST / MATERIAL_CHARACTER_SELECT) + replacePathByName(GENSHIN_MATERIAL_LIST)；NO_NEEDS / FAILED: toast
├── showLevelPicker(key, step, config)（L46）→ getUIContext().showTextPickerDialog → onAccept → confirmPicker → vm.updateCurrent / updateTarget
└── (无 RefreshBuilder、无 Section header)
```

> **StarRail 差异**：角色 → 行迹（ForEach LevelRow，4 项）→ `LevelRow('lightCone', vm.lightConeLevel)`（光锥代替武器）  
> **ZZZ 差异**：角色 → `LevelRow('weapon')` → 技能使用 `@Builder SkillLevelRow`（L299，6 个技能分别渲染）

### 2.2 ZZZ 额外结构

ZZZMaterialTargetConfig 在通用模板基础上的差异：
- 技能渲染使用专用 `@Builder SkillLevelRow`（L298-358）；布局与 `LevelRow` **完全相同**，唯一区别是 key 在 onClick 内拼接（`'skill' + config.skillType`），属于复制而非差异化实现
- 默认技能数量为 6 个（Genshin 3 个天赋，StarRail 4 个行迹）
- 配置项顺序：角色 → 武器 → 技能（Genshin 为角色 → 技能 → 武器）

---

## 3. 合规审查

### 3.1 ArkTS 语法规范

| 规则 | 状态 | 说明 |
|------|------|------|
| @ComponentV2 使用 | ✅ | 正确使用 V2 装饰器 |
| @Local 状态管理 | ✅ | vm、tm、buttonModifier 用 @Local；`pickerConfigKey` / `pickerStep` / `pickerValue`（L32-34）是普通实例字段，只在弹窗回调间传值，不参与渲染 |
| 内联 @Builder 检查 | ⚠️ | `@Builder LevelRow(key, config)`（L236-293，约 57 行）是**页面内的行内 Builder**，用于渲染等级配置行（角色/武器/技能）；三页各一份，ZZZ 还多一份同构的 `SkillLevelRow` |
| const TAG | ⚠️ | 无模块级 TAG；`startCalculation()` 内局部 `const TAG = 'MaterialTargetConfig'`（L101） |
| 类型声明完整 | ✅ | pickerStep 使用了 `type PickerStep = 'current' | 'target'` 联合类型 |
| TextPickerDialog 使用 | ✅ | 官方 API，用法正确 |

### 3.2 命名约定

| 规则 | 状态 | 说明 |
|------|------|------|
| 文件名 PascalCase | ✅ | GenshinMaterialTargetConfigPage.ets 等符合规范 |
| struct 名 PascalCase | ✅ | 与文件名一致 |
| type alias | ✅ | `PickerStep` 使用小写联合字面量，命名清晰 |
| import 分组排序 | ✅ | 三文件 import 除 VM 名外完全一致，均无 `GameId` 导入（跳转使用 localStack.replacePathByName） |
| i18n | ⚠️ | `formatLevel()` 硬编码 `` `${level} 级` ``（Genshin L323 / StarRail L327 / ZZZ L391）；StarRail L325-326 注释称已配 `material_target_config_level_suffix`，但代码未使用 |

### 3.3 组件复用

| 复用的组件 | 说明 |
|-----------|------|
| `ThemeManager + ThemeFonts` | 主题系统 |
| `PrimaryButtonModifier` | 按钮样式 |
| `AppRoutes` + `localStack` | 路由导航（replacePathByName） |
| MaterialComputeResult | 计算服务返回值类型 |

**复用率：中等。** `LevelRow` / `SkillLevelRow` 目前作为页面内 @Builder 存在，未提取为独立组件。四份 Builder 逐行同构，只依赖 `LevelConfigVM` + 点击回调，提取难度低；游戏差异全部在 VM 的配置项与 `getLabelResource` 的 case 里。

### 3.4 职责划分

| 层级 | 职责 | 评价 |
|------|------|------|
| Page (MaterialTargetConfig) | UI 布局 + PickerDialog 交互 + 提交导航 | ✅ 清晰 |
| ViewModel | 等级配置管理 + 材料计算调用 | ✅ 合理 |
| Model (MaterialTargetConfigModels) | `LevelConfigVM` / `SkillLevelConfigVM` / `LevelLabelKeys` | ✅ 定义完整 |
| Service (MaterialComputeService) | 实际材料数量计算 | ✅ 已提取 |

### 3.5 主题适配

- ✅ 使用 `themeManager` + `ThemeFonts`
- ✅ `PrimaryButtonModifier` 封装按钮样式
- ⚠️ 无显式深色模式颜色切换（依赖 ThemeManager 内部处理）

---

## 4. 重复度评估

### 4.1 代码重复统计

三文件之间的差异：

| 差异类型 | 行数估计 | 说明 |
|----------|----------|------|
| 注释 / 日志前缀 / struct·VM·Preview·Builder 名 | ~15 行 | 模板替换 |
| 资源 key（TipCard、技能标题、页面标题） | ~4 行 | 每游戏一套 |
| 配置行调用 | ~3–8 行 | 原神：角色 → 技能 → 武器；星铁：角色 → 行迹 → 光锥；ZZZ：角色 → 武器 → 技能（`SkillLevelRow`） |
| `getLabelResource` case | ~10–14 行 | 技能标签不同 |
| startCalculation 路由 | 2 行 | `removeByName` / `replacePathByName` 的目标常量 |
| ZZZ `SkillLevelRow` | 61 行 | `LevelRow` 的副本 |

**重复率估算：** 以原神为基准 `diff`，星铁仅 35 行不同（约 90% 相同），ZZZ 98 行不同（约 76% 相同，其中 61 行是 `SkillLevelRow` 副本）。

### 4.2 合并建议

**不推荐合并为单一文件。**

理由：
1. 三个路由入口 + 三个 Builder 必须保留（routerMap 契约），合并只能做"共享内部实现"。
2. 游戏差异集中在 VM（配置项、上限、DB 读写）与标签映射；页面外壳与 `LevelRow` 才是可共享部分。
3. 三页均无 Local Test，大幅合并缺乏回归保护。

**推荐方案：** 保持三份独立文件；优先把 `LevelRow` / `SkillLevelRow` 提取为一个 `LevelConfigRow` 组件（M-TARGET-1），外壳容器 `BaseTargetConfigPage`（NavDestination + Scroll + TipCard + Button）留待新增游戏时再评估（M-TARGET-2）。

---

## 5. 问题与改进建议

### 5.1 发现的问题

| 优先级 | 编号 | 问题 | 说明 |
|--------|------|------|------|
| **中** | M-TARGET-1 | 等级行 `@Builder` 四份同构副本 | ✅ 已关闭（M7）：提取 `views/LevelConfigRow.ets`，三页 `LevelRow` 改为 10 行委托；ZZZ 删除 `SkillLevelRow`，改用同一个 `LevelRow('skill' + skillType, skill)`。 |
| **中** | M-TARGET-2 | 三页 UI 框架层复制（约 76–90%） | 🔶 部分关闭（M7）：`TipCard` 已提取为 `TargetConfigTipCard`，等级行已共享；`NavDestination + Scroll + 底部按钮` 外壳与 `showLevelPicker` / `startCalculation` 仍各一份，按计划不合并。 |
| **低** | M-TARGET-3 | Picker 中间状态存放在实例字段 | ✅ 已关闭（M7）：删除 `pickerConfigKey` / `pickerStep` / `pickerValue`，`onAccept` 闭包直接捕获 `key` / `step`，`confirmPicker(key, step, value)` 显式传参。 |
| **低** | M-TARGET-4 | 页面标题用错资源 | 三页 `.title()` 仍使用材料汇总页标题；UI 文案变更，单独提交。 |
| **低** | M-TARGET-5 | Picker 选项硬编码中文"级" | `formatLevel()` 仍返回 `` `${level} 级` ``；资源已存在但未使用，属文案变更，单独提交。 |

### 5.2 改进建议

| 优先级 | 编号 | 建议 |
|--------|------|------|
| **信息** | M-TARGET-6 | 上述 M-TARGET-1~5 的"怎么做"已写在对应行的建议里；本表不再重复列条目（更早版本的 M-TARGET-4/5 与 1/3 是同一件事，已合并）。 |

---

## 6. 依赖文件索引

| 类型 | 文件 |
|------|------|
| ViewModel | `features/material/src/main/ets/viewmodel/GenshinMaterialTargetConfigViewModel.ets` / `features/material/src/main/ets/viewmodel/StarRailMaterialTargetConfigViewModel.ets` / `features/material/src/main/ets/viewmodel/ZZZMaterialTargetConfigViewModel.ets` |
| Model | `features/material/src/main/ets/model/MaterialTargetConfigModels.ets`（共享：LevelConfigVM, SkillLevelConfigVM, LevelLabelKeys） |
| Model | `features/material/src/main/ets/model/ToolsModels.ets`（共享：MaterialTargetConfigParam） |
| Service | `features/material/src/main/ets/model/service/MaterialComputeService.ets`（共享） |
| Theme | `common/basic/src/main/ets/theme/ThemeManager.ets`、`common/basic/src/main/ets/theme/ThemeFonts.ets` |
| Style | `common/basic/src/main/ets/theme/PrimaryButtonModifier.ets` |
| Constant | `common/basic/src/main/ets/constants/AppRoutes.ets` |
| Core | `'core'` (Logger) |

---

## 7. 重构执行备注（M7 · MaterialTargetConfig）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 路由 | `custom_router_map.json:74-76 / 79-81 / 84-86`（Genshin / StarRail / ZZZ）：三条 `*MaterialTargetConfig` 路由分别指向三个页面与 `GenshinMaterialTargetConfigBuilder` / `StarRailMaterialTargetConfigBuilder` / `ZZZMaterialTargetConfigBuilder`，**页面路径与 Builder 名冻结** |
| 路由常量 | `AppRoutes.{GENSHIN,STARRAIL,ZZZ}_MATERIAL_TARGET_CONFIG` 字符串冻结 |
| 路由参数 | `MaterialTargetConfigParam` 来自 `features/material/src/main/ets/model/ToolsModels.ets`，被 MaterialCharacterSelect / MaterialList / 本家族共用（`MaterialCalc` 用的是自己的 `MaterialCalcParam`），不移动 |
| 跨页栈操作 | 成功后 `removeByName(AppRoutes.*_MATERIAL_LIST)` + `removeByName(AppRoutes.MATERIAL_CHARACTER_SELECT)`（各页 L126-127）再 `replacePathByName`（L128）——依赖这两个路由名字符串，改名会让返回栈残留旧页 |
| 测试 | 三个 `*MaterialTargetConfigViewModel` **没有** Local Test；验收只能走冒烟 |
| 页面类型 | `type PickerStep = 'current' | 'target'` 定义在各自页面内，仅本页使用；保持现状 |
| 内联 Builder | `LevelRow` 是页面内 `@Builder`（Genshin L237），不强制提取；ZZZ 另有 `SkillLevelRow`（L299） |

### 重构范围（已执行）

- 三页配置行收敛到 `views/LevelConfigRow.ets`：三份 `LevelRow` 与 ZZZ 的 `SkillLevelRow` 改为共享组件；ZZZ 技能行改用 `LevelRow('skill' + skillType, skill)`，删除 61 行副本。
- 顶部提示卡片收敛到 `views/TargetConfigTipCard.ets`。
- 删除 Picker 中间状态字段 `pickerConfigKey` / `pickerStep` / `pickerValue`，`confirmPicker` 改为显式传参。
- 三页配置顺序、`getLabelResource`、`formatLevel`、`startCalculation` 路由保持不变；三个路由入口与 Builder 名冻结。
- 三页 342 / 346 / 410 → 261 / 265 / 266 行。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. 无 Local Test：冒烟——三个游戏目标配置页、等级 Picker、当前/目标切换；带选中角色提交 → 替换为材料清单页（返回直接回工具页）；从选角页右上角无选中进入 → 保存后 toast 并返回。
3. 重点回归 ZZZ（6 个技能共用 `LevelRow`）。

### 已知问题归属

- Medium（三页 UI 外壳仍复制）：记录，不合并页面；新增游戏时再评估 `BaseTargetConfigPage`。
- Low（标题用错资源、"级"硬编码）：UI 文案变更，单独提交，不夹带在重构里。

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 结构） | 三游戏文件行数、结构树修正（RefreshBuilder/LevelRow/SkillLevelRow） | ✅ |
| 第 2 轮（关键代码段） | `onCommit`→`startCalculation`→`localStack.replacePathByName` 链路、import 一致性 | ✅ |
| 第 3 轮（全面复核） | ZZZ 结构差异、levelConfigCard 引用统一替换、已知问题归属 | ✅ |
| 第 4 轮（2026-10-27 逐条复核） | 三页逐行 diff、三个 VM、`pickerStep` 修饰符、ZZZ `SkillLevelRow` 与 `LevelRow` 对比、标题与 Picker 文案资源 | ✅ 修正：`pickerStep` 非 @Local、`SkillLevelRow` 与 `LevelRow` 同构（非"布局不同"）、星铁 4 个行迹、重复率 40–50% → 76–90%、`LevelRow` 无"材料需求概览"、`MaterialTargetConfigParam` 不被 MaterialCalc 使用；新增 2 Low（标题资源、"级"硬编码）；编号重排为 M-TARGET-1~6 |
| 第 5 轮（2026-10-30 断链修复） | §1 三页路径补全为 `features/material/src/main/ets/pages/`；§37 ViewModel + Model 全量更新为绝对路径；§6 依赖表 8 个相对路径 → `features/material/src/main/ets/{viewmodel,model,model/service}/` + `common/basic/src/main/ets/theme/constants/`；§7 `models/ToolsModels.ets` → 绝对路径 | ✅ 13 处路径全部验证存在 |
| 第 6 轮（2026-11-04 M7 执行后） | 三页 261 / 265 / 266L；新增 `LevelConfigRow` 76L + `TargetConfigTipCard` 32L；ZZZ `SkillLevelRow` 已删；Picker 实例字段已删；`bash run.sh uat` 通过 | ✅ 行数与结构复核一致 |

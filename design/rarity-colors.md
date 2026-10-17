# 米哈游游戏稀有度颜色方案

> 创建时间：2026-07-22

本文档记录原神、星穹铁道、绝区零三款游戏的稀有度颜色方案，用于材料卡片、角色卡片等 UI 组件的背景色。

---

## 一、原神（Genshin Impact）

原神使用 **1-5 星** 稀有度系统。

| 稀有度 | 颜色名 | 颜色值 | 说明 |
|--------|--------|--------|------|
| 5 星 | `rarity_5star_bg` | `#6B4C1E` | 金色/橙色，传说级角色和武器 |
| 4 星 | `rarity_4star_bg` | `#4A3060` | 紫色，史诗级角色和武器 |
| 3 星 | `rarity_3star_bg` | `#4A5568` | 蓝灰色，稀有级材料 |
| 2 星 | `rarity_2star_bg` | `#2D3748` | 深灰色，普通级材料 |
| 1 星 | `rarity_1star_bg` | `#1A202C` | 近黑色，常见级材料 |

**材料示例**：
- 5 星：哀叙冰玉、自在松石等角色突破宝石
- 4 星：极寒之核、飓风之种等 BOSS 材料
- 3 星：「勤劳」的指引、「繁荣」的指引等天赋书
- 2 星：「勤劳」的教导、破损的面具等基础材料
- 1 星：破损的面具、导能绘卷等低级材料

---

## 二、星穹铁道（Honkai: Star Rail）

星铁同样使用 **1-5 星** 稀有度系统，颜色方案与原神一致。

| 稀有度 | 颜色名 | 颜色值 | 说明 |
|--------|--------|--------|------|
| 5 星 | `rarity_5star_bg` | `#6B4C1E` | 金色/橙色，传说级角色和光锥 |
| 4 星 | `rarity_4star_bg` | `#4A3060` | 紫色，史诗级角色和光锥 |
| 3 星 | `rarity_3star_bg` | `#4A5568` | 蓝灰色，稀有级材料 |
| 2 星 | `rarity_2star_bg` | `#2D3748` | 深灰色，普通级材料 |
| 1 星 | `rarity_1star_bg` | `#1A202C` | 近黑色，常见级材料 |

**材料示例**：
- 5 星：永恒之眼、虚幻铸铁等高级材料
- 4 星：混沌核心、琥珀之壁等中级材料
- 3 星：破碎之刃、增幅器等基础材料

---

## 三、绝区零（Zenless Zone Zero）

绝区零使用 **A/S 级** 稀有度系统（对应 4/5 星）。

| 稀有度 | 对应星级 | 颜色名 | 颜色值 | 说明 |
|--------|----------|--------|--------|------|
| S 级 | 5 星 | `rarity_5star_bg` | `#6B4C1E` | 金色/橙色，顶级角色和音擎 |
| A 级 | 4 星 | `rarity_4star_bg` | `#4A3060` | 紫色，高级角色和音擎 |
| B 级 | 3 星 | `rarity_3star_bg` | `#4A5568` | 蓝灰色，中级材料 |
| - | 2 星 | `rarity_2star_bg` | `#2D3748` | 深灰色，普通材料 |

**材料示例**：
- S 级：高维数据、认证芯片等高级材料
- A 级：驱动盘、强化模块等中级材料
- B 级：基础经验材料

---

## 四、代码使用示例

```typescript
/**
 * 根据稀有度获取材料背景色
 * 支持 1-5 星稀有度，绝区零的 A/S 级映射为 4/5 星
 */
private getMaterialRarityBg(rarity: number): ResourceColor {
  if (rarity >= 5) {
    return $r('app.color.rarity_5star_bg')
  }
  if (rarity >= 4) {
    return $r('app.color.rarity_4star_bg')
  }
  if (rarity >= 3) {
    return $r('app.color.rarity_3star_bg')
  }
  if (rarity >= 2) {
    return $r('app.color.rarity_2star_bg')
  }
  return $r('app.color.rarity_1star_bg')
}

// 绝区零 A/S 级映射
// S 级 → rarity = 5
// A 级 → rarity = 4
// B 级 → rarity = 3
```

---

## 五、颜色设计原则

1. **渐变过渡自然**：从 1 星到 5 星，颜色亮度逐渐提高，形成自然的视觉梯度
2. **符合行业标准**：遵循 Diablo/WoW 建立的稀有度颜色体系（灰 → 绿 → 蓝 → 紫 → 金）
3. **深色背景适配**：所有颜色值都是深色调，适合在深色主题下使用
4. **统一跨游戏**：三款游戏使用相同的颜色值，保持视觉一致性

---

## 六、颜色参考来源

- 行业通用稀有度颜色方案：灰（普通）→ 绿（优秀）→ 蓝（稀有）→ 紫（史诗）→ 金（传说）
- 原神已有的 `rarity_5star_bg`（`#6B4C1E`）和 `rarity_4star_bg`（`#4A3060`）
- 项目深色主题配色方案（`dark_400`、`dark_500` 等）

---

## 七、后续维护

如需调整颜色值，请同步修改以下文件：
- `entry/src/main/resources/base/element/color.json` — 颜色定义
- `entry/src/main/resources/en/element/color.json` — 英文资源
- `entry/src/main/resources/zh_HK/element/color.json` — 繁体中文资源

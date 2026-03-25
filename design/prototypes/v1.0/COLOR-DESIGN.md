# Color Design System — v1.0

> 确认日期：2026-03-22
> 状态：已锁定，禁止修改本文件。如需改版，在 `v1.1/` 目录中更新。

---

## 设计原则

1. **三层分离**：Palette（原始色值）→ Semantic（语义用途）→ Token（代码字段名）
2. **组件解耦**：颜色命名不与任何页面或组件绑定，描述"是什么颜色"或"用来做什么"
3. **单一来源**：所有颜色值只在 `color.json` 中定义，`DefaultTheme.ets` 通过 `$r()` 引用
4. **元素力固定**：`element_*` 系列是唯一跨主题不变的颜色，不参与主题替换

---

## 第一层：调色板（Palette）

原始色值，不含任何语义，只描述"这是什么颜色"。

### 深色背景调色板

| color.json name      | 色值      | 说明                    |
| -------------------- | --------- | ----------------------- |
| `palette_blue_950`   | `#081428` | 深蓝（最深）            |
| `palette_blue_900`   | `#0A2A4A` | 深蓝                    |
| `palette_blue_800`   | `#0D1E3A` | 深蓝中                  |
| `palette_blue_700`   | `#0A1E3A` | 蓝灰深                  |
| `palette_blue_600`   | `#0A101E` | 近黑蓝                  |
| `palette_blue_500`   | `#0C1A30` | 蓝黑                    |
| `palette_red_900`    | `#180808` | 深红（最深）            |
| `palette_red_800`    | `#2A0E0A` | 深红                    |
| `palette_red_700`    | `#3A1008` | 深红亮                  |
| `palette_purple_900` | `#100818` | 深紫（最深）            |
| `palette_purple_800` | `#1E0A30` | 深紫                    |
| `palette_purple_700` | `#2A1040` | 深紫亮                  |
| `palette_green_900`  | `#040E02` | 深绿（最深）            |
| `palette_green_800`  | `#081E06` | 深绿                    |
| `palette_green_700`  | `#0A2A08` | 深绿亮                  |
| `palette_teal_900`   | `#041810` | 深青（最深）            |
| `palette_teal_800`   | `#062A1E` | 深青                    |
| `palette_teal_700`   | `#083A2A` | 深青亮                  |
| `palette_amber_900`  | `#100E02` | 深琥珀（最深）          |
| `palette_amber_800`  | `#1E1604` | 深琥珀                  |
| `palette_amber_700`  | `#2A1E04` | 深琥珀亮                |
| `palette_navy_900`   | `#040E18` | 深海蓝（最深）          |
| `palette_navy_800`   | `#081628` | 深海蓝                  |
| `palette_navy_700`   | `#0A1E3A` | 深海蓝亮（同 blue_700） |
| `palette_dark_950`   | `#0D0D18` | 近黑（页面底色）        |
| `palette_dark_900`   | `#0E0E22` | 深暗蓝黑                |
| `palette_dark_800`   | `#0A1E38` | 深蓝灰                  |

---

## 第二层：语义色（Semantic）

描述"这个颜色用来做什么"，与具体组件无关。

### Surface（表面 / 容器）

| color.json name           | 色值        | 说明                                  |
| ------------------------- | ----------- | ------------------------------------- |
| `surface_glass_xs`        | `#0AFFFFFF` | 极弱玻璃感（卡片背景）                |
| `surface_glass_sm`        | `#0FFFFFFF` | 弱玻璃感（图标背景 / 分割线）         |
| `surface_glass_md`        | `#14FFFFFF` | 中玻璃感（图标背景 / 遮罩）           |
| `surface_glass_lg`        | `#26FFFFFF` | 较强玻璃感（好感度标签背景）          |
| `surface_overlay_xs`      | `#08FFFFFF` | 极弱白色叠加                          |
| `surface_overlay_sm`      | `#0DFFFFFF` | 弱白色叠加（分割线）                  |
| `surface_overlay_md`      | `#12FFFFFF` | 中白色叠加（分割线）                  |
| `surface_dark_xs`         | `#08000000` | 极弱黑色叠加                          |
| `surface_dark_sm`         | `#14000000` | 弱黑色叠加（图标背景）                |
| `surface_dark_md`         | `#26000000` | 中黑色叠加（圣遗物行背景）            |
| `surface_dark_lg`         | `#40000000` | 较强黑色叠加（属性网格 / 命座未激活） |
| `surface_dark_xl`         | `#59000000` | 强黑色叠加（属性面板背景）            |
| `surface_dark_2xl`        | `#80000000` | 极强黑色叠加（命座未激活 / 技能背景） |
| `surface_dark_3xl`        | `#8C000000` | 武器遮罩                              |
| `surface_active_primary`  | `#404FC3F7` | 主色激活态（命座激活背景）            |
| `surface_active_border`   | `#CC4FC3F7` | 主色激活描边                          |
| `surface_inactive_border` | `#33FFFFFF` | 未激活描边                            |

### Text（文字）

| color.json name          | 色值        | 说明                                              |
| ------------------------ | ----------- | ------------------------------------------------- |
| `text_on_dark_high`      | `#DDDDDD`   | 暗色背景上的高亮文字                              |
| `text_on_dark_medium`    | `#CCCCCC`   | 暗色背景上的中等文字（等级）                      |
| `text_on_dark_secondary` | `#B3FFFFFF` | 暗色背景上的次要文字（属性标签）                  |
| `text_on_dark_tertiary`  | `#8CFFFFFF` | 暗色背景上的三级文字（圣遗物副词条标签）          |
| `text_on_dark_muted`     | `#80FFFFFF` | 暗色背景上的弱文字（武器等级 / 圣遗物主词条标签） |
| `text_on_dark_faint`     | `#66FFFFFF` | 暗色背景上的极弱文字（圣遗物等级）                |
| `text_on_dark_ghost`     | `#99FFFFFF` | 暗色背景上的幽灵文字（Phone 小字）                |
| `text_inactive`          | `#444444`   | 未激活状态文字                                    |
| `text_lock_icon`         | `#BFFFFFFF` | 锁图标颜色                                        |

### Accent（强调色）

| color.json name         | 色值        | 说明                                 |
| ----------------------- | ----------- | ------------------------------------ |
| `accent_refine`         | `#FFCA28`   | 精炼 / 星级金色                      |
| `accent_refine_bg`      | `#26FFCA28` | 精炼标签背景                         |
| `accent_primary_strong` | `#E64FC3F7` | 圣遗物主词条强调色（高不透明度主色） |

### Overlay（遮罩 / 渐变用色）

| color.json name           | 色值        | 说明                       |
| ------------------------- | ----------- | -------------------------- |
| `overlay_scrim_top`       | `#BF000000` | 宽屏遮罩底部不透明色       |
| `overlay_portrait_base`   | `#0C1A30`   | Phone 竖屏遮罩基色（纯色） |
| `overlay_portrait_strong` | `#E00C1A30` | Phone 竖屏遮罩强           |
| `overlay_portrait_mid`    | `#660C1A30` | Phone 竖屏遮罩中           |
| `overlay_portrait_bot`    | `#E60A101E` | Phone 竖屏底部遮罩         |
| `overlay_land_opaque`     | `#FF0A101E` | Phone 横屏遮罩不透明       |
| `overlay_land_strong`     | `#B30A101E` | Phone 横屏遮罩强           |
| `overlay_land_fade`       | `#1A0A101E` | Phone 横屏遮罩淡出         |

### Background（背景渐变色）

每种元素力对应三个深度梯度，用于角色详情页背景渐变。

| color.json name        | 色值      | 元素力   | 梯度 |
| ---------------------- | --------- | -------- | ---- |
| `bg_element_hydro_1`   | `#0A2A4A` | 水       | 浅   |
| `bg_element_hydro_2`   | `#0D1E3A` | 水       | 中   |
| `bg_element_hydro_3`   | `#081428` | 水       | 深   |
| `bg_element_pyro_1`    | `#3A1008` | 火       | 浅   |
| `bg_element_pyro_2`    | `#2A0E0A` | 火       | 中   |
| `bg_element_pyro_3`    | `#180808` | 火       | 深   |
| `bg_element_electro_1` | `#2A1040` | 雷       | 浅   |
| `bg_element_electro_2` | `#1E0A30` | 雷       | 中   |
| `bg_element_electro_3` | `#100818` | 雷       | 深   |
| `bg_element_anemo_1`   | `#083A2A` | 风       | 浅   |
| `bg_element_anemo_2`   | `#062A1E` | 风       | 中   |
| `bg_element_anemo_3`   | `#041810` | 风       | 深   |
| `bg_element_geo_1`     | `#2A1E04` | 岩       | 浅   |
| `bg_element_geo_2`     | `#1E1604` | 岩       | 中   |
| `bg_element_geo_3`     | `#100E02` | 岩       | 深   |
| `bg_element_cryo_1`    | `#0A1E3A` | 冰       | 浅   |
| `bg_element_cryo_2`    | `#081628` | 冰       | 中   |
| `bg_element_cryo_3`    | `#040E18` | 冰       | 深   |
| `bg_element_dendro_1`  | `#0A2A08` | 草       | 浅   |
| `bg_element_dendro_2`  | `#081E06` | 草       | 中   |
| `bg_element_dendro_3`  | `#040E02` | 草       | 深   |
| `bg_portrait_1`        | `#0A1E38` | 通用竖屏 | 浅   |
| `bg_portrait_2`        | `#0E0E22` | 通用竖屏 | 深   |
| `bg_page_deep`         | `#0D0D18` | 页面底色 | —    |

---

## 元素力颜色（固定不变）

以下颜色跨所有主题固定不变，不参与重命名：

| color.json name   | 色值      | 说明   |
| ----------------- | --------- | ------ |
| `element_pyro`    | `#EF7A35` | 火元素 |
| `element_hydro`   | `#4BC3F1` | 水元素 |
| `element_anemo`   | `#74C2A8` | 风元素 |
| `element_electro` | `#B08FC2` | 雷元素 |
| `element_dendro`  | `#A5C83B` | 草元素 |
| `element_cryo`    | `#98D5E4` | 冰元素 |
| `element_geo`     | `#CFA726` | 岩元素 |

---

## 渐变角度 Token

| Token 字段名       | 值   | 用途                      |
| ------------------ | ---- | ------------------------- |
| `gradientAngle0`   | 0°   | 底部遮罩（从下到上渐变）  |
| `gradientAngle90`  | 90°  | 左右遮罩（从左到右渐变）  |
| `gradientAngle135` | 135° | 元素背景渐变（左上→右下） |
| `gradientAngle150` | 150° | Phone 背景渐变            |
| `gradientAngle180` | 180° | 上下遮罩（从上到下渐变）  |

---

## 合并优化说明

重命名后，以下 color.json 条目可以合并（多个旧条目值相同，统一为一个新条目）：

| 合并后 name          | 色值        | 合并前的旧条目                                                                                                                                                                                     |
| -------------------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `surface_glass_xs`   | `#0AFFFFFF` | `char_detail_weapon_card_bg`, `char_detail_relic_card_bg`                                                                                                                                          |
| `surface_glass_sm`   | `#0FFFFFFF` | `char_detail_weapon_icon_bg_lg`, `char_detail_weapon_row_divider`, `char_detail_relic_row_divider`, `char_detail_relic_left_divider`, `char_detail_relic_main_divider`, `char_detail_stat_divider` |
| `surface_glass_md`   | `#14FFFFFF` | `char_detail_weapon_icon_bg_sm`, `char_detail_relic_icon_bg`, `char_detail_relic_lv_bg`, `char_detail_relic_card_border`                                                                           |
| `surface_dark_lg`    | `#40000000` | `char_detail_grid_bg`, `char_detail_relic_panel_bg`                                                                                                                                                |
| `surface_dark_2xl`   | `#80000000` | `char_detail_cons_inactive_bg`, `char_detail_skill_bg`, `weapon_overlay_bg`（近似）                                                                                                                |
| `text_on_dark_muted` | `#80FFFFFF` | `char_detail_weapon_lv_color`, `char_detail_relic_main_label_color`, `char_detail_stat_label_color`（近似）                                                                                        |
| `text_on_dark_ghost` | `#99FFFFFF` | `char_detail_weapon_lv_color_sm`, `char_detail_relic_lv_color_sm`, `char_detail_relic_sub_label_color_sm`                                                                                          |

合并后 color.json 条目数量从约 70 个减少到约 45 个。

# Color Design System — v1.0

> 最后更新：2026-04-14
> 状态：与代码同步，仅保留实际使用的 token。

---

## 设计原则

1. **三层分离**：Palette（原始色值）→ Semantic（语义用途）→ Token（代码字段名）
2. **组件解耦**：颜色命名不与任何页面或组件绑定
3. **单一来源**：所有颜色值只在 `color.json` 中定义，`DefaultTheme.ets` 通过 `$r()` 引用
4. **元素力固定**：`element_*` 系列是唯一跨主题不变的颜色

---

## 一、基础语义色

| color.json name    | Light       | Dark        | 用途                        |
| ------------------ | ----------- | ----------- | --------------------------- |
| `color_primary`    | `#007DFF`   | `#4DA3FF`   | 主色（米游蓝），按钮/选中态 |
| `color_primary_bg` | `#1A007DFF` | `#1A4DA3FF` | 主色背景（轻量高亮）        |
| `color_accent`     | `#007DFF`   | `#4DA3FF`   | 强调色（同主色）            |
| `color_danger`     | `#E8534A`   | `#FF6B6B`   | 危险/错误/低值              |
| `color_danger_bg`  | `#1AE8534A` | `#1AFF6B6B` | 危险背景                    |
| `color_warning`    | `#F0A030`   | `#F5B942`   | 警告/中低值                 |

---

## 二、文字色

| color.json name        | Light     | Dark      | 用途       |
| ---------------------- | --------- | --------- | ---------- |
| `color_text_primary`   | `#333333` | `#E0E0E0` | 主文字     |
| `color_text_secondary` | `#666666` | `#999999` | 次要文字   |
| `color_placeholder`    | `#999999` | `#555555` | 占位符文字 |

---

## 三、背景 / 容器色

| color.json name      | Light       | Dark        | 用途                        |
| -------------------- | ----------- | ----------- | --------------------------- |
| `color_page_bg`      | `#F2F2F7`   | `#000000`   | 页面背景 / 卡片背景（合并） |
| `color_surface_card` | `#FFFFFF`   | `#1C1C1C`   | 卡片表面（次层）            |
| `color_divider`      | `#EEEEEE`   | `#2A2A2A`   | 分割线 / 卡片边框（合并）   |
| `color_skeleton_bg`  | `#E0E0E0`   | `#2E2E2E`   | 骨架屏占位色                |
| `color_mask`         | `#80000000` | `#99000000` | 遮罩层                      |
| `color_shadow`       | `#14000000` | `#28000000` | 阴影                        |
| `color_transparent`  | `#00000000` | `#00000000` | 透明                        |

---

## 四、游戏品牌色

| color.json name       | Light     | Dark      | 用途           |
| --------------------- | --------- | --------- | -------------- |
| `game_color_genshin`  | `#4A90D9` | `#5BA3E8` | 原神品牌色     |
| `game_color_starrail` | `#7B68EE` | `#9B8EFF` | 星穹铁道品牌色 |
| `game_color_zzz`      | `#F5A623` | `#F7B84B` | 绝区零品牌色   |
| `game_color_honkai3`  | `#E8534A` | `#FF6B6B` | 崩坏3品牌色    |

---

## 五、元素力颜色（固定不变，跨主题）

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

## 六、绝区零元素色（固定不变）

| color.json name        | 色值      | 说明   |
| ---------------------- | --------- | ------ |
| `zzz_element_physical` | `#9E9E9E` | 物理   |
| `zzz_element_fire`     | `#FF7043` | 火属性 |
| `zzz_element_ice`      | `#4FC3F7` | 冰属性 |
| `zzz_element_electric` | `#CE93D8` | 电属性 |
| `zzz_element_ether`    | `#E040FB` | 以太   |

---

## 七、稀有度色

| color.json name   | 色值      | 用途                |
| ----------------- | --------- | ------------------- |
| `rarity_5star`    | `#C8922A` | 5星文字色           |
| `rarity_5star_bg` | `#6B4C1E` | 5星背景色（深金棕） |
| `rarity_4star_bg` | `#4A3060` | 4星背景色（深紫）   |

---

## 八、Surface 透明叠加色（固定，暗色系专用）

| color.json name              | 色值        | 用途                                     |
| ---------------------------- | ----------- | ---------------------------------------- |
| `surface_glass`              | `#12FFFFFF` | 白色透明叠加（卡片背景/图标背景/分割线） |
| `surface_dark_sm`            | `#1A000000` | 弱黑色叠加                               |
| `surface_dark_md`            | `#40000000` | 中黑色叠加（属性网格/命座未激活）        |
| `surface_dark_lg`            | `#80000000` | 强黑色叠加（属性面板/技能背景）          |
| `surface_active_primary`     | `#404FC3F7` | 主色激活态（命座激活背景）               |
| `surface_active_border`      | `#CC4FC3F7` | 主色激活描边                             |
| `surface_inactive_border`    | `#33FFFFFF` | 未激活描边                               |
| `surface_skill_border_phone` | `#594FC3F7` | 技能边框（Phone）                        |
| `surface_fetter_bg`          | `#1F4FC3F7` | 好感度标签背景                           |
| `surface_fetter_border`      | `#334FC3F7` | 好感度标签边框                           |

---

## 九、暗色背景文字色（固定，角色详情专用）

| color.json name          | 色值        | 用途                                            |
| ------------------------ | ----------- | ----------------------------------------------- |
| `text_on_dark_high`      | `#DDDDDD`   | 暗色背景上的高亮文字                            |
| `text_on_dark_medium`    | `#CCCCCC`   | 暗色背景上的中等文字（等级）                    |
| `text_on_dark_secondary` | `#B3FFFFFF` | 暗色背景上的次要文字（属性标签）                |
| `text_on_dark_tertiary`  | `#8CFFFFFF` | 暗色背景上的三级文字（圣遗物副词条标签）        |
| `text_on_dark_muted`     | `#80FFFFFF` | 暗色背景上的弱文字（武器等级/圣遗物主词条标签） |
| `text_on_dark_faint`     | `#66FFFFFF` | 暗色背景上的极弱文字（圣遗物等级）              |
| `text_on_dark_ghost`     | `#99FFFFFF` | 暗色背景上的幽灵文字（Phone 小字）              |
| `text_inactive`          | `#444444`   | 未激活状态文字                                  |
| `text_lock_icon`         | `#BFFFFFFF` | 锁图标颜色                                      |

---

## 十、强调色

| color.json name         | 色值        | 用途               |
| ----------------------- | ----------- | ------------------ |
| `accent_refine`         | `#FFCA28`   | 精炼/星级金色      |
| `accent_refine_bg`      | `#26FFCA28` | 精炼标签背景       |
| `accent_primary_strong` | `#E64FC3F7` | 圣遗物主词条强调色 |

---

## 十一、遮罩 / 渐变用色

| color.json name           | 色值        | 用途                 |
| ------------------------- | ----------- | -------------------- |
| `overlay_gradient_end`    | `#B3000000` | 渐变遮罩终止色       |
| `overlay_scrim_top`       | `#BF000000` | 宽屏遮罩底部不透明色 |
| `overlay_shadow`          | `#E6000000` | 阴影遮罩             |
| `overlay_portrait_base`   | `#0C1A30`   | Phone 竖屏遮罩基色   |
| `overlay_portrait_strong` | `#E00C1A30` | Phone 竖屏遮罩强     |
| `overlay_portrait_mid`    | `#660C1A30` | Phone 竖屏遮罩中     |
| `overlay_portrait_bot`    | `#E60A101E` | Phone 竖屏底部遮罩   |
| `overlay_land_opaque`     | `#FF0A101E` | Phone 横屏遮罩不透明 |
| `overlay_land_strong`     | `#B30A101E` | Phone 横屏遮罩强     |
| `overlay_land_fade`       | `#1A0A101E` | Phone 横屏遮罩淡出   |

---

## 十二、角色详情背景渐变色（三档，用于 linearGradient）

每种元素力对应三个深度梯度，用于角色详情页背景渐变（`[color1, 0], [color2, 0.4], [color3, 1.0]`）。

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

## 十三、其他功能色

| color.json name       | 色值        | 用途                 |
| --------------------- | ----------- | -------------------- |
| `weapon_overlay_bg`   | `#8C000000` | 武器卡片遮罩         |
| `rarity_5star`        | `#C8922A`   | 5星文字色            |
| `rarity_5star_bg`     | `#33C8922A` | 5星背景色            |
| `rarity_4star_bg`     | `#339B72CF` | 4星背景色            |
| `role_card_server_bg` | `#66000000` | 角色卡服务器标签背景 |
| `role_card_stat_bg`   | `#73000000` | 角色卡统计格子背景   |
| `login_tab_bar_bg`    | `#0A000000` | 登录页 Tab 栏背景    |
| `login_input_bg`      | `#F8F8F8`   | 登录页输入框背景     |

---

## 渐变角度 Token

| Token 字段名 | 值   | 用途                      |
| ------------ | ---- | ------------------------- |
| `a0`         | 0°   | 底部遮罩（从下到上渐变）  |
| `a90`        | 90°  | 左右遮罩（从左到右渐变）  |
| `a135`       | 135° | 元素背景渐变（左上→右下） |
| `a150`       | 150° | Phone 背景渐变            |
| `a180`       | 180° | 上下遮罩（从上到下渐变）  |

---

## 变更记录

| 日期       | 变更内容                                                                                                                                                                                                                        |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2026-04-14 | 删除 24 个未使用 token：`start_window_background`、`color_nav_bar_solid`、`rarity_4star`、`weapon_affix_bg`、`surface_glass_lg`、`surface_overlay_xs`、`surface_dark_sm`、`surface_dark_3xl`、`sr_element_*` ×7、`sr_path_*` ×9 |
| 2026-03-22 | 初始版本，完成 token 合并优化                                                                                                                                                                                                   |

---

## 待补全颜色（确认后加入 color.json）

### 星铁属性颜色（`sr_element_*`）

| color.json name        | 色值      | 说明 |
| ---------------------- | --------- | ---- |
| `sr_element_physical`  | `#9E9E9E` | 物理 |
| `sr_element_fire`      | `#FF7043` | 火   |
| `sr_element_ice`       | `#4FC3F7` | 冰   |
| `sr_element_lightning` | `#CE93D8` | 雷   |
| `sr_element_wind`      | `#69F0AE` | 风   |
| `sr_element_quantum`   | `#7C4DFF` | 量子 |
| `sr_element_imaginary` | `#FFD54F` | 虚数 |

### 星铁角色详情背景渐变（`bg_sr_element_*`，三档）

| 属性      | 浅        | 中        | 深        |
| --------- | --------- | --------- | --------- |
| physical  | `#1A1A1A` | `#111111` | `#080808` |
| fire      | `#3A1008` | `#2A0E0A` | `#180808` |
| ice       | `#0A2A3A` | `#081E2A` | `#041018` |
| lightning | `#2A1040` | `#1E0A30` | `#100818` |
| wind      | `#083A20` | `#062A18` | `#041810` |
| quantum   | `#1A0A40` | `#120830` | `#080418` |
| imaginary | `#2A2004` | `#1E1804` | `#100E02` |

### 绝区零角色详情背景渐变（`bg_zzz_element_*`，三档）

| 属性     | 浅        | 中        | 深        |
| -------- | --------- | --------- | --------- |
| physical | `#1A1A1A` | `#111111` | `#080808` |
| fire     | `#3A1008` | `#2A0E0A` | `#180808` |
| ice      | `#0A2A3A` | `#081E2A` | `#041018` |
| electric | `#2A1040` | `#1E0A30` | `#100818` |
| ether    | `#2A0A30` | `#1E0820` | `#100410` |

# entry 模块组件测试设计文档

## 说明

本文档针对 `entry/src/main/ets/components/` 下每个 `@ComponentV2` 组件，
分别设计 `@Preview` 预览状态和设备端 UI 测试用例。

**@Preview 规范**：

- 每个组件文件末尾必须有至少一个 `@Preview` 结构体
- 禁止 IIFE，使用 `@Local` 字段存储预览数据
- 背景色统一使用 `'#1a1a2e'`
- 字符串用 `$r('app.string.xxx')`，颜色用 `$r('app.color.xxx')`

**UI 测试位置**：`entry/src/ohosTest/ets/test/`，使用 Hypium + `@ohos/uitest`

---

## 一、home/ 目录组件

### GameToolCard

文件：`components/home/GameToolCard.ets`

**@Preview 状态**

| Preview 名称          | 数据状态                           | 说明                       |
| --------------------- | ---------------------------------- | -------------------------- |
| `GameToolCardPreview` | card1=原神无数据，card2=星铁无数据 | 两张卡片并排，验证空态布局 |

**UI 测试用例**（`GameToolCardTest.test.ets`）

| 用例                 | 操作             | 预期                          |
| -------------------- | ---------------- | ----------------------------- |
| 卡片可点击           | 点击卡片区域     | `onTap` 回调触发              |
| 无数据时显示提示文字 | snapshot=null    | 显示 `home_no_data_hint` 文字 |
| 有数据时显示内容区   | snapshot 非 null | 内容区组件可见                |

---

### UserGameSection

文件：`components/home/UserGameSection.ets`

**@Preview 状态**

| Preview 名称             | 数据状态             | 说明               |
| ------------------------ | -------------------- | ------------------ |
| `UserGameSectionPreview` | 1 个账号，无角色卡片 | 验证账号标题行布局 |

**UI 测试用例**（`UserGameSectionTest.test.ets`）

| 用例                  | 操作                   | 预期                   |
| --------------------- | ---------------------- | ---------------------- |
| 账号昵称显示          | 传入 nickname='旅行者' | 显示 '旅行者'          |
| 无昵称时显示 username | nickname=''            | 显示 username          |
| 角色卡片数量正确      | 传入 2 个角色          | 渲染 2 个 GameToolCard |

---

### HomePlaceholderView

文件：`components/home/HomePlaceholderView.ets`（已有 @Preview）

**UI 测试用例**（`HomePlaceholderViewTest.test.ets`）

| 用例         | 操作         | 预期                              |
| ------------ | ------------ | --------------------------------- |
| 标题文字可见 | 渲染组件     | `home_placeholder_title` 文字可见 |
| 按钮可点击   | 点击登录按钮 | 触发路由跳转到 Login 页           |

---

### HomeSkeletonView

文件：`components/home/HomeSkeletonView.ets`（已有 @Preview）

**UI 测试用例**（`HomeSkeletonViewTest.test.ets`）

| 用例         | 操作      | 预期                  |
| ------------ | --------- | --------------------- |
| 骨架块可见   | 渲染组件  | 至少 2 个骨架色块可见 |
| 骨架动画运行 | 等待 1 秒 | 骨架块透明度发生变化  |

---

### HomeRefreshButton

文件：`components/home/HomeRefreshButton.ets`

**@Preview 状态**

| Preview 名称               | 数据状态                     | 说明             |
| -------------------------- | ---------------------------- | ---------------- |
| `HomeRefreshButtonPreview` | DATA/刷新中/LOADING 三种状态 | 验证按钮显隐逻辑 |

**UI 测试用例**（`HomeRefreshButtonTest.test.ets`）

| 用例                   | 操作                     | 预期                 |
| ---------------------- | ------------------------ | -------------------- |
| DATA 状态按钮可见      | viewState=DATA           | 刷新按钮可见         |
| LOADING 状态按钮不可见 | viewState=LOADING        | 刷新按钮不可见       |
| 刷新中按钮禁用         | isRefreshing=true        | 按钮不可点击         |
| 点击触发回调           | viewState=DATA，点击按钮 | `onRefresh` 回调触发 |

---

### GenshinGameToolCardContent

文件：`components/home/GenshinGameToolCardContent.ets`

**@Preview 状态**

| Preview 名称                        | 数据状态                           | 说明             |
| ----------------------------------- | ---------------------------------- | ---------------- |
| `GenshinGameToolCardContentPreview` | 树脂 140/200，有派遣/宝钱/委托数据 | 验证完整数据布局 |

**UI 测试用例**（`GenshinGameToolCardContentTest.test.ets`）

| 用例             | 操作                               | 预期                   |
| ---------------- | ---------------------------------- | ---------------------- |
| 树脂数值显示     | primaryCurrent=140，primaryMax=200 | 显示 '140' 和 '/200'   |
| 树脂满时颜色变红 | isFull=true                        | 数值颜色为 colorDanger |
| 恢复描述显示     | primaryRecoveryDesc 非空           | 描述文字可见           |
| 环形进度条渲染   | progressRatio=0.7                  | Progress 组件可见      |

---

### StarRailGameToolCardContent

文件：`components/home/StarRailGameToolCardContent.ets`

**@Preview 状态**

| Preview 名称                         | 数据状态                                 | 说明             |
| ------------------------------------ | ---------------------------------------- | ---------------- |
| `StarRailGameToolCardContentPreview` | 开拓力 180/300，有后备/实训/模拟宇宙数据 | 验证完整数据布局 |

**UI 测试用例**（`StarRailGameToolCardContentTest.test.ets`）

| 用例           | 操作                                     | 预期           |
| -------------- | ---------------------------------------- | -------------- |
| 开拓力数值显示 | primaryCurrent=180                       | 显示 '180'     |
| 后备开拓力显示 | reserveStamina=2400                      | 显示 '2400'    |
| 实训积分显示   | trainScoreCurrent=400，trainScoreMax=500 | 显示 '400/500' |

---

### ZZZGameToolCardContent

文件：`components/home/ZZZGameToolCardContent.ets`

**@Preview 状态**

| Preview 名称                    | 数据状态                               | 说明             |
| ------------------------------- | -------------------------------------- | ---------------- |
| `ZZZGameToolCardContentPreview` | 电量 180/240，活跃度/刮刮卡/录像店数据 | 验证完整数据布局 |

**UI 测试用例**（`ZZZGameToolCardContentTest.test.ets`）

| 用例         | 操作                   | 预期          |
| ------------ | ---------------------- | ------------- |
| 电量数值显示 | primaryCurrent=180     | 显示 '180'    |
| 刮刮卡已完成 | scratchCardDone=true   | 显示 '已完成' |
| 录像店营业中 | videoStoreState='open' | 显示 '营业中' |

---

### GenericGameToolCardContent

文件：`components/home/GenericGameToolCardContent.ets`

**@Preview 状态**

| Preview 名称                        | 数据状态                 | 说明         |
| ----------------------------------- | ------------------------ | ------------ |
| `GenericGameToolCardContentPreview` | 体力 120/240，有恢复描述 | 验证通用布局 |

---

### GameDataRow

文件：`components/home/GameDataRow.ets`

**@Preview 状态**

| Preview 名称         | 数据状态     | 说明                   |
| -------------------- | ------------ | ---------------------- |
| `GameDataRowPreview` | 3 行不同数据 | 验证 emoji+标签+值布局 |

**UI 测试用例**（`GameDataRowTest.test.ets`）

| 用例         | 操作                                            | 预期           |
| ------------ | ----------------------------------------------- | -------------- |
| 标签文字显示 | label=`$r('app.string.daily_note_resin_title')` | 标签文字可见   |
| 值文字显示   | value='140/200'                                 | '140/200' 可见 |

---

### HomeContent

文件：`components/home/HomeContent.ets`

**UI 测试用例**（`HomeContentTest.test.ets`）

| 用例                   | 操作                       | 预期                     |
| ---------------------- | -------------------------- | ------------------------ |
| LOADING 状态显示骨架屏 | viewState=LOADING          | HomeSkeletonView 可见    |
| EMPTY 状态显示占位     | viewState=EMPTY            | HomePlaceholderView 可见 |
| DATA 状态显示账号列表  | viewState=DATA，有账号数据 | UserGameSection 可见     |

---

## 二、characters/ 目录组件

### CharacterCard

文件：`components/characters/CharacterCard.ets`

**@Preview 状态**

| Preview 名称           | 数据状态                   | 说明                     |
| ---------------------- | -------------------------- | ------------------------ |
| `CharacterCardPreview` | 原神/星铁/绝区零各一张卡片 | 验证三种游戏的差异化布局 |

**UI 测试用例**（`CharacterCardTest.test.ets`）

| 用例                      | 操作                               | 预期                                   |
| ------------------------- | ---------------------------------- | -------------------------------------- |
| 角色名显示                | name='纳西妲'                      | '纳西妲' 文字可见                      |
| 5 星背景色                | rarity=5                           | 背景色为 rarity_5star_bg               |
| 4 星背景色                | rarity=4                           | 背景色为 rarity_4star_bg               |
| 命座数字显示              | extraInt1=6                        | '6' 可见（右上角）                     |
| 点击触发回调              | 点击卡片                           | `onTap` 回调触发，参数为对应 character |
| 原神显示元素圆形角标      | gameId='genshin'                   | 左上角元素圆形标签可见                 |
| 星铁显示属性+命途标签     | gameId='starrail'                  | 左上角纵向胶囊标签可见                 |
| 绝区零显示稀有度+属性标签 | gameId='zzz'                       | 左上角纵向胶囊标签可见                 |
| 有武器时显示武器浮层      | hasWeaponSlot=true，weaponLevel=90 | 右下角武器浮层可见，显示 Lv.90         |
| 无武器时显示未装备占位    | hasWeaponSlot=true，weaponLevel=0  | 右下角显示禁止圆圈图标和"未装备"文字   |
| 无武器槽位时不显示浮层    | hasWeaponSlot=false                | 右下角武器浮层不可见                   |

---

### CharactersSkeleton

文件：`components/characters/CharactersSkeleton.ets`（已有 @Preview）

**UI 测试用例**（`CharactersSkeletonTest.test.ets`）

| 用例       | 操作     | 预期                  |
| ---------- | -------- | --------------------- |
| 骨架块数量 | 渲染组件 | 至少 4 个骨架色块可见 |

---

### GameTabBar

文件：`components/characters/GameTabBar.ets`（已有 @Preview）

**UI 测试用例**（`GameTabBarTest.test.ets`）

| 用例              | 操作           | 预期                                 |
| ----------------- | -------------- | ------------------------------------ |
| 选中 Tab 高亮     | selectedIdx=0  | 第一个 Tab 背景色为 color_primary_bg |
| 未选中 Tab 无高亮 | selectedIdx=0  | 第二个 Tab 背景透明                  |
| 点击 Tab 触发回调 | 点击第二个 Tab | `onSelect(1)` 触发                   |

---

### CharactersContent

文件：`components/characters/CharactersContent.ets`

**@Preview 状态**

| Preview 名称                    | 数据状态                | 说明         |
| ------------------------------- | ----------------------- | ------------ |
| `CharactersContentPreviewEmpty` | viewState=EMPTY，无账号 | 验证空态占位 |

**UI 测试用例**（`CharactersContentTest.test.ets`）

| 用例                     | 操作                                 | 预期                     |
| ------------------------ | ------------------------------------ | ------------------------ |
| LOADING 显示骨架屏       | viewState=LOADING                    | CharactersSkeleton 可见  |
| EMPTY 无账号显示登录占位 | viewState=EMPTY，accountOptions=[]   | HomePlaceholderView 可见 |
| EMPTY 有账号显示刷新提示 | viewState=EMPTY，accountOptions 非空 | 刷新按钮可见             |
| DATA 显示角色网格        | viewState=DATA，有角色数据           | CharacterCard 可见       |
| 多游戏时显示 Tab 栏      | gameTabs.length > 1                  | GameTabBar 可见          |
| 单游戏时不显示 Tab 栏    | gameTabs.length = 1                  | GameTabBar 不可见        |

---

## 三、chardetail/ 目录组件

### CharDetailHeroPanel

文件：`components/chardetail/CharDetailHeroPanel.ets`（已有 @Preview）

**UI 测试用例**（`CharDetailHeroPanelTest.test.ets`）

| 用例               | 操作                    | 预期                                  |
| ------------------ | ----------------------- | ------------------------------------- |
| WIDE 模式渲染      | mode=WIDE               | CharDetailHeroPanelWide 可见          |
| PORTRAIT 模式渲染  | mode=PORTRAIT           | CharDetailHeroPanelPortrait 可见      |
| LANDSCAPE 模式渲染 | mode=LANDSCAPE          | CharDetailHeroPanelLandscape 可见     |
| 角色名显示         | charName='夜兰'         | '夜兰' 文字可见                       |
| 命座数量正确       | constellations.length=6 | 6 个命座图标可见                      |
| 已激活命座高亮     | isActived=true          | 激活命座背景色为 surfaceActivePrimary |

---

### CharDetailStatsPanel

文件：`components/chardetail/CharDetailStatsPanel.ets`（已有 @Preview）

**UI 测试用例**（`CharDetailStatsPanelTest.test.ets`）

| 用例         | 操作                   | 预期             |
| ------------ | ---------------------- | ---------------- |
| 武器名显示   | weapon.name='苇海信标' | '苇海信标' 可见  |
| 武器等级显示 | weapon.level=90        | 'Lv.90' 可见     |
| 精炼等级显示 | weapon.affix=1         | 'R1' 可见        |
| 属性列表渲染 | stats 有 7 条          | 7 行属性可见     |
| 暴击率高亮   | stat.isHighlight=true  | 文字颜色为元素色 |

---

### CharDetailRelicsPanel

文件：`components/chardetail/CharDetailRelicsPanel.ets`（已有 @Preview）

**UI 测试用例**（`CharDetailRelicsPanelTest.test.ets`）

| 用例           | 操作                      | 预期               |
| -------------- | ------------------------- | ------------------ |
| 宽屏 5 行等分  | isPhone=false，5 件圣遗物 | 5 行圣遗物可见     |
| Phone 2 列网格 | isPhone=true，5 件圣遗物  | 5 个圣遗物卡片可见 |
| 主词条显示     | mainStatValue='46.6%'     | '46.6%' 可见       |
| 副词条显示     | subStats 有 4 条          | 4 条副词条可见     |

---

### CharDetailSkillsColumn

文件：`components/chardetail/CharDetailSkillsColumn.ets`（已有 @Preview）

**UI 测试用例**（`CharDetailSkillsColumnTest.test.ets`）

| 用例         | 操作            | 预期                 |
| ------------ | --------------- | -------------------- |
| 技能数量正确 | skills.length=3 | 3 个技能等级数字可见 |
| 技能等级显示 | skill.level=10  | '10' 可见            |

---

### CharDetailConsColumn

文件：`components/chardetail/CharDetailConsColumn.ets`（已有 @Preview）

**UI 测试用例**（`CharDetailConsColumnTest.test.ets`）

| 用例               | 操作                    | 预期         |
| ------------------ | ----------------------- | ------------ |
| 命座数量正确       | constellations.length=6 | 6 个命座可见 |
| 已激活命座无锁图标 | isActived=true          | 锁图标不可见 |
| 未激活命座有锁图标 | isActived=false         | 锁图标可见   |

---

### CharDetailEmptyView

文件：`components/chardetail/CharDetailEmptyView.ets`

**@Preview 状态**

| Preview 名称                 | 数据状态 | 说明             |
| ---------------------------- | -------- | ---------------- |
| `CharDetailEmptyViewPreview` | 默认状态 | 验证空态文字居中 |

**UI 测试用例**（`CharDetailEmptyViewTest.test.ets`）

| 用例         | 操作     | 预期                           |
| ------------ | -------- | ------------------------------ |
| 空态文字可见 | 渲染组件 | `char_detail_no_data` 文字可见 |

---

### CharDetailLoadingView

文件：`components/chardetail/CharDetailLoadingView.ets`

**@Preview 状态**

| Preview 名称                   | 数据状态 | 说明             |
| ------------------------------ | -------- | ---------------- |
| `CharDetailLoadingViewPreview` | 默认状态 | 验证加载动画居中 |

**UI 测试用例**（`CharDetailLoadingViewTest.test.ets`）

| 用例                 | 操作     | 预期                     |
| -------------------- | -------- | ------------------------ |
| LoadingProgress 可见 | 渲染组件 | LoadingProgress 组件可见 |

---

## 四、dailynote/ 目录组件

### DailyNoteCard

文件：`components/dailynote/DailyNoteCard.ets`（已有 @Preview）

**UI 测试用例**（`DailyNoteCardTest.test.ets`）

| 用例           | 操作                                     | 预期                  |
| -------------- | ---------------------------------------- | --------------------- |
| 标题文字显示   | title='原粹树脂'                         | '原粹树脂' 可见       |
| 副标题显示     | hasSubtitle=true，subtitle='4小时后恢复' | 副标题可见            |
| 副标题隐藏     | hasSubtitle=false                        | 副标题不可见          |
| 右侧值显示     | hasValueText=true，valueText='140/200'   | '140/200' 可见        |
| 自定义右侧插槽 | hasCustomRight=true                      | customRight 内容可见  |
| 自定义底部插槽 | hasCustomBottom=true                     | customBottom 内容可见 |

---

### DailyNoteGenshin

文件：`components/dailynote/DailyNoteGenshin.ets`（已有 @Preview）

**UI 测试用例**（`DailyNoteGenshinTest.test.ets`）

| 用例           | 操作                              | 预期                     |
| -------------- | --------------------------------- | ------------------------ |
| 树脂数值显示   | currentResin=140，maxResin=200    | '140/200' 可见           |
| 树脂满时警告色 | currentResin=200，maxResin=200    | 数值颜色为 colorDanger   |
| 洞天宝钱显示   | currentHomeCoin=1800              | '1800/2400' 可见         |
| 委托完成状态   | finishedTaskNum=4，totalTaskNum=4 | 4 个勾选标记可见         |
| 派遣列表显示   | expeditions.length=3              | 3 个 ExpeditionItem 可见 |
| 参量质变仪就绪 | transformerReady=true             | '可使用' 文字可见        |

---

### ExpeditionItem

文件：`components/dailynote/ExpeditionItem.ets`（已有 @Preview）

**UI 测试用例**（`ExpeditionItemTest.test.ets`）

| 用例               | 操作                                     | 预期                                      |
| ------------------ | ---------------------------------------- | ----------------------------------------- |
| 进行中显示剩余时间 | finished=false，remainTime='8小时14分钟' | '8小时14分钟' 可见                        |
| 已完成显示完成文字 | finished=true                            | `daily_note_expedition_finished` 文字可见 |
| 无头像显示占位圆   | avatarUrl=''                             | 占位圆可见                                |

---

## 五、login/ 目录组件

### LoginQRCode

文件：`components/login/LoginQRCode.ets`（已有 @Preview）

**UI 测试用例**（`LoginQRCodeTest.test.ets`）

| 用例                       | 操作                             | 预期                            |
| -------------------------- | -------------------------------- | ------------------------------- |
| LOADING 状态显示加载动画   | qrCodeStat=LOADING               | LoadingProgress 可见            |
| READY 状态显示二维码       | qrCodeStat=READY，qrCodeUrl 非空 | QRCode 组件可见                 |
| SCANNED 状态显示已扫码提示 | qrCodeStat=SCANNED               | `login_qrcode_scanned` 文字可见 |
| EXPIRED 状态显示刷新按钮   | qrCodeStat=EXPIRED               | 刷新按钮可见                    |
| 点击刷新按钮触发刷新       | qrCodeStat=EXPIRED，点击刷新     | `vm.refreshQRCode()` 被调用     |

---

### LoginLogoSection

文件：`components/login/LoginLogoSection.ets`

**@Preview 状态**

| Preview 名称              | 数据状态    | 说明                        |
| ------------------------- | ----------- | --------------------------- |
| `LoginLogoSectionPreview` | logoSize=64 | 验证 Logo+应用名+副标题布局 |

**UI 测试用例**（`LoginLogoSectionTest.test.ets`）

| 用例       | 操作     | 预期                       |
| ---------- | -------- | -------------------------- |
| 应用名显示 | 渲染组件 | `app_name` 文字可见        |
| 副标题显示 | 渲染组件 | `launch_subtitle` 文字可见 |

---

### LoginTabBar

文件：`components/login/LoginTabBar.ets`

**@Preview 状态**

| Preview 名称         | 数据状态        | 说明              |
| -------------------- | --------------- | ----------------- |
| `LoginTabBarPreview` | activeTab=PHONE | 验证三个 Tab 布局 |

**UI 测试用例**（`LoginTabBarTest.test.ets`）

| 用例            | 操作           | 预期                                   |
| --------------- | -------------- | -------------------------------------- |
| 手机号 Tab 可见 | 渲染组件       | `login_tab_phone` 文字可见             |
| 二维码 Tab 可见 | 渲染组件       | `login_tab_qrcode` 文字可见            |
| Cookie Tab 可见 | 渲染组件       | `login_tab_cookie` 文字可见            |
| 点击 Tab 切换   | 点击二维码 Tab | `vm.switchTab(LoginTab.QRCODE)` 被调用 |

---

### LoginCookie

文件：`components/login/LoginCookie.ets`

**@Preview 状态**

| Preview 名称         | 数据状态   | 说明                |
| -------------------- | ---------- | ------------------- |
| `LoginCookiePreview` | 默认空状态 | 验证输入框+按钮布局 |

**UI 测试用例**（`LoginCookieTest.test.ets`）

| 用例                       | 操作                   | 预期                        |
| -------------------------- | ---------------------- | --------------------------- |
| 输入框可见                 | 渲染组件               | TextArea 可见               |
| 空输入时按钮禁用           | cookieInput=''         | 登录按钮不可点击            |
| 有输入时按钮启用           | cookieInput='xxx=yyy'  | 登录按钮可点击              |
| 点击登录触发 loginByCookie | 输入 Cookie 后点击登录 | `vm.loginByCookie()` 被调用 |
| 错误信息显示               | vm.errorMsg='错误'     | 错误文字可见                |

---

### LoginFeatureItem

文件：`components/login/LoginFeatureItem.ets`

**@Preview 状态**

| Preview 名称              | 数据状态     | 说明              |
| ------------------------- | ------------ | ----------------- |
| `LoginFeatureItemPreview` | 2 个特性条目 | 验证圆点+文字布局 |

---

## 六、my/ 目录组件

### AccountListSection

文件：`components/my/AccountListSection.ets`

**@Preview 状态**

| Preview 名称                | 数据状态              | 说明               |
| --------------------------- | --------------------- | ------------------ |
| `AccountListSectionPreview` | 有账号/空账号两种状态 | 验证列表和空态布局 |

**UI 测试用例**（`AccountListSectionTest.test.ets`）

| 用例               | 操作              | 预期                        |
| ------------------ | ----------------- | --------------------------- |
| 空账号显示提示文字 | accounts=[]       | `my_account_empty` 文字可见 |
| 账号列表显示       | accounts 有 2 条  | 2 个账号行可见              |
| 账号昵称显示       | nickname='旅行者' | '旅行者' 可见               |
| 点击账号触发回调   | 点击账号行        | `onAccountTap` 回调触发     |
| 添加账号按钮可见   | 渲染组件          | `my_account_add` 按钮可见   |
| 点击添加触发回调   | 点击添加按钮      | `onAddTap` 回调触发         |

---

### SectionHeader

文件：`components/my/SectionHeader.ets`

**@Preview 状态**

| Preview 名称           | 数据状态     | 说明             |
| ---------------------- | ------------ | ---------------- |
| `SectionHeaderPreview` | 2 个不同标题 | 验证标题文字样式 |

**UI 测试用例**（`SectionHeaderTest.test.ets`）

| 用例         | 操作                                        | 预期         |
| ------------ | ------------------------------------------- | ------------ |
| 标题文字显示 | title=`$r('app.string.my_section_account')` | 对应文字可见 |

---

### AboutSection

文件：`components/my/AboutSection.ets`

**@Preview 状态**

| Preview 名称          | 数据状态 | 说明                         |
| --------------------- | -------- | ---------------------------- |
| `AboutSectionPreview` | 默认状态 | 验证版本号/GitHub/许可证布局 |

**UI 测试用例**（`AboutSectionTest.test.ets`）

| 用例              | 操作     | 预期                        |
| ----------------- | -------- | --------------------------- |
| 版本号行可见      | 渲染组件 | `my_about_version` 文字可见 |
| GitHub 链接行可见 | 渲染组件 | `my_about_github` 文字可见  |
| 许可证行可见      | 渲染组件 | `my_about_license` 文字可见 |

---

### AppearanceSection

文件：`components/my/AppearanceSection.ets`

**@Preview 状态**

| Preview 名称               | 数据状态                  | 说明                 |
| -------------------------- | ------------------------- | -------------------- |
| `AppearanceSectionPreview` | themeMode=COLOR_MODE_DARK | 验证深色模式选中状态 |

**UI 测试用例**（`AppearanceSectionTest.test.ets`）

| 用例             | 操作                      | 预期                                   |
| ---------------- | ------------------------- | -------------------------------------- |
| 三个主题按钮可见 | 渲染组件                  | 浅色/深色/跟随系统按钮可见             |
| 当前模式按钮高亮 | themeMode=COLOR_MODE_DARK | 深色按钮背景为 colorPrimary            |
| 点击切换触发回调 | 点击浅色按钮              | `onThemeChange(COLOR_MODE_LIGHT)` 触发 |

---

## 七、accountdetail/ 目录组件

### AccountRolesSection

文件：`components/accountdetail/AccountRolesSection.ets`

**@Preview 状态**

| Preview 名称                 | 数据状态                 | 说明                 |
| ---------------------------- | ------------------------ | -------------------- |
| `AccountRolesSectionPreview` | 1 个原神角色，有统计数据 | 验证角色卡片完整布局 |

**UI 测试用例**（`AccountRolesSectionTest.test.ets`）

| 用例             | 操作                   | 预期                        |
| ---------------- | ---------------------- | --------------------------- |
| 空角色显示提示   | roles=[]               | `my_account_empty` 文字可见 |
| 游戏名显示       | role.gameName=原神     | 游戏名文字可见              |
| 昵称显示         | role.nickname='旅行者' | '旅行者' 可见               |
| 等级标签显示     | role.level=60          | 'Lv.60' 可见                |
| 统计数据格子显示 | stats 有 4 条          | 4 个统计格子可见            |

---

### AccountActionsSection

文件：`components/accountdetail/AccountActionsSection.ets`

**@Preview 状态**

| Preview 名称                   | 数据状态 | 说明             |
| ------------------------------ | -------- | ---------------- |
| `AccountActionsSectionPreview` | 默认状态 | 验证删除按钮布局 |

**UI 测试用例**（`AccountActionsSectionTest.test.ets`）

| 用例             | 操作         | 预期                             |
| ---------------- | ------------ | -------------------------------- |
| 删除按钮可见     | 渲染组件     | `account_detail_delete` 按钮可见 |
| 点击删除触发回调 | 点击删除按钮 | `onDelete` 回调触发              |

---

## 八、main/ 目录组件

### BottomTabItem

文件：`components/main/BottomTabItem.ets`

**@Preview 状态**

| Preview 名称           | 数据状态             | 说明                |
| ---------------------- | -------------------- | ------------------- |
| `BottomTabItemPreview` | 3 个 Tab，第一个选中 | 验证选中/未选中状态 |

**UI 测试用例**（`BottomTabItemTest.test.ets`）

| 用例                        | 操作                 | 预期                          |
| --------------------------- | -------------------- | ----------------------------- |
| 选中 Tab 标签颜色为主色     | tab=0，selectedTab=0 | 标签颜色为 colorPrimary       |
| 未选中 Tab 标签颜色为次要色 | tab=1，selectedTab=0 | 标签颜色为 colorTextSecondary |
| 点击触发回调                | 点击 Tab             | `onSelect(tab)` 触发          |

---

### SidebarNavItem

文件：`components/main/SidebarNavItem.ets`

**@Preview 状态**

| Preview 名称            | 数据状态               | 说明                |
| ----------------------- | ---------------------- | ------------------- |
| `SidebarNavItemPreview` | 3 个导航项，第一个选中 | 验证选中/未选中状态 |

**UI 测试用例**（`SidebarNavItemTest.test.ets`）

| 用例             | 操作                 | 预期                      |
| ---------------- | -------------------- | ------------------------- |
| 选中项背景高亮   | tab=0，selectedTab=0 | 背景色为 color_primary_bg |
| 未选中项背景透明 | tab=1，selectedTab=0 | 背景透明                  |
| 点击触发回调     | 点击导航项           | `onSelect(tab)` 触发      |

---

## 九、根目录组件

### SplitPlaceholder

文件：`components/SplitPlaceholder.ets`

**@Preview 状态**

| Preview 名称              | 数据状态 | 说明           |
| ------------------------- | -------- | -------------- |
| `SplitPlaceholderPreview` | 默认状态 | 验证全屏背景色 |

**UI 测试用例**（`SplitPlaceholderTest.test.ets`）

| 用例               | 操作     | 预期                 |
| ------------------ | -------- | -------------------- |
| 背景色为页面背景色 | 渲染组件 | 背景色为 colorPageBg |
| 占满全部空间       | 渲染组件 | 宽高均为 100%        |

---

## 十、Unhappy Flow 和边界场景补充

> 以下用例补充到对应组件测试文件中。

### 10.1 通用边界场景

**超长文字截断**

| 组件                | 用例                       | 预期结果                   |
| ------------------- | -------------------------- | -------------------------- |
| GameToolCard        | nickname 超过 20 个字符    | 文字截断显示省略号，不换行 |
| GameToolCard        | server 名称超长            | 文字截断，不溢出卡片       |
| AccountListSection  | nickname 超过 20 个字符    | 文字截断显示省略号         |
| AccountRolesSection | 游戏名超长                 | 文字截断，不溢出           |
| CharacterCard       | 角色名超长（如 10 个汉字） | 文字截断，不换行           |

**空 URL 图片占位**

| 组件                | 用例                             | 预期结果                           |
| ------------------- | -------------------------------- | ---------------------------------- |
| GameToolCard        | gameLogoResource 对应游戏无 logo | 显示默认 logo，不崩溃              |
| UserGameSection     | avatarUrl=''                     | 显示占位色块，不崩溃               |
| AccountListSection  | avatarUrl=''                     | 显示占位色块，不崩溃               |
| CharacterCard       | iconUrl=''                       | 显示背景色，不崩溃                 |
| CharacterCard       | squareIconUrl=''                 | 显示背景色，不崩溃                 |
| CharacterCard       | weaponIconUrl=''                 | 显示占位色块，不崩溃               |
| AccountRolesSection | bgImageUrl=''                    | 显示纯色背景，不崩溃               |
| AccountRolesSection | bgImageUrl='invalid_url'         | 图片加载失败，显示纯色背景，不崩溃 |

---

### 10.2 home/ 组件边界场景

**GameToolCard**

| 用例                    | 操作                  | 预期结果                                    |
| ----------------------- | --------------------- | ------------------------------------------- |
| snapshot 为 null        | card.snapshot=null    | 显示 `home_no_data_hint`，不崩溃            |
| primaryCurrent=0        | snap.primaryCurrent=0 | 显示 '0'，不崩溃                            |
| primaryMax=0            | snap.primaryMax=0     | 显示 '/0'，progressRatio 不除以 0（应为 0） |
| progressRatio=1.0（满） | progressRatio=1.0     | 环形进度条满格，不崩溃                      |
| progressRatio=0         | progressRatio=0       | 环形进度条为空，不崩溃                      |
| isFull=true             | snap.isFull=true      | 数值颜色为 colorDanger                      |

**GenshinGameToolCardContent**

| 用例                      | 操作                           | 预期结果                   |
| ------------------------- | ------------------------------ | -------------------------- |
| expeditionCurrent=-1      | snap.expeditionCurrent=-1      | 不显示派遣行（< 0 时隐藏） |
| homeCoinCurrent=-1        | snap.homeCoinCurrent=-1        | 不显示宝钱行               |
| dailyTaskFinished=-1      | snap.dailyTaskFinished=-1      | 不显示委托行               |
| dailyTaskAllReceived=true | snap.dailyTaskAllReceived=true | 显示 '已全部领取'          |

**StarRailGameToolCardContent**

| 用例                 | 操作                      | 预期结果           |
| -------------------- | ------------------------- | ------------------ |
| reserveStamina=-1    | snap.reserveStamina=-1    | 不显示后备开拓力行 |
| trainScoreCurrent=-1 | snap.trainScoreCurrent=-1 | 不显示实训积分行   |

**ZZZGameToolCardContent**

| 用例                            | 操作                                 | 预期结果       |
| ------------------------------- | ------------------------------------ | -------------- |
| vitalityCurrent=-1              | snap.vitalityCurrent=-1              | 不显示活跃度行 |
| videoStoreState=''              | snap.videoStoreState=''              | 不显示录像店行 |
| videoStoreState='SaleStateDone' | snap.videoStoreState='SaleStateDone' | 显示 '已结算'  |

---

### 10.3 characters/ 组件边界场景

**CharacterCard**

| 用例                   | 操作                                        | 预期结果                                      |
| ---------------------- | ------------------------------------------- | --------------------------------------------- |
| rarity=4（4 星）       | character.rarity=4                          | 背景色为 rarity_4star_bg                      |
| rarity=5（5 星）       | character.rarity=5                          | 背景色为 rarity_5star_bg                      |
| extraInt1=0（0 命）    | character.extraInt1=0                       | 右上角显示 '0'                                |
| extraInt1=6（6 命）    | character.extraInt1=6                       | 右上角显示 '6'                                |
| extraInt2=0（好感 0）  | character.extraInt2=0                       | 底部显示 '好感 0'                             |
| extraInt2=10（好感满） | character.extraInt2=10                      | 底部显示 '好感 10'                            |
| level=1（最低等级）    | character.level=1                           | 显示 'Lv.1'                                   |
| level=90（最高等级）   | character.level=90                          | 显示 'Lv.90'                                  |
| weaponLevel=0          | character.weaponLevel=0，hasWeaponSlot=true | 显示未装备占位（禁止圆圈 + "未装备"），不崩溃 |
| weaponAffix=1（R1）    | character.weaponAffix=1                     | 显示 'R1'                                     |
| weaponAffix=5（R5）    | character.weaponAffix=5                     | 显示 'R5'                                     |
| 绝区零 rarity='S'      | character.rarity=5（映射为 S）              | 左上角显示 'S'                                |
| 绝区零 rarity='A'      | character.rarity=4（映射为 A）              | 左上角显示 'A'                                |

---

### 10.4 chardetail/ 组件边界场景

**CharDetailConsColumn**

| 用例                     | 操作              | 预期结果               |
| ------------------------ | ----------------- | ---------------------- |
| constellations 为空数组  | constellations=[] | 不显示任何命座，不崩溃 |
| 命座无图标（iconUrl=''） | c.iconUrl=''      | 显示序号兜底，不崩溃   |

**CharDetailRelicsPanel**

| 用例            | 操作              | 预期结果                 |
| --------------- | ----------------- | ------------------------ |
| relics 为空数组 | vm.relics=[]      | 不显示任何圣遗物，不崩溃 |
| 圣遗物无副词条  | relic.subStats=[] | 不显示副词条区域，不崩溃 |
| 圣遗物 level=0  | relic.level=0     | 显示 '+0'，不崩溃        |
| 圣遗物 level=20 | relic.level=20    | 显示 '+20'               |

**CharDetailStatsPanel**

| 用例                    | 操作                 | 预期结果               |
| ----------------------- | -------------------- | ---------------------- |
| stats 为空数组          | vm.stats=[]          | 不显示属性列表，不崩溃 |
| weapon.subLabel=null    | weapon.subLabel=null | 不显示副词条行，不崩溃 |
| weapon.rarity=3（3 星） | weapon.rarity=3      | 显示 3 个星级，不崩溃  |

---

### 10.5 dailynote/ 组件边界场景

**DailyNoteGenshin**

| 用例                     | 操作                                               | 预期结果                               |
| ------------------------ | -------------------------------------------------- | -------------------------------------- |
| 树脂值为 0               | currentResin=0，maxResin=200                       | 显示 '0/200'，不崩溃                   |
| 树脂值等于上限           | currentResin=200，maxResin=200                     | 显示红色警告，恢复描述为空             |
| 树脂超过上限（异常数据） | currentResin=201，maxResin=200                     | 不崩溃，progressRatio 被 min(1.0) 限制 |
| 洞天宝钱为 0             | currentHomeCoin=0                                  | 显示 '0/2400'，不崩溃                  |
| 洞天宝钱等于上限         | currentHomeCoin=2400                               | 恢复描述为空                           |
| 委托全部完成且已领取     | finishedTaskNum=4，isExtraTaskRewardReceived=true  | 显示 '已全部领取'                      |
| 委托全部完成但未领取     | finishedTaskNum=4，isExtraTaskRewardReceived=false | 显示 '未领取' 提示                     |
| 派遣列表为空             | expeditions=[]                                     | 不显示派遣区域，不崩溃                 |
| 参量质变仪已就绪         | transformerReady=true                              | 显示 '可使用'，不显示倒计时            |
| 参量质变仪未获得         | transformer.obtained=false                         | 不显示参量质变仪行（或显示未获得状态） |

**ExpeditionItem**

| 用例                 | 操作                        | 预期结果                         |
| -------------------- | --------------------------- | -------------------------------- |
| remainTime 为 '0'    | expedition.remainedTime='0' | 显示已完成状态                   |
| avatarUrl 为无效 URL | avatarUrl='invalid'         | 图片加载失败，显示占位圆，不崩溃 |

---

### 10.6 login/ 组件边界场景

**LoginCookie**

| 用例                      | 操作                           | 预期结果                    |
| ------------------------- | ------------------------------ | --------------------------- |
| cookieInput 只有空格      | cookieInput=' '                | 登录按钮禁用（trim 后为空） |
| cookieInput 超长（>10KB） | 粘贴超长内容                   | 输入框接受，不崩溃          |
| errorMsg 超长             | errorMsg 为 200 字符的错误信息 | 文字截断或换行，不溢出      |

**LoginQRCode**

| 用例                 | 操作                           | 预期结果                        |
| -------------------- | ------------------------------ | ------------------------------- |
| qrCodeUrl 为空字符串 | qrCodeUrl=''，qrCodeStat=READY | QRCode 组件显示空二维码，不崩溃 |
| qrCodeUrl 超长       | qrCodeUrl 为 500 字符的 URL    | QRCode 正常生成，不崩溃         |

---

### 10.7 my/ 组件边界场景

**AccountListSection**

| 用例                   | 操作               | 预期结果                     |
| ---------------------- | ------------------ | ---------------------------- |
| 账号数量极多（>10 个） | accounts.length=10 | 全部显示，列表可滚动，不崩溃 |
| 账号 roles.length=0    | roles=[]           | 显示 '0 个游戏角色'，不崩溃  |
| 账号 roles.length 极大 | roles.length=20    | 数字正确显示，不崩溃         |

**AccountRolesSection**

| 用例                | 操作                   | 预期结果                           |
| ------------------- | ---------------------- | ---------------------------------- |
| stats 为空数组      | role.stats=[]          | 不显示统计格子，不崩溃             |
| stats 数量不足 4 个 | stats.length=2         | 只显示 2 个格子，不崩溃            |
| stats 数量超过 8 个 | stats.length=10        | 显示全部（Grid 自动换行），不崩溃  |
| stat.value 超长     | stat.value='999999999' | 文字截断，不溢出格子               |
| level=0             | role.level=0           | 不显示等级标签（level > 0 才显示） |

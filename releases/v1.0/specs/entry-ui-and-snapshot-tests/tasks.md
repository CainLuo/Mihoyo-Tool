# Tasks

## Task List

### 1. entry/src/ohosTest/ — 页面级 UI 测试

- [ ] 1.1 新建 `entry/src/ohosTest/ets/test/MainPageTest.test.ets`
  - 测试默认显示 Home Tab（Home Tab 高亮）
  - 测试点击 Characters Tab 切换（Characters 内容区可见）
  - 测试点击 My Tab 切换（My 内容区可见）
  - 测试切换 Tab 不重置导航栈（Home Tab 进入详情页后切换到 My Tab 再切回，仍显示详情页）
  - 测试 Phone 模式显示底部 Tab 栏
  - 测试宽屏模式显示侧边导航
  - 测试 Home Tab 显示刷新按钮（有账号数据时）
  - 测试非 Home Tab 不显示刷新按钮
  - 测试快速连续切换 Tab 不崩溃
  - 测试应用冷启动无账号数据时 Home/Characters/My 均显示空态

- [ ] 1.2 新建 `entry/src/ohosTest/ets/test/HomePageTest.test.ets`
  - 测试无账号时显示空态占位（`home_placeholder_title` 文字可见）
  - 测试无账号时显示登录按钮（`home_placeholder_button` 按钮可见）
  - 测试有账号时显示骨架屏（加载中立即截图，HomeSkeletonView 骨架块可见）
  - 测试有账号时加载完成显示卡片（等待 1 秒，UserGameSection 可见）
  - 测试刷新按钮在 DATA 状态可见
  - 测试点击刷新按钮触发刷新（按钮进入禁用状态）
  - 测试点击游戏卡片跳转便笺详情（点击原神卡片，跳转到 GenshinDailyDetail 页）
  - 测试网络错误时弹出 Alert（Mock retcode=-100，弹出错误 Dialog）
  - 测试有账号但无任何游戏角色（显示账号标题行，无游戏卡片，不崩溃）
  - 测试 30 分钟内重复刷新弹出冷却 Dialog

- [ ] 1.3 新建 `entry/src/ohosTest/ets/test/CharactersPageTest.test.ets`
  - 测试无账号时显示登录占位（HomePlaceholderView 可见）
  - 测试有账号无角色数据时显示骨架屏（CharactersSkeleton 可见）
  - 测试有角色数据时显示角色网格（等待 1 秒，CharacterCard 可见）
  - 测试多游戏时显示 Tab 栏（GameTabBar 可见）
  - 测试点击 Tab 切换游戏（点击星铁 Tab，显示星铁角色数据）
  - 测试点击角色卡片跳转详情（跳转到 GenshinCharacterDetail 页）
  - 测试刷新冷却时弹出 Dialog（30 分钟内已同步）
  - 测试冷却 Dialog 点击强制同步（触发 forceRefresh）
  - 测试快速切换账号不崩溃（最终显示最后选中账号的数据）
  - 测试同步失败后显示空态（viewState 变为 EMPTY，不崩溃）

- [ ] 1.4 新建 `entry/src/ohosTest/ets/test/MyPageTest.test.ets`
  - 测试无账号时显示空态提示（`my_account_empty` 文字可见）
  - 测试有账号时显示账号列表（账号行可见）
  - 测试账号昵称显示（昵称文字可见）
  - 测试点击账号跳转详情（跳转到 AccountDetail 页）
  - 测试添加账号按钮可见（`my_account_add` 按钮可见）
  - 测试点击添加账号跳转登录（跳转到 Login 页）
  - 测试外观设置区域可见（AppearanceSection 可见）
  - 测试关于区域可见（AboutSection 可见）
  - 测试切换主题模式（点击深色模式按钮，深色按钮高亮，主题切换）
  - 测试删除最后一个账号后显示空态（`my_account_empty` 可见）

- [ ] 1.5 新建 `entry/src/ohosTest/ets/test/LoginPageTest.test.ets`
  - 测试默认显示手机号 Tab（手机号 Tab 高亮）
  - 测试点击二维码 Tab 切换（二维码内容区可见）
  - 测试点击 Cookie Tab 切换（Cookie 输入框可见）
  - 测试 Cookie 输入框可输入（输入 'account_id=1'，输入框内容更新）
  - 测试 Cookie 为空时登录按钮禁用（按钮不可点击）
  - 测试 Cookie 有内容时登录按钮启用（按钮可点击）
  - 测试二维码加载中显示 Loading（切换到二维码 Tab 立即截图，LoadingProgress 可见）
  - 测试二维码就绪后显示 QRCode（等待 1 秒，QRCode 组件可见）
  - 测试登录成功跳转账号详情（Cookie 登录成功，AccountDetail 页可见）
  - 测试重复点击登录按钮只触发一次（isLoading 防重）
  - 测试 Cookie 只有空格时登录按钮禁用（trim 后为空）

- [ ] 1.6 新建 `entry/src/ohosTest/ets/test/AccountDetailPageTest.test.ets`
  - 测试账号昵称显示（传入有昵称的账号，昵称文字可见）
  - 测试无昵称时显示 username（传入无昵称的账号，username 文字可见）
  - 测试角色列表显示（账号有游戏角色，AccountRolesSection 可见）
  - 测试无角色时显示空态（`my_account_empty` 文字可见）
  - 测试删除按钮可见（`account_detail_delete` 按钮可见）
  - 测试点击删除弹出确认（确认 Dialog 弹出）
  - 测试确认删除后返回 My 页（返回 My 页，账号消失）
  - 测试删除账号时 DB 失败（errorMsg 更新，不跳转，不崩溃）
  - 测试快速连续点击删除按钮只弹出一次确认 Dialog

- [ ] 1.7 新建 `entry/src/ohosTest/ets/test/GenshinDailyDetailPageTest.test.ets`
  - 测试加载中显示 LoadingProgress（进入页面立即截图）
  - 测试无数据时显示空态（`home_no_data_hint` 文字可见）
  - 测试有数据时显示便笺内容（DailyNoteGenshin 可见）
  - 测试树脂数值显示（树脂数值文字可见）
  - 测试派遣列表显示（ExpeditionItem 可见）
  - 测试数据延迟提示可见（`genshin_daily_data_delay_hint` 文字可见）
  - 测试 rawJson 为空字符串时显示全 0 数据不崩溃
  - 测试快速进入退出页面 5 次不崩溃

- [ ] 1.8 新建 `entry/src/ohosTest/ets/test/GenshinCharacterDetailPageTest.test.ets`
  - 测试加载中显示 CharDetailLoadingView（进入页面立即截图，LoadingProgress 可见）
  - 测试无数据时显示 CharDetailEmptyView（`char_detail_no_data` 文字可见）
  - 测试有数据时 Phone 竖屏显示 Portrait 布局（CharDetailPortraitLayout 可见）
  - 测试有数据时宽屏显示 Wide 布局（CharDetailWideLayout 可见）
  - 测试角色名显示（角色名文字可见）
  - 测试武器名显示（武器名文字可见）
  - 测试圣遗物区域可见（CharDetailRelicsPanel 可见）
  - 测试 rawJson 为空字符串时显示 CharDetailEmptyView 不崩溃
  - 测试快速进入退出页面 5 次不崩溃

- [ ] 1.9 更新 `entry/src/ohosTest/ets/test/List.test.ets`
  - import 并注册以上 8 个页面 UI 测试套件（MainPageTest、HomePageTest、CharactersPageTest、MyPageTest、LoginPageTest、AccountDetailPageTest、GenshinDailyDetailPageTest、GenshinCharacterDetailPageTest）

---

### 2. entry/src/ohosTest/ — 组件截图测试

- [ ] 2.1 新建 `entry/src/ohosTest/ets/test/SnapshotHelper.ets`
  - 实现 `get(componentId)` — 调用 `componentSnapshot.get` 截取指定组件 PixelMap
  - 实现 `saveToFile(pixelMap, path)` — 将 PixelMap 保存为 PNG 文件
  - 实现 `comparePixelMaps(a, b)` — 逐像素对比，返回差异百分比（0.0~1.0）
  - 实现 `compareOrSave(driver, componentId, baselineName)` — 基准图不存在时保存并返回 true，存在时对比并返回差异是否 ≤ 1%
  - 基准图目录：`entry/src/ohosTest/snapshots/baseline/`
  - 等待渲染：调用前通过 `Driver.delayMs(500)` 等待

- [ ] 2.2 新建 `entry/src/ohosTest/ets/test/HomeSnapshotTest.test.ets`
  - 测试 Home 页空态截图（Mock 无账号数据，对比基准图 `home_empty`）
  - 测试 Home 页骨架屏截图（Mock 有账号数据，加载中状态，对比基准图 `home_skeleton`）
  - 测试 Home 页有数据截图（Mock 有账号数据，加载完成，对比基准图 `home_data`）

- [ ] 2.3 新建 `entry/src/ohosTest/ets/test/CharactersSnapshotTest.test.ets`
  - 测试 Characters 页空态截图（Mock 无账号数据，对比基准图 `characters_empty`）
  - 测试 Characters 页骨架屏截图（Mock 有账号但无角色数据，对比基准图 `characters_skeleton`）
  - 测试 Characters 页有数据截图（Mock 有原神角色数据，加载完成，对比基准图 `characters_data`）

- [ ] 2.4 新建 `entry/src/ohosTest/ets/test/LoginSnapshotTest.test.ets`
  - 测试 Login 页手机号 Tab 截图（默认状态，对比基准图 `login_phone_tab`）
  - 测试 Login 页二维码 Tab 截图（切换到二维码 Tab，对比基准图 `login_qrcode_tab`）
  - 测试 Login 页 Cookie Tab 截图（切换到 Cookie Tab，对比基准图 `login_cookie_tab`）

- [ ] 2.5 新建 `entry/src/ohosTest/ets/test/CharDetailSnapshotTest.test.ets`
  - 测试 GenshinCharacterDetail 页 Phone 竖屏布局截图（有角色数据，对比基准图 `char_detail_portrait`）
  - 测试 GenshinCharacterDetail 页宽屏布局截图（有角色数据，宽屏，对比基准图 `char_detail_wide`）
  - 测试 GenshinCharacterDetail 页空态截图（无数据，对比基准图 `char_detail_empty`）

- [ ] 2.6 更新 `entry/src/ohosTest/ets/test/List.test.ets`
  - 在任务 1.9 的基础上，追加 import 并注册 4 个截图测试套件（HomeSnapshotTest、CharactersSnapshotTest、LoginSnapshotTest、CharDetailSnapshotTest）
  - 截图测试套件注册在 UI 测试套件之后

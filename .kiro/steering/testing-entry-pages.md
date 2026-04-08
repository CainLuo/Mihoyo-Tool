# entry 模块页面测试设计文档

## 说明

本文档针对 `entry/src/main/ets/pages/` 下每个页面，
分别设计 `@Preview` 预览状态和设备端 UI 测试用例。

**页面测试位置**：`entry/src/ohosTest/ets/test/`，使用 Hypium + `@ohos/uitest`
**ViewModel 测试位置**：`entry/src/test/`（纯逻辑，不依赖设备）

---

## 一、ViewModel 单元测试（entry/src/test/）

> ViewModel 只测试纯逻辑，不依赖设备。
> 不得 import core 模块的 Repository 或 DAO，只测试 ViewModel 自身的状态转换逻辑。

### HomeViewModel（HomeViewModel.test.ets）

被测类：`entry/src/main/ets/viewmodel/HomeViewModel.ets`

| 测试用例                                 | 前置条件            | 操作                  | 预期结果                          |
| ---------------------------------------- | ------------------- | --------------------- | --------------------------------- |
| 初始 viewState 为 LOADING                | 新建实例            | `new HomeViewModel()` | `viewState === ViewState.LOADING` |
| 初始 accounts 为空数组                   | 新建实例            | `new HomeViewModel()` | `accounts.length === 0`           |
| 初始 isRefreshing 为 false               | 新建实例            | `new HomeViewModel()` | `isRefreshing === false`          |
| 初始 networkErrorMsg 为空                | 新建实例            | `new HomeViewModel()` | `networkErrorMsg === ''`          |
| 初始 geetestTrigger 为 null              | 新建实例            | `new HomeViewModel()` | `geetestTrigger === null`         |
| refresh 时 isRefreshing 已为 true 则跳过 | `isRefreshing=true` | `refresh()`           | 不重复触发                        |

> 注：`resinRecoveryDesc` 方法已移至 View 层 `TimeFormatUtil`，不再在 ViewModel 中测试。

---

### CharactersViewModel（CharactersViewModel.test.ets）

被测类：`entry/src/main/ets/viewmodel/CharactersViewModel.ets`

| 测试用例                                       | 前置条件                                              | 操作                                           | 预期结果                           |
| ---------------------------------------------- | ----------------------------------------------------- | ---------------------------------------------- | ---------------------------------- |
| 初始 viewState 为 LOADING                      | 新建实例                                              | `new CharactersViewModel()`                    | `viewState === ViewState.LOADING`  |
| 初始 selectedAccountIdx 为 0                   | 新建实例                                              | `new CharactersViewModel()`                    | `selectedAccountIdx === 0`         |
| 初始 selectedGameIdx 为 0                      | 新建实例                                              | `new CharactersViewModel()`                    | `selectedGameIdx === 0`            |
| 初始 characters 为空数组                       | 新建实例                                              | `new CharactersViewModel()`                    | `characters.length === 0`          |
| 初始 showAccountSwitcher 为 false              | 新建实例                                              | `new CharactersViewModel()`                    | `showAccountSwitcher === false`    |
| 初始 showRefreshButton 为 false                | 新建实例                                              | `new CharactersViewModel()`                    | `showRefreshButton === false`      |
| selectAccount 相同 idx 不触发重载              | `selectedAccountIdx=0`                                | `selectAccount(0)`                             | 不改变 selectedAccountIdx          |
| selectGame 相同 idx 不触发重载                 | `selectedGameIdx=0`                                   | `selectGame(0)`                                | 不改变 selectedGameIdx             |
| refresh 时 isRefreshing 已为 true 则跳过       | `isRefreshing=true`                                   | `refresh()`                                    | 不重复触发                         |
| toSelectOptions 转换正确（使用 username）      | `opts=[new AccountOption(1,'u1','旅行者','','uid1')]` | `CharactersViewModel.toSelectOptions(opts)`    | 返回 `[{value:'u1'}]`              |
| AccountOption 仅传两个参数时其余字段为空字符串 | —                                                     | `new AccountOption(1, 'user1')`                | `nickname/avatarUrl/uid` 均为 `''` |
| AccountOption 传全部参数时正确赋值             | —                                                     | `new AccountOption(2,'u2','昵称','url','uid')` | 各字段正确赋值                     |
| selectAccount 超出范围的 idx 不崩溃            | `accountOptions=[]`                                   | `selectAccount(999)`                           | 不崩溃                             |

---

### LoginViewModel（LoginViewModel.test.ets）

被测类：`entry/src/main/ets/viewmodel/LoginViewModel.ets`

| 测试用例                    | 前置条件                    | 操作                         | 预期结果                        |
| --------------------------- | --------------------------- | ---------------------------- | ------------------------------- |
| 初始 activeTab 为 PHONE     | 新建实例                    | `new LoginViewModel()`       | `activeTab === LoginTab.PHONE`  |
| 初始 loginSuccess 为 false  | 新建实例                    | `new LoginViewModel()`       | `loginSuccess === false`        |
| 初始 isLoading 为 false     | 新建实例                    | `new LoginViewModel()`       | `isLoading === false`           |
| 初始 errorMsg 为空          | 新建实例                    | `new LoginViewModel()`       | `errorMsg === ''`               |
| switchTab 切换 Tab          | `activeTab=PHONE`           | `switchTab(LoginTab.COOKIE)` | `activeTab === LoginTab.COOKIE` |
| switchTab 清空 errorMsg     | `errorMsg='error'`          | `switchTab(LoginTab.COOKIE)` | `errorMsg === ''`               |
| maskedPhone 脱敏正确        | `phoneNumber='13812345678'` | `vm.maskedPhone`             | `'138****5678'`                 |
| maskedPhone 短号不脱敏      | `phoneNumber='123'`         | `vm.maskedPhone`             | `'123'`                         |
| backToPhoneInput 重置步骤   | `phoneStep=INPUT_CODE`      | `backToPhoneInput()`         | `phoneStep === INPUT_PHONE`     |
| backToPhoneInput 清空验证码 | `smsCode='123456'`          | `backToPhoneInput()`         | `smsCode === ''`                |
| loginByCookie 空输入不触发  | `cookieInput=''`            | `loginByCookie()`            | `errorMsg === 'cookie_empty'`   |

---

### MyViewModel（MyViewModel.test.ets）

被测类：`entry/src/main/ets/viewmodel/MyViewModel.ets`

| 测试用例                  | 前置条件 | 操作                | 预期结果                          |
| ------------------------- | -------- | ------------------- | --------------------------------- |
| 初始 viewState 为 LOADING | 新建实例 | `new MyViewModel()` | `viewState === ViewState.LOADING` |
| 初始 accounts 为空数组    | 新建实例 | `new MyViewModel()` | `accounts.length === 0`           |

---

### AccountDetailViewModel（AccountDetailViewModel.test.ets）

被测类：`entry/src/main/ets/viewmodel/AccountDetailViewModel.ets`

| 测试用例              | 前置条件 | 操作                           | 预期结果            |
| --------------------- | -------- | ------------------------------ | ------------------- |
| 初始 deleted 为 false | 新建实例 | `new AccountDetailViewModel()` | `deleted === false` |
| 初始 errorMsg 为空    | 新建实例 | `new AccountDetailViewModel()` | `errorMsg === ''`   |

---

### GenshinDailyDetailViewModel（GenshinDailyDetailViewModel.test.ets）

被测类：`entry/src/main/ets/viewmodel/GenshinDailyDetailViewModel.ets`

| 测试用例                       | 前置条件 | 操作                                | 预期结果                          |
| ------------------------------ | -------- | ----------------------------------- | --------------------------------- |
| 初始 viewState 为 LOADING      | 新建实例 | `new GenshinDailyDetailViewModel()` | `viewState === ViewState.LOADING` |
| init 设置 accountId 和 roleUid | 新建实例 | `vm.init(1, 'uid1')`                | 内部 accountId=1，roleUid='uid1'  |
| formatSeconds 超过 1 小时      | —        | `formatSeconds(3660)`               | 包含 '1小时'                      |
| formatSeconds 不足 1 小时      | —        | `formatSeconds(600)`                | 包含 '10分钟'                     |
| formatSeconds 为 0             | —        | `formatSeconds(0)`                  | 返回 `''`                         |
| formatTransformer 有天数       | —        | `formatTransformer(1, 2, 30)`       | 包含 '1天'                        |
| formatTransformer 只有小时     | —        | `formatTransformer(0, 3, 0)`        | 包含 '3小时'                      |
| formatTransformer 只有分钟     | —        | `formatTransformer(0, 0, 15)`       | 包含 '15分钟'                     |

---

### GenshinCharacterDetailViewModel（GenshinCharacterDetailViewModel.test.ets）

被测类：`entry/src/main/ets/viewmodel/GenshinCharacterDetailViewModel.ets`

| 测试用例                         | 前置条件 | 操作                                                    | 预期结果                               |
| -------------------------------- | -------- | ------------------------------------------------------- | -------------------------------------- |
| 初始 viewState 为 LOADING        | 新建实例 | `new GenshinCharacterDetailViewModel()`                 | `viewState === ViewState.LOADING`      |
| init 设置三个参数                | 新建实例 | `vm.init(1, 'uid1', 'avatarId1')`                       | 内部参数正确设置                       |
| propertyTypeToResource HP_FLAT   | —        | `propertyTypeToResource(GenshinPropertyType.HP_FLAT)`   | 返回 `$r('app.string.prop_hp_flat')`   |
| propertyTypeToResource CRIT_RATE | —        | `propertyTypeToResource(GenshinPropertyType.CRIT_RATE)` | 返回 `$r('app.string.prop_crit_rate')` |
| propertyTypeToResource 未知类型  | —        | `propertyTypeToResource(9999)`                          | 返回 `null`                            |

---

## 二、页面 UI 测试（entry/src/ohosTest/ets/test/）

> 设备端 UI 测试，验证页面级交互流程。
> 使用 Hypium + `@ohos/uitest`，每个测试用例独立，不依赖其他测试的状态。
> 测试前通过 `Driver.delayMs(500)` 等待页面渲染完成。

---

### Home 页（HomePageTest.test.ets）

被测页面：`pages/Home.ets`，ViewModel：`HomeViewModel`

**@Preview 状态**

| Preview 名称                             | 数据状态 | 说明                         |
| ---------------------------------------- | -------- | ---------------------------- |
| 无（Home 是 Tab 内嵌页，通过 Main 渲染） | —        | 通过 Main 页面的 UI 测试覆盖 |

**UI 测试用例**

| 用例                         | 前置条件               | 操作                     | 预期结果                           |
| ---------------------------- | ---------------------- | ------------------------ | ---------------------------------- |
| 无账号时显示空态占位         | Mock 环境，无账号数据  | 启动应用，进入 Home Tab  | `home_placeholder_title` 文字可见  |
| 无账号时显示登录按钮         | Mock 环境，无账号数据  | 进入 Home Tab            | `home_placeholder_button` 按钮可见 |
| 有账号时显示骨架屏（加载中） | Mock 环境，有账号数据  | 进入 Home Tab，立即截图  | HomeSkeletonView 骨架块可见        |
| 有账号时加载完成显示卡片     | Mock 环境，有账号数据  | 进入 Home Tab，等待 1 秒 | UserGameSection 可见               |
| 刷新按钮在 DATA 状态可见     | 有账号数据，加载完成   | 查看右上角               | 刷新按钮可见                       |
| 点击刷新按钮触发刷新         | 有账号数据，加载完成   | 点击刷新按钮             | isRefreshing 变为 true（按钮禁用） |
| 点击游戏卡片跳转便笺详情     | 有原神账号数据         | 点击原神卡片             | 跳转到 GenshinDailyDetail 页       |
| 网络错误时弹出 Alert         | Mock 文件 retcode=-100 | 触发同步                 | 弹出错误 Dialog                    |

---

### Characters 页（CharactersPageTest.test.ets）

被测页面：`pages/Characters.ets`，ViewModel：`CharactersViewModel`

**UI 测试用例**

| 用例                           | 前置条件                      | 操作                           | 预期结果                         |
| ------------------------------ | ----------------------------- | ------------------------------ | -------------------------------- |
| 无账号时显示登录占位           | Mock 环境，无账号数据         | 进入 Characters Tab            | HomePlaceholderView 可见         |
| 有账号无角色数据时显示骨架屏   | Mock 环境，有账号但无角色数据 | 进入 Characters Tab            | CharactersSkeleton 可见          |
| 有角色数据时显示角色网格       | Mock 环境，有原神角色数据     | 进入 Characters Tab，等待 1 秒 | CharacterCard 可见               |
| 多游戏时显示 Tab 栏            | Mock 环境，有原神+星铁数据    | 进入 Characters Tab            | GameTabBar 可见                  |
| 点击 Tab 切换游戏              | 有原神+星铁数据               | 点击星铁 Tab                   | 显示星铁角色数据                 |
| 点击角色卡片跳转详情           | 有原神角色数据                | 点击角色卡片                   | 跳转到 GenshinCharacterDetail 页 |
| 刷新冷却时弹出 Dialog          | 30 分钟内已同步               | 点击刷新                       | 弹出冷却 Dialog                  |
| 冷却 Dialog 点击强制同步       | 冷却 Dialog 已弹出            | 点击"立即同步"按钮             | 触发 forceRefresh                |
| 单账号时右上角不显示切换按钮   | Mock 环境，只有 1 个账号      | 进入 Characters Tab            | 账号切换按钮不可见               |
| 多账号时右上角显示切换按钮     | Mock 环境，有 2 个以上账号    | 进入 Characters Tab            | 账号切换按钮（👥）可见           |
| 点击切换按钮弹出账号 Menu      | 有 2 个账号                   | 点击切换按钮                   | Menu 弹出，显示 2 个账号 item    |
| Menu item 显示昵称和 UID       | 账号有昵称和 uid              | 弹出 Menu                      | 昵称文字和 UID 文字可见          |
| 点击 Menu item 切换账号        | Menu 已弹出，有 2 个账号      | 点击第 2 个账号 item           | 角色列表切换为第 2 个账号的数据  |
| 切换账号后当前账号有 ✓ 标记    | 已选中第 2 个账号             | 再次打开 Menu                  | 第 2 个 item 有选中标记          |
| 删除账号后 Characters 自动刷新 | 在 My 页删除一个账号          | 确认删除，返回 Characters Tab  | 账号列表更新，已删除账号消失     |
| 删除当前选中账号后不越界       | 选中最后一个账号，删除它      | 确认删除                       | selectedAccountIdx 自动 clamp    |

---

### My 页（MyPageTest.test.ets）

被测页面：`pages/My.ets`，ViewModel：`MyViewModel`

**UI 测试用例**

| 用例                 | 前置条件              | 操作             | 预期结果                    |
| -------------------- | --------------------- | ---------------- | --------------------------- |
| 无账号时显示空态提示 | Mock 环境，无账号数据 | 进入 My Tab      | `my_account_empty` 文字可见 |
| 有账号时显示账号列表 | Mock 环境，有账号数据 | 进入 My Tab      | 账号行可见                  |
| 账号昵称显示         | Mock 账号有昵称       | 进入 My Tab      | 昵称文字可见                |
| 点击账号跳转详情     | 有账号数据            | 点击账号行       | 跳转到 AccountDetail 页     |
| 添加账号按钮可见     | 任意状态              | 进入 My Tab      | `my_account_add` 按钮可见   |
| 点击添加账号跳转登录 | 任意状态              | 点击添加账号按钮 | 跳转到 Login 页             |
| 外观设置区域可见     | 任意状态              | 进入 My Tab      | AppearanceSection 可见      |
| 关于区域可见         | 任意状态              | 进入 My Tab      | AboutSection 可见           |
| 切换主题模式         | 任意状态              | 点击深色模式按钮 | 深色按钮高亮，主题切换      |

---

### Login 页（LoginPageTest.test.ets）

被测页面：`pages/Login.ets`，ViewModel：`LoginViewModel`

**UI 测试用例**

| 用例                        | 前置条件                    | 操作                | 预期结果             |
| --------------------------- | --------------------------- | ------------------- | -------------------- |
| 默认显示手机号 Tab          | 进入 Login 页               | 查看 Tab 栏         | 手机号 Tab 高亮      |
| 点击二维码 Tab 切换         | 进入 Login 页               | 点击二维码 Tab      | 二维码内容区可见     |
| 点击 Cookie Tab 切换        | 进入 Login 页               | 点击 Cookie Tab     | Cookie 输入框可见    |
| Cookie 输入框可输入         | Cookie Tab 激活             | 输入 'account_id=1' | 输入框内容更新       |
| Cookie 为空时登录按钮禁用   | Cookie Tab，输入框为空      | 查看登录按钮        | 按钮不可点击         |
| Cookie 有内容时登录按钮启用 | Cookie Tab，输入框有内容    | 查看登录按钮        | 按钮可点击           |
| 二维码加载中显示 Loading    | 切换到二维码 Tab            | 立即截图            | LoadingProgress 可见 |
| 二维码就绪后显示 QRCode     | 切换到二维码 Tab，等待 1 秒 | 查看内容区          | QRCode 组件可见      |
| 登录成功跳转账号详情        | Cookie 登录成功             | 等待跳转            | AccountDetail 页可见 |

---

### AccountDetail 页（AccountDetailPageTest.test.ets）

被测页面：`pages/AccountDetail.ets`，ViewModel：`AccountDetailViewModel`

**UI 测试用例**

| 用例                  | 前置条件           | 操作                  | 预期结果                         |
| --------------------- | ------------------ | --------------------- | -------------------------------- |
| 账号昵称显示          | 传入有昵称的账号   | 进入 AccountDetail 页 | 昵称文字可见                     |
| 无昵称时显示 username | 传入无昵称的账号   | 进入 AccountDetail 页 | username 文字可见                |
| 角色列表显示          | 账号有游戏角色     | 进入 AccountDetail 页 | AccountRolesSection 可见         |
| 无角色时显示空态      | 账号无游戏角色     | 进入 AccountDetail 页 | `my_account_empty` 文字可见      |
| 删除按钮可见          | 任意状态           | 进入 AccountDetail 页 | `account_detail_delete` 按钮可见 |
| 点击删除弹出确认      | 任意状态           | 点击删除按钮          | 确认 Dialog 弹出                 |
| 确认删除后返回 My 页  | 确认 Dialog 已弹出 | 点击确认              | 返回 My 页，账号消失             |

---

### GenshinDailyDetail 页（GenshinDailyDetailPageTest.test.ets）

被测页面：`pages/GenshinDailyDetail.ets`，ViewModel：`GenshinDailyDetailViewModel`

**UI 测试用例**

| 用例                       | 前置条件                  | 操作         | 预期结果                                 |
| -------------------------- | ------------------------- | ------------ | ---------------------------------------- |
| 加载中显示 LoadingProgress | 进入页面，立即截图        | 查看内容区   | LoadingProgress 可见                     |
| 无数据时显示空态           | DB 无对应数据             | 等待加载完成 | `home_no_data_hint` 文字可见             |
| 有数据时显示便笺内容       | Mock 环境，有原神便笺数据 | 等待加载完成 | DailyNoteGenshin 可见                    |
| 树脂数值显示               | 有便笺数据                | 查看树脂行   | 树脂数值文字可见                         |
| 派遣列表显示               | 有派遣数据                | 查看派遣区域 | ExpeditionItem 可见                      |
| 数据延迟提示可见           | 有便笺数据                | 查看页面顶部 | `genshin_daily_data_delay_hint` 文字可见 |

---

### GenshinCharacterDetail 页（GenshinCharacterDetailPageTest.test.ets）

被测页面：`pages/GenshinCharacterDetail.ets`，ViewModel：`GenshinCharacterDetailViewModel`

**UI 测试用例**

| 用例                                  | 前置条件                   | 操作         | 预期结果                       |
| ------------------------------------- | -------------------------- | ------------ | ------------------------------ |
| 加载中显示 CharDetailLoadingView      | 进入页面，立即截图         | 查看内容区   | LoadingProgress 可见           |
| 无数据时显示 CharDetailEmptyView      | DB 无对应数据              | 等待加载完成 | `char_detail_no_data` 文字可见 |
| 有数据时 Phone 竖屏显示 Portrait 布局 | 有角色详情数据，Phone 竖屏 | 等待加载完成 | CharDetailPortraitLayout 可见  |
| 有数据时宽屏显示 Wide 布局            | 有角色详情数据，平板/PC    | 等待加载完成 | CharDetailWideLayout 可见      |
| 角色名显示                            | 有角色详情数据             | 查看立绘区   | 角色名文字可见                 |
| 武器名显示                            | 有角色详情数据             | 查看属性区   | 武器名文字可见                 |
| 圣遗物区域可见                        | 有角色详情数据             | 查看圣遗物区 | CharDetailRelicsPanel 可见     |

---

### Main 页（MainPageTest.test.ets）

被测页面：`pages/Main.ets`

**UI 测试用例**

| 用例                                | 前置条件                         | 操作                 | 预期结果                   |
| ----------------------------------- | -------------------------------- | -------------------- | -------------------------- |
| 默认显示 Home Tab                   | 启动应用                         | 查看底部 Tab 栏      | Home Tab 高亮              |
| 点击 Characters Tab 切换            | 在 Home Tab                      | 点击 Characters Tab  | Characters 内容区可见      |
| 点击 My Tab 切换                    | 在 Home Tab                      | 点击 My Tab          | My 内容区可见              |
| 切换 Tab 不重置导航栈               | 在 Home Tab 进入详情页           | 切换到 My Tab 再切回 | Home Tab 仍显示详情页      |
| Phone 模式显示底部 Tab 栏           | Phone 设备                       | 查看底部             | 底部 Tab 栏可见            |
| 宽屏模式显示侧边导航                | 平板/PC 设备                     | 查看左侧             | 侧边导航可见               |
| Home Tab 显示刷新按钮               | 在 Home Tab，有账号数据          | 查看右上角           | 刷新按钮可见               |
| Characters Tab 显示刷新按钮         | 在 Characters Tab，有角色数据    | 查看右上角           | 刷新按钮可见               |
| Characters Tab 单账号不显示切换按钮 | 在 Characters Tab，只有 1 个账号 | 查看右上角           | 账号切换按钮不可见         |
| Characters Tab 多账号显示切换按钮   | 在 Characters Tab，有 2+ 个账号  | 查看右上角           | 账号切换按钮可见           |
| My Tab 不显示刷新和切换按钮         | 在 My Tab                        | 查看右上角           | 刷新按钮和切换按钮均不可见 |

---

## 三、测试文件注册

### entry/src/test/List.test.ets

```typescript
import homeViewModelTest from "./HomeViewModel.test";
import charactersViewModelTest from "./CharactersViewModel.test";
import loginViewModelTest from "./LoginViewModel.test";
import myViewModelTest from "./MyViewModel.test";
import accountDetailViewModelTest from "./AccountDetailViewModel.test";
import genshinDailyDetailViewModelTest from "./GenshinDailyDetailViewModel.test";
import genshinCharDetailViewModelTest from "./GenshinCharacterDetailViewModel.test";

export default function testsuite() {
  homeViewModelTest();
  charactersViewModelTest();
  loginViewModelTest();
  myViewModelTest();
  accountDetailViewModelTest();
  genshinDailyDetailViewModelTest();
  genshinCharDetailViewModelTest();
}
```

### entry/src/ohosTest/ets/test/List.test.ets

```typescript
import homePageTest from "./HomePageTest.test";
import charactersPageTest from "./CharactersPageTest.test";
import myPageTest from "./MyPageTest.test";
import loginPageTest from "./LoginPageTest.test";
import accountDetailPageTest from "./AccountDetailPageTest.test";
import genshinDailyDetailPageTest from "./GenshinDailyDetailPageTest.test";
import genshinCharDetailPageTest from "./GenshinCharacterDetailPageTest.test";
import mainPageTest from "./MainPageTest.test";

export default function testsuite() {
  homePageTest();
  charactersPageTest();
  myPageTest();
  loginPageTest();
  accountDetailPageTest();
  genshinDailyDetailPageTest();
  genshinCharDetailPageTest();
  mainPageTest();
}
```

---

## 四、Unhappy Flow 和边界场景补充

> 以下用例补充到对应测试文件中，覆盖真实用户可能触发的异常路径。

### 4.1 登录页 — 异常场景（LoginPageTest.test.ets）

| 用例                             | 操作                                 | 预期结果                                        |
| -------------------------------- | ------------------------------------ | ----------------------------------------------- |
| Cookie 格式错误（无 account_id） | 输入 `ltoken=abc; ltuid=1`，点击登录 | 登录流程继续（username 使用 'unknown'），不崩溃 |
| Cookie 含特殊字符                | 输入含 `=` 和 `;` 的 Cookie          | 不崩溃，正常提交                                |
| Cookie 超长（>10KB）             | 粘贴超长 Cookie                      | 输入框接受，不崩溃                              |
| 登录中快速切换 Tab               | isLoading=true 时点击二维码 Tab      | Tab 切换成功，不崩溃                            |
| 二维码过期后立即刷新             | qrCodeStat=EXPIRED，点击刷新         | 重新生成二维码，不显示旧二维码                  |
| 二维码轮询中切换到 Cookie Tab    | 轮询进行中，点击 Cookie Tab          | 轮询停止，不继续发请求                          |
| 登录成功后快速点击返回           | loginSuccess=true，立即点击返回      | 不崩溃，正常返回 My 页                          |
| 网络超时时登录                   | 模拟网络超时                         | errorMsg 显示错误信息，isLoading 变为 false     |
| 重复点击登录按钮                 | 快速连续点击登录按钮                 | 只触发一次登录请求（isLoading 防重）            |

---

### 4.2 Home 页 — 异常场景（HomePageTest.test.ets）

| 用例                   | 操作                              | 预期结果                                          |
| ---------------------- | --------------------------------- | ------------------------------------------------- |
| 有账号但无任何游戏角色 | 账号存在但 game_role_table 为空   | 显示账号标题行，无游戏卡片，不崩溃                |
| 账号昵称为空字符串     | nickname=''                       | 显示 username 代替昵称                            |
| 账号头像 URL 为空      | avatarUrl=''                      | 显示占位色块，不崩溃                              |
| 账号头像 URL 无效      | avatarUrl='invalid_url'           | 图片加载失败，显示占位，不崩溃                    |
| 刷新时网络断开         | 触发刷新，网络不可用              | networkErrorMsg 显示错误，isRefreshing 变为 false |
| 30 分钟内重复刷新      | 刚刷新完立即再次刷新              | 弹出冷却 Dialog                                   |
| 冷却 Dialog 点击取消   | 冷却 Dialog 弹出，点击取消        | Dialog 关闭，不触发刷新                           |
| Geetest 验证取消       | Geetest Dialog 弹出，点击关闭     | Dialog 关闭，不重试同步，不崩溃                   |
| 多账号多游戏同时同步   | 2 个账号各有 3 个游戏角色         | 6 个角色逐一同步，不崩溃，全部完成后 UI 更新      |
| 同步中切换到其他 Tab   | 同步进行中，切换到 Characters Tab | 同步继续在后台运行，切回 Home 后 UI 更新          |
| 应用进入后台再回到前台 | 同步中按 Home 键，再切回          | 不崩溃，定时器继续运行                            |
| 树脂值为 0             | currentResin=0，maxResin=200      | 显示 '0/200'，不崩溃                              |
| 树脂值等于上限         | currentResin=200，maxResin=200    | 显示红色警告，恢复描述为空                        |

---

### 4.3 Characters 页 — 异常场景（CharactersPageTest.test.ets）

| 用例                     | 操作                                                 | 预期结果                             |
| ------------------------ | ---------------------------------------------------- | ------------------------------------ |
| 有账号但角色数据为空     | game_role_table 有记录但 genshin_character_list 为空 | 触发后台同步，显示骨架屏             |
| 同步失败后显示空态       | 后台同步抛出错误                                     | viewState 变为 EMPTY，不崩溃         |
| 快速切换账号             | 连续点击不同账号                                     | 不崩溃，最终显示最后选中账号的数据   |
| 快速切换游戏 Tab         | 连续点击不同游戏 Tab                                 | 不崩溃，最终显示最后选中游戏的数据   |
| 角色数量极多（>100 个）  | 角色列表有 100+ 条                                   | LazyForEach 懒加载，不卡顿，滚动流畅 |
| 角色名为空字符串         | character.name=''                                    | 显示空白，不崩溃                     |
| 角色图标 URL 为空        | iconUrl=''                                           | 显示占位背景色，不崩溃               |
| 武器图标 URL 无效        | weaponIconUrl='invalid'                              | 图片加载失败，显示占位，不崩溃       |
| 刷新冷却 Dialog 点击取消 | 冷却 Dialog 弹出，点击取消                           | Dialog 关闭，不触发刷新              |

---

### 4.4 My 页 — 异常场景（MyPageTest.test.ets）

| 用例                       | 操作                          | 预期结果                                  |
| -------------------------- | ----------------------------- | ----------------------------------------- |
| 多账号（>5 个）            | 已登录 5 个账号               | 全部显示，列表可滚动，不崩溃              |
| 账号角色数为 0             | roles=[]                      | 显示 '0 个游戏角色'，不崩溃               |
| 账号角色数极多（>20 个）   | roles.length=20               | 统计数字正确显示，不崩溃                  |
| 账号 statsJson 为空字符串  | statsJson=''                  | 不显示统计格子，不崩溃                    |
| 账号 statsJson 为无效 JSON | statsJson='invalid'           | 不崩溃，统计格子不显示                    |
| 账号背景图 URL 无效        | bgImageUrl='invalid'          | 图片加载失败，显示纯色背景，不崩溃        |
| 删除最后一个账号           | 只有 1 个账号，点击删除并确认 | 账号列表变为空态，显示 `my_account_empty` |
| 删除账号后立即添加新账号   | 删除后立即点击添加            | 跳转到 Login 页，不崩溃                   |
| 快速连续点击账号行         | 快速双击账号行                | 只跳转一次，不重复 push 导航栈            |

---

### 4.5 AccountDetail 页 — 异常场景（AccountDetailPageTest.test.ets）

| 用例                               | 操作                   | 预期结果                                                   |
| ---------------------------------- | ---------------------- | ---------------------------------------------------------- |
| 账号无游戏角色                     | roles=[]               | 显示空态提示，不崩溃                                       |
| 角色背景图 URL 无效                | bgImageUrl='invalid'   | 图片加载失败，显示纯色背景，不崩溃                         |
| 角色统计数据为空                   | stats=[]               | 不显示统计格子，不崩溃                                     |
| 删除账号时网络/DB 失败             | deleteAccount 抛出错误 | errorMsg 更新，不跳转，不崩溃                              |
| 快速连续点击删除按钮               | 快速双击删除按钮       | 只弹出一次确认 Dialog                                      |
| 确认删除后立即按返回键             | 确认删除，立即按返回   | 不崩溃，最终返回 My 页                                     |
| 删除账号后 Home Tab 自动刷新       | 确认删除               | Home Tab 账号卡片消失（AccountSignal.notify() 触发重载）   |
| 删除账号后 Characters Tab 自动刷新 | 确认删除               | Characters Tab 账号列表更新（AccountSignal.notify() 触发） |

---

### 4.6 GenshinDailyDetail 页 — 异常场景（GenshinDailyDetailPageTest.test.ets）

| 用例                 | 操作                       | 预期结果                                 |
| -------------------- | -------------------------- | ---------------------------------------- |
| rawJson 为空字符串   | DB 中 rawJson=''           | Parser 返回默认值，显示全 0 数据，不崩溃 |
| rawJson 为无效 JSON  | DB 中 rawJson='invalid'    | Parser 返回默认值，不崩溃                |
| 树脂值为 0           | currentResin=0             | 显示 '0/200'，不崩溃                     |
| 树脂值等于上限       | currentResin=200           | 显示红色，恢复描述为空                   |
| 派遣列表为空         | expeditions=[]             | 不显示派遣区域，不崩溃                   |
| 参量质变仪未获得     | transformer.obtained=false | 不显示参量质变仪行（或显示未获得状态）   |
| 折叠屏展开时布局切换 | 在折叠屏上展开             | 布局自适应，不崩溃                       |
| 快速进入退出页面     | 连续进入退出 5 次          | 不内存泄漏，不崩溃                       |

---

### 4.7 GenshinCharacterDetail 页 — 异常场景（GenshinCharacterDetailPageTest.test.ets）

| 用例                            | 操作                      | 预期结果                                 |
| ------------------------------- | ------------------------- | ---------------------------------------- |
| rawJson 为空字符串              | DB 中 rawJson=''          | 显示 CharDetailEmptyView，不崩溃         |
| 圣遗物数量不足 5 件             | relics.length=3           | 只显示 3 件，不崩溃                      |
| 圣遗物副词条为空                | subStats=[]               | 不显示副词条，不崩溃                     |
| 技能数量不足 3 个               | skills.length=1           | 只显示 1 个技能，不崩溃                  |
| 命座全未激活                    | activatedConstellations=0 | 6 个命座全部显示锁图标，不崩溃           |
| 命座全激活                      | activatedConstellations=6 | 6 个命座全部高亮，无锁图标               |
| 武器图标 URL 为空               | weapon.iconUrl=''         | 显示占位色块，不崩溃                     |
| Phone 横屏时显示 Landscape 布局 | 旋转到横屏                | 切换到 CharDetailLandscapeLayout，不崩溃 |
| 宽屏切换到 Phone 模式           | 折叠屏折叠                | 切换到 Portrait 布局，不崩溃             |
| 快速进入退出页面                | 连续进入退出 5 次         | 不内存泄漏，不崩溃                       |

---

### 4.8 Main 页 — 异常场景（MainPageTest.test.ets）

| 用例                            | 操作                                 | 预期结果                              |
| ------------------------------- | ------------------------------------ | ------------------------------------- |
| 快速连续切换 Tab                | 快速点击 3 个 Tab                    | 不崩溃，最终停在最后点击的 Tab        |
| 在详情页时切换 Tab              | Home Tab 进入便笺详情，切换到 My Tab | My Tab 正常显示，Home Tab 导航栈保留  |
| 切回 Home Tab 后导航栈恢复      | 从 My Tab 切回 Home Tab              | 仍显示便笺详情页（导航栈未清空）      |
| 宽屏模式下分栏显示              | 平板/PC 宽屏                         | 左侧列表+右侧详情分栏显示，不崩溃     |
| 宽屏模式下右侧无内容            | 宽屏，未点击任何卡片                 | 右侧显示 SplitPlaceholder，不崩溃     |
| 折叠屏展开时从 Phone 切换到宽屏 | 展开折叠屏                           | 布局从单栏切换到分栏，不崩溃          |
| 折叠屏折叠时从宽屏切换到 Phone  | 折叠折叠屏                           | 布局从分栏切换到单栏，不崩溃          |
| 应用冷启动（无账号数据）        | 全新安装，首次启动                   | Home/Characters/My 均显示空态，不崩溃 |
| 应用热启动（有账号数据）        | 已有账号，重新打开应用               | 数据正常加载，不崩溃                  |

---

### 4.9 ViewModel — 边界场景（各 ViewModel 测试文件）

**HomeViewModel**

| 用例                                          | 操作                         | 预期结果                             |
| --------------------------------------------- | ---------------------------- | ------------------------------------ |
| dispose 后定时器停止                          | `vm.dispose()`               | 不再触发自动刷新                     |
| 多次调用 dispose                              | 连续调用 `dispose()` 两次    | 不崩溃                               |
| onGeetestResult 传入 null                     | `vm.onGeetestResult(null)`   | 不触发重试，不崩溃                   |
| onGeetestResult 在 geetestTrigger=null 时调用 | `vm.onGeetestResult(result)` | 不崩溃（trigger 为 null 时直接返回） |

**LoginViewModel**

| 用例                                  | 操作                | 预期结果                                 |
| ------------------------------------- | ------------------- | ---------------------------------------- |
| dispose 后定时器停止                  | `vm.dispose()`      | 二维码轮询停止，短信倒计时停止           |
| smsCooldown 倒计时到 0                | 等待 60 秒          | smsCooldown 变为 0，不变为负数           |
| switchTab 到 QRCODE 再切回 PHONE      | 切换两次            | 二维码轮询启动后停止，不内存泄漏         |
| loginByCookie 时 cookieInput 只有空格 | `cookieInput='   '` | `errorMsg='cookie_empty'`（trim 后为空） |

**CharactersViewModel**

| 用例                                          | 操作                                 | 预期结果                                 |
| --------------------------------------------- | ------------------------------------ | ---------------------------------------- |
| selectAccount 超出范围的 idx                  | `selectAccount(999)`                 | 不崩溃（数组越界保护）                   |
| selectGame 超出范围的 idx                     | `selectGame(999)`                    | 不崩溃                                   |
| forceRefresh 时 gameTabs 为空                 | `gameTabs=[]`，调用 `forceRefresh()` | 不崩溃，直接返回                         |
| loadData 后 selectedAccountIdx clamp          | 已选中 idx=2，账号减少到 1 个        | selectedAccountIdx 被 clamp 为 0，不越界 |
| loadData 后 selectedAccountIdx 保留（未越界） | 已选中 idx=1，账号仍有 3 个          | selectedAccountIdx 保持为 1，不重置为 0  |

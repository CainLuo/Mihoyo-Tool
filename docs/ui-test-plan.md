# UI 测试骨架与主链路清单

> 状态：**已在模拟器上执行通过**（2026-11-19，Mate 80 Pro Max 模拟器）。
> 代码入口：[`entry/src/ohosTest/ets/test/ui/MainFlow.test.ets`](../entry/src/ohosTest/ets/test/ui/MainFlow.test.ets)
> 执行结果：`Tests run: 2, Failure: 0, Error: 0, Pass: 2`

## 1. 运行条件与命令

1. 连接真机或模拟器，`hdc list targets` 非空。
2. 构建并安装测试 HAP（`onDeviceTest` 会先卸载再安装被测包，**会清空应用数据**）：

```bash
export DEVECO_SDK_HOME='/Applications/DevEco-Studio.app/Contents/sdk'
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw \
  --mode module -p module=entry@ohosTest -p product=default onDeviceTest
```

3. 单独复跑（不重新安装）：

```bash
hdc shell "aa test -b com.cainluo.miyoyo.tools -m entry_test \
  -s unittest OpenHarmonyTestRunner -s timeout 120000"
```

4. 改过测试源码后增量编译不可靠，先清缓存再构建：

```bash
rm -rf entry/build/default/cache/ohosTest entry/build/default/intermediates/loader_out/ohosTest
```

5. `onDeviceTest` 每次都会 **卸载整包** 再安装，所以 `core_test` 与 `entry_test` 不能各自跑一遍 `onDeviceTest`——第二次会把第一个测试模块连同主 HAP 一起删掉。同时跑两个模块的顺序是：

```bash
# 先装主 HAP + entry_test（会顺带跑 entry 用例）
hvigorw --mode module -p module=entry@ohosTest -p product=default onDeviceTest
# 再把 core_test 追加进同一个包（-r 不卸载，保留主 HAP）
hdc install -r core/build/default/outputs/ohosTest/core-ohosTest-signed.hap
hdc shell "aa test -b com.cainluo.miyoyo.tools -m core_test \
  -s unittest OpenHarmonyTestRunner -s timeout 240000"
```

### 1.1 首次安装会停在「用户协议」页

`onDeviceTest` 每次都会卸载重装，应用数据为空，`LaunchPage` 会先 `replace` 到隐私协议页，**不会**进入主框架。测试在 `beforeAll` 里先把 entry 模块的 `legal_prefs` 同意标记写成 `true`，再启动 `EntryAbility`。

- preferences 按模块隔离：`/data/storage/el2/base/haps/<module>/preferences`。
- 测试代码运行在 `entry_test` 模块，`createModuleContext('entry')` 拿到的是**应用级**目录（写到 `/base/preferences`），应用读的是 `haps/entry/preferences`，所以 `MainFlow.test.ets` 直接按沙箱布局拼路径写 XML。
- 标记写法必须与 `LegalPreferences` 一致：`legal_prefs` + `<bool key="hasAgreedPrivacy" value="true"/>`。

### 1.2 为什么设备测试跑在 default 产品而不是 UAT

- hvigor 明确禁止把 `ohosTest` target 关联到产品：`The 'ohosTest' target does not need to be packaged into the application. 'ohosTest' target cannot be applied to product.`
- `onDeviceTest` 的安装流程是 `uninstall <bundle> → install`，指向 `com.cainluo.miyoyo.tools.uat` 会把 UAT 包里的登录账号、Widget 配置一起清掉。
- 因此设备端测试固定在 `-p product=default`（包名 `com.cainluo.miyoyo.tools`），源码与 UAT 完全相同，差异只有包名与 `EntryAbility` 标签。UAT 包只用于手工回归。

## 2. 已补的稳定控件 id

| id | 位置 | 用途 |
| --- | --- | --- |
| `main_navigation` | `entry/src/main/ets/pages/MainPage.ets` | 主页面 Navigation，启动冒烟兜底 |
| `home_scroll` | `features/home/src/main/ets/pages/HomePage.ets` | 首页内容滚动容器 |
| `login_page` | `features/account/src/main/ets/pages/LoginPage.ets` | 未登录时确认登录页可达 |
| `char_detail_material_calc_entry` | `features/chardetail/src/main/ets/views/common/CharDetailMaterialCalcEntry.ets` | 角色详情页「材料计算」入口 |
| `material_calc_page` | `features/material/src/main/ets/pages/MaterialCalcPage.ets` | 材料计算页根容器 |
| `material_calc_loading` | `features/material/src/main/ets/views/MaterialCalcLoadingView.ets` | 材料计算加载态 |
| `material_calc_empty` | `features/material/src/main/ets/views/MaterialCalcEmptyView.ets` | 材料计算空态 |
| `material_calc_content` | `features/material/src/main/ets/views/MaterialCalcContentView.ets` | 材料计算内容滚动区 |
| `material_calc_character` | `features/material/src/main/ets/views/MaterialCalcCharacter.ets` | 角色信息与等级按钮 |

## 3. 当前用例

| 用例 | 断言 | 状态 |
| --- | --- | --- |
| `应用启动后落在首页或登录页` | 启动 `EntryAbility` 后 10s 内命中 `main_navigation`，否则 2s 内命中 `login_page` | ✅ 通过 |

`Ability.test.ets` 的 `assertContain` 是 hypium 模板残留用例，只验证框架本身可用。

## 4. 待补链路

1. **首页角色卡 → 角色详情**：点第一张 `GameToolCard`（下一步给每张卡补 `role_card_<roleUid>` id），断言角色名/等级出现。
2. **角色详情 → 材料计算**：点 `char_detail_material_calc_entry`，断言 `material_calc_page` 出现，并至少命中 `material_calc_content` 或 `material_calc_empty`。
3. **未登录 → 登录**：清空账号后启动，断言 `login_page`，完成登录后断言 `home_scroll`。

## 5. 约束

- 坐标点击不可作为正式用例；必须用 `ON.id(...)`。
- 需要真实账号数据时，测试前用测试账号登录，不要在用例里写死 Cookie。
- `it()` 只接受 3 个参数（hypium 1.0.25），单条用例硬超时 15s，等待时长之和必须留余量。
- 顶层（`describe` 外）的 `beforeAll` / `beforeEach` 不生效，必须写在 `describe` 内。
- 从 `entry_test` 启动 `entry` 模块的 `EntryAbility` 时，`Want` 必须带 `moduleName: 'entry'`；缺了会报 `16000001`（The specified ability does not exist），此时前台会停在 TestAbility 的 “Test running” 页，表现为断言找不到 `main_navigation`。

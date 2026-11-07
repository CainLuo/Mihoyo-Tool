# UI 测试骨架与主链路清单

> 状态：骨架已建立，**尚未在设备上执行**（当前 `hdc list targets` 为空）。
> 代码入口：[`entry/src/ohosTest/ets/test/ui/MainFlow.test.ets`](../entry/src/ohosTest/ets/test/ui/MainFlow.test.ets)

## 1. 运行条件

1. 连接真机或模拟器，`hdc list targets` 非空。
2. 设备上已登录至少一个米游社账号，首页有可点击的角色卡片。
3. 运行：

```bash
bash test-entry.sh                     # 先确认 UI / 设备测试 HAP 能编译
hvigorw test --mode module -p module=entry@ohosTest -p product=default
```

当前 `MainFlow.test.ets` 只做启动冒烟：验证应用启动后落在 `main_navigation` 或 `login_page`。后续链路按下面的 id 补全。

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

## 3. 待补链路

1. **首页角色卡 → 角色详情**：点第一张 `GameToolCard`（下一步给每张卡补 `role_card_<roleUid>` id），断言角色名/等级出现。
2. **角色详情 → 材料计算**：点 `char_detail_material_calc_entry`，断言 `material_calc_page` 出现，并至少命中 `material_calc_content` 或 `material_calc_empty`。
3. **未登录 → 登录**：清空账号后启动，断言 `login_page`，完成登录后断言 `home_scroll`。

## 4. 约束

- 坐标点击不可作为正式用例；必须用 `ON.id(...)`。
- 需要真实账号数据时，测试前用测试账号登录，不要在用例里写死 Cookie。
- 当前 `entry/src/ohosTest` 只做编译验证，`test-entry.sh` 不执行测试；设备端执行结果需要单独记录。

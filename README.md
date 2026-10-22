# 米悠悠 (Mihoyo-Tool)

HarmonyOS NEXT 米游社工具箱，支持原神、崩坏：星穹铁道、绝区零的游戏数据查看。

基于 ArkTS + ArkUI 开发，采用 MVVM 架构，支持 Phone / Tablet / 2in1 多设备自适应布局。

---

## 功能

- **首页**：多账号游戏数据概览，支持原神树脂、星穹铁道开拓力、绝区零电量等实时便笺数据
- **角色**：原神、星穹铁道、绝区零角色列表，支持多账号切换，角色详情查看（属性面板、武器、圣遗物/遗器）
- **我的**：账号管理（Cookie / 手机号 / 扫码登录），外观设置（浅色 / 深色 / 跟随系统）

> **当前支持的游戏**：原神、崩坏：星穹铁道、绝区零
>
> 崩坏3 等其他游戏的角色数据会正常写入数据库，但暂不在 UI 中展示。
> 如需启用，在 `core/src/main/ets/common/constants/GameId.ets` 的 `SUPPORTED` 数组中添加对应的 `GameId` 即可。

---

## 开发环境

| 工具               | 版本                  |
| ------------------ | --------------------- |
| DevEco Studio      | 6.0.2                 |
| HarmonyOS NEXT SDK | API 18（6.0.2）       |
| ArkTS              | 严格模式              |
| ohpm               | 随 DevEco Studio 附带 |

支持的开发平台：**macOS**、**Windows**、**鸿蒙 PC**

---

## 快速开始

### 第一步：安装 DevEco Studio

从华为开发者联盟下载并安装 DevEco Studio 6.0.2：

https://developer.huawei.com/consumer/cn/deveco-studio/

安装完成后，在 DevEco Studio 内通过 `SDK Manager` 安装 **HarmonyOS NEXT API 18（6.0.2）** SDK。

### 第二步：克隆仓库

```bash
git clone <仓库地址>
cd Mihoyo-Tool
```

### 第三步：安装依赖

用 DevEco Studio 打开项目，IDE 会自动执行依赖安装（ohpm install）。

如果没有自动执行，手动运行：

```bash
# macOS / 鸿蒙 PC
ohpm install

# Windows（在项目根目录的命令提示符或 PowerShell 中执行）
ohpm.cmd install
```

> ohpm 随 DevEco Studio 一起安装，路径通常在：
>
> - macOS：`~/Library/Huawei/ohpm/bin/ohpm`
> - Windows：`%USERPROFILE%\AppData\Local\Huawei\ohpm\bin\ohpm.cmd`
> - 鸿蒙 PC：`~/Huawei/ohpm/bin/ohpm`
>
> 如果命令找不到，可以在 DevEco Studio 的 `File → Settings → Build → Ohpm` 中查看 ohpm 路径。

### 第四步：选择构建环境

运行环境只有三个：`release`、`uat`、`mock`。DevEco Studio 还会显示一个 `default` product，它是 Hvigor / DevEco 要求的技术兜底产品，身份等同 `release`，不是第四个运行环境。

| 运行环境  | Product   | Bundle ID                       | APP_ENV   | Build mode | API                        | 调试能力                     |
| --------- | --------- | ------------------------------- | --------- | ---------- | -------------------------- | ---------------------------- |
| Release   | `release` | `com.cainluo.miyoyo.tools`      | `release` | `release`  | 官方 API                   | 关闭日志 / TestPage / 抓包   |
| UAT       | `uat`     | `com.cainluo.miyoyo.tools.uat`  | `uat`     | `debug`    | 官方 API                   | 保留日志 / TestPage / 抓包   |
| Mock      | `mock`    | `com.cainluo.miyoyo.tools.mock` | `mock`    | `debug`    | `http://127.0.0.1:8787`    | 保留日志 / TestPage / 抓包   |

三个环境使用不同 Bundle ID，可以同时安装、互不覆盖。手机号 / 二维码 / Cookie 登录在三个环境中都可用，默认 Tab 为手机号登录。

> `default` 主要用于 IDE 兜底和 `ohosTest`，不要用它区分运行环境。

**签名说明**：`release` 使用 `Certificates/release/` 下的正式材料。`uat` / `mock` 必须在 AGC 为对应 Bundle ID 创建独立的调试证书和调试 Profile，并填入 `build-profile.json5` 的 `signingConfigs`；不能复用 release 签名。材料补齐前，`uat` / `mock` 只能构建出 unsigned HAP，不能安装。

### 第五步：运行

**方式一：DevEco Studio 直接运行（所有平台通用）**

1. 连接模拟器或真机
2. 右上角选择目标 product（`uat` / `mock` / `release`）
3. 点击 Run 按钮

**方式二：命令行脚本（仅 macOS）**

```bash
bash run.sh uat       # UAT：官方 API，Debug 能力
bash run.sh mock      # Mock：本机 local-service
bash run.sh release   # Release：正式包
bash run.sh           # 交互选择（5 秒无输入默认 uat）
```

脚本会自动启动模拟器（如未运行）、Clean、Build、安装、启动，一步到位。`uat` / `mock` 缺少签名材料时会在构建前直接报错，避免误装 unsigned 包。

---

## 项目结构

```
Mihoyo-Tool/
├── entry/                          # UI 层
│   └── src/main/ets/
│       ├── pages/                  # 页面（Home、Characters、My、Login 等）
│       ├── components/             # 可复用 UI 组件（含 login/ 手机号登录）
│       ├── viewmodel/              # ViewModel（UI 状态 + 业务逻辑）
│       ├── theme/                  # 主题系统（AppTheme、DefaultTheme）
│       └── constants/              # 路由常量、枚举
├── core/                           # 基础设施层（HAR）
│   └── src/main/ets/
│       ├── MihoyoKit/              # 账号 / 登录 / BBS / 签到
│       ├── GenshinKit/             # 原神
│       ├── StarRailKit/            # 崩坏：星穹铁道
│       ├── ZZZKit/                 # 绝区零
│       ├── base/                   # network / log / errors / utils / cookie
│       ├── common/                 # constants / material
│       ├── db/                     # RdbManager、SchemaRegistry、迁移基础设施
│       └── sync/                   # 同步队列与同步模型
├── mock-service/                   # 本地 Node Mock 服务（fixtures + RPC）
├── Certificates/                   # 签名材料（release / uat / mock 分开）
├── AppScope/                       # 应用级资源（图标、应用名）
├── build-profile.json5             # 构建配置（product / buildMode / signingConfigs）
├── run.sh                          # 三环境构建安装脚本（macOS）
├── pull-logs.sh                    # 拉取 mock / uat / release 日志
├── test-core.sh                    # 构建 core + entry 单元测试 HAP
├── test-entry.sh                   # 构建 entry 单元测试 HAP
├── test-cookie-refresh.sh          # Cookie 刷新场景测试
└── tag-release.sh                  # 打 release tag / 构建 APP
```

---

## 架构说明

项目采用 **MVVM + 分层架构**，严格隔离 UI 层和数据层：

```
entry（UI 层）                         core（基础设施层）
─────────────────────────────         ──────────────────────────────
pages / components                    Kit Repository / ApiService
       ↕ @Param / @Trace                       ↕
    ViewModel                         base/network（BaseApiService / DS / Cookie）
       ↕ 调用                                  ↕
    （禁止直接访问 DB）                db（RdbManager / DAO / SchemaRegistry）
```

- **entry** 只调用 `core` 的 Repository 高层方法，不直接操作数据库或网络
- **环境切换**通过 product 的 `APP_ENV` 字段控制，entry 层无感知；域名统一由 `MihoyoDomain` 解析
- **UAT / Release** 使用官方 API；**Mock** 使用本机 `http://127.0.0.1:8787`，并保留 `/apihub` 前缀
- **多账号隔离**通过 `accountId + roleUid` 在数据库层实现

---

## Mock 数据说明

Mock 数据已移出 HAP，放在独立服务目录：

```
mock-service/
├── fixtures/
│   └── {accountId}/
│       └── {roleUid}/
│           ├── game_record_app_genshin_api_dailyNote.json
│           └── ...
├── router.mjs
└── server.mjs
```

`mock` product 当前只把 API 域名切到 `http://127.0.0.1:8787`；`mock-service/server.mjs` 目前仅提供 `/__health`、`/` 和 `POST /__mock/rpc`，直接 REST 路由尚未实现。因此 **Mock 数据链路仍未完成**，不能把 Mock 包当成已可用的离线数据版本。

---

## 常见问题

### clone 后 IDE 报大量错误

执行依赖安装后重新 Sync：

```bash
ohpm install
```

或在 DevEco Studio 中：`File → Sync and Refresh Project`

### 模拟器连接失败

确认模拟器已启动并连接：

```bash
# macOS
/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc list targets
```

应输出 `127.0.0.1:5555`，如果没有则需要先在 DevEco Studio 的 Device Manager 中启动模拟器。

### DevEco Studio 点击 Run 后报 "The specified ability does not exist"

这是 DevEco Studio 6.0 的缓存 bug，IDE 内部启动命令使用了旧的 bundle name。

**解决方案**：在 `Run → Edit Configurations → entry → Launch Flags` 中填入：

```
-b com.cainluo.miyoyo.tools.mock -a EntryAbility
```

（根据当前选择的 product 替换对应的 bundle id）

### Windows 下命令行工具路径

ohpm 和 hdc 在 Windows 下的路径：

- ohpm：`%USERPROFILE%\AppData\Local\Huawei\ohpm\bin\ohpm.cmd`
- hdc：`%USERPROFILE%\AppData\Local\Huawei\Sdk\openharmony\{版本}\toolchains\hdc.exe`

建议将上述路径加入系统 PATH 环境变量，方便直接使用。

---

## 依赖

| 包                | 版本   | 用途          |
| ----------------- | ------ | ------------- |
| `@ohos/axios`     | 2.2.7  | HTTP 网络请求 |
| `@ohos/crypto-js` | 2.0.5  | DS 签名加密   |
| `@ohos/hypium`    | 1.0.25 | 单元测试框架  |
| `@ohos/hamock`    | 1.0.0  | Mock 测试工具 |

---

## License

[MIT](LICENSE)

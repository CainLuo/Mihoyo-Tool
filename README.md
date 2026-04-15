# 米悠悠 (Mihoyo-Tool)

HarmonyOS NEXT 米游社工具箱，支持原神、崩坏：星穹铁道、绝区零的游戏数据查看。

基于 ArkTS + ArkUI V2 开发，采用 MVVM 架构，支持 Phone / Tablet / 2in1 多设备自适应布局。

---

## 功能

- **首页**：多账号游戏数据概览，支持原神树脂、星穹铁道开拓力、绝区零电量等实时便笺数据
- **角色**：原神、星穹铁道、绝区零角色列表，支持多账号切换，角色详情查看（属性面板、武器、圣遗物/遗器）
- **我的**：账号管理（Cookie / 手机号 / 扫码登录），外观设置（浅色 / 深色 / 跟随系统）

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

项目有三个 product，在 DevEco Studio 右上角点击 product 选择器切换：

| Product   | Bundle ID                        | App 名称     | 说明                         |
| --------- | -------------------------------- | ------------ | ---------------------------- |
| `default` | `com.cainluo.mihoyo.tools`       | 米悠悠       | 正式发布，连接真实 API       |
| `mock`    | `com.cainluo.mihoyo.tools.mock`  | 米悠悠-mock  | 本地 Mock 数据，日常开发首选 |
| `debug`   | `com.cainluo.mihoyo.tools.debug` | 米悠悠-debug | 真实 API，可配合抓包工具调试 |

三个环境可以同时安装在设备上，互不干扰。

**日常开发推荐使用 `mock` product**，无需真实账号即可看到完整 UI。

### 第五步：运行

**方式一：DevEco Studio 直接运行（所有平台通用）**

1. 连接模拟器或真机
2. 右上角选择目标 product（推荐 `mock`）
3. 点击 Run 按钮

**方式二：命令行脚本（仅 macOS）**

```bash
bash run-mock.sh      # mock 环境（日常开发）
bash run-debug.sh     # debug 环境（真实 API 调试）
bash run.sh           # release 环境（正式发布）
```

脚本会自动启动模拟器（如未运行）、Clean、Build、安装、启动，一步到位。

---

## 项目结构

```
Mihoyo-Tool/
├── entry/                          # UI 层
│   └── src/main/ets/
│       ├── pages/                  # 页面（Home、Characters、My、Login 等）
│       ├── components/             # 可复用 UI 组件
│       ├── viewmodel/              # ViewModel（UI 状态 + 业务逻辑）
│       ├── theme/                  # 主题系统（AppTheme、DefaultTheme）
│       └── constants/              # 路由常量、枚举
├── core/                           # 基础设施层
│   └── src/main/ets/
│       ├── network/                # 网络层（ApiService、MockService、DSUtil）
│       ├── database/               # 数据库层（RdbManager、DAO）
│       ├── repository/             # Repository 层（BBSRepository、GenshinRepository 等）
│       ├── models/                 # 数据模型（Row 模型、原始数据模型）
│       ├── parsers/                # JSON 解析器（便笺、角色数据）
│       └── constants/              # 常量（GameId、GameServer、ApiErrorCodes 等）
├── AppScope/                       # 应用级资源（图标、应用名）
├── build-profile.json5             # 构建配置（product / buildMode）
├── run.sh                          # release 构建脚本（macOS）
├── run-mock.sh                     # mock 构建脚本（macOS）
└── run-debug.sh                    # debug 构建脚本（macOS）
```

---

## 架构说明

项目采用 **MVVM + 分层架构**，严格隔离 UI 层和数据层：

```
entry（UI 层）                    core（基础设施层）
─────────────────────────────    ──────────────────────────────
pages / components               network（ApiService / MockService）
       ↕ @Param / @Trace                  ↕
    ViewModel                    repository（BBSRepository 等）
       ↕ 调用                             ↕
    （禁止直接访问 DB）           database（RdbManager / DAO）
```

- **entry** 只调用 `core` 的 Repository 高层方法，不直接操作数据库或网络
- **mock / release 切换**通过 product 的 `APP_ENV` 字段控制，entry 层无感知
- **多账号隔离**通过 `accountId + roleUid` 在数据库层实现

---

## Mock 数据说明

`mock` product 使用本地 JSON 文件模拟 API 响应，数据文件位于：

```
core/src/main/resources/rawfile/mock/
└── {accountId}/
    └── {roleUid}/
        ├── game_record_app_genshin_api_dailyNote.json
        ├── game_record_app_genshin_api_character_list.json
        └── ...
```

文件命名规则：将 API 路径中的 `/` 替换为 `_`，例如：

- `/game_record/app/genshin/api/dailyNote` → `game_record_app_genshin_api_dailyNote.json`

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
-b com.cainluo.mihoyo.tools.mock -a EntryAbility
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

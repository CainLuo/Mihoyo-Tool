# 米游社数据工具箱（纯血鸿蒙版）技术规格说明书（V2.0 最终定稿版）

版本：V2.0

适用对象：开发人员、Kiro、Trae CN

架构原则：纯鸿蒙原生、无安卓残留、严谨可扩展、迭代友好

编写依据：

- 需求规格说明书（HoYoLab_Toolkit_SRS_v1.0.md）

- 页面细节规范（HoYoLab_Toolkit_UI_Spec_v1.0.md）

- 华为官方 HarmonyOS 开发文档（优先参考）

- 接口参考：https://github.com/BTMuli/TeyvatGuide、https://github.com/UIGF-org/mihoyo-api-collect

- 华为官方穿戴设备分类规范、鸿蒙多设备适配标准

- 米游社 DS 加密算法官方规范（UIGF-org 提供）

# 1. 总则（强制执行）

## 1.1 官方文档优先原则

所有代码实现必须优先查阅华为官方 HarmonyOS 文档，禁止使用非官方、过时、第三方替代方案。涉及 UI、数据库、Web、路由、文件、本地化、后台任务等，一律以官方文档为准。

## 1.2 文档访问与登录规则

- 部分官方 API 文档需要登录华为开发者联盟账号才能查看。

- 若 Kiro / Trae CN 无法访问文档，需提示：**“请登录华为开发者联盟账号并授权后继续”**

- 登录后仍无法查看，提示：**“请完成开发者实名认证”**。

## 1.3 官方文档地址（核心常用）

### 中文官方文档：https://developer.huawei.com/consumer/cn/doc/

- Ability Kit（程序框架服务）：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ability-api

- ArkData（方舟数据管理）：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkdata-api

- ArkTS（方舟编程语言）：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-api

- ArkUI（方舟UI框架）：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkui-api

- ArkWeb（方舟Web）：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkweb-api

- Background Tasks Kit（后台任务开发服务）：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/background-tasks-api

- Core File Kit（文件基础服务）：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/core-file-api

- Data Augmentation Kit（数据增强服务）：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/data-augmentation-api

- Form Kit（卡片开发服务）：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/form-api

- Localization Kit（本地化开发服务）：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/localization-api

- UI Design Kit（UI设计套件）：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ui-design-api

- 网络：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/system-network-api

- Notification Kit（用户通知服务）：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/notification-api

- Push Kit（推送服务）：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/push-api

### 英文官方文档（与中文一一对应，优先参考中文，英文用于辅助）：https://developer.huawei.com/consumer/en/doc/

- Ability Kit（程序框架服务）：https://developer.huawei.com/consumer/en/doc/harmonyos-references/ability-api

- ArkData（方舟数据管理）：https://developer.huawei.com/consumer/en/doc/harmonyos-references/arkdata-api

- ArkTS（方舟编程语言）：https://developer.huawei.com/consumer/en/doc/harmonyos-references/arkts-api

- ArkUI（方舟UI框架）：https://developer.huawei.com/consumer/en/doc/harmonyos-references/arkui-api

- ArkWeb（方舟Web）：https://developer.huawei.com/consumer/en/doc/harmonyos-references/arkweb-api

- Background Tasks Kit（后台任务开发服务）：https://developer.huawei.com/consumer/en/doc/harmonyos-references/background-tasks-api

- Core File Kit（文件基础服务）：https://developer.huawei.com/consumer/en/doc/harmonyos-references/core-file-api

- Data Augmentation Kit（数据增强服务）：https://developer.huawei.com/consumer/en/doc/harmonyos-references/data-augmentation-api

- Form Kit（卡片开发服务）：https://developer.huawei.com/consumer/en/doc/harmonyos-references/form-api

- Localization Kit（本地化开发服务）：https://developer.huawei.com/consumer/en/doc/harmonyos-references/localization-api

- UI Design Kit（UI设计套件）：https://developer.huawei.com/consumer/en/doc/harmonyos-references/ui-design-api

- 网络：https://developer.huawei.com/consumer/en/doc/harmonyos-references/system-network-api

- Notification Kit（用户通知服务）：https://developer.huawei.com/consumer/en/doc/harmonyos-references/notification-api

- Push Kit（推送服务）：https://developer.huawei.com/consumer/en/doc/harmonyos-references/push-api

补充说明：鸿蒙官方文档以中文为核心更新优先，英文文档与中文文档模块、内容完全对应，仅语言不同，用于开发人员辅助查阅（如英文环境适配、海外技术参考），核心开发仍以中文官方文档为准，确保与鸿蒙原生开发规范一致。

## 1.4 API / 组件变更提示机制

当 Kiro/Trae CN 发现以下情况时，**必须主动提示用户**：

- 当前使用的 ArkTS / ArkUI API / 组件被官方标记为 @Deprecated、过时、移除、行为变更

- 官方有明确推荐的替代 API/组件

**标准提示语：**

> 【API/组件变更提示】
> 当前代码使用的 **[API/组件名]** 已被官方标记为 **[废弃/过时/行为变更]**。
> 推荐替代：**[替代方案]**。
> 是否需要更新为最新官方 API/组件？

**处理流程：**

- 用户回复「是」：按最新官方文档重构代码，确保兼容当前 targetSdkVersion

- 用户回复「否」：保留原有代码，记录变更信息，后续异常时再次提醒

- 未明确回复：暂停相关代码编写，等待用户确认后再继续

# 2. 模块架构（core + entry，纯鸿蒙分层）

## 2.1 模块拆分（强制）

- **core（HSP 动态共享包）**：鸿蒙原生共享能力包，包含网络请求、数据库、Model 解析、Repository、DataSource、DS 加密工具、UIGF 中间转换层（预留）、工具类、环境配置、业务逻辑；无 UI、无页面、无资源，仅提供核心能力。

- **entry（HAP 主应用）**：鸿蒙应用入口包，包含UI 页面、ViewModel、路由、主题、国际化、设备适配（当前仅手机/折叠屏）、全局状态、应用入口；依赖 core，不包含核心业务逻辑。

## 2.2 依赖关系

entry → core（单向依赖，禁止反向依赖，确保核心逻辑可复用、可维护）

## 2.3 目录结构（标准规范）

```plain text
core/
  src/main/ets/
    network/
      DSUtil.ts        # DS2 加密工具（统一实现）
      BaseHttpClient.ts # 网络请求封装
    database/          # 关系型数据库操作
    model/             # 数据结构与解析
      enum/             # 枚举统一管理目录（存储元素力、命途等枚举）
        GameElementEnum.ts # 原神元素力枚举
        PathEnum.ts        # 星穹铁道命途枚举
        WeaponTypeEnum.ts  # 武器类型枚举
    repository/        # 数据仓库（统一数据出口）
    utils/             # 通用工具类
      constant/         # 常量统一管理目录
        AppConstant.ts  # 全局通用常量（含刷新、Cookie/Token更新等）
    env/               # 环境配置（Salt、版本号等）
    uigf/              # 预留：UIGF 中间转换层
entry/
  src/main/ets/
    pages/             # 所有UI页面（仅适配手机/折叠屏）
    viewmodel/         # 页面状态与交互逻辑
    router/            # 路由管理（官方Navigation + NavPathStack）
    resources/         # 资源目录（仅包含手机/折叠屏相关资源）
    app.ets            # 应用入口，初始化core
```

# 3. 多环境配置（Release / Debug / Mock）

- 环境定义：Release（真实接口，关闭日志）、Debug（真实接口，开启日志）、Mock（本地JSON，不发起网络请求）。

- 环境传入：从 build-profile.json5 的 Target 中获取 APP_ENV，在 entry 的 onCreate 中传入 core 完成初始化。

- 数据源切换：core 根据环境自动切换，Mock 环境使用 MockDataSource，Debug/Release 环境使用 RemoteDataSource。

# 4. 设备适配范围（当前 V1.0 明确版）

## 4.1 当前 V1.0 支持设备（仅适配）

- Phone（直屏手机）：资源限定词 **phone**，底部 TabBar 导航，单列布局。

- Foldable / WideFold / TripleFold（折叠屏手机）：资源限定词**foldable**，展开后大屏适配，默认底部 TabBar（与手机一致）；后续迭代（V2.0及以后）可优化为侧边栏，优化触发条件：折叠屏展开状态下，屏幕宽度≥1200vp，双列布局。

## 4.2 当前 V1.0 不支持设备（后续迭代规划）

以下设备适配延后至后续版本（V2.0 及以后），当前不做任何开发，不影响现有代码架构：

- Tablet（平板）

- PC / 2in1 / 2in1 Foldable（鸿蒙 PC / 二合一设备）

- TV（电视）

- 穿戴设备：所有手环（含华为手环10，轻量鸿蒙，不支持独立App）、全功能智能手表（WATCH 3/4/5系列，完整鸿蒙，后续可适配独立App）

## 4.3 适配架构保障（可扩展）

本项目采用鸿蒙官方「资源限定词 + 响应式布局」架构，未来新增任何设备适配时：

- 不修改现有业务代码（core层完全复用）

- 不重构数据库、不破坏现有功能

- 仅需新增对应设备的资源目录（如 tablet/、pc/、wearable/），调整UI布局与交互，无需改动核心逻辑。

## 4.4 当前适配规范（手机/折叠屏）

- 布局：仅使用 flex、weight、百分比、vp，禁止写死 px，确保折叠屏展开/折叠时自动适配。

- 导航：统一使用底部 TabBar（战绩 / 角色列表 / 我的），折叠屏展开后可暂不调整，后续迭代优化。

- 资源目录：仅保留 base/、phone/、foldable/，其余设备资源目录暂不创建。

# 5. 网络与 API 规范

## 5.1 API 参考来源

1. TeyvatGuide（https://github.com/BTMuli/TeyvatGuide）：用于登录、Geetest 验证、角色详情、实时便笺等核心逻辑参考。

2. UIGF-org（https://github.com/UIGF-org/mihoyo-api-collect）：用于标准化接口、字段定义、DS 加密鉴权规范，为后续 UIGF 适配预留基础。

## 5.2 米游社 API 鉴权（DS 加密，强制）

### 5.2.1 参考来源

- UIGF-org 官方鉴权规范：https://github.com/UIGF-org/mihoyo-api-collect/blob/main/other/authentication.md

- 实现参考：https://github.com/Womsxd/MihoyoBBSTools/blob/master/tools.py

### 5.2.2 算法与 client_type 规范（纯鸿蒙兼容）

- 算法：所有接口统一使用 **DS2**（高安全性，适配米游社游戏数据接口，无需区分设备）。

- client_type：米游社未为鸿蒙分配独立类型，采用兼容策略，**所有设备（当前手机/折叠屏）统一固定为 2**。

- 说明：client_type=2 仅为网络请求鉴权兼容所需，确保能通过米游社API鉴权，与应用系统（鸿蒙/安卓）无关，不影响本应用“纯鸿蒙原生”属性，不代表应用为安卓应用。

### 5.2.3 DS2 算法实现（DSUtil.ts）

核心逻辑（固定，禁止修改）：

```typescript
// DS2 生成逻辑
t = 时间戳(秒)
r = 6位随机字符串
b = POST body（空则为""）
q = GET 参数按 key 正序拼接
sign = md5(`salt=${SALT}&t=${t}&r=${r}&b=${b}&q=${q}`)
DS = `${t},${r},${sign}`

```

### 5.2.4 必传请求头

所有米游社 API 请求必须携带以下请求头，由 DSUtil 统一封装：

- DS：生成的签名字符串

- x-rpc-app_version：对应米游社版本号（配置在 core/env/EnvConfig.ts）

- x-rpc-client_type：2（固定）

- X-Requested-With：com.mihoyo.hyperion

### 5.2.5 配置管理

Salt、米游社版本号统一配置在 core/env/EnvConfig.ts，支持多环境独立配置，可随米游社版本更新热切换，禁止硬编码。

# 6. UIGF 架构设计（专业级，预留扩展）

## 6.1 架构原则（强制）

- 本地数据库 = 唯一权威数据源（Source of Truth），不被外部格式（UIGF）侵入。

- UIGF 仅作为外部数据交换格式（导入/导出），不修改本地数据库结构。

- 使用独立中间转换层（UigfConverter），负责 UIGF 与本地模型的相互转换，隔离外部格式变更。

- 数据新旧判断以本地 update_time 时间戳为准，与 API 时间、UIGF 时间完全分离。

## 6.2 架构分层

```plain text
外部 UIGF 文件
       ↓
UIGF 中间转换层（UigfConverter）→ core/uigf/（预留）
       ↓
本地数据库（内部结构，唯一权威）

```

## 6.3 V1.0 做法（预留，不实现完整功能）

- 数据库表结构预留 update_time 字段，为后续 UIGF 导入/导出做准备。

- core 内预留 uigf/ 目录，不实现具体转换逻辑，确保后续迭代可无缝接入。

- 数据库结构不随 UIGF 标准变更，仅通过中间层适配不同 UIGF 版本（v2/v3/SRGF/ZZZF）。

# 7. 数据持久化（core 层，强制规范）

## 7.1 关系型数据库（RelationalStore）

### 7.1.1 强制字段（每张表必须包含）

```sql
id            INTEGER PRIMARY KEY AUTOINCREMENT,   -- 自增主键（唯一标识，必须，独立于API返回ID）
create_time   INTEGER,                             -- 本地插入时间（毫秒时间戳，本地生成，不被API/UIGF覆盖）
update_time   INTEGER                              -- 本地更新时间（毫秒时间戳，本地生成，不被API/UIGF覆盖）
```

### 7.1.2 关键规则

- 上述 3 个字段为本地系统字段，与 API 返回无关，由应用本地生成，不被 API 数据、UIGF 数据覆盖。

- API 返回的时间字段（如服务器更新时间），需单独存储（如 server_update_time），与本地时间完全分离。

- 所有表需额外新增 userId（米游社账号隔离）、gameId（游戏隔离）两个强制字段（独立于API返回字段），确保多账号、多游戏数据不混淆。

### 7.1.3 主要数据表

- user_accounts：米游社账号信息

- game_accounts：游戏账号信息（原神/星穹铁道/绝区零）

- characters：角色基础信息

- weapons / lightCones：武器/光锥信息

- relics / ornaments：圣遗物/遗器信息

- user_stats：实时便笺、战绩数据

## 7.2 轻量级存储（DataPrefs）

用于存储全局配置信息：主题模式、语言设置、当前选中账号 ID、上一次全局刷新时间戳。

## 7.3 文件存储（FileAccess）

用于存储：角色/武器图片缓存、Mock 数据 JSON、本地日志（仅 Debug 环境）。

# 8. UI 与页面规范（当前仅手机/折叠屏）

- 路由：使用官方 Navigation + NavPathStack 管理路由，统一路由跳转规范。

- 架构：采用 MVVM 架构，UI 层仅负责渲染，ViewModel 处理页面状态、交互逻辑、数据请求，不包含核心业务逻辑。

- 交互规范：所有可点击按钮必须实现防暴力点击（点击后立即置灰，动作完成后恢复）；刷新操作遵守 30 分钟冷却规则，触发时弹出提示框。

- 国际化：所有文案放入 string.json，禁止硬编码，通过 $r('app.string.xxx') 访问，支持 zh_CN、zh_HK、en。

- 主题：支持浅色/深色/跟随系统，使用官方 color.json + dark 资源限定词，通过 $r('app.color.xxx') 访问。

- **UI 常量与主题适配专业实现方式**：用户描述的方式，专业术语为 **「接口（Protocol）约束 + 实现类（Concrete Class）分离」**，本质是基于 **依赖倒置原则** 的**主题适配架构**，与鸿蒙官方「多主题适配」规范兼容，同时兼顾可扩展性与可维护性。通俗解读：先定义“颜色、尺寸等UI常量的统一标准”（接口），再为不同主题（浅色/深色）编写具体的常量值（实现类），切换主题时仅需替换实现类，无需修改UI代码。

- **专业术语详细说明**：1. 核心术语：接口（Protocol）约束 + 实现类分离（对应Swift中的Protocol与遵循协议的Class），鸿蒙ArkTS中对应 **interface（接口）** 与**class（实现类）**；2. 架构本质：属于「依赖注入 + 策略模式」的结合，通过接口定义UI常量（颜色、尺寸等）的统一规范，由不同实现类提供具体值，实现主题的无缝切换；3. 对应用户描述的场景：- 接口（Protocol）：对应 AppColor（颜色）、AppDimension（尺寸，含padding、高度、宽度等）等接口，仅声明所需常量的名称与类型，不定义具体值；- 实现类：对应 DefaultTheme、DarkTheme、LightTheme 等，遵循上述接口，实现接口中所有常量的具体值（如颜色十六进制、尺寸vp值）；- 切换逻辑：全局维护一个主题管理类，通过替换实现类实例（如将DefaultTheme替换为DarkTheme），实现所有UI组件常量的统一切换，无需修改任何UI渲染代码。

- **本项目 V1.0 及后续实现规范**：1. 接口定义：在 core/utils 目录下新建 theme 文件夹，定义接口：- IAppColor：声明所有UI所需颜色常量（如 primaryColor、backgroundColor、textPrimaryColor 等）；- IAppDimension：声明所有UI尺寸常量（如 paddingSmall、buttonHeight、cornerRadius、fontSizeMedium 等）；2. 实现类：在同一目录下创建实现类，遵循上述接口：- DefaultTheme：默认主题，实现IAppColor、IAppDimension，提供默认主题的常量值；- DarkTheme：深色主题，实现接口，提供深色模式下的常量值；- LightTheme：浅色主题，实现接口，提供浅色模式下的常量值；3. 全局管理：创建 ThemeManager 工具类，统一提供当前主题的常量实例，UI组件通过 ThemeManager 获取常量（如 ThemeManager.currentTheme.primaryColor），不直接硬编码常量值；4. 扩展与切换：后续新增主题（如CustomTheme），仅需新增实现类并遵循接口；切换主题时，修改ThemeManager的当前主题实例即可，所有UI组件自动同步更新，无需改动其他代码。

- **全局常量统一管理规范**：所有业务相关、配置相关常量（非UI常量），需集中存储在 core/utils/constant/AppConstant.ts 文件中，禁止分散硬编码，便于后续统一修改、维护，同时需添加清晰注释，说明常量含义、用途及修改注意事项。

- **核心常量定义（含注释，强制遵循）**：1. 数据刷新相关常量：用于控制页面自动刷新、手动刷新冷却时间；2. 鉴权相关常量：用于控制Cookie、Token自动更新周期，避免鉴权失效；3. 其他通用常量：后续新增的固定配置值（如请求超时时间、分页大小等），均需纳入此类管理；
  具体示例代码（仅作规范参考，无需单独生成AppConstant.ts文件，用代码块包裹）：

```TypeScript
// 仅作示例，无需单独生成文件，按此规范在core/utils/constant/AppConstant.ts中定义
export const AppConstant = {
  // 数据刷新相关常量（单位：毫秒ms）
  REFRESH_COOLDOWN: 30 * 60 * 1000, // 刷新冷却时间：30分钟（首页战绩列表、实时便笺等通用）
  AUTO_REFRESH_INTERVAL: 30 * 60 * 1000, // 自动刷新间隔：30分钟（首页战绩列表自动刷新）

  // 鉴权相关常量（单位：毫秒ms）
  COOKIE_AUTO_UPDATE_INTERVAL: 2 * 24 * 60 * 60 * 1000, // Cookie自动更新周期：2天（最低2天，可调整为3天）
  TOKEN_AUTO_UPDATE_INTERVAL: 2 * 24 * 60 * 60 * 1000, // Token自动更新周期：2天（与Cookie同步，避免鉴权失效）

  // 网络请求相关常量（单位：毫秒ms）
  HTTP_REQUEST_TIMEOUT: 10 * 1000, // 网络请求超时时间：10秒

  // 分页相关常量
  PAGE_SIZE: 20, // 列表分页默认每页条数（角色列表、战绩列表等通用）
};
```

- **常量使用规则**：1. 所有业务代码、UI逻辑中，需通过 import 导入 AppConstant 常量，如 AppConstant.REFRESH_COOLDOWN，禁止直接写死数值；2. 常量修改规范：若需调整常量值（如刷新时间、Cookie更新周期），仅修改 core/utils/constant/AppConstant.ts 中的对应值，无需改动任何引用该常量的业务代码；3. 新增常量规范：后续新增常量时，需按“功能分类”添加到 AppConstant.ts 对应区域，同时补充详细注释，说明常量用途、单位及修改限制；4. 禁止在 AppConstant.ts 中定义UI相关常量（如颜色、尺寸），UI常量统一通过主题接口（IAppColor、IAppDimension）管理；5. 示例代码仅作规范参考，无需单独生成AppConstant.ts文件，直接在指定目录下按示例规范定义即可。

# 9. 安全与合规（强制）

- 敏感信息：Cookie、账号相关信息加密存储，不明文保存。

- 数据隐私：所有用户数据仅存储在本地，不上传任何服务器，不收集设备信息、不埋点、不上报日志。

- 权限申请：仅申请最小权限，包括网络权限、存储权限（图片缓存）、相机权限（仅扫码登录使用）。

- 合规要求：登录页底部必须展示用户协议与隐私政策链接。

# 10. 编码规范（Kiro / Trae CN 必须遵守）

1. 优先查阅华为官方文档，无法访问时按规则提示用户登录授权。

2. 严格遵循 core/entry 单向依赖，禁止反向依赖，核心逻辑全部放在 core 层。

3. 国际化、主题、多设备适配（当前手机/折叠屏）必须使用官方资源体系，禁止硬编码文案、尺寸、颜色。UI 常量（颜色、尺寸、圆角等）需采用「接口约束 + 实现类分离」模式管理，通过ThemeManager统一获取，支持主题无缝切换。

4. 所有米游社 API 请求必须经过 DSUtil 生成 DS2 签名，禁止硬编码 Salt、client_type。

5. 数据库表必须包含 id、create_time、update_time、userId、gameId 字段，本地时间与 API 时间分离存储。

6. 发现 ArkTS/ArkUI API/组件废弃、变更时，必须按 1.4 节规则提示用户，未经确认不得擅自升级。

7. 当前仅开发手机/折叠屏适配代码，不提前编写平板、PC、TV、穿戴设备相关代码，避免冗余。

8. 布局仅使用 flex、weight、百分比、vp，禁止写死 px，确保折叠屏适配兼容性。

9. 所有业务相关、配置相关常量（如刷新时间、Cookie/Token更新周期），必须统一存储在 core/utils/constant/AppConstant.ts 文件中，禁止分散硬编码，且每个常量需添加清晰注释，说明含义、用途及单位。

10. **枚举（Enum）使用规范（强制）**：针对API返回的所有固定值类型（含示例中提及的原神元素力类型、星穹铁道命途、武器类型、游戏类型等，以及纯数值类型的固定标识，示例仅作参考，不代表全部场景），一旦发现API返回此类固定值（无论是否在现有示例中，无论值为字符串还是纯数值），均必须使用枚举（Enum）统一装载管理，禁止直接在logic层、UI层硬编码字符串或数值进行判断、赋值或业务操作，确保代码可维护性、可扩展性，避免拼写错误、数值混淆导致的业务异常。同时，为应对米游社API更新新增未识别类型的场景，所有枚举必须定义保留值（默认值），用于兼容未识别的API返回值，避免应用崩溃。本条款为枚举使用的唯一强制规范，后续章节不再重复，所有枚举相关操作均按本条执行。

11. **枚举适用场景（明确范围，示例仅作参考，不局限于以下场景）**：1. 游戏相关固定类型：原神元素力（pyro/火、hydro/水等字符串类型）、星穹铁道命途（开拓、毁灭等字符串类型）、武器类型（单手剑、双手剑等字符串类型）；2. API返回固定状态：账号登录状态、数据刷新状态、请求状态（成功/失败/加载中）等（字符串或数值类型均可）；3. 应用内部固定分类：游戏账号类型（原神、星穹铁道、绝区零）、数据类型（角色数据、武器数据、圣遗物数据）等；4. API返回的纯数值固定标识：如原神 property_type 字段（属性标识纯数值，每个数值对应唯一属性含义）、其他游戏/接口返回的纯数值固定编码（数量多、含义固定的场景优先适用）；5. 其他所有API返回的固定值类型：无论值为字符串还是纯数值，无论是否在上述示例中，只要API返回值为固定不变、且有明确对应含义的，均需纳入枚举管理。

12. **枚举存储与实现规范**：1. 存储位置：在 core/model 目录下新建 enum 文件夹，按功能分类创建枚举文件，禁止分散在logic层、UI层或其他目录；2. 命名规范：枚举文件命名格式为「功能+Enum.ts」（如 GameElementEnum.ts、PathEnum.ts、WeaponTypeEnum.ts、PropertyTypeEnum.ts），枚举名称与文件名称对应，首字母大写；3. 实现要求：枚举值与API返回的固定值（字符串/纯数值）完全一致，同时添加清晰注释说明枚举含义（尤其纯数值类型，需明确数值对应的具体含义），便于开发人员对应API返回值；对于数量较多的纯数值枚举（如原神 property_type），需按属性类别分类注释，提升可读性；4. 保留值（默认值）要求：所有枚举必须新增保留值（默认值），命名统一为 UNKNOWN，用于兼容米游社API更新后新增、本应用未及时适配的未识别类型，避免因未识别值导致应用崩溃；保留值需添加明确注释，说明其作用为兼容未识别API返回值；5. 补充说明：示例代码仅展示常见场景，不代表全部枚举类型，开发过程中若发现API返回新的固定值（无论字符串还是纯数值），需及时新增对应枚举值，遵循本规范统一管理；若暂未适配，需使用保留值兜底；6. 示例代码（仅作规范参考，不局限于以下枚举，重点补充保留值）：

```TypeScript
// core/model/enum/GameElementEnum.ts（原神元素力枚举，字符串类型，含保留值）
export enum GameElementEnum {
  PYRO = "pyro", // 火元素，与API返回字符串完全一致
  HYDRO = "hydro", // 水元素，与API返回字符串完全一致
  ANEMO = "anemo", // 风元素，与API返回字符串完全一致
  ELECTRO = "electro", // 雷元素，与API返回字符串完全一致
  DENDRO = "dendro", // 草元素，与API返回字符串完全一致
  CRYO = "cryo", // 冰元素，与API返回字符串完全一致
  GEO = "geo", // 岩元素，与API返回字符串完全一致
  UNKNOWN = "unknown" // 保留值（默认值）：兼容米游社API新增未识别的元素类型，避免应用崩溃
}

// core/model/enum/PathEnum.ts（星穹铁道命途枚举，字符串类型，含保留值）
export enum PathEnum {
  PRESERVATION = "Preservation", // 开拓，与API返回字符串完全一致
  DESTRUCTION = "Destruction", // 毁灭，与API返回字符串完全一致
  HUNT = "Hunt", // 巡猎，与API返回字符串完全一致
  ERUDITION = "Erudition", // 智识，与API返回字符串完全一致
  HARMONY = "Harmony", // 同谐，与API返回字符串完全一致
  NIHILITY = "Nihility", // 虚无，与API返回字符串完全一致
  ABUNDANCE = "Abundance", // 丰饶，与API返回字符串完全一致
  UNKNOWN = "unknown" // 保留值（默认值）：兼容米游社API新增未识别的命途类型，避免应用崩溃
}

// core/model/enum/PropertyTypeEnum.ts（原神property_type枚举，纯数值类型，数量多，含保留值）
export enum PropertyTypeEnum {
  // 基础属性
  HP = 1, // 生命值
  HP_PERCENT = 2, // 生命值百分比
  ATK = 3, // 攻击力
  ATK_PERCENT = 4, // 攻击力百分比
  DEF = 5, // 防御力
  DEF_PERCENT = 6, // 防御力百分比
  // 元素属性
  ELEMENTAL_MASTERY = 7, // 元素精通
  ENERGY_RECHARGE = 8, // 元素充能效率
  CRIT_RATE = 9, // 暴击率
  CRIT_DAMAGE = 10, // 暴击伤害
  // 元素伤害加成（按元素分类）
  PYRO_DAMAGE_BONUS = 11, // 火元素伤害加成
  HYDRO_DAMAGE_BONUS = 12, // 水元素伤害加成
  ANEMO_DAMAGE_BONUS = 13, // 风元素伤害加成
  ELECTRO_DAMAGE_BONUS = 14, // 雷元素伤害加成
  DENDRO_DAMAGE_BONUS = 15, // 草元素伤害加成
  CRYO_DAMAGE_BONUS = 16, // 冰元素伤害加成
  GEO_DAMAGE_BONUS = 17, // 岩元素伤害加成
  // 其他属性（可按API返回补充，数量可灵活扩展）
  PHYSICAL_DAMAGE_BONUS = 18, // 物理伤害加成
  HEAL_BONUS = 19, // 治疗加成
  SHIELD_STRENGTH = 20, // 护盾强效
  UNKNOWN = -1 // 保留值（默认值）：兼容米游社API新增未识别的属性类型（纯数值），避免应用崩溃
}

```

1. **枚举使用规则**：1. 所有logic层、UI层涉及API返回固定值（字符串/纯数值）的判断、赋值、展示等操作，必须引用对应枚举（如判断元素类型时用 GameElementEnum.PYRO，判断原神属性时用 PropertyTypeEnum.HP，而非直接写 "pyro" 或 1）；2. 新增API返回固定值（无论字符串还是纯数值）时，需在对应枚举文件中新增枚举值，禁止直接在业务代码中硬编码；无论该固定值是否在原有示例中、数量多少，均需按本规范统一用枚举管理；对于数量较多的纯数值枚举（如原神 property_type），需分类注释，便于后续维护与查找；3. 枚举值需与API返回值严格一致（字符串完全匹配、数值完全相等），若API返回值变更，仅修改对应枚举值，无需改动所有业务代码；4. 禁止在枚举中定义与业务无关的常量，枚举仅用于管理API返回的固定值类型（字符串/纯数值），业务配置类常量仍放在 AppConstant.ts 中；5. 枚举可结合TypeScript类型校验，确保业务代码中使用的类型符合枚举规范，减少类型错误；对于纯数值枚举，可避免因数值混淆（如将HP的1写成DEF的5）导致的业务异常；6. 保留值（默认值）使用规则：当API返回未识别的固定值（即枚举中无对应值）时，统一使用枚举的 UNKNOWN 保留值兜底；业务代码中需对 UNKNOWN 值做兼容处理（如UI展示“未知类型”，不触发异常逻辑），同时记录日志，便于后续适配API新增类型；适配完成后，在枚举中新增对应值，无需修改业务兼容逻辑。

# 11. V2.0 及以后迭代规划（非当前范围）

- 设备适配：逐步新增平板、PC/二合一、TV、全功能智能手表（WATCH 3/4/5系列）适配，仅新增资源目录与UI调整，不改动core层。

- UIGF 功能：实现 UIGF 中间转换层，支持 UIGF v2/v3、SRGF、ZZZF 格式导入/导出，按 update_time 判断数据新旧。

- 额外功能：桌面卡片、通知提醒、数据备份/导出（非 UIGF 格式）。

- **桌面卡片补充说明**：鸿蒙桌面卡片（官方称「服务卡片」），本质是应用核心功能/数据的桌面快捷展示组件，与安卓小部件、iOS小组件功能一致，用户长按应用图标即可添加至桌面，无需打开App就能查看关键信息，点击可直达App对应页面，提升用户体验。本项目V2.0规划支持的桌面卡片，属于鸿蒙动态卡片（Dynamic Widget），支持数据周期性刷新与点击交互，不支持静态卡片（Static Widget），避免频繁刷新导致的功耗过高问题。

- **桌面卡片实现方案（V2.0 执行标准）**：

- 1. 卡片配置：在entry目录下新建Service Widget（Dynamic Widget），生成form_config.json配置文件、EntryFormAbility.ets卡片能力文件、WidgetCard.ets卡片UI文件，配置卡片名称、显示规格、刷新周期（默认30分钟，与App数据刷新冷却规则一致）、主题适配等参数；

- 2. UI开发：基于ArkTS声明式开发卡片UI，仅展示核心数据（如当前选中账号的游戏角色数、实时便笺状态），禁止使用复杂组件、动态共享包，避免卡片渲染异常；

- 3. 交互实现：通过postCardAction接口实现点击跳转，点击卡片可直达App战绩页、便笺页，适配应用前台/后台两种状态的跳转逻辑，在EntryAbility的onCreate、onNewWant生命周期中处理跳转参数；

- 4. 数据同步：复用core层现有数据接口，卡片数据与本地数据库同步，通过message事件触发卡片刷新，确保卡片数据与App内数据一致，不新增独立数据源，不改动core层业务逻辑；

- 5. 资源适配：仅适配手机/折叠屏卡片规格，支持默认尺寸与扩展尺寸，与App主题（浅色/深色/跟随系统）同步，复用现有资源目录，不新增额外资源冗余。

# 12. 补充说明

1. 华为手环10（含所有手环、轻量手表）：无论系统版本（鸿蒙4.0/5.0），均为轻量鸿蒙，不支持独立鸿蒙App，后续仅考虑与手机App联动，不开发独立穿戴版。

2. 后续新增设备适配时，严格遵循鸿蒙官方资源限定词与响应式布局规范，确保代码复用率100%，不做无意义重构。
   > （注：文档部分内容可能由 AI 生成）

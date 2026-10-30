# entry 命名改名映射（2026-10-28）

> 依据 [`naming-conventions.md`](./naming-conventions.md) 执行。代码已改、**待本地编译验证**（本环境无 DevEco 工具链）。
> 校验：静态引用检查（相对 import 可解析、import 符号有导出、routerMap / form_config / module.json5 路径存在、`@Monitor` 字段有声明）0 问题；旧标识符在 `entry/src/main` 与 `entry/src/test` 的代码中（排除字符串与注释）0 残留。
> 不改的名字见规范 §4。`docs/` 与 `entry/Refactor_Spec.md` 中的文件名已按本表替换；分析文档的 `file:line` 行号仍是基线 `105c8d3` 的行号。

## 1. 文件与目录

| 旧 | 新 |
| --- | --- |
| `pages/Xxx.ets`（24 个：AccountDetail、Characters、Genshin/StarRail/ZZZ CharacterDetail、Genshin/StarRail/ZZZ DailyDetail、Genshin/StarRail/ZZZ MaterialList、Genshin/StarRail/ZZZ MaterialTargetConfig、Home、Launch、Login、Main、MaterialCalc、MaterialCharacterSelect、My、NotificationSettings、Tools、WidgetSettings） | `pages/XxxPage.ets`（`Index.ets`、`AppearanceSettingsPage.ets`、`PrivacyConsentPage.ets`、`TestPage.ets`、`WebViewPage.ets` 不变） |
| `builders/MaterialCharacterSelectBuilder.ets` | `builders/MaterialCharacterSelectPageBuilder.ets` |
| `components/material-calc/` | `components/materialcalc/` |
| `components/material-list/` | `components/materiallist/` |
| `components/widgetconfig/` | `components/widgetsettings/` |
| `viewmodel/WidgetConfigViewModel.ets` | `viewmodel/WidgetSettingsViewModel.ets` |
| `constants/ViewStates.ets` | `constants/ViewState.ets` |
| `constants/LoginTabEnum.ets` | `constants/LoginConstants.ets` |
| `constants/SignalMonitorKey.ets` | `constants/SignalStorageKey.ets` |
| `constants/GenshinElement.ets` / `StarRailElement.ets` / `ZZZElement.ets` | `utils/GenshinElementUtil.ets` / `StarRailElementUtil.ets` / `ZZZElementUtil.ets`（内容是资源映射函数，不是常量） |
| `styles/ButtonModifier.ets` | `styles/PrimaryButtonModifier.ets` |
| `utils/CharacterSort.ets` | `utils/CharacterSortUtil.ets` |
| `utils/MaterialRoutes.ets` | `utils/MaterialRouteUtil.ets` |
| `models/SegmentedTabModels.ets`（M0 新建） | `models/SegmentedTabItem.ets` |
| `components/chardetail/starrail/StarRailCharDetailHeroInfo.ets` | `…/StarRailCharDetailHeroProfile.ets` |
| `components/chardetail/zzz/ZZZCharDetailHeroInfo.ets` | `…/ZZZCharDetailHeroProfile.ets` |
| `widget/utils/WidgetMockData.ets` | `widget/utils/WidgetMockPayload.ets` |
| `resources/base/profile/custom_router_map.json` | 19 条 `pageSourceFile` 与 `buildFunction` 同步；`name`（路由名）不变 |

## 2. 类型名

| 旧 | 新 |
| --- | --- |
| 页面 struct `Xxx` / `XxxPreview` / Builder `XxxBuilder` | `XxxPage` / `XxxPagePreview` / `XxxPageBuilder`（`AppearanceSettingsBuilder` → `AppearanceSettingsPageBuilder`；`notification/NotificationModels` 中的模型类 `NotificationSettings` 不受影响） |
| `SignalMonitorKey` | `SignalStorageKey` |
| `WidgetConfigViewModel` / `WidgetConfigStep` | `WidgetSettingsViewModel` / `WidgetSettingsStep` |
| `WIDGET_GAME_ID`（类） | `WidgetGameId` |
| `WidgetGameData` / `WidgetSlotData` | `WidgetGameSnapshot` / `WidgetSlotSnapshot` |
| `RecoveryTimeData` / `RecoveryData` | `RecoveryTime` / `StaminaRecovery` |
| `FormInfo` / `PreviewStaminaData` | `FormSpec` / `PreviewStamina` |
| `CharDetailHeroInfo` / `StarRailCharDetailHeroInfo` / `ZZZCharDetailHeroInfo` | `…HeroProfile` |
| `WidgetMockData` | `WidgetMockPayload` |

## 3. 常量与枚举值

| 旧 | 新 |
| --- | --- |
| `ThemeFonts.font10 … font26`、`fontBold13 … fontBold26`、`fontMedium17` | `ThemeFonts.FONT_10 … FONT_26`、`FONT_BOLD_13 … FONT_BOLD_26`、`FONT_MEDIUM_17`（`Theme` 接口字段 `this.tm.current.fontXX` 是对象属性，保持小驼峰） |
| `WidgetSize.SIZE_1x2 / 2x2 / 2x4 / 4x4` | `SIZE_1X2 / 2X2 / 2X4 / 4X4`（枚举**值** `'1x2'` 等不变，存盘兼容） |
| `Widget2x2/2x4/4x4ViewModel.MAX_GAMES_2x2 / 2x4 / 4x4` | `MAX_GAMES_2X2 / 2X4 / 4X4` |
| `SignalMonitorKey` 的 8 个 `@Monitor` 路径值 | 删除（D1） |
| 17 个 VM 的 `XxxViewModelKeys` 类 / `static KEYS` / `XXX_VM_*` 路径常量 | 删除（与 D1 一致：`@Monitor` 写字面量；这些常量除测试断言外无引用，对应断言用例一并删除） |

## 4. 布尔名（字段 / 参数 / 局部变量）

状态用 `is`，"是否显示"用 `shouldShow`，"是否需要做"用 `should`：

`archonQuestDone→isArchonQuestDone`、`autoSyncIfEmpty→shouldAutoSyncIfEmpty`、`buttonEnabled→isButtonEnabled`、`charIsRefreshing→isCharRefreshing`、`charShowRefresh→shouldShowCharRefresh`、`charShowSwitcher→shouldShowCharSwitcher`、`homeIsRefreshing→isHomeRefreshing`、`homeShowRefresh→shouldShowHomeRefresh`、`collapsed→isCollapsed`、`dailyTaskAllReceived→isDailyTaskAllReceived`、`deleted→isDeleted`、`dismissed→isDismissed`、`enabled→isEnabled`（ArkUI `.enabled()` 属性方法与持久化 key `'enabled'` 不变）、`finished→isFinished`（数字局部变量 `finished` 改为 `finishedCount`）、`forceReload→shouldForceReload`、`fpPromptPending→isFpPromptPending`、`fpPromptShowing→isFpPromptShowing`、`geetestCancelAllRequested→isGeetestCancelAllRequested`、`geetestPending→isGeetestPending`、`geetestShowing→isGeetestShowing`、`inNestedContainer→isInNestedContainer`、`initialized→isInitialized`、`loginSuccess→isLoginSuccess`、`memberCardIsOpen→isMemberCardOpen`、`pageLoaded→isPageLoaded`、`permissionDenied→isPermissionDenied`、`pollInFlight→isPollInFlight`、`privacyScrolledToBottom→isPrivacyScrolledToBottom`、`termsScrolledToBottom→isTermsScrolledToBottom`、`pushUpdate→shouldPushUpdate`、`qrFetching→isQrFetching`、`refreshBusy→isRefreshBusy`、`refreshCoolingDown→isRefreshCoolingDown`、`rogueTournExpIsFull→isRogueTournExpFull`、`rogueTournWeeklyUnlocked→isRogueTournWeeklyUnlocked`、`showAccountSwitcher→shouldShowAccountSwitcher`、`showLevelPicker→shouldShowLevelPicker`、`showLimitDialog→shouldShowLimitDialog`、`showNoStokenDialog→shouldShowStokenMissingDialog`（去否定式）、`showRefresh→shouldShowRefresh`、`showRefreshButton→shouldShowRefreshButton`、`showSwitcher→shouldShowSwitcher`、`showing→isShowing`、`success→isSuccess`、`targetEnabled→isTargetEnabled`、`targetOn→isTargetOn`、`transformerReady→isTransformerReady`、`valid→isValid`、`visible→isVisible`。

`@Monitor('vm.xxx')` 字面量已同步。读取 core 数据对象的同名字段（如 `data.memberCardIsOpen`、`e.properties[j].valid`）保持不变。

## 5. 方法 / 函数名（动词开头）

| 规则 | 旧 → 新 |
| --- | --- |
| 取值 → `get` | `paddingLeft/Right`、`elementBgColor`、`relicPosName`、`resinColor`、`staminaColor`、`energyColor`、`temple/memberCard/cafe/vhs/cardSign` + `Label/Color`、`progressRatio`、`rarityBackgroundColor`、`rarityTextColor`、`themeModeLabel`、`multiGameGradientColors`、`maxLevel`、`fallbackMax`、`defaultThreshold`、`secondsPerUnit`、`staminaName`、`geetestLabel`、`gameAccountLabel`、`tabTitle`、`badgeIcons`、`heroHeight`、`langSuffix`、`privacyPath`、`termsPath`、`themeItems`、`slotColor`、`gameNameResource`、`gameLogo`、`primaryColor`、`gameColorRes`、`gameNameRes`、`staminaLabelRes`、`dailyDetailPage`、`widgetBgDark/Mid/LightRes`、`materialListRoute`、`materialTargetConfigRoute`、`serverDisplayName`、`starRailElementIcon`、`starRailPathIcon`、`zzzElementIcon`、`zzzProfessionIcon`、`SnackbarParams.icon/color`、`StaminaNotificationService.gameName`、`NotificationSettingsViewModel.gameName`、`HomeViewModel.gameColor` → 前缀 `get` 的同名 |
| 映射函数 → `get` | `gameIdToName/Color/Logo → getGameName/Color/Logo`；`gameIdStrToName/Color/Logo → getGameName/Color/LogoByStr`；`gameIdToWidgetName/Color → getWidgetGameName/Color`；`gameIdToBgColors → getWidgetBgColors`；`elementIcon/Color → getGenshinElementIcon/Color`；`genshinPropertyTypeToResource → getGenshinPropertyResource`；`starRailPropertyTypeToResource → getStarRailPropertyResource`；`dimensionToSize → getSizeByDimension`；`sizeToFormName/Dimension/PresetKey → getFormName/getDimension/getPresetKey`；`formNameToPresetKey → getPresetKeyByFormName`；`gameIdToString → getGameIdString`；`keyOf → getDedupKey`；`accountIdOf → getAccountId`；`msg → getErrorMessage`；`staminaColorType → getStaminaColorType`；`relicIdx → getRelicIndex` |
| 解析 → `parse` | `gameIdFromApiUrl → parseGameIdFromApiUrl`、`gameIdFromFormName → parseGameIdFromFormName`、`stringToGameId → parseGameId`、`idToNumber → parseIdNumber`、`zzzRarityToInt → parseZZZRarity`、`starRailRankBonus → parseStarRailRankBonus`、`zzzSkillLevels → parseZZZSkillLevels` |
| 格式化 → `format` | `starsText → formatStars`、`recoveryTimeText → formatRecoveryTime`、`recoveryDesc → formatRecoveryDesc`、`colorIntToHex → formatColorHex` |
| 构造 / 计算 | `defaults → createDefault`、`genshinElementBgGradient → createGenshinElementBgGradient`、`widgetSingle/Two/MultiGameGradient → createSingle/Two/MultiGameGradient`、`widgetGradient → createWidgetGradient`、`genshin/starRail/zzzRowsToSummaries → buildGenshin/StarRail/ZZZSummaries`、`starRailPointTarget → calcStarRailPointTarget`、`starRailBaseLevel → calcStarRailBaseLevel`、`colorWithAlpha → applyAlpha`、`hashNotifId → hashNotificationId` |
| 其他动作 | `accountNameOf → loadAccountName`（异步读库）、`autoSyncCharacters → syncCharactersInBackground` |
| 返回布尔 | `needsCharacterSync → shouldSyncCharacters`、`HomeViewModel.needsDailyNoteSync → shouldSyncDailyNote`（其内部调用的 core `GenshinRepository` / `StarRailRepository` / `ZZZRepository.needsDailyNoteSync` 不变）、`imageExists → hasImage`、`allImagesExist → hasAllImages` |
| 单例访问 | 8 个 entry 类的 `instance()` → `getInstance()`（`NotificationSettingsStore`、`StaminaNotificationService`、`NotificationStateStore`、`GeetestSignal`、`CookieExpiredSignal`、`AccountSignal`、`DeviceFpInvalidSignal`、`SyncRetrySignal`）；core 类的 `instance()` 不变 |
| 保留 | 转换惯用法 `toJson` / `fromJson` / `toResult` / `toVM` / `toExpeditionVMs` / `toSelectOptions` / `toGameId` / `toLocalStorageRecord`；`forceRefresh`（force 为动词）；框架方法与 `@Builder` 函数（规范 §4） |

## 5.1 首次编译修复（2026-10-28）

首次本地编译报 18 处 ArkTS 错误，两个原因，均已修复并做全量排查：
- 方法改名脚本跳过了模板字符串 `${...}` 内的调用（`msg` ×11、`langSuffix` ×2、`keyOf`、`gameIdToName`）——已补改；全量扫描 `${}` 内旧方法名 0 残留。
- `HomeViewModel` 中对 core 三个 Repository 的 `needsDailyNoteSync()` 调用被误改——已改回；全量比对旧方法名与 core 方法名，仅此一处与 `ZZZRecordRequest.accountIdOf`（entry 未调用）重名。

## 5.2 M0 方法命名遗漏修复（2026-10-30）

私有方法 `loadRecoveryData` → `loadStaminaRecovery`（类 `RecoveryData` → `StaminaRecovery` 已改名，但方法名未同步）：
- 文件：`features/notification/src/main/ets/model/service/StaminaNotificationService.ets`
- 改动：方法定义 + 2 处调用点 + 1 处日志自引用字符串（共 4 处）
- 验证：grep `loadRecoveryData` 零残留，grep `loadStaminaRecovery` 命中 4 处 ✅

## 6. 资源

| 旧 | 新 |
| --- | --- |
| `string.json` 中 `character_element_Pyro / Hydro / Anemo / Electro / Dendro / Cryo / Geo`（base / en / zh_HK） | 删除——唯一使用方 `elementLabel` 已在 M0 作为死代码删除，名字也不符合小写 snake_case |

## 7. 测试同步（2026-10-28 用户批准改测试）

| 文件 | 改动 |
| --- | --- |
| 全部测试 | import 路径与符号随上表更新 |
| `HomeViewModel.test` | 不存在的 `components/home/HomeModels` 与 `GAME_*` 常量改为 core `GameId`；未知 gameId 用例改测 `getGameColorByStr`（`GameId` 枚举在类型上传不进未知值）；删除 `KEYS` 断言 |
| `CharactersViewModel.test` | `AccountOption` 改从 `models/AccountOption` 导入；`accountId` 实参改为字符串；私有 `gameTabs` 断言改为公开的 `currentGameId`；删除 `KEYS` 断言 |
| `GenshinCharacterDetailViewModel.test` | `propertyTypeToResource` 改为测 `utils/GenshinPropertyUtil.getGenshinPropertyResource`；`init` 实参改字符串；删除 `KEYS` 断言 |
| `GenshinDailyDetailViewModel.test` | 删除 9 个以字符串索引调用 VM 上已不存在的 `formatSeconds` / `formatTransformer` 的用例（已迁到 `TimeFormatUtil`，需要 `UIContext`，无法在 Local Test 运行）；`init` 实参改字符串 |
| `AccountDetailViewModel` / `MyViewModel` / `LoginViewModel.test` | 删除路径常量断言 |

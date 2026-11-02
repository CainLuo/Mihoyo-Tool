// basic 导出文件：主题、通用组件、通用工具、常量、全局信号
//
// 只导出跨模块（≥2 个 feature）实际使用的符号。仅供 basic 内部使用的实现
// （SnackbarParams / SnackbarContent / UserGameSectionHeader、ColorUtil 的 Alpha / applyAlpha）
// 与各文件的 @Preview 结构体不在此导出——需要时用相对路径直接 import。
// 只服务单一 feature 的组件也不放在这里（SettingRow 已随 M0 移入 features/account/views/）。

// config
export { APP_ENV } from './src/main/ets/config/RuntimeConfig';

// constants
export { AppConstants } from './src/main/ets/constants/AppConstants';
export { AppRoutes } from './src/main/ets/constants/AppRoutes';
export { FeedbackType } from './src/main/ets/constants/FeedbackType';
export { HeroPanelMode } from './src/main/ets/constants/HeroPanelMode';
export { SignalStorageKey } from './src/main/ets/constants/SignalStorageKey';
export { ViewState } from './src/main/ets/constants/ViewState';

// model
export { AccountOption } from './src/main/ets/model/AccountOptionModel';
export { GameDataRowVM, GameNoteSnapshotVM, GameRoleCardVM, MihoyoAccountVM } from './src/main/ets/model/AccountRoleModels';
export { SegmentedTabItem } from './src/main/ets/model/SegmentedTabItemModel';

// shares
export { AccountSwitchDialogParams, AccountSwitchDialog } from './src/main/ets/shares/AccountSwitchDialog';
export { PlaceholderState, PlaceholderView } from './src/main/ets/shares/PlaceholderView';
export { SegmentedTabBar } from './src/main/ets/shares/SegmentedTabBar';
export { SplitPlaceholder, splitPlaceholderBuilder } from './src/main/ets/shares/SplitPlaceholder';
export { UserGameSection } from './src/main/ets/shares/UserGameSection';

// signals
export { AccountSignal } from './src/main/ets/signals/AccountSignal';
export { CookieExpiredSignal } from './src/main/ets/signals/CookieExpiredSignal';
export { SyncRetrySignal } from './src/main/ets/signals/SyncRetrySignal';
export { WidgetSyncHandler, WidgetSyncHook } from './src/main/ets/signals/WidgetSyncHook';

// theme
export { PrimaryButtonModifier } from './src/main/ets/theme/PrimaryButtonModifier';
export { ThemeFonts } from './src/main/ets/theme/ThemeFonts';
export { themeManager, ThemeManager } from './src/main/ets/theme/ThemeManager';

// utils
export { compareCharacter } from './src/main/ets/utils/CharacterSortUtil';
export { TransparentColorCache } from './src/main/ets/utils/ColorUtil';
export { DialogDedup } from './src/main/ets/utils/DialogDedupUtil';
export { showFeedback } from './src/main/ets/utils/FeedbackUtil';
export { getGameName, getGameColor, getGameLogo, getGameNameByStr, getGameColorByStr, getGameLogoByStr, parseGameIdFromApiUrl } from './src/main/ets/utils/GameIdUtil';
export { getGenshinElementIcon, getGenshinElementColor, GenshinElement, genshinElementFromString } from './src/main/ets/utils/GenshinElementUtil';
export { RouterUtil } from './src/main/ets/utils/RouterUtil';
export { getServerDisplayName } from './src/main/ets/utils/ServerNameUtil';
export { getStarRailElementIcon, getStarRailPathIcon, StarRailElement, StarRailPath, starRailElementFromString, starRailPathFromNumber } from './src/main/ets/utils/StarRailElementUtil';
export { TimeFormatUtil } from './src/main/ets/utils/TimeFormatUtil';
export { getZZZElementIcon, getZZZProfessionIcon, ZZZElementType, ZZZProfession, zzzElementTypeFromNumber, zzzProfessionFromNumber } from './src/main/ets/utils/ZZZElementUtil';

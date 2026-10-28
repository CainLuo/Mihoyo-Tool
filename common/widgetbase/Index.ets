// widgetbase 导出文件：服务卡片页面导入链上的纯代码（只能包含卡片支持的 API）

// model
export { StaminaColorType, RecoveryTime, WidgetColors, WidgetExtraRow, ExpeditionAvatar, Widget1x2RoleUIState, Widget1x2UIState, WidgetRoleUIState, Widget2x2UIState, Widget2x4UIState, Widget4x4UIState } from './src/main/ets/model/WidgetUIStateModels';

// theme
export { AppColor, FontSize, Spacing, Duration, Percent, Radius, Shadow, Angle, Opacity, Theme, makeFont } from './src/main/ets/theme/AppTheme';
export { DefaultTheme } from './src/main/ets/theme/DefaultTheme';

// utils
export { ParsedExtraRow, WidgetDataHelper } from './src/main/ets/utils/WidgetDataUtil';
export { WidgetExtraRowConfig } from './src/main/ets/constants/WidgetExtraRowConstants';
export { ExtraRowType } from './src/main/ets/constants/WidgetExtraRowType';
export { WidgetLogger } from './src/main/ets/utils/WidgetLogger';
export { ParsedRole, ParsedGame, ParsedAccount, ParsedPayload, parsePayload } from './src/main/ets/utils/WidgetPayloadUtil';
export { WidgetGameId, getGameName, getGameColor, getStaminaColorByType, formatRecoveryTimeText, parseCurrent, parseMax, parseSeconds, calcIsFull, calcRatio, getGameColorRes, getGameNameRes, getStaminaLabelRes, getDailyDetailPage, formatRecoveryDesc, WIDGET_GRADIENT_ANGLE, GradientPosition, getWidgetBgDarkRes, getWidgetBgMidRes, getWidgetBgLightRes, createSingleGameGradient, createTwoGameGradient, createMultiGameGradient, createWidgetGradient } from './src/main/ets/utils/WidgetUtil';

/**
 * WidgetEntryRoute — 卡片点击打开 App 时携带的路由参数
 *
 * 1×2 卡片点击直达对应游戏的便笺详情页，携带 gameId + accountId + roleUid；
 * 2×2 / 2×4 / 4×4 只带来源标记，落在首页。
 *
 * 卡片页面用 postCardAction 的 params 传字面量 key（ArkTS 不允许对象字面量的
 * 计算属性名），这里的常量供 EntryAbility 读取 want.parameters 时使用。
 */

/** 卡片来源标记：want.parameters / postCardAction.params 的 key */
export const WIDGET_ENTRY_FROM_PARAM: string = 'from';
/** 卡片来源标记的值 */
export const WIDGET_ENTRY_FROM_VALUE: string = 'widget';
/** 直达路由参数 key：游戏 ID（genshin/starrail/zzz） */
export const WIDGET_ENTRY_GAME_PARAM: string = 'gameId';
/** 直达路由参数 key：米游社账号 ID */
export const WIDGET_ENTRY_ACCOUNT_PARAM: string = 'accountId';
/** 直达路由参数 key：游戏角色 UID */
export const WIDGET_ENTRY_ROLE_PARAM: string = 'roleUid';
/** EntryAbility → MainPage 的 AppStorage key（冷启动） */
export const WIDGET_ENTRY_ROUTE_STORAGE: string = 'widgetEntryRoute';
/** EntryAbility → MainPage 的 EventHub 事件名（热启动 onNewWant） */
export const WIDGET_ENTRY_ROUTE_EVENT: string = 'widgetEntryRoute';

/** 卡片点击直达详情页的路由参数 */
export class WidgetEntryRoute {
  gameId: string = '';
  accountId: string = '';
  roleUid: string = '';
}

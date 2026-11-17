/**
 * MainDialogLabels — MainPage 弹窗标题的账号标签
 *
 * 多账号排队时提示是哪个游戏账号（游戏名 · UID）；取不到游戏 UID 时显示 fallback。
 */
import { GameId } from 'core';
import { getGameName } from 'basic';

/** "游戏名 · UID xxx"；roleId 为空时返回 fallback */
export function getGameAccountLabel(uiCtx: UIContext | null, gameId: GameId, roleId: string,
                                    fallback: string): string {
  if (roleId.length === 0) {
    return fallback;
  }
  const context = uiCtx?.getHostContext();
  if (context === undefined) {
    return roleId;
  }
  try {
    const rm = context.resourceManager;
    const uidText = rm.getStringSync($r('app.string.common_uid_format').id, roleId);
    const gameName = rm.getStringSync(getGameName(gameId).id);
    if (gameName.length === 0) {
      return uidText;
    }
    const dot = rm.getStringSync($r('app.string.common_dot_separator').id);
    return `${gameName} ${dot} ${uidText}`;
  } catch (_e) {
    return roleId;
  }
}

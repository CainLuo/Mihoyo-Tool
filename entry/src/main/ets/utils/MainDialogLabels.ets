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
  let gameName = '';
  try {
    gameName = uiCtx?.getHostContext()?.resourceManager.getStringSync(getGameName(gameId).id) ?? '';
  } catch (_) {
  }
  return gameName.length > 0 ? `${gameName} · UID ${roleId}` : `UID ${roleId}`;
}

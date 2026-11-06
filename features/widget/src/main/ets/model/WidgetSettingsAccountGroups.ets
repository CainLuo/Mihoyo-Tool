/**
 * WidgetSettingsAccountGroups — Widget 配置页的账号分组构建
 *
 * 把 WidgetDataStore 转换为首页可复用的 MihoyoAccountVM 列表：
 * 账号内角色按「原神 → 星铁 → 绝区零」排序。
 */
import { GameId } from 'core';
import { GameRoleCardVM, getGameLogoByStr, MihoyoAccountVM } from 'basic';
import { WidgetDataStore } from './WidgetDataStoreModels';

/** 角色排序权重，未知游戏排最后 */
const GAME_ORDER: Record<string, number> = {
  'genshin': 0,
  'starrail': 1,
  'zzz': 2,
  'honkai3': 3,
};

/** 按账号分组构建 MihoyoAccountVM[]（供 2x2 及以上尺寸使用） */
export function buildAccountGroups(dataStore: WidgetDataStore): MihoyoAccountVM[] {
  const groups: MihoyoAccountVM[] = [];
  const accountIds = Object.keys(dataStore.data);

  for (let i = 0; i < accountIds.length; i++) {
    const accountId = accountIds[i];
    const account = dataStore.data[accountId];
    const roleIds = Object.keys(account.slots);

    const roles: GameRoleCardVM[] = [];
    for (let j = 0; j < roleIds.length; j++) {
      const roleId = roleIds[j];
      const slot = account.slots[roleId];
      // 只填充 Widget 配置需要的字段
      roles.push(new GameRoleCardVM(
        slot.gameId as GameId,
        '',
        $r('app.color.color_primary'),
        roleId,
        slot.nickname,
        slot.serverName,
        null,  // snapshot 不需要
        '',    // lastSyncDesc 不需要
        getGameLogoByStr(slot.gameId)
      ));
    }

    roles.sort((a: GameRoleCardVM, b: GameRoleCardVM): number => {
      return (GAME_ORDER[a.gameId] ?? 99) - (GAME_ORDER[b.gameId] ?? 99);
    });

    groups.push(new MihoyoAccountVM(
      accountId,
      accountId,
      roles,
      account.accountName,
      account.avatarUrl
    ));
  }

  return groups;
}

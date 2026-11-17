import { describe, it, expect } from '@ohos/hypium';
import { HomeSyncCoordinator } from '../main/ets/viewmodel/HomeSyncCoordinator';
import { AccountRow, GameId, GameRoleRow } from 'core';

function makeAccount(): AccountRow {
  const account = new AccountRow();
  account.uid = '100000001';
  account.username = 'tester';
  account.nickname = '测试账号';
  account.cookie = 'cookie';
  return account;
}

function makeRole(gameId: GameId): GameRoleRow {
  const role = new GameRoleRow();
  role.gameId = gameId;
  role.roleId = '800000001';
  role.server = 'cn_gf01';
  return role;
}

/**
 * 只覆盖不会触发网络 / DB 的分支。
 * 真实同步、Cookie 失效、验证码分支依赖 Repository 与全局 Signal，留给设备端测试。
 */
export default function homeSyncCoordinatorTest() {
  describe('HomeSyncCoordinator', () => {

    it('不支持的游戏 syncDailyNote 直接返回空错误信息', 0, async (done: Function) => {
      const result = await HomeSyncCoordinator.syncDailyNote(makeAccount(), makeRole(GameId.HONKAI3), false);
      expect(result).assertEqual('');
      done();
    });

    it('不支持的游戏自动同步也返回空错误信息', 0, async (done: Function) => {
      const result = await HomeSyncCoordinator.syncDailyNote(makeAccount(), makeRole(GameId.HONKAI3), true);
      expect(result).assertEqual('');
      done();
    });

  });
}

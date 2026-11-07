import { describe, it, expect } from '@ohos/hypium';
import { CharactersDataLoader } from '../main/ets/viewmodel/CharactersDataLoader';
import { AccountRow, GameId } from 'core';

function makeAccount(uid: string, username: string, nickname: string): AccountRow {
  const account = new AccountRow();
  account.uid = uid;
  account.username = username;
  account.nickname = nickname;
  account.avatarUrl = 'https://example.com/avatar.png';
  return account;
}

export default function charactersDataLoaderTest() {
  describe('CharactersDataLoader', () => {

    it('不支持的游戏 loadCharacters 返回空数组', 0, async (done: Function) => {
      const result = await CharactersDataLoader.loadCharacters('', GameId.HONKAI3, '');
      expect(result.length).assertEqual(0);
      done();
    });

    it('不支持的游戏 shouldSyncCharacters 返回 true', 0, async (done: Function) => {
      const result = await CharactersDataLoader.shouldSyncCharacters('', '', GameId.HONKAI3);
      expect(result).assertTrue();
      done();
    });

    it('buildAccountOptions 空数组返回空数组', 0, () => {
      expect(CharactersDataLoader.buildAccountOptions([]).length).assertEqual(0);
    });

    it('buildAccountOptions 映射账号字段', 0, () => {
      const result = CharactersDataLoader.buildAccountOptions([
        makeAccount('uid1', 'user1', '旅行者'),
        makeAccount('uid2', 'user2', ''),
      ]);
      expect(result.length).assertEqual(2);
      expect(result[0].accountId).assertEqual('uid1');
      expect(result[0].username).assertEqual('user1');
      expect(result[0].nickname).assertEqual('旅行者');
      expect(result[0].avatarUrl).assertEqual('https://example.com/avatar.png');
      expect(result[0].uid).assertEqual('uid1');
    });

    it('toSelectOptions 使用 username 作为 value', 0, () => {
      const options = CharactersDataLoader.buildAccountOptions([
        makeAccount('uid1', 'user1', '旅行者'),
      ]);
      const result = CharactersDataLoader.toSelectOptions(options);
      expect(result.length).assertEqual(1);
      expect(result[0].value).assertEqual('user1');
    });

    it('getGameNameResource 对四个游戏都返回非空 Resource', 0, () => {
      expect(CharactersDataLoader.getGameNameResource(GameId.GENSHIN) !== null).assertTrue();
      expect(CharactersDataLoader.getGameNameResource(GameId.STARRAIL) !== null).assertTrue();
      expect(CharactersDataLoader.getGameNameResource(GameId.ZZZ) !== null).assertTrue();
      expect(CharactersDataLoader.getGameNameResource(GameId.HONKAI3) !== null).assertTrue();
    });

  });
}

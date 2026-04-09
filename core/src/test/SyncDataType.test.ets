/**
 * SyncDataType.test.ets
 *
 * 验证 SyncDataType 枚举值与数据库表名一致。
 * 防止重构时意外改变字符串值导致 sync_meta 查询失效。
 */

import { describe, it, expect } from '@ohos/hypium';
import { SyncDataType } from '../main/ets/constants/SyncDataType';

export default function syncDataTypeTest() {
  describe('SyncDataType', () => {

    it('ACCOUNT_matchesTableName', 0, () => {
      expect(SyncDataType.ACCOUNT).assertEqual('account_table');
    });

    it('GAME_ROLE_matchesTableName', 0, () => {
      expect(SyncDataType.GAME_ROLE).assertEqual('game_role_table');
    });

    it('GENSHIN_CHARACTER_LIST_matchesTableName', 0, () => {
      expect(SyncDataType.GENSHIN_CHARACTER_LIST).assertEqual('genshin_character_list');
    });

    it('GENSHIN_DAILY_NOTE_matchesTableName', 0, () => {
      expect(SyncDataType.GENSHIN_DAILY_NOTE).assertEqual('genshin_daily_note');
    });

    it('GENSHIN_CHARACTER_DETAIL_matchesTableName', 0, () => {
      expect(SyncDataType.GENSHIN_CHARACTER_DETAIL).assertEqual('genshin_character_detail');
    });

    it('GENSHIN_CHARACTER_COMPUTE_matchesTableName', 0, () => {
      expect(SyncDataType.GENSHIN_CHARACTER_COMPUTE).assertEqual('genshin_character_compute');
    });

    it('STARRAIL_AVATAR_BASIC_matchesTableName', 0, () => {
      expect(SyncDataType.STARRAIL_AVATAR_BASIC).assertEqual('starrail_avatar_basic');
    });

    it('STARRAIL_DAILY_NOTE_matchesTableName', 0, () => {
      expect(SyncDataType.STARRAIL_DAILY_NOTE).assertEqual('starrail_daily_note');
    });

    it('STARRAIL_AVATAR_INFO_matchesTableName', 0, () => {
      expect(SyncDataType.STARRAIL_AVATAR_INFO).assertEqual('starrail_avatar_info');
    });

    it('STARRAIL_AVATAR_COMPUTE_matchesTableName', 0, () => {
      expect(SyncDataType.STARRAIL_AVATAR_COMPUTE).assertEqual('starrail_avatar_compute');
    });

    it('ZZZ_AVATAR_BASIC_matchesTableName', 0, () => {
      expect(SyncDataType.ZZZ_AVATAR_BASIC).assertEqual('zzz_avatar_basic');
    });

    it('ZZZ_DAILY_NOTE_matchesTableName', 0, () => {
      expect(SyncDataType.ZZZ_DAILY_NOTE).assertEqual('zzz_daily_note');
    });

    it('ZZZ_AVATAR_INFO_matchesTableName', 0, () => {
      expect(SyncDataType.ZZZ_AVATAR_INFO).assertEqual('zzz_avatar_info');
    });

    it('ZZZ_AVATAR_COMPUTE_matchesTableName', 0, () => {
      expect(SyncDataType.ZZZ_AVATAR_COMPUTE).assertEqual('zzz_avatar_compute');
    });

    it('SYNC_META_matchesTableName', 0, () => {
      expect(SyncDataType.SYNC_META).assertEqual('sync_meta');
    });
  });
}

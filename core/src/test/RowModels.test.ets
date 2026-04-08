/**
 * RowModels.test.ets
 *
 * 验证 Row 模型的默认值正确，防止字段初始化错误导致 DB 写入异常。
 */

import { describe, it, expect } from '@ohos/hypium';
import { AccountRow } from '../main/ets/models/AccountRow';
import { GameRoleRow } from '../main/ets/models/GameRoleRow';
import {
  GenshinCharacterListRow,
  GenshinDailyNoteRow,
  GenshinCharacterDetailRow,
  GenshinCharacterComputeRow
} from '../main/ets/models/GenshinRows';
import {
  StarRailAvatarBasicRow,
  StarRailDailyNoteRow,
  StarRailAvatarInfoRow,
  StarRailAvatarComputeRow
} from '../main/ets/models/StarRailRows';
import {
  ZZZAvatarBasicRow,
  ZZZDailyNoteRow,
  ZZZAvatarInfoRow,
  ZZZAvatarComputeRow
} from '../main/ets/models/ZZZRows';
import { SyncMetaRow } from '../main/ets/models/SyncMetaRow';

export default function rowModelsTest() {
  describe('AccountRowV2', () => {
    it('defaultValues_areCorrect', 0, () => {
      const row = new AccountRow();
      expect(row.id).assertEqual(0);
      expect(row.username).assertEqual('');
      expect(row.cookie).assertEqual('');
      expect(row.stoken).assertEqual('');
      expect(row.isActive).assertEqual(0);
      expect(row.uid).assertEqual('');
      expect(row.nickname).assertEqual('');
      expect(row.avatarUrl).assertEqual('');
    });
  });

  describe('GameRoleRowV2', () => {
    it('defaultValues_areCorrect', 0, () => {
      const row = new GameRoleRow();
      expect(row.id).assertEqual(0);
      expect(row.accountId).assertEqual(0);
      expect(row.gameId).assertEqual('');
      expect(row.roleId).assertEqual('');
      expect(row.level).assertEqual(0);
      expect(row.isChosen).assertEqual(0);
      expect(row.isPublic).assertEqual(0);
    });
  });

  describe('GenshinCharacterListRow', () => {
    it('defaultValues_areCorrect', 0, () => {
      const row = new GenshinCharacterListRow();
      expect(row.id).assertEqual(0);
      expect(row.accountId).assertEqual(0);
      expect(row.roleUid).assertEqual('');
      expect(row.avatarId).assertEqual('');
      expect(row.rarity).assertEqual(0);
      expect(row.level).assertEqual(0);
      expect(row.fetter).assertEqual(0);
      expect(row.activedConstellationNum).assertEqual(0);
      expect(row.weaponIconUrl).assertEqual('');
      expect(row.image).assertEqual('');
      expect(row.isChosen).assertEqual(0);
    });
  });

  describe('GenshinDailyNoteRow', () => {
    it('defaultValues_areCorrect', 0, () => {
      const row = new GenshinDailyNoteRow();
      expect(row.currentResin).assertEqual(0);
      expect(row.maxResin).assertEqual(0);
      expect(row.resinRecoveryTime).assertEqual(0);
      expect(row.finishedTaskNum).assertEqual(0);
      expect(row.rawJson).assertEqual('');
    });
  });

  describe('GenshinCharacterDetailRow', () => {
    it('defaultValues_areCorrect', 0, () => {
      const row = new GenshinCharacterDetailRow();
      expect(row.avatarId).assertEqual('');
      expect(row.weaponId).assertEqual('');
      expect(row.relicIds).assertEqual('');
      expect(row.skillLevels).assertEqual('');
      expect(row.rawJson).assertEqual('');
    });
  });

  describe('GenshinCharacterComputeRow', () => {
    it('defaultValues_areCorrect', 0, () => {
      const row = new GenshinCharacterComputeRow();
      expect(row.avatarId).assertEqual('');
      expect(row.avatarConsumeJson).assertEqual('');
      expect(row.skillConsumeJson).assertEqual('');
      expect(row.weaponConsumeJson).assertEqual('');
    });
  });

  describe('StarRailAvatarBasicRow', () => {
    it('defaultValues_areCorrect', 0, () => {
      const row = new StarRailAvatarBasicRow();
      expect(row.avatarId).assertEqual('');
      expect(row.rarity).assertEqual(0);
      expect(row.level).assertEqual(0);
      expect(row.rank).assertEqual(0);
      expect(row.baseType).assertEqual(0);
      expect(row.elementId).assertEqual(0);
      expect(row.equipIconUrl).assertEqual('');
      expect(row.isChosen).assertEqual(0);
    });
  });

  describe('StarRailDailyNoteRow', () => {
    it('defaultValues_areCorrect', 0, () => {
      const row = new StarRailDailyNoteRow();
      expect(row.currentStamina).assertEqual(0);
      expect(row.maxStamina).assertEqual(0);
      expect(row.gridFightWeeklyCur).assertEqual(0);
      expect(row.gridFightWeeklyMax).assertEqual(0);
    });
  });

  describe('StarRailAvatarInfoRow', () => {
    it('defaultValues_areCorrect', 0, () => {
      const row = new StarRailAvatarInfoRow();
      expect(row.avatarId).assertEqual('');
      expect(row.equipId).assertEqual('');
      expect(row.relicIds).assertEqual('');
      expect(row.skillTreeJson).assertEqual('');
    });
  });

  describe('StarRailAvatarComputeRow', () => {
    it('defaultValues_areCorrect', 0, () => {
      const row = new StarRailAvatarComputeRow();
      expect(row.avatarConsumeJson).assertEqual('');
      expect(row.skillConsumeJson).assertEqual('');
      expect(row.equipmentConsumeJson).assertEqual('');
    });
  });

  describe('ZZZAvatarBasicRow', () => {
    it('defaultValues_areCorrect', 0, () => {
      const row = new ZZZAvatarBasicRow();
      expect(row.avatarId).assertEqual('');
      expect(row.rarity).assertEqual('');
      expect(row.level).assertEqual(0);
      expect(row.rank).assertEqual(0);
      expect(row.elementType).assertEqual(0);
      expect(row.avatarProfession).assertEqual(0);
      expect(row.awakenState).assertEqual(0);
      expect(row.isChosen).assertEqual(0);
    });
  });

  describe('ZZZDailyNoteRow', () => {
    it('defaultValues_areCorrect', 0, () => {
      const row = new ZZZDailyNoteRow();
      expect(row.energyCurrent).assertEqual(0);
      expect(row.energyMax).assertEqual(0);
      expect(row.vhsSaleState).assertEqual('');
      expect(row.cardSign).assertEqual('');
    });
  });

  describe('ZZZAvatarInfoRow', () => {
    it('defaultValues_areCorrect', 0, () => {
      const row = new ZZZAvatarInfoRow();
      expect(row.avatarId).assertEqual('');
      expect(row.weaponId).assertEqual('');
      expect(row.equipIds).assertEqual('');
      expect(row.skillLevelsJson).assertEqual('');
    });
  });

  describe('ZZZAvatarComputeRow', () => {
    it('defaultValues_areCorrect', 0, () => {
      const row = new ZZZAvatarComputeRow();
      expect(row.avatarConsumeJson).assertEqual('');
      expect(row.weaponConsumeJson).assertEqual('');
      expect(row.skillConsumeJson).assertEqual('');
    });
  });

  describe('SyncMetaRow', () => {
    it('defaultValues_areCorrect', 0, () => {
      const row = new SyncMetaRow();
      expect(row.id).assertEqual(0);
      expect(row.accountId).assertEqual(0);
      expect(row.roleUid).assertEqual('');
      expect(row.dataType).assertEqual('');
      expect(row.lastSyncTime).assertEqual(0);
      expect(row.syncStatus).assertEqual('');
      expect(row.errorMsg).assertEqual('');
    });
  });
}

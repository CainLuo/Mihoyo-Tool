/**
 * CharactersDataLoader.ets
 *
 * 角色 Tab 的数据读取与映射：账号选项、按游戏读取角色摘要、同步判定、Tab 名称。
 * 从 `CharactersViewModel` 拆出，保持原有排序与字段映射。
 */

import {
  CoreInitializer,
  AccountRow,
  GameDataSummary,
  GameId,
  GenshinCharacterListRow,
  StarRailAvatarBasicRow,
  ZZZAvatarBasicRow,
} from 'core';
import { AccountOption, compareCharacter } from 'basic';

export class CharactersDataLoader {
  /** 从 Repository 读取角色数据并转换为 GameDataSummary */
  static async loadCharacters(accountId: string, gameId: GameId, roleUid: string): Promise<GameDataSummary[]> {
    let result: GameDataSummary[] = [];
    if (gameId === GameId.GENSHIN) {
      const rows = await CoreInitializer.genshinRepository.getAvatarList(accountId, roleUid);
      result = CharactersDataLoader.buildGenshinSummaries(rows, roleUid);
    } else if (gameId === GameId.STARRAIL) {
      const rows = await CoreInitializer.starRailRepository.getAvatarList(accountId, roleUid);
      result = CharactersDataLoader.buildStarRailSummaries(rows, roleUid);
    } else if (gameId === GameId.ZZZ) {
      const rows = await CoreInitializer.zzzRepository.getAvatarList(accountId, roleUid);
      result = CharactersDataLoader.buildZZZSummaries(rows, roleUid);
    }
    // 星级从高到低，同星级按角色 ID 从大到小
    result.sort((a: GameDataSummary, b: GameDataSummary) => compareCharacter(a.rarity, a.entityId, b.rarity, b.entityId));
    return result;
  }

  /** 将 GenshinCharacterListRow[] 转换为 GameDataSummary[] */
  private static buildGenshinSummaries(rows: GenshinCharacterListRow[], roleUid: string): GameDataSummary[] {
    const result: GameDataSummary[] = [];
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i];
      const s = new GameDataSummary();
      s.gameId = GameId.GENSHIN;
      s.roleUid = roleUid;
      s.entityId = r.avatarId;
      s.name = r.name;
      s.rarity = r.rarity;
      s.level = r.level;
      s.extraInt1 = r.activedConstellationNum;
      s.extraInt2 = r.fetter;
      s.extraText1 = r.element;
      s.extraText2 = `${r.weaponType}`;
      s.iconUrl = r.icon;
      s.squareIconUrl = r.sideIcon;
      s.weaponName = r.weaponName;
      s.weaponLevel = r.weaponLevel;
      s.weaponAffix = r.weaponAffixLevel;
      s.weaponRarity = r.weaponRarity;
      s.weaponIconUrl = r.weaponIconUrl;
      s.hasWeaponSlot = true;
      s.updateTime = r.updateTime;
      result[result.length] = s;
    }
    return result;
  }

  /** 将 StarRailAvatarBasicRow[] 转换为 GameDataSummary[] */
  private static buildStarRailSummaries(rows: StarRailAvatarBasicRow[], roleUid: string): GameDataSummary[] {
    const result: GameDataSummary[] = [];
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i];
      const s = new GameDataSummary();
      s.gameId = GameId.STARRAIL;
      s.roleUid = roleUid;
      s.entityId = r.avatarId;
      s.name = r.name;
      s.rarity = r.rarity;
      s.level = r.level;
      s.extraInt1 = r.rank;
      s.extraInt2 = 0;
      s.extraText1 = r.element;
      s.extraText2 = `${r.baseType}`;
      s.iconUrl = r.icon;
      s.squareIconUrl = r.figurePath;
      s.weaponName = r.equipName;
      s.weaponLevel = r.equipLevel;
      s.weaponAffix = r.equipRank;
      s.weaponRarity = r.equipRarity;
      s.weaponIconUrl = r.equipIconUrl;
      s.hasWeaponSlot = true;
      s.updateTime = r.updateTime;
      result[result.length] = s;
    }
    return result;
  }

  /** 将 ZZZAvatarBasicRow[] 转换为 GameDataSummary[] */
  private static buildZZZSummaries(rows: ZZZAvatarBasicRow[], roleUid: string): GameDataSummary[] {
    const result: GameDataSummary[] = [];
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i];
      const s = new GameDataSummary();
      s.gameId = GameId.ZZZ;
      s.roleUid = roleUid;
      s.entityId = r.avatarId;
      s.name = r.nameMi18n;
      s.fullName = r.fullNameMi18n;
      s.rarity = r.rarity === 'S' ? 5 : 4;
      s.level = r.level;
      s.extraInt1 = r.rank;
      s.extraInt2 = 0;
      s.extraText1 = `${r.elementType}`;
      s.extraText2 = `${r.avatarProfession}`;
      s.iconUrl = r.hollowIconPath;
      s.squareIconUrl = r.roleSquareUrl;
      s.groupIconUrl = r.groupIconPath;
      s.updateTime = r.updateTime;
      result[result.length] = s;
    }
    return result;
  }

  /** 检查指定游戏角色是否需要同步角色数据 */
  static async shouldSyncCharacters(accountId: string, roleUid: string, gameId: GameId): Promise<boolean> {
    if (gameId === GameId.GENSHIN) {
      return CoreInitializer.genshinRepository.needsAvatarListSync(accountId, roleUid);
    }
    if (gameId === GameId.STARRAIL) {
      return CoreInitializer.starRailRepository.needsAvatarListSync(accountId, roleUid);
    }
    if (gameId === GameId.ZZZ) {
      return CoreInitializer.zzzRepository.needsAvatarListSync(accountId, roleUid);
    }
    return true;
  }

  static buildAccountOptions(accounts: AccountRow[]): AccountOption[] {
    const opts: AccountOption[] = [];
    for (let i = 0; i < accounts.length; i++) {
      const a = accounts[i];
      opts[opts.length] = new AccountOption(a.uid, a.username, a.nickname, a.avatarUrl, a.uid);
    }
    return opts;
  }

  static toSelectOptions(opts: AccountOption[]): SelectOption[] {
    const result: SelectOption[] = [];
    for (let i = 0; i < opts.length; i++) {
      const so: SelectOption = { value: opts[i].username };
      result[result.length] = so;
    }
    return result;
  }

  static getGameNameResource(gameId: GameId): Resource {
    if (gameId === GameId.GENSHIN) {
      return $r('app.string.game_name_genshin');
    }
    if (gameId === GameId.STARRAIL) {
      return $r('app.string.game_name_starrail');
    }
    if (gameId === GameId.ZZZ) {
      return $r('app.string.game_name_zzz');
    }
    if (gameId === GameId.HONKAI3) {
      return $r('app.string.game_name_honkai3');
    }
    return $r('app.string.game_name_genshin');
  }
}

import { AccountRow } from '../MihoyoKit/model/AccountRow';
import { GameRoleRow } from '../MihoyoKit/model/GameRoleRow';
import { ZZZAvatarBasicRow } from '../ZZZKit/model/ZZZRows';

/** 同步队列需要的账号 / 角色读取能力 */
export interface SyncAccountStore {
  getAccountByUid(uid: string): Promise<AccountRow | null>;
  getGameRoles(accountId: string): Promise<GameRoleRow[]>;
}

/** 原神同步能力 */
export interface GenshinSyncPort {
  syncAvatarList(accountId: string, roleUid: string, server: string, cookie: string): Promise<void>;
  syncAvatarDetail(accountId: string, roleUid: string, server: string, cookie: string): Promise<void>;
  syncDailyNote(accountId: string, roleUid: string, server: string, cookie: string, geetestChallenge?: string): Promise<void>;
}

/** 星铁同步能力 */
export interface StarRailSyncPort {
  syncAvatarList(accountId: string, roleUid: string, server: string, cookie: string): Promise<void>;
  syncAvatarInfo(accountId: string, roleUid: string, server: string, cookie: string): Promise<void>;
  syncDailyNote(accountId: string, roleUid: string, server: string, cookie: string, geetestChallenge?: string): Promise<void>;
}

/** 绝区零同步能力 */
export interface ZZYSyncPort {
  syncAvatarList(accountId: string, roleUid: string, server: string, cookie: string): Promise<void>;
  getAvatarList(accountId: string, roleUid: string): Promise<ZZZAvatarBasicRow[]>;
  syncAvatarInfo(accountId: string, roleUid: string, server: string, cookie: string, avatarId?: string): Promise<void>;
  syncBuddyList(accountId: string, roleUid: string, server: string, cookie: string): Promise<void>;
  syncDailyNote(accountId: string, roleUid: string, server: string, cookie: string, geetestChallenge?: string): Promise<void>;
}

/**
 * SyncQueueRunner 的依赖容器。
 * 用接口隔离具体 Repository，避免 sync 反向 import CoreInitializer / Kit Repository。
 */
export class SyncDependencies {
  accountStore: SyncAccountStore;
  genshin: GenshinSyncPort;
  starRail: StarRailSyncPort;
  zzz: ZZYSyncPort;

  constructor(
    accountStore: SyncAccountStore,
    genshin: GenshinSyncPort,
    starRail: StarRailSyncPort,
    zzz: ZZYSyncPort,
  ) {
    this.accountStore = accountStore;
    this.genshin = genshin;
    this.starRail = starRail;
    this.zzz = zzz;
  }
}

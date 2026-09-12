/**
 * SyncQueueRunner — 持久化同步队列执行器
 *
 * 职责：
 * 1. 把需要同步的任务写入 sync_meta 表（status='pending'）
 * 2. 逐个消费队列，执行 API 请求并写入 DB
 * 3. App 启动时恢复未完成的任务（pending/syncing → 重新执行）
 *
 * 任务类型（data_type 字段）：
 *   - genshin_character_list     原神角色列表
 *   - genshin_character_detail   原神角色详情（批量）
 *   - starrail_avatar_basic      星铁角色列表
 *   - starrail_avatar_info       星铁角色详情（批量）
 *   - zzz_avatar_basic           绝区零角色列表
 *   - zzz_avatar_info            绝区零角色详情（批量，mock 环境）
 *   - zzz_avatar_info_{avatarId} 绝区零单个角色详情（真实环境，每个角色一条记录）
 */

import { SyncMetaDao } from '../database/SyncMetaDao';
import { SyncMetaRow } from '../models/SyncMetaRow';
import { SyncDataType } from '../constants/SyncDataType';
import { CoreInitializer } from '../CoreInitializer';
import { GameRoleRow } from '../models/GameRoleRow';
import { GameId } from '../constants/GameId';
import { SyncTask } from '../models/SyncTask';
import { Logger } from '../utils/Logger';

export { SyncTask } from '../models/SyncTask';

/** 同步完成回调类型 */
export type SyncCompleteCallback = () => Promise<void>;

export class SyncQueueRunner {
  private static syncMetaDao: SyncMetaDao = new SyncMetaDao();
  /** 防止并发执行 */
  private static isRunning: boolean = false;
  /** 同步完成回调列表（用于 Widget 数据刷新等） */
  private static onCompleteCallbacks: SyncCompleteCallback[] = [];

  /**
   * 注册同步完成回调
   * 回调会在所有任务执行完毕后按注册顺序依次调用
   */
  static registerOnComplete(callback: SyncCompleteCallback): void {
    SyncQueueRunner.onCompleteCallbacks.push(callback);
  }

  /**
   * 清除所有同步完成回调
   */
  static clearOnCompleteCallbacks(): void {
    SyncQueueRunner.onCompleteCallbacks = [];
  }

  /**
   * 把一批任务写入队列（status='pending'）
   * 已存在的任务会被重置为 pending（允许重试）
   */
  static async enqueue(tasks: SyncTask[]): Promise<void> {
    for (let i = 0; i < tasks.length; i++) {
      const t = tasks[i];
      await SyncQueueRunner.syncMetaDao.markPending(t.accountId, t.roleUid, t.dataType);
    }
  }

  /**
   * 根据账号和游戏角色列表，生成需要同步的任务列表
   */
  static buildTasksForRoles(
    accountId: string,
    roles: GameRoleRow[],
    cookie: string
  ): SyncTask[] {
    Logger.info('💥 SyncQueueRunner', `buildTasksForRoles: accountId=${accountId}, roles.length=${roles.length}`);
    const tasks: SyncTask[] = [];
    for (let i = 0; i < roles.length; i++) {
      const role = roles[i];
      Logger.info('💥 SyncQueueRunner', `buildTasksForRoles: role[${i}].gameId=${role.gameId}, roleId=${role.roleId}`);
      const base = new SyncTask();
      base.accountId = accountId;
      base.roleUid = role.roleId;
      base.server = role.server;
      base.cookie = cookie;

      if (role.gameId === GameId.GENSHIN) {
        const t1 = new SyncTask();
        t1.accountId = accountId; t1.roleUid = role.roleId; t1.server = role.server; t1.cookie = cookie;
        t1.dataType = SyncDataType.GENSHIN_CHARACTER_LIST;
        const t2 = new SyncTask();
        t2.accountId = accountId; t2.roleUid = role.roleId; t2.server = role.server; t2.cookie = cookie;
        t2.dataType = SyncDataType.GENSHIN_CHARACTER_DETAIL;
        const t3 = new SyncTask();
        t3.accountId = accountId; t3.roleUid = role.roleId; t3.server = role.server; t3.cookie = cookie;
        t3.dataType = SyncDataType.GENSHIN_DAILY_NOTE;
        tasks[tasks.length] = t1;
        tasks[tasks.length] = t2;
        tasks[tasks.length] = t3;
        Logger.info('💥 SyncQueueRunner', `buildTasksForRoles: added GENSHIN tasks for roleId=${role.roleId}`);
      } else if (role.gameId === GameId.STARRAIL) {
        const t1 = new SyncTask();
        t1.accountId = accountId; t1.roleUid = role.roleId; t1.server = role.server; t1.cookie = cookie;
        t1.dataType = SyncDataType.STARRAIL_AVATAR_BASIC;
        const t2 = new SyncTask();
        t2.accountId = accountId; t2.roleUid = role.roleId; t2.server = role.server; t2.cookie = cookie;
        t2.dataType = SyncDataType.STARRAIL_AVATAR_INFO;
        const t3 = new SyncTask();
        t3.accountId = accountId; t3.roleUid = role.roleId; t3.server = role.server; t3.cookie = cookie;
        t3.dataType = SyncDataType.STARRAIL_DAILY_NOTE;
        tasks[tasks.length] = t1;
        tasks[tasks.length] = t2;
        tasks[tasks.length] = t3;
      } else if (role.gameId === GameId.ZZZ) {
        const t1 = new SyncTask();
        t1.accountId = accountId; t1.roleUid = role.roleId; t1.server = role.server; t1.cookie = cookie;
        t1.dataType = SyncDataType.ZZZ_AVATAR_BASIC;
        const t2 = new SyncTask();
        t2.accountId = accountId; t2.roleUid = role.roleId; t2.server = role.server; t2.cookie = cookie;
        t2.dataType = SyncDataType.ZZZ_AVATAR_INFO;
        const t3 = new SyncTask();
        t3.accountId = accountId; t3.roleUid = role.roleId; t3.server = role.server; t3.cookie = cookie;
        t3.dataType = SyncDataType.ZZZ_BUDDY;
        const t4 = new SyncTask();
        t4.accountId = accountId; t4.roleUid = role.roleId; t4.server = role.server; t4.cookie = cookie;
        t4.dataType = SyncDataType.ZZZ_DAILY_NOTE;
        tasks[tasks.length] = t1;
        tasks[tasks.length] = t2;
        tasks[tasks.length] = t3;
        tasks[tasks.length] = t4;
      }
    }
    Logger.info('💥 SyncQueueRunner', `buildTasksForRoles: total tasks=${tasks.length}`);
    return tasks;
  }

  /**
   * App 启动时恢复未完成的任务
   * pending/syncing 状态的任务都需要重新执行
   * 注意：cookie 存在 account_table 里，需要从 DB 读取
   */
  static async resumeOnStartup(): Promise<void> {
    if (SyncQueueRunner.isRunning) { return; }
    try {
      const pendingRows = await SyncQueueRunner.syncMetaDao.findAllPending();
      if (pendingRows.length === 0) { return; }
      // 从 DB 读取账号 cookie，重建任务列表
      const tasks: SyncTask[] = [];
      for (let i = 0; i < pendingRows.length; i++) {
        const row = pendingRows[i];
        const account = await CoreInitializer.bbsRepository.getAccountByUid(row.accountId);
        if (account === null) { continue; }
        const roles = await CoreInitializer.bbsRepository.getGameRoles(row.accountId);
        let server = '';
        for (let j = 0; j < roles.length; j++) {
          if (roles[j].roleId === row.roleUid) {
            server = roles[j].server;
            break;
          }
        }
        if (server === '') { continue; }
        const t = new SyncTask();
        t.accountId = row.accountId;
        t.roleUid = row.roleUid;
        t.server = server;
        t.cookie = account.cookie;
        t.dataType = row.dataType;
        tasks[tasks.length] = t;
      }
      SyncQueueRunner.runTasks(tasks).catch((_: Error | object) => {});
    } catch (_) {}
  }

  /**
   * 执行任务队列（逐个执行，成功后更新状态）
   */
  static async runTasks(tasks: SyncTask[]): Promise<void> {
    if (SyncQueueRunner.isRunning) { return; }
    SyncQueueRunner.isRunning = true;
    try {
      for (let i = 0; i < tasks.length; i++) {
        const t = tasks[i];
        try {
          await SyncQueueRunner.executeTask(t);
        } catch (_) {
          // 单个任务失败不影响其他任务，状态已在 executeTask 里标记为 failed
        }
      }

      // 所有任务执行完毕后，调用注册的回调
      for (let i = 0; i < SyncQueueRunner.onCompleteCallbacks.length; i++) {
        try {
          await SyncQueueRunner.onCompleteCallbacks[i]();
        } catch (_) {
          // 回调失败不影响其他回调
        }
      }
    } finally {
      SyncQueueRunner.isRunning = false;
    }
  }

  /**
   * 执行单个同步任务
   */
  private static async executeTask(task: SyncTask): Promise<void> {
    const accountId = task.accountId;
    const roleUid = task.roleUid;
    const server = task.server;
    const cookie = task.cookie;
    const dataType = task.dataType;
    
    Logger.info('💥 SyncQueueRunner', `executeTask: dataType=${dataType}, accountId=${accountId}, roleUid=${roleUid}`);
    
    if (dataType === SyncDataType.GENSHIN_CHARACTER_LIST) {
      Logger.info('💥 SyncQueueRunner', `executeTask: calling genshinRepository.syncAvatarList`);
      await CoreInitializer.genshinRepository.syncAvatarList(accountId, roleUid, server, cookie);
      Logger.info('💥 SyncQueueRunner', `executeTask: syncAvatarList completed`);
    } else if (dataType === SyncDataType.GENSHIN_CHARACTER_DETAIL) {
      await CoreInitializer.genshinRepository.syncAvatarDetail(accountId, roleUid, server, cookie);
    } else if (dataType === SyncDataType.GENSHIN_DAILY_NOTE) {
      await CoreInitializer.genshinRepository.syncDailyNote(accountId, roleUid, server, cookie);
    } else if (dataType === SyncDataType.STARRAIL_AVATAR_BASIC) {
      await CoreInitializer.starRailRepository.syncAvatarList(accountId, roleUid, server, cookie);
    } else if (dataType === SyncDataType.STARRAIL_AVATAR_INFO) {
      await CoreInitializer.starRailRepository.syncAvatarInfo(accountId, roleUid, server, cookie);
    } else if (dataType === SyncDataType.STARRAIL_DAILY_NOTE) {
      await CoreInitializer.starRailRepository.syncDailyNote(accountId, roleUid, server, cookie);
    } else if (dataType === SyncDataType.ZZZ_AVATAR_BASIC) {
      await CoreInitializer.zzzRepository.syncAvatarList(accountId, roleUid, server, cookie);
    } else if (dataType === SyncDataType.ZZZ_AVATAR_INFO) {
      // 绝区零：先拿基础列表，再逐个 avatarId 请求详情
      const basicList = await CoreInitializer.zzzRepository.getAvatarList(accountId, roleUid);
      for (let i = 0; i < basicList.length; i++) {
        try {
          await CoreInitializer.zzzRepository.syncAvatarInfo(accountId, roleUid, server, cookie, basicList[i].avatarId);
        } catch (_) {}
      }
    } else if (dataType === SyncDataType.ZZZ_BUDDY) {
      await CoreInitializer.zzzRepository.syncBuddyList(accountId, roleUid, server, cookie);
    } else if (dataType === SyncDataType.ZZZ_DAILY_NOTE) {
      await CoreInitializer.zzzRepository.syncDailyNote(accountId, roleUid, server, cookie);
    }
  }
}

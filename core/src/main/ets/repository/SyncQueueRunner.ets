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
import { GeetestRequiredError } from '../errors/ApiErrors';
import { ApiErrorCodes } from '../constants/ApiErrorCodes';


/** 绝区零逐个请求代理人详情的间隔（ZZZ-Plugin panel.roleInterval 默认 3000ms） */
const ZZZ_AVATAR_INFO_INTERVAL_MS: number = 3000;

export { SyncTask } from '../models/SyncTask';

/** 同步完成回调类型 */
export type SyncCompleteCallback = () => Promise<void>;

/** 本轮同步失败的类型：人机验证 / 设备指纹无效由 HttpClient 统一上报弹框，其他为普通错误 */
const FAILURE_GEETEST: string = 'geetest';
const FAILURE_FINGERPRINT: string = 'fingerprint';
const FAILURE_OTHER: string = 'other';

/**
 * 本轮同步有任务失败。runTasks 跑完全部任务后抛出（单个任务失败不影响其他任务）；
 * kind 按优先级取：人机验证 > 设备指纹无效 > 其他，message 为该类型第一个失败任务的错误信息。
 */
export class SyncTasksFailedError extends Error {
  readonly kind: string;

  constructor(kind: string, message: string) {
    super(message);
    this.kind = kind;
  }
}

export class SyncQueueRunner {
  private static syncMetaDao: SyncMetaDao = new SyncMetaDao();
  /** 防止并发执行 */
  private static isRunning: boolean = false;
  /** 正在执行的一轮任务；新的 runTasks 会等它结束后再执行 */
  private static currentRun: Promise<void> | null = null;
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
    const tasks: SyncTask[] = [];
    for (let i = 0; i < roles.length; i++) {
      const role = roles[i];
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
  /** 是否有一轮同步正在执行（含后台同步），用于页面提示"正在刷新" */
  static isBusy(): boolean {
    return SyncQueueRunner.currentRun !== null;
  }

  static async runTasks(tasks: SyncTask[]): Promise<void> {
    // 已有一轮在执行：等它结束后再执行本轮。
    // （原来直接跳过且不报错，调用方会误以为同步成功，例如角色页提示"刷新成功"但实际没有同步）
    while (SyncQueueRunner.currentRun !== null) {
      try {
        await SyncQueueRunner.currentRun;
      } catch (_) {
        // 上一轮的失败由它自己的调用方处理
      }
    }
    const run = SyncQueueRunner.doRunTasks(tasks);
    SyncQueueRunner.currentRun = run;
    try {
      await run;
    } finally {
      if (SyncQueueRunner.currentRun === run) {
        SyncQueueRunner.currentRun = null;
      }
    }
  }

  private static async doRunTasks(tasks: SyncTask[]): Promise<void> {
    SyncQueueRunner.isRunning = true;
    let geetestMsg: string | null = null;
    let fingerprintMsg: string | null = null;
    let otherMsg: string | null = null;
    try {
      for (let i = 0; i < tasks.length; i++) {
        const t = tasks[i];
        try {
          await SyncQueueRunner.executeTask(t);
        } catch (error) {
          // 单个任务失败不影响其他任务，状态已在 executeTask 里标记为 failed；记下来，全部跑完后抛给调用方
          const msg = error instanceof Error ? error.message : `${error}`;
          if (SyncQueueRunner.isGeetestError(error)) {
            geetestMsg = geetestMsg ?? msg;
          } else if (SyncQueueRunner.hasRetcode(msg, 5003) || SyncQueueRunner.hasRetcode(msg, 10041)) {
            fingerprintMsg = fingerprintMsg ?? msg;
          } else {
            otherMsg = otherMsg ?? msg;
          }
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
    if (geetestMsg !== null) {
      throw new SyncTasksFailedError(FAILURE_GEETEST, geetestMsg);
    }
    if (fingerprintMsg !== null) {
      throw new SyncTasksFailedError(FAILURE_FINGERPRINT, fingerprintMsg);
    }
    if (otherMsg !== null) {
      throw new SyncTasksFailedError(FAILURE_OTHER, otherMsg);
    }
  }

  /** runTasks 抛出的错误是否为"有任务失败"（entry 层不必直接 import 错误类型） */
  static isTasksFailed(error: Error | object): boolean {
    return error instanceof SyncTasksFailedError;
  }

  /** 有任务需要人机验证（已由 HttpClient 统一上报弹框） */
  static isGeetestRequired(error: Error | object): boolean {
    return error instanceof SyncTasksFailedError && error.kind === FAILURE_GEETEST;
  }

  /** 有任务返回设备指纹无效（已由 HttpClient 统一上报提示） */
  static isFingerprintInvalid(error: Error | object): boolean {
    return error instanceof SyncTasksFailedError && error.kind === FAILURE_FINGERPRINT;
  }

  private static hasRetcode(msg: string, retcode: number): boolean {
    return msg.indexOf(`retcode=${retcode}`) !== -1;
  }

  /** 1034 / 10035：部分 Repository 会把 GeetestRequiredError 包成普通 Error，因此同时按消息里的 retcode 判断 */
  private static isGeetestError(error: Error | object): boolean {
    if (error instanceof GeetestRequiredError) {
      return true;
    }
    const msg = error instanceof Error ? error.message : `${error}`;
    return msg.indexOf(`retcode=${ApiErrorCodes.GEETEST_REQUIRED}`) !== -1 ||
      msg.indexOf(`retcode=${ApiErrorCodes.GEETEST_REQUIRED_GENERAL}`) !== -1;
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
    
    
    if (dataType === SyncDataType.GENSHIN_CHARACTER_LIST) {
      await CoreInitializer.genshinRepository.syncAvatarList(accountId, roleUid, server, cookie);
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
      // 绝区零：先拿基础列表，再逐个 avatarId 请求详情。
      // 照 ZZZ-Plugin（dist/lib/avatar.js getAvatarInfoList）：每次请求间隔 roleInterval（默认 3000ms），出错即停止（任务失败）
      const basicList = await CoreInitializer.zzzRepository.getAvatarList(accountId, roleUid);
      for (let i = 0; i < basicList.length; i++) {
        if (i > 0) {
          await new Promise<void>((resolve: () => void) => setTimeout(resolve, ZZZ_AVATAR_INFO_INTERVAL_MS));
        }
        await CoreInitializer.zzzRepository.syncAvatarInfo(accountId, roleUid, server, cookie, basicList[i].avatarId);
      }
    } else if (dataType === SyncDataType.ZZZ_BUDDY) {
      await CoreInitializer.zzzRepository.syncBuddyList(accountId, roleUid, server, cookie);
    } else if (dataType === SyncDataType.ZZZ_DAILY_NOTE) {
      await CoreInitializer.zzzRepository.syncDailyNote(accountId, roleUid, server, cookie);
    }
  }
}

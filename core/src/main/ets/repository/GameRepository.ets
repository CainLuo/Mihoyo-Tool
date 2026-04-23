import { MihoyoApiService } from '../network/MihoyoApiService';
import { SyncMetaDao } from '../database/SyncMetaDao';
import { SyncMetaRow } from '../models/SyncMetaRow';
import { RdbManager } from '../database/RdbManager';
import {
  SYNC_STATUS_SYNCING,
  SYNC_STATUS_SUCCESS,
  SYNC_STATUS_FAILED,
} from '../constants/ApiConstants';

export abstract class GameRepository {
  // 同步间隔阈值（秒）
  protected static readonly SYNC_INTERVAL_SECONDS: number = 300;

  // Service 实例，由 CoreInitializer 注入
  private service: MihoyoApiService | null = null;
  private syncMetaDao: SyncMetaDao = new SyncMetaDao();

  /**
   * 注入 Service 实例（由 CoreInitializer 调用）
   */
  setService(service: MihoyoApiService): void {
    this.service = service;
  }

  /**
   * 获取 Service 实例（子类及 ViewModel 层调用）
   * ArkTS 严格模式：禁止 ! 非空断言，改为显式 null 检查
   */
  getService(): MihoyoApiService {
    if (this.service === null) {
      throw new Error('GameRepository: service not initialized, call setService() first');
    }
    return this.service;
  }

  /**
   * 检查是否需要同步（距上次同步超过 SYNC_INTERVAL_SECONDS）
   */
  protected async needsSync(accountId: string, roleUid: string, dataType: string): Promise<boolean> {
    const meta = await this.syncMetaDao.findOne(accountId, roleUid, dataType);
    if (meta === null) {
      return true;
    }
    const now = Math.floor(Date.now() / 1000);
    return (now - meta.lastSyncTime) > GameRepository.SYNC_INTERVAL_SECONDS;
  }

  /**
   * 获取指定数据类型的上次同步时间（Unix 秒级时间戳）
   * 未同步过返回 0
   */
  async getLastSyncTime(accountId: string, roleUid: string, dataType: string): Promise<number> {
    const meta = await this.syncMetaDao.findOne(accountId, roleUid, dataType);
    return meta !== null ? meta.lastSyncTime : 0;
  }

  /**
   * 标记同步开始（设置 sync_status = 'syncing'）
   */
  protected async markSyncing(accountId: string, roleUid: string, dataType: string): Promise<void> {
    await this.syncMetaDao.updateStatus(accountId, roleUid, dataType, SYNC_STATUS_SYNCING);
  }

  /**
   * 标记同步成功（设置 sync_status = 'success'，更新 last_sync_time）
   */
  protected async markSuccess(accountId: string, roleUid: string, dataType: string): Promise<void> {
    // 先确保 sync_meta 记录存在
    const existing = await this.syncMetaDao.findOne(accountId, roleUid, dataType);
    if (existing === null) {
      const row = new SyncMetaRow();
      row.accountId = accountId;
      row.roleUid = roleUid;
      row.dataType = dataType;
      row.lastSyncTime = Math.floor(Date.now() / 1000);
      row.syncStatus = SYNC_STATUS_SUCCESS;
      row.errorMsg = '';
      await this.syncMetaDao.upsert(row);
    } else {
      await this.syncMetaDao.updateStatus(accountId, roleUid, dataType, SYNC_STATUS_SUCCESS);
    }
  }

  /**
   * 标记同步失败（设置 sync_status = 'failed'，记录错误信息）
   */
  protected async markFailed(accountId: string, roleUid: string, dataType: string, errorMsg: string): Promise<void> {
    const existing = await this.syncMetaDao.findOne(accountId, roleUid, dataType);
    if (existing === null) {
      const row = new SyncMetaRow();
      row.accountId = accountId;
      row.roleUid = roleUid;
      row.dataType = dataType;
      row.lastSyncTime = 0;
      row.syncStatus = SYNC_STATUS_FAILED;
      row.errorMsg = errorMsg;
      await this.syncMetaDao.upsert(row);
    } else {
      await this.syncMetaDao.updateStatus(accountId, roleUid, dataType, SYNC_STATUS_FAILED, errorMsg);
    }
  }

  /**
   * 在事务中执行写入操作
   */
  protected async runInTransaction(fn: () => Promise<void>): Promise<void> {
    await RdbManager.runInTransaction(fn);
  }

  /**
   * 统一错误处理：将 catch 到的 Object 转为错误消息字符串
   */
  protected toErrorMessage(error: Error | object): string {
    if (error instanceof Error) {
      return error.message;
    }
    return `${error}`;
  }
}

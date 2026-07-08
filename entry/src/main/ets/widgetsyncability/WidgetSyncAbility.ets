/**
 * WidgetSyncAbility — Widget 数据同步 UIAbility
 *
 * 职责：
 * 1. 处理 Widget 通过 call 事件发起的数据同步请求
 * 2. 执行网络请求获取最新便笺数据
 * 3. 更新 Widget 数据存储并推送更新
 *
 * 工作流程：
 * 1. Widget 调用 postCardAction({ action: 'call', abilityName: 'WidgetSyncAbility', method: 'sync' })
 * 2. WidgetSyncAbility.onCreate() 注册 callee 监听
 * 3. 收到 call 事件后，检查冷却期（30 分钟内不重复同步）
 * 4. 执行网络同步（可访问 core 模块）
 * 5. 同步完成后，调用 formProvider.updateForm() 推送更新
 *
 * 配置要求：
 * - module.json5 中添加 ohos.permission.KEEP_BACKGROUND_RUNNING 权限
 * - module.json5 的 abilities 数组中注册此 Ability
 */

import { UIAbility, AbilityConstant, Want, common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { rpc } from '@kit.IPCKit';
import { formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { CoreInitializer, Logger, GameId, AppEnv } from 'core';
import { WidgetDataStoreBuilder } from '../widget/utils/WidgetDataStoreBuilder';
import { WidgetUpdateNotifier } from '../widget/utils/WidgetUpdateNotifier';
import { WidgetConfigStore } from '../widget/utils/WidgetConfigStore';
import { WidgetDataStoreManager } from '../widget/utils/WidgetDataStoreManager';

const TAG = 'WidgetSyncAbility';

/** call 事件方法名 */
const METHOD_SYNC = 'sync';

/** 同步冷却期（秒）- 30 分钟 */
const COOLDOWN_SECONDS = 30 * 60;

/** 上次同步时间存储 key */
const PREFS_KEY_LAST_SYNC = 'widget_last_sync_time';

/** 同步状态标记（防止并发） */
let isSyncing: boolean = false;

/** Preferences 实例 */
let cachedPrefs: preferences.Preferences | null = null;

/** IPC 返回值 */
class SyncParcelable implements rpc.Parcelable {
  success: boolean = false;
  message: string = '';

  constructor(success: boolean, message: string) {
    this.success = success;
    this.message = message;
  }

  marshalling(messageSequence: rpc.MessageSequence): boolean {
    try {
      messageSequence.writeInt(this.success ? 1 : 0);
      messageSequence.writeString(this.message);
      return true;
    } catch (e) {
      Logger.error(TAG, `marshalling failed: ${e}`);
      return false;
    }
  }

  unmarshalling(messageSequence: rpc.MessageSequence): boolean {
    try {
      this.success = messageSequence.readInt() === 1;
      this.message = messageSequence.readString();
      return true;
    } catch (e) {
      Logger.error(TAG, `unmarshalling failed: ${e}`);
      return false;
    }
  }
}

/**
 * 同步所有 Widget 的数据
 */
async function syncAllWidgets(context: common.UIAbilityContext): Promise<void> {
  Logger.info(TAG, 'syncAllWidgets: start');

  try {
    // 初始化存储
    await WidgetConfigStore.init(context);
    await WidgetDataStoreManager.init(context);

    // 获取所有账号
    const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
    Logger.info(TAG, `syncAllWidgets: found ${accounts.length} accounts`);

    if (accounts.length === 0) {
      Logger.info(TAG, 'syncAllWidgets: no accounts, skipping');
      return;
    }

    // 遍历每个账号
    for (let ai = 0; ai < accounts.length; ai++) {
      const account = accounts[ai];
      Logger.info(TAG, `syncAllWidgets: processing account[${ai}] uid=${account.uid}`);

      // 获取该账号下的所有游戏角色
      const roles = await CoreInitializer.bbsRepository.getGameRoles(account.uid);
      Logger.info(TAG, `syncAllWidgets: account ${account.uid} has ${roles.length} roles`);

      // 遍历每个角色，同步便笺
      for (let ri = 0; ri < roles.length; ri++) {
        const role = roles[ri];
        await syncDailyNoteQuietly(account.uid, role.roleId, role.gameId, account.cookie, role.server);
      }
    }

    // 刷新 Widget 数据存储
    const success = await WidgetDataStoreBuilder.refreshAndSave(context, undefined, false);
    if (!success) {
      Logger.warn(TAG, 'syncAllWidgets: refreshAndSave failed');
      return;
    }

    // 推送更新到所有 Widget
    await WidgetUpdateNotifier.notifyAllWidgets(context);

    Logger.info(TAG, 'syncAllWidgets: completed');
  } catch (e) {
    const err = e as BusinessError;
    Logger.error(TAG, `syncAllWidgets error: code=${err.code} msg=${err.message}`);
  }
}

/**
 * 静默同步单个角色的便笺
 */
async function syncDailyNoteQuietly(
  accountId: string,
  roleId: string,
  gameId: string,
  cookie: string,
  server: string
): Promise<void> {
  Logger.info(TAG, `syncDailyNoteQuietly: accountId=${accountId} roleId=${roleId} gameId=${gameId}`);

  try {
    if (gameId === GameId.GENSHIN) {
      await CoreInitializer.genshinRepository.syncDailyNote(accountId, roleId, server, cookie);
      Logger.info(TAG, `syncDailyNoteQuietly: genshin success for ${roleId}`);
    } else if (gameId === GameId.STARRAIL) {
      await CoreInitializer.starRailRepository.syncDailyNote(accountId, roleId, server, cookie);
      Logger.info(TAG, `syncDailyNoteQuietly: starrail success for ${roleId}`);
    } else if (gameId === GameId.ZZZ) {
      await CoreInitializer.zzzRepository.syncDailyNote(accountId, roleId, server, cookie);
      Logger.info(TAG, `syncDailyNoteQuietly: zzz success for ${roleId}`);
    } else {
      Logger.warn(TAG, `syncDailyNoteQuietly: unsupported gameId=${gameId}`);
    }
  } catch (e) {
    const msg = e instanceof Error ? e.message : `${e}`;
    if (msg.includes('10035') || msg.includes('geetest')) {
      Logger.info(TAG, `syncDailyNoteQuietly: geetest required for ${roleId}, skipping`);
    } else {
      Logger.warn(TAG, `syncDailyNoteQuietly: error for ${roleId}: ${msg}`);
    }
  }
}

export default class WidgetSyncAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info(TAG, `onCreate: action=${want.action}, launchReason=${launchParam.launchReason}`);

    // 初始化 Preferences
    try {
      cachedPrefs = preferences.getPreferencesSync(this.context, { name: 'widget_sync' });
      Logger.info(TAG, 'onCreate: prefs initialized');
    } catch (e) {
      Logger.warn(TAG, `onCreate: failed to init prefs: ${JSON.stringify(e)}`);
    }

    // 注册 call 事件监听
    try {
      Logger.info(TAG, `onCreate: registering callee.on('${METHOD_SYNC}')`);
      
      this.callee.on(METHOD_SYNC, (data: rpc.MessageSequence) => {
        Logger.info(TAG, 'handleSyncCall: CALLED!');
        const paramsStr = data.readString();
        Logger.info(TAG, `handleSyncCall: params=${paramsStr}`);

        // 防止并发同步
        if (isSyncing) {
          Logger.info(TAG, 'handleSyncCall: already syncing, skip');
          return new SyncParcelable(false, 'Already syncing');
        }

        // 检查冷却期
        const now = Math.floor(Date.now() / 1000);
        const lastSync = cachedPrefs?.getSync(PREFS_KEY_LAST_SYNC, 0) as number ?? 0;
        const elapsed = now - lastSync;

        if (elapsed < COOLDOWN_SECONDS) {
          const remaining = COOLDOWN_SECONDS - elapsed;
          Logger.info(TAG, `handleSyncCall: in cooldown, remaining=${remaining}s`);
          return new SyncParcelable(false, `In cooldown, ${Math.floor(remaining / 60)} minutes remaining`);
        }

        // 初始化 core 模块（WidgetSyncAbility 是独立 UIAbility，需要单独初始化）
        CoreInitializer.initCore({ env: AppEnv.MOCK, context: this.context })
          .then(async () => {
            Logger.info(TAG, 'CoreInitializer.initCore completed');
            
            // 初始化 Widget 数据存储
            await WidgetDataStoreManager.init(this.context);
            await WidgetConfigStore.init(this.context);
            
            // 执行同步
            isSyncing = true;
            try {
              await syncAllWidgets(this.context);
              // 更新上次同步时间
              cachedPrefs?.putSync(PREFS_KEY_LAST_SYNC, Math.floor(Date.now() / 1000));
              cachedPrefs?.flush();
              Logger.info(TAG, 'handleSyncCall: sync completed');
            } catch (syncErr) {
              Logger.error(TAG, `handleSyncCall: sync failed, error=${JSON.stringify(syncErr)}`);
            } finally {
              isSyncing = false;
            }
          })
          .catch((initErr: Error) => {
            Logger.error(TAG, `CoreInitializer.initCore failed: ${initErr.message}`);
          });

        return new SyncParcelable(true, 'Sync started');
      });
      
      Logger.info(TAG, `onCreate: callee.on('${METHOD_SYNC}') registered successfully`);
    } catch (e) {
      const err = e as BusinessError;
      Logger.error(TAG, `onCreate: failed to register callee, code=${err.code} msg=${err.message}`);
    }
  }

  onDestroy(): void {
    Logger.info(TAG, 'onDestroy');

    try {
      this.callee.off(METHOD_SYNC);
    } catch (e) {
      // 静默处理
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 不需要加载 UI，这是一个后台 Ability
    Logger.info(TAG, 'onWindowStageCreate');
  }
}

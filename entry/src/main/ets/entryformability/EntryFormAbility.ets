/**
 * EntryFormAbility — 卡片生命周期管理
 *
 * 注意：
 * 1. 不能 import StaminaNotificationService（含 backgroundTaskManager）
 * 2. 不能 import CoreInitializer（依赖 UIAbilityContext）
 * 3. 只初始化 RdbManager，直接使用 Repository 读取数据
 * 4. FormExtensionAbility 进程在回调完成后 10 秒内退出，不能做超时操作
 */

import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { RdbManager, Logger, BBSRepository } from 'core';
import { WidgetFormIdStore, WidgetConfig } from '../widget/utils/WidgetFormIdStore';
import { WidgetDataBuilder } from '../widget/utils/WidgetDataBuilder';

const TAG = 'EntryFormAbility';

export default class EntryFormAbility extends FormExtensionAbility {

  /**
   * 卡片被添加到桌面时触发
   * 1. 读取 want.parameters 中的 accountId 和 selectedGames
   * 2. 保存 formId + 配置到 Preferences
   * 3. 立即返回初始数据（避免等待最多 30 分钟的定时刷新偏差）
   */
  onAddForm(want: Want): formBindingData.FormBindingData {
    Logger.info(TAG, 'onAddForm');
    const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string ?? '';
    const formName = want.parameters?.[formInfo.FormParam.NAME_KEY] as string ?? '';
    const accountId = want.parameters?.['accountId'] as string ?? '';
    const selectedGamesRaw = want.parameters?.['selectedGames'] as string ?? '';
    const selectedGames = selectedGamesRaw.length > 0 ? selectedGamesRaw.split(',') : [];

    Logger.info(TAG, `formId=${formId}, formName=${formName}, accountId=${accountId}, games=${selectedGamesRaw}`);

    // 异步初始化并保存 formId（不阻塞 onAddForm 返回）
    this.initAndSave(formId, formName, accountId, selectedGames);

    // 返回初始占位数据，让卡片能显示基本结构（避免 gameCount=0 时渲染空白）
    // 真实数据由 initAndSave 异步推送
    const initialData: Record<string, string | number> = {};
    initialData['accountName'] = accountId.length > 0 ? accountId : '---';
    initialData['accountUid'] = accountId;
    initialData['gameCount'] = '1';
    initialData['game0Id'] = 'genshin';
    initialData['game0Json'] = '{"gameId":"genshin","currentStr":"0","maxStr":"200","secondsStr":"0"}';
    return formBindingData.createFormBindingData(initialData);
  }

  /**
   * 定时刷新触发（updateDuration=1，每 30 分钟）
   */
  onUpdateForm(formId: string): void {
    Logger.info(TAG, `onUpdateForm formId=${formId}`);
    this.pushUpdate(formId);
  }

  /**
   * 卡片被移除时触发
   */
  onRemoveForm(formId: string): void {
    Logger.info(TAG, `onRemoveForm formId=${formId}`);
    this.initStore().then(() => {
      WidgetFormIdStore.remove(formId).catch((e: BusinessError) => {
        Logger.error(TAG, `remove formId failed: ${e.message}`);
      });
    });
  }

  /**
   * 卡片内点击刷新按钮触发（message 事件）
   */
  onFormEvent(formId: string, message: string): void {
    Logger.info(TAG, `onFormEvent formId=${formId}, message=${message}`);
    this.pushUpdate(formId);
  }

  // ── 私有方法 ──────────────────────────────────────────────────────

  /** 初始化 RdbManager 和 WidgetFormIdStore */
  private async initStore(): Promise<void> {
    try {
      // FormExtensionContext 继承自 Context，可以传给 RdbManager.init
      Logger.info(TAG, `initStore: databaseDir=${this.context.databaseDir}`);
      await RdbManager.init(this.context);
      Logger.info(TAG, 'initStore: RdbManager init success');
    } catch (e) {
      Logger.error(TAG, `RdbManager init failed: ${JSON.stringify(e)}`);
    }
    await WidgetFormIdStore.init(this.context);
  }

  /** 初始化、保存 formId、推送初始数据 */
  private async initAndSave(
    formId: string,
    formName: string,
    accountId: string,
    selectedGames: string[],
  ): Promise<void> {
    await this.initStore();
    if (formId === '') {
      Logger.warn(TAG, 'initAndSave: missing formId, skip');
      return;
    }

    // 如果 accountId 为空（桌面长按添加），自动使用第一个账号
    let resolvedAccountId = accountId;
    let resolvedGames = selectedGames;
    if (resolvedAccountId === '') {
      try {
        const repo = new BBSRepository();
        const accounts = await repo.getAllAccounts();
        Logger.info(TAG, `auto-resolve: getAllAccounts returned ${accounts.length} accounts`);
        if (accounts.length > 0) {
          resolvedAccountId = accounts[0].uid;
          const roles = await repo.getGameRoles(resolvedAccountId);
          const gameIds: string[] = [];
          for (let i = 0; i < roles.length; i++) {
            if (gameIds.indexOf(roles[i].gameId) < 0) {
              gameIds.push(roles[i].gameId);
            }
          }
          resolvedGames = gameIds;
          Logger.info(TAG, `auto-resolved account: ${resolvedAccountId}, games count: ${resolvedGames.length}`);
        }
      } catch (e) {
        Logger.error(TAG, `auto-resolve account failed: ${JSON.stringify(e)}`);
      }
    }

    if (resolvedAccountId === '') {
      Logger.warn(TAG, 'initAndSave: no account available, skip');
      return;
    }

    // 根据 formName 调整 selectedGames 顺序，确保对应游戏排在第一位
    let orderedGames = resolvedGames;
    if (formName === 'widget_1x2_genshin') {
      orderedGames = this.reorderGames(resolvedGames, 'genshin');
    } else if (formName === 'widget_1x2_starrail') {
      orderedGames = this.reorderGames(resolvedGames, 'starrail');
    } else if (formName === 'widget_1x2_zzz') {
      orderedGames = this.reorderGames(resolvedGames, 'zzz');
    }

    const config: WidgetConfig = { accountId: resolvedAccountId, selectedGames: orderedGames, formName };
    await WidgetFormIdStore.save(formId, config);
    await this.pushUpdateWithConfig(formId, config);
  }

  /**
   * 将指定游戏移到列表最前面，其余游戏保持原顺序
   */
  private reorderGames(games: string[], firstGame: string): string[] {
    const result: string[] = [];
    // 先加目标游戏
    for (let i = 0; i < games.length; i++) {
      if (games[i] === firstGame) {
        result.push(games[i]);
        break;
      }
    }
    // 再加其余游戏
    for (let i = 0; i < games.length; i++) {
      if (games[i] !== firstGame) {
        result.push(games[i]);
      }
    }
    return result;
  }

  /** 推送指定 formId 的最新数据 */
  private async pushUpdate(formId: string): Promise<void> {
    await this.initStore();
    let config = WidgetFormIdStore.getConfig(formId);
    if (config === null) {
      Logger.warn(TAG, `pushUpdate: no config for formId=${formId}, trying auto-resolve`);
      // formId 没有配置，尝试自动解析账号并保存
      try {
        const repo = new BBSRepository();
        const accounts = await repo.getAllAccounts();
        if (accounts.length > 0) {
          const resolvedAccountId = accounts[0].uid;
          const roles = await repo.getGameRoles(resolvedAccountId);
          const gameIds: string[] = [];
          for (let i = 0; i < roles.length; i++) {
            if (gameIds.indexOf(roles[i].gameId) < 0) {
              gameIds.push(roles[i].gameId);
            }
          }
          const newConfig: WidgetConfig = {
            accountId: resolvedAccountId,
            selectedGames: gameIds,
            formName: '',
          };
          await WidgetFormIdStore.save(formId, newConfig);
          config = newConfig;
        }
      } catch (e) {
        Logger.error(TAG, `pushUpdate: auto-resolve failed: ${JSON.stringify(e)}`);
      }
    }
    if (config === null) {
      Logger.warn(TAG, `pushUpdate: still no config for formId=${formId}, skip`);
      return;
    }
    await this.pushUpdateWithConfig(formId, config);
  }

  private async pushUpdateWithConfig(formId: string, config: WidgetConfig): Promise<void> {
    try {
      Logger.info(TAG, `[WIDGET_DIAG] pushUpdateWithConfig: formId=${formId} formName=${config.formName} games=${config.selectedGames.length}`);
      const payload = await WidgetDataBuilder.buildPayload(formId, config);
      await formProvider.updateForm(formId, payload);
      Logger.info(TAG, `[WIDGET_DIAG] updateForm SUCCESS formId=${formId}`);
    } catch (e) {
      const err = e as BusinessError;
      Logger.error(TAG, `[WIDGET_DIAG] updateForm FAILED formId=${formId}: code=${err.code} msg=${err.message}`);
    }
  }
}

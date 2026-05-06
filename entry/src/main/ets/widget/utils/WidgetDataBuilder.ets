/**
 * WidgetDataBuilder — 从 DB 读取体力数据并构建卡片推送 payload
 *
 * 注意：
 * 1. 此文件不能 import StaminaNotificationService（含 backgroundTaskManager）
 * 2. 此文件不能 import CoreInitializer（依赖 UIAbilityContext）
 * 3. 直接使用 Repository 读取数据，Repository 依赖已初始化的 RdbManager
 */

import { formBindingData, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import {
  Logger,
  GameId,
  GenshinDailyNoteParser,
  StarRailDailyNoteParser,
  ZZZDailyNoteParser,
  GenshinRepository,
  StarRailRepository,
  ZZZRepository,
  BBSRepository,
  StarRailDailyNoteRow,
  GenshinDailyNoteRow,
  ZZZDailyNoteRow,
  AccountRow,
  GameRoleRow,
} from 'core';
import { WidgetFormIdStore, WidgetConfig } from './WidgetFormIdStore';
import { WidgetGameData } from '../models/WidgetModels';

const TAG = 'WidgetDataBuilder';

export class WidgetDataBuilder {
  private static genshinRepo: GenshinRepository = new GenshinRepository();
  private static starRailRepo: StarRailRepository = new StarRailRepository();
  private static zzzRepo: ZZZRepository = new ZZZRepository();
  private static bbsRepo: BBSRepository = new BBSRepository();

  /**
   * 构建并推送指定账号下所有相关卡片的数据
   * 在 UIAbility 进程中调用（由 StaminaNotificationService 触发）
   * 注意：主进程调用 formProvider.updateForm 不能更新卡片 UI，
   * 必须通过 setFormNextRefreshTime 触发 FormExtensionAbility 进程的 onUpdateForm 来更新。
   */
  static async buildAndPushForAccount(accountId: string): Promise<void> {
    const formIds = WidgetFormIdStore.getFormIdsByAccount(accountId);
    if (formIds.length === 0) {
      return;
    }
    for (let i = 0; i < formIds.length; i++) {
      const formId = formIds[i];
      try {
        // 触发 FormExtensionAbility 进程的 onUpdateForm（最短 5 分钟后）
        await formProvider.setFormNextRefreshTime(formId, 5);
        Logger.info(TAG, `setFormNextRefreshTime success formId=${formId}`);
      } catch (e) {
        const err = e as BusinessError;
        Logger.error(TAG, `setFormNextRefreshTime failed formId=${formId}: code=${err.code} msg=${err.message}`);
      }
    }
  }

  /**
   * 构建单个 formId 的推送数据
   * 在 EntryFormAbility 进程中调用（onAddForm / onUpdateForm）
   */
  static async buildPayload(
    _formId: string,
    config: WidgetConfig,
  ): Promise<formBindingData.FormBindingData> {
    const accountId = config.accountId;
    const selectedGames = config.selectedGames;

    // 读取账号信息
    const account: AccountRow | null = await WidgetDataBuilder.bbsRepo.getAccountByUid(accountId);
    const accountName: string = account !== null
      ? (account.nickname.length > 0 ? account.nickname : account.username)
      : accountId;

    // 读取各游戏角色
    const roles: GameRoleRow[] = await WidgetDataBuilder.bbsRepo.getGameRoles(accountId);
    Logger.info(TAG, `[WIDGET_DIAG] buildPayload start: accountId=${accountId} account=${account !== null ? 'found' : 'null'} roles=${roles.length} selectedGames=${selectedGames.length}`);

    // 构建各游戏数据
    const gameDataList: WidgetGameData[] = [];
    for (let gi = 0; gi < selectedGames.length; gi++) {
      const gameId = selectedGames[gi];
      // 找到该游戏的第一个角色
      let roleUid = '';
      for (let ri = 0; ri < roles.length; ri++) {
        if (roles[ri].gameId === gameId) {
          roleUid = roles[ri].roleId;
          break;
        }
      }
      if (roleUid === '') {
        Logger.warn(TAG, `[WIDGET_DIAG] no roleUid for game=${gameId}`);
        continue;
      }
      const data = await WidgetDataBuilder.buildGameData(accountId, roleUid, gameId);
      Logger.info(TAG, `[WIDGET_DIAG] game=${gameId} roleUid=${roleUid} data=${data !== null ? 'ok cur=' + data.currentStr + ' max=' + data.maxStr : 'null'}`);
      if (data !== null) {
        gameDataList.push(data);
      }
    }

    // 构建 payload 对象
    const obj: Record<string, string | number | boolean> = {};
    obj['accountName'] = accountName;
    obj['accountUid'] = accountId;
    obj['gameCount'] = String(gameDataList.length);
    Logger.info(TAG, `[WIDGET_DIAG] buildPayload done: gameCount=${gameDataList.length} (string type)`);

    for (let i = 0; i < gameDataList.length; i++) {
      gameDataList[i].writeToPayload(obj, `game${i}Json`);
      // 单独存 gameId，供 @Entry 组件判断跳转目标，避免重复解析 JSON
      obj[`game${i}Id`] = gameDataList[i].gameId;
    }

    return formBindingData.createFormBindingData(obj);
  }

  // ── 私有：各游戏数据读取 ──────────────────────────────────────────

  private static async buildGameData(
    accountId: string,
    roleUid: string,
    gameId: string,
  ): Promise<WidgetGameData | null> {
    try {
      if (gameId === GameId.GENSHIN) {
        return await WidgetDataBuilder.buildGenshinData(accountId, roleUid);
      }
      if (gameId === GameId.STARRAIL) {
        return await WidgetDataBuilder.buildStarRailData(accountId, roleUid);
      }
      if (gameId === GameId.ZZZ) {
        return await WidgetDataBuilder.buildZZZData(accountId, roleUid);
      }
      return null;
    } catch (e) {
      Logger.error(TAG, `buildGameData failed ${gameId}/${roleUid}: ${JSON.stringify(e)}`);
      return null;
    }
  }

  private static async buildGenshinData(accountId: string, roleUid: string): Promise<WidgetGameData | null> {
    const row: GenshinDailyNoteRow | null = await WidgetDataBuilder.genshinRepo.getDailyNote(accountId, roleUid);
    if (row === null || row.rawJson.length === 0) {
      return null;
    }
    const parsed = GenshinDailyNoteParser.parse(row.rawJson);
    // 如果解析后体力上限为 0，说明数据无效
    const maxResin: number = parsed.maxResin > 0 ? parsed.maxResin : row.maxResin;
    if (maxResin === 0) {
      return null;
    }
    const d = new WidgetGameData();
    d.gameId = GameId.GENSHIN;
    d.currentStr = String(parsed.currentResin);
    d.maxStr = String(maxResin);
    d.secondsStr = String(parsed.resinRecoveryTime);
    d.coinStr = String(parsed.currentHomeCoin);
    d.coinMaxStr = String(parsed.maxHomeCoin);
    d.taskStr = String(parsed.finishedTaskNum);
    d.taskTotalStr = String(parsed.totalTaskNum);
    d.taskAllReceived = String(parsed.isExtraTaskRewardReceived);
    d.transformerStr = String(parsed.transformer.reached);
    d.expeditionMaxStr = String(parsed.maxExpeditionNum);
    // 统计已完成的派遣数量
    let finishedCount = 0;
    for (let i = 0; i < parsed.expeditions.length; i++) {
      if (parsed.expeditions[i].status === 'Finished') {
        finishedCount++;
      }
    }
    d.expeditionFinishedStr = String(finishedCount);
    return d;
  }

  private static async buildStarRailData(accountId: string, roleUid: string): Promise<WidgetGameData | null> {
    const row: StarRailDailyNoteRow | null = await WidgetDataBuilder.starRailRepo.getDailyNote(accountId, roleUid);
    if (row === null || row.rawJson.length === 0) {
      return null;
    }
    const parsed = StarRailDailyNoteParser.parse(row.rawJson);
    const maxStamina = parsed.maxStamina > 0 ? parsed.maxStamina : row.maxStamina;
    if (maxStamina === 0) {
      return null;
    }
    const d = new WidgetGameData();
    d.gameId = GameId.STARRAIL;
    d.currentStr = String(parsed.currentStamina > 0 ? parsed.currentStamina : row.currentStamina);
    d.maxStr = String(maxStamina);
    d.secondsStr = String(parsed.staminaRecoverTime);
    d.reserveStr = String(parsed.currentReserveStamina);
    d.trainStr = String(parsed.currentTrainScore);
    d.trainMaxStr = String(parsed.maxTrainScore);
    d.cocoonStr = String(parsed.weeklyCocoonCnt);
    d.cocoonLimitStr = String(parsed.weeklyCocoonLimit);
    d.rogueStr = String(parsed.rogueTournWeeklyCur);
    d.rogueMaxStr = String(parsed.rogueTournWeeklyMax);
    return d;
  }

  private static async buildZZZData(accountId: string, roleUid: string): Promise<WidgetGameData | null> {
    const row: ZZZDailyNoteRow | null = await WidgetDataBuilder.zzzRepo.getDailyNote(accountId, roleUid);
    if (row === null || row.rawJson.length === 0) {
      return null;
    }
    const parsed = ZZZDailyNoteParser.parse(row.rawJson);
    const maxEnergy: number = parsed.maxEnergy > 0 ? parsed.maxEnergy : row.energyMax;
    if (maxEnergy === 0) {
      return null;
    }
    const d = new WidgetGameData();
    d.gameId = GameId.ZZZ;
    d.currentStr = String(parsed.currentEnergy > 0 ? parsed.currentEnergy : row.energyCurrent);
    d.maxStr = String(maxEnergy);
    d.secondsStr = String(parsed.energyRecoverTime);
    d.vitalityStr = String(parsed.currentVitality);
    d.vitalityMaxStr = String(parsed.maxVitality);
    d.cardSign = parsed.cardSign;
    d.videoStore = parsed.videoStoreState;
    return d;
  }

}

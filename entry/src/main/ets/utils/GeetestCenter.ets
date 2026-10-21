/**
 * GeetestCenter — 人机验证（retcode=1034 / 10035）统一处理
 *
 * 任何接口返回 1034 / 10035 时，core 的具体 API 通过 GeetestService.setRequiredListener() 显式上报，
 * 这里统一申请验证并推入 GeetestSignal，由 Main.ets 弹框：
 * - 同一账号申请 / 排队 / 弹框中时不重复；不同账号排队依次弹（GeetestSignal 队列）
 * - 用户取消（或申请 / 提交验证失败）后，该账号本次启动不再弹
 * - 验证通过后通过 SyncRetrySignal 通知首页 / 角色页重新同步
 *
 * 验证方式与 PizzaHelperUnited 一致：用失败接口地址作为 x-rpc-challenge_path 申请 / 提交验证，通过后直接重新请求。
 */
import { AccountRow, CoreInitializer, GeetestService, GeetestVerifyInput, Logger } from 'core'
import { GeetestTrigger } from '../models/GeetestTrigger'
import { GeetestSignal } from './GeetestSignal'
import { SyncRetrySignal } from './SyncRetrySignal'
import { gameIdFromApiUrl } from './GameIdUtil'

const TAG: string = 'GeetestCenter'
const ACCOUNT_ID_KEYS: string[] = ['account_id', 'ltuid', 'stuid']

export class GeetestCenter {
  /** 申请 / 排队 / 弹框中的账号 */
  private static pendingAccounts: Set<string> = new Set<string>()
  /** 用户取消过（或验证失败）的账号：本次启动不再弹 */
  private static skippedAccounts: Set<string> = new Set<string>()
  private static initialized: boolean = false

  /** 注册 core 的人机验证上报（App 启动时调用一次） */
  static init(): void {
    if (GeetestCenter.initialized) {
      return
    }
    GeetestCenter.initialized = true
    GeetestService.setRequiredListener((url: string, cookie: string, roleUid: string, retcode: number) => {
      GeetestCenter.onRequired(url, cookie, roleUid, retcode)
    })
  }

  private static async onRequired(url: string, cookie: string, roleUid: string, retcode: number): Promise<void> {
    if (cookie.length === 0) {
      return
    }
    const accountId = GeetestCenter.accountIdOf(cookie)
    if (GeetestCenter.pendingAccounts.has(accountId) || GeetestCenter.skippedAccounts.has(accountId)) {
      return
    }
    GeetestCenter.pendingAccounts.add(accountId)
    const gameId = gameIdFromApiUrl(url)
    try {
      const createResult = await GeetestService.createVerification(cookie, gameId, url, retcode)
      // roleUid / gameId 用于弹框时提示是哪个游戏账号（Main.ets 显示"游戏名 · UID"）
      const trigger = new GeetestTrigger(createResult, cookie, gameId, roleUid, '', accountId)
      trigger.challengePath = url
      trigger.retcode = retcode
      const accountName = await GeetestCenter.accountNameOf(accountId)
      GeetestSignal.instance().push(trigger, {
        onSuccess: (_gt: string, challenge: string, validate: string) => {
          GeetestCenter.verify(trigger, challenge, validate)
        },
        onCancel: () => {
          GeetestCenter.giveUp(accountId)
        }
      }, accountName)
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.error(TAG, `createVerification failed for ${url}: ${msg}`)
      GeetestCenter.giveUp(accountId)
    }
  }

  private static async verify(trigger: GeetestTrigger, challenge: string, validate: string): Promise<void> {
    const input = new GeetestVerifyInput()
    input.geetest_challenge = challenge
    input.geetest_validate = validate
    input.geetest_seccode = validate + '|jordan'
    try {
      await GeetestService.verifyVerification(input, trigger.cookie, trigger.gameId, trigger.challengePath, trigger.retcode)
      GeetestCenter.pendingAccounts.delete(trigger.accountId)
      SyncRetrySignal.instance().notify(trigger.accountId)
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.error(TAG, `verifyVerification failed for ${trigger.challengePath}: ${msg}`)
      GeetestCenter.giveUp(trigger.accountId)
    }
  }

  /** 本次启动不再为该账号弹验证 */
  private static giveUp(accountId: string): void {
    GeetestCenter.pendingAccounts.delete(accountId)
    GeetestCenter.skippedAccounts.add(accountId)
  }

  /** Cookie 中的米游社 UID；取不到时用整个 Cookie 作为账号标识 */
  private static accountIdOf(cookie: string): string {
    for (let i = 0; i < ACCOUNT_ID_KEYS.length; i++) {
      const m = cookie.match(new RegExp(`(?:^|;\\s*)${ACCOUNT_ID_KEYS[i]}=([^;]+)`))
      if (m !== null) {
        return m[1].trim()
      }
    }
    return cookie
  }

  private static async accountNameOf(accountId: string): Promise<string> {
    try {
      const accounts: AccountRow[] = await CoreInitializer.bbsRepository.getAllAccounts()
      for (let i = 0; i < accounts.length; i++) {
        if (accounts[i].uid === accountId) {
          return accounts[i].nickname.length > 0 ? accounts[i].nickname : accounts[i].username
        }
      }
    } catch (_) {
    }
    return ''
  }
}

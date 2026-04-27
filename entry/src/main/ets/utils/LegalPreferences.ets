/**
 * LegalPreferences — 持久化存储用户是否已完成隐私合规流程
 *
 * 使用 @kit.ArkData 的 preferences 模块（XML 模式）。
 * hasAgreed 同步读取，setAgreed 异步写入并 flush 到磁盘。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from 'core';

const TAG: string = 'LegalPreferences';
const STORE_NAME: string = 'legal_prefs';
const KEY_AGREED: string = 'hasAgreedPrivacy';

export class LegalPreferences {
  /** 同步检查用户是否已同意（首次返回 false） */
  static hasAgreed(context: common.UIAbilityContext): boolean {
    try {
      const prefs = preferences.getPreferencesSync(context, { name: STORE_NAME });
      return prefs.getSync(KEY_AGREED, false) as boolean;
    } catch (e) {
      Logger.warn(TAG, `hasAgreed failed: ${(e as Error).message}`);
      return false;
    }
  }

  /** 标记用户已同意，并持久化到磁盘 */
  static setAgreed(context: common.UIAbilityContext): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      try {
        const prefs = preferences.getPreferencesSync(context, { name: STORE_NAME });
        prefs.putSync(KEY_AGREED, true);
        prefs.flush((err: BusinessError) => {
          if (err) {
            Logger.error(TAG, `flush failed: ${err.message}`);
            reject(err);
          } else {
            resolve();
          }
        });
      } catch (e) {
        Logger.error(TAG, `setAgreed failed: ${(e as Error).message}`);
        reject(e);
      }
    });
  }
}

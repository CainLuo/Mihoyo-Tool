/**
 * WidgetSettingsConfigSaver — Widget 配置页的持久化与拉起表单
 *
 * 从 ViewModel 拆出的副作用层：
 * - 预配置写入 WidgetDataStore.widgets（EntryFormAbility 读取）
 * - pending config 写入 Preferences（onAddForm 按 formName 读取）
 * - 构建并拉起系统卡片管理器
 *
 * 注意：Preferences 文件名与 want 参数是跨进程契约，不能随意修改。
 */
import { formProvider } from '@kit.FormKit';
import { Want, bundleManager, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { Logger } from 'core';
import { WidgetDataStore } from '../WidgetDataStoreModels';
import { WidgetDataStoreManager } from './WidgetDataStoreManager';

const TAG = 'WIDGET';
const PREFS_NAME = 'widget_configs';

/** 保存预配置到 WidgetDataStore.widgets */
export async function savePresetSlots(dataStore: WidgetDataStore, presetKey: string,
                                      slotKeys: string[]): Promise<void> {
  Logger.info(TAG, `savePresetSlots: presetKey=${presetKey} slots=${slotKeys.join(',')}`);
  dataStore.setPresetSlots(presetKey, slotKeys);

  const saved = await WidgetDataStoreManager.save(dataStore);
  if (saved) {
    Logger.info(TAG, `savePresetSlots: SUCCESS - saved to WidgetDataStore.widgets[${presetKey}]`);
  } else {
    Logger.error(TAG, `savePresetSlots: FAILED - could not save to WidgetDataStore`);
  }
}

/**
 * 保存 pending config 到 Preferences。
 *
 * 主应用进程写入、FormExtension 进程读取，必须 flush 完成后再调用 openFormManager。
 */
export async function savePendingConfig(context: common.UIAbilityContext | null, key: string,
                                        configJson: string): Promise<void> {
  if (context === null) {
    Logger.error(TAG, 'savePendingConfig: context is null');
    return;
  }
  try {
    Logger.info(TAG, `savePendingConfig: start saving key=${key} jsonLen=${configJson.length}`);

    // 先清缓存，避免多进程间的 Preferences 缓存不一致
    preferences.removePreferencesFromCacheSync(context, { name: PREFS_NAME });
    const prefs = await preferences.getPreferences(context, PREFS_NAME);

    await prefs.put(key, configJson);
    prefs.flushSync();

    // 验证写入
    const verifyJson = prefs.getSync(key, '') as string;
    if (verifyJson.length === 0) {
      Logger.error(TAG, `savePendingConfig: VERIFY FAILED - json is empty after flush!`);
    } else {
      Logger.info(TAG, `savePendingConfig: ✅ VERIFY SUCCESS`);
    }
  } catch (e) {
    const err = e as BusinessError;
    Logger.error(TAG, `savePendingConfig failed: code=${err.code} msg=${err.message}`);
  }
}

/** 构建 openFormManager 的 Want（只含系统标准参数） */
export function buildFormManagerWant(formName: string, dimension: number): Want {
  return {
    // HAR 的 BuildProfile 没有 BUNDLE_NAME，改为运行时读取本应用包名
    bundleName: bundleManager.getBundleInfoForSelfSync(
      bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT).name,
    abilityName: 'EntryFormAbility',
    parameters: {
      'ohos.extra.param.key.form_dimension': dimension,
      'ohos.extra.param.key.form_name': formName,
      'ohos.extra.param.key.module_name': 'entry',
      // 注意：自定义参数无法传递，已验证
    },
  };
}

/** 拉起系统卡片管理器，失败只记录日志 */
export function openFormManager(want: Want): boolean {
  try {
    formProvider.openFormManager(want);
    return true;
  } catch (e) {
    const err = e as BusinessError;
    Logger.error(TAG, `openFormManager failed: code=${err.code} msg=${err.message}`);
    return false;
  }
}

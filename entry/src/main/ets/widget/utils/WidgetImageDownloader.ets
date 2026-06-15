/**
 * WidgetImageDownloader.ets — Widget 网络图片下载器
 *
 * 职责：
 * - 通用的网络图片下载工具
 * - 保存到应用临时目录
 * - 将路径保存到 Preferences 供 FormExtensionAbility 读取
 *
 * 使用场景：
 * - 主应用同步数据后调用，下载 Widget 需要显示的网络图片
 * - FormExtensionAbility 通过 loadFormImagesSync() 读取已下载的图片 fd
 *
 * 流程：
 * 1. 主应用进程：调用 downloadAndSave() 下载图片
 * 2. 图片保存到 context.tempDir
 * 3. 路径保存到 Preferences（key 由调用方指定）
 * 4. FormExtension 进程：调用 loadFormImagesSync() 读取图片 fd
 * 5. Widget 组件使用 memory://key 格式显示图片
 *
 * 使用示例：
 * // 主应用进程 — 下载图片
 * const urls = ['https://...', 'https://...'];
 * await WidgetImageDownloader.downloadAndSave(context, 'expedition_avatars', urls);
 *
 * // FormExtension 进程 — 读取图片 fd
 * const formImages = WidgetImageDownloader.loadFormImagesSync(context, 'expedition_avatars');
 * // formImages = { 'expedition_avatars_0': fd0, 'expedition_avatars_1': fd1, ... }
 *
 * // Widget 组件 — 显示图片
 * Image('memory://expedition_avatars_0')
 */

import { http } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Logger } from 'core';

const TAG = 'WIDGET';

/**
 * Widget 网络图片下载器
 */
export class WidgetImageDownloader {
  /**
   * 下载并保存图片列表
   *
   * @param context UIAbilityContext
   * @param prefsKey Preferences 存储的 key 前缀（如 'expedition_avatars'）
   * @param urls 图片 URL 列表
   * @returns 成功下载的图片数量
   */
  static async downloadAndSave(
    context: common.UIAbilityContext,
    prefsKey: string,
    urls: string[]
  ): Promise<number> {
    if (urls.length === 0) {
      Logger.info(TAG, `[WidgetImage] no urls to download for ${prefsKey}`);
      return 0;
    }

    Logger.info(TAG, `[WidgetImage] downloading ${urls.length} images for ${prefsKey}`);

    // 初始化 Preferences
    let prefs: preferences.Preferences | null = null;
    try {
      prefs = await preferences.getPreferences(context, 'widget_images');
    } catch (e) {
      Logger.error(TAG, `[WidgetImage] failed to init prefs: ${JSON.stringify(e)}`);
      return 0;
    }

    // 下载每个图片
    const filesDir = context.filesDir; // 使用持久化目录（tempDir 会在应用重启后清空）
    const imageNames: Record<string, string> = {}; // 只存相对文件名，不存绝对路径
    let successCount = 0;

    for (let i = 0; i < urls.length; i++) {
      const url = urls[i];
      if (url.length === 0) {
        continue;
      }

      try {
        // 生成文件名（只存相对文件名，在 FormExtension 中用当前 filesDir 拼接）
        const fileName = `${prefsKey}_${i}.png`;
        const filePath = `${filesDir}/${fileName}`;

        // 检查文件是否已存在（避免重复下载）
        let fileExists = false;
        try {
          const stat = fileIo.statSync(filePath);
          fileExists = stat.size > 0;
        } catch (_e) {
          // 文件不存在，需要下载
        }

        // 如果文件已存在，跳过下载
        if (fileExists) {
          const key = `${prefsKey}_${i}`;
          imageNames[key] = fileName;
          successCount++;
          Logger.info(TAG, `[WidgetImage] file already exists: ${key} -> ${filePath}`);
          continue;
        }

        // 下载图片
        const success = await WidgetImageDownloader.downloadImage(url, filePath);
        if (success) {
          // 使用统一的 key 格式：{prefsKey}_{index}
          const key = `${prefsKey}_${i}`;
          imageNames[key] = fileName; // 只存相对文件名
          successCount++;
          Logger.info(TAG, `[WidgetImage] downloaded ${key} -> ${filePath}`);
        }
      } catch (e) {
        Logger.error(TAG, `[WidgetImage] failed to download image ${i}: ${JSON.stringify(e)}`);
      }
    }

    // 保存到 Preferences（只存相对文件名）
    if (successCount > 0) {
      try {
        // 先清除该 prefsKey 相关的旧记录
        const all = prefs.getAll();
        const oldKeys = Object.keys(all);
        for (let i = 0; i < oldKeys.length; i++) {
          const key = oldKeys[i];
          if (key.startsWith(prefsKey + '_')) {
            await prefs.delete(key);
          }
        }

        // 写入新记录（相对文件名）
        const keys = Object.keys(imageNames);
        for (let i = 0; i < keys.length; i++) {
          const key = keys[i];
          await prefs.put(key, imageNames[key]);
        }
        await prefs.flush();
        Logger.info(TAG, `[WidgetImage] saved ${keys.length} image names to prefs`);
      } catch (e) {
        Logger.error(TAG, `[WidgetImage] failed to save prefs: ${JSON.stringify(e)}`);
      }
    }

    return successCount;
  }

  /**
   * 同步加载已下载的图片 fd
   * 在 FormExtensionAbility.onAddForm() 中调用
   *
   * @param context FormExtensionContext
   * @param prefsKey Preferences 存储的 key 前缀
   * @param maxCount 最大加载数量
   * @returns formImages 映射：{ 'key_0': fd0, 'key_1': fd1, ... }
   */
  static loadFormImagesSync(
    context: common.FormExtensionContext,
    prefsKey: string,
    maxCount: number = 10
  ): Record<string, number> {
    const formImages: Record<string, number> = {};
    let hasMissingFiles = false;

    try {
      // 从 Preferences 读取图片相对文件名
      const avatarPrefs = preferences.getPreferencesSync(context, { name: 'widget_images' });

      // 获取当前进程的 filesDir（每次应用安装后可能不同）
      const filesDir = context.filesDir;

      // 尝试读取指定数量的图片
      for (let i = 0; i < maxCount; i++) {
        const key = `${prefsKey}_${i}`;
        const fileName = avatarPrefs.getSync(key, '') as string;

        if (fileName.length === 0) {
          continue;
        }

        // 用当前 filesDir 拼接完整路径
        const filePath = `${filesDir}/${fileName}`;

        try {
          // 打开文件获取 fd
          const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
          formImages[key] = file.fd;
          Logger.info(TAG, `[WidgetImage] loadFormImagesSync: ${key} -> fd=${file.fd}`);
        } catch (e) {
          // 文件不存在，标记为需要重新下载
          hasMissingFiles = true;
          Logger.warn(TAG, `[WidgetImage] file not found: ${key} at ${filePath}, will need to re-download`);
        }
      }

      // 如果有文件丢失，请求主应用刷新数据
      if (hasMissingFiles) {
        Logger.info(TAG, `[WidgetImage] some images are missing, requesting refresh from main app`);
        // 注意：FormExtension 无法直接触发下载，需要依赖主应用启动时自动下载
        // 主应用在 EntryAbility.onCreate() 中会调用 initAndSave() 重新下载
      }

      Logger.info(TAG, `[WidgetImage] loadFormImagesSync: loaded ${Object.keys(formImages).length} images for ${prefsKey}`);
    } catch (e) {
      Logger.error(TAG, `[WidgetImage] loadFormImagesSync error: ${JSON.stringify(e)}`);
    }

    return formImages;
  }

  /**
   * 清除指定 key 前缀的缓存图片
   *
   * @param context UIAbilityContext
   * @param prefsKey Preferences 存储的 key 前缀
   */
  static async clearCache(context: common.UIAbilityContext, prefsKey: string): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(context, 'widget_images');
      const all = await prefs.getAll();
      const keys = Object.keys(all);
      const filesDir = context.filesDir;

      let clearedCount = 0;
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        if (key.startsWith(prefsKey + '_')) {
          const fileName = await prefs.get(key, '') as string;
          if (fileName.length > 0) {
            try {
              // 用当前 filesDir 拼接完整路径
              const filePath = `${filesDir}/${fileName}`;
              fileIo.unlinkSync(filePath);
              clearedCount++;
            } catch (_e) {
              // 忽略删除错误
            }
          }
          await prefs.delete(key);
        }
      }
      await prefs.flush();
      Logger.info(TAG, `[WidgetImage] cleared ${clearedCount} cached images for ${prefsKey}`);
    } catch (e) {
      Logger.error(TAG, `[WidgetImage] clearCache error: ${JSON.stringify(e)}`);
    }
  }

  /**
   * 清除所有缓存图片
   *
   * @param context UIAbilityContext
   */
  static async clearAllCache(context: common.UIAbilityContext): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(context, 'widget_images');
      const all = await prefs.getAll();
      const keys = Object.keys(all);
      const filesDir = context.filesDir;

      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const fileName = await prefs.get(key, '') as string;
        if (fileName.length > 0) {
          try {
            // 用当前 filesDir 拼接完整路径
            const filePath = `${filesDir}/${fileName}`;
            fileIo.unlinkSync(filePath);
          } catch (_e) {
            // 忽略删除错误
          }
        }
        await prefs.delete(key);
      }
      await prefs.flush();
      Logger.info(TAG, `[WidgetImage] cleared all ${keys.length} cached images`);
    } catch (e) {
      Logger.error(TAG, `[WidgetImage] clearAllCache error: ${JSON.stringify(e)}`);
    }
  }

  /**
   * 检查图片是否存在
   *
   * @param context FormExtensionContext 或 UIAbilityContext
   * @param prefsKey Preferences 存储的 key 前缀
   * @param index 图片索引
   * @returns 文件是否存在
   */
  static imageExists(
    context: common.FormExtensionContext | common.UIAbilityContext,
    prefsKey: string,
    index: number
  ): boolean {
    try {
      const avatarPrefs = preferences.getPreferencesSync(context, { name: 'widget_images' });
      const fileName = avatarPrefs.getSync(`${prefsKey}_${index}`, '') as string;
      if (fileName.length === 0) {
        return false;
      }
      const filePath = `${context.filesDir}/${fileName}`;
      const stat = fileIo.statSync(filePath);
      return stat.size > 0;
    } catch (e) {
      return false;
    }
  }

  /**
   * 检查指定 key 前缀的所有图片是否都已存在
   *
   * @param context FormExtensionContext 或 UIAbilityContext
   * @param prefsKey Preferences 存储的 key 前缀
   * @param count 需要检查的图片数量
   * @returns 所有图片是否都存在
   */
  static allImagesExist(
    context: common.FormExtensionContext | common.UIAbilityContext,
    prefsKey: string,
    count: number
  ): boolean {
    for (let i = 0; i < count; i++) {
      if (!WidgetImageDownloader.imageExists(context, prefsKey, i)) {
        return false;
      }
    }
    return true;
  }

  // ── 私有方法 ──────────────────────────────────────────────────────

  /**
   * 下载单张图片
   */
  private static async downloadImage(url: string, filePath: string): Promise<boolean> {
    const httpRequest = http.createHttp();

    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'User-Agent': 'Mozilla/5.0'
        }
      });

      if (response.responseCode !== http.ResponseCode.OK) {
        Logger.error(TAG, `[WidgetImage] download failed: ${response.responseCode}`);
        return false;
      }

      // 写入文件
      const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      try {
        const result = response.result;
        if (result instanceof ArrayBuffer) {
          await fileIo.write(file.fd, result);
          return true;
        } else {
          Logger.error(TAG, `[WidgetImage] unexpected result type: ${typeof result}`);
          return false;
        }
      } finally {
        fileIo.closeSync(file);
      }
    } catch (e) {
      Logger.error(TAG, `[WidgetImage] downloadImage error: ${JSON.stringify(e)}`);
      return false;
    } finally {
      httpRequest.destroy();
    }
  }
}

/**
 * 派遣头像 URL 解析工具
 * 从原神便笺 rawJson 中解析派遣角色头像 URL
 */
export class ExpeditionAvatarParser {
  /**
   * 从 rawJson 解析派遣头像 URL 列表
   *
   * @param rawJson 原神便笺 rawJson
   * @param maxCount 最大解析数量（默认 5）
   * @returns 头像 URL 列表
   */
  static parseUrls(rawJson: string, maxCount: number = 5): string[] {
    const urls: string[] = [];

    if (rawJson.length === 0) {
      return urls;
    }

    try {
      const data = JSON.parse(rawJson) as Record<string, Object>;
      const expeditions = data['expeditions'];

      if (!Array.isArray(expeditions)) {
        return urls;
      }

      for (let i = 0; i < Math.min(expeditions.length, maxCount); i++) {
        const exp = expeditions[i] as Record<string, Object>;
        const url = String(exp['avatar_side_icon'] ?? '');
        if (url.length > 0) {
          urls.push(url);
        }
      }
    } catch (e) {
      Logger.error(TAG, `[ExpeditionAvatar] parseUrls failed: ${JSON.stringify(e)}`);
    }

    return urls;
  }
}

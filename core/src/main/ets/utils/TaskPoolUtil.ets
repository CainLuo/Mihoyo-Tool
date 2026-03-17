import { taskpool } from '@kit.ArkTS';
import { RdbManager } from '../database';

/**
 * 游戏资产数据接口
 */
export interface GameAsset {
  type: string;
  entityId: string;
  level: number;
  element: string;
  rawJson: string;
}

/**
 * 解析原神角色 JSON 数据（在 taskpool 线程中执行）
 * @param jsonString JSON 字符串
 * @returns 资产数据列表
 */
@Concurrent
export function parseCharactersJson(jsonString: string): Record<string, Object>[] {
  try {
    const data: Record<string, Object> = JSON.parse(jsonString);
    const dataObj: Record<string, Object> = data['data'] as Record<string, Object>;
    const characters: Record<string, Object>[] = dataObj['characters'] as Record<string, Object>[] || [];

    return characters.map((character: Record<string, Object>) => {
      const asset: Record<string, Object> = {};
      asset['type'] = 'character';
      asset['entityId'] = (character['id'] as string)?.toString() || '';
      asset['level'] = (character['level'] as number) || 0;
      asset['element'] = (character['element'] as string) || '';
      asset['rawJson'] = JSON.stringify(character);
      return asset;
    });
  } catch (error) {
    console.error(`Failed to parse characters JSON: ${error}`);
    return [];
  }
}

/**
 * 解析通用游戏资产 JSON 数据（在 taskpool 线程中执行）
 * @param jsonString JSON 字符串
 * @param assetType 资产类型
 * @param idField ID 字段名
 * @param levelField 等级字段名
 * @param elementField 元素字段名
 * @returns 资产数据列表
 */
@Concurrent
export function parseGameAssetsJson(
  jsonString: string,
  assetType: string,
  idField: string,
  levelField: string,
  elementField: string
): Record<string, Object>[] {
  try {
    const data: Record<string, Object> = JSON.parse(jsonString);
    const dataObj: Record<string, Object> = data['data'] as Record<string, Object>;
    const items: Record<string, Object>[] = dataObj['list'] as Record<string, Object>[] || [];

    return items.map((item: Record<string, Object>) => {
      const asset: Record<string, Object> = {};
      asset['type'] = assetType;
      asset['entityId'] = (item[idField] as string)?.toString() || '';
      asset['level'] = (item[levelField] as number) || 0;
      asset['element'] = (item[elementField] as string) || '';
      asset['rawJson'] = JSON.stringify(item);
      return asset;
    });
  } catch (error) {
    console.error(`Failed to parse game assets JSON: ${error}`);
    return [];
  }
}

function toErrorMessage(error: Error | object): string {
  if (error instanceof Error) {
    return error.message;
  }
  return `${error}`;
}

/**
 * 任务池工具类
 * 在 taskpool 线程中解析大型 JSON，解析完成后回到主线程写入数据库
 */
export class TaskPoolUtil {
  /**
   * 解析并批量存储原神角色数据
   */
  public static async processGenshinCharacters(
    jsonString: string,
    roleId: string,
    gameId: string
  ): Promise<void> {
    try {
      const task: taskpool.Task = new taskpool.Task(parseCharactersJson, jsonString);
      const rawAssets = await taskpool.execute(task) as Record<string, Object>[];

      const assets: GameAsset[] = rawAssets.map((asset: Record<string, Object>) => {
        const gameAsset: GameAsset = {
          type: asset['type'] as string,
          entityId: asset['entityId'] as string,
          level: asset['level'] as number,
          element: asset['element'] as string,
          rawJson: asset['rawJson'] as string
        };
        return gameAsset;
      });

      await RdbManager.replaceGameAssets(roleId, gameId, assets);
    } catch (error) {
      console.error(`Failed to process genshin characters: ${toErrorMessage(error)}`);
    }
  }

  /**
   * 解析并批量存储通用游戏资产数据
   */
  public static async processGameAssets(
    jsonString: string,
    roleId: string,
    gameId: string,
    assetType: string,
    idField: string = 'id',
    levelField: string = 'level',
    elementField: string = 'element'
  ): Promise<void> {
    try {
      const task: taskpool.Task = new taskpool.Task(
        parseGameAssetsJson, jsonString, assetType, idField, levelField, elementField
      );
      const rawAssets = await taskpool.execute(task) as Record<string, Object>[];

      const assets: GameAsset[] = rawAssets.map((asset: Record<string, Object>) => {
        const gameAsset: GameAsset = {
          type: asset['type'] as string,
          entityId: asset['entityId'] as string,
          level: asset['level'] as number,
          element: asset['element'] as string,
          rawJson: asset['rawJson'] as string
        };
        return gameAsset;
      });

      await RdbManager.replaceGameAssets(roleId, gameId, assets);
    } catch (error) {
      throw new Error(`Failed to process game assets: ${toErrorMessage(error)}`);
    }
  }
}

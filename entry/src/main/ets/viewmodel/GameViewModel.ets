/**
 * 游戏数据响应接口
 */
// export interface GameResponse {
//   data: Object;
//   code: number;
//   message: string;
// }

/**
 * 游戏数据 ViewModel
 * 处理游戏相关的网络请求和数据管理
 */
// export class GameViewModel {
//   private apiService = NetworkFactory.getInstance();
//
//   /**
//    * 获取原神角色列表
//    * @param uid 玩家 UID
//    * @returns Promise<GameResponse>
//    */
//   public async getGenshinCharacters(uid: string): Promise<GameResponse> {
//     try {
//       const response = await this.apiService.get<GameResponse>(
//         `/genshin/api/character/list`,
//         { uid },
//         ApiConfig.BaseUrlType.TAKUMI_RECORD
//       );
//       return response;
//     } catch (error) {
//       console.error('Failed to get genshin characters:', error);
//       throw error;
//     }
//   }
//
//   /**
//    * 获取崩坏星穹铁道角色列表
//    * @param uid 玩家 UID
//    * @returns Promise<GameResponse>
//    */
//   public async getHonkaiCharacters(uid: string): Promise<GameResponse> {
//     try {
//       const response = await this.apiService.get<GameResponse>(
//         `/honkai/api/character/list`,
//         { uid },
//         ApiConfig.BaseUrlType.TAKUMI_RECORD
//       );
//       return response;
//     } catch (error) {
//       console.error('Failed to get honkai characters:', error);
//       throw error;
//     }
//   }
//
//   /**
//    * 刷新游戏数据
//    * @param gameId 游戏 ID
//    * @param uid 玩家 UID
//    * @returns Promise<GameResponse>
//    */
//   public async refreshGameData(gameId: string, uid: string): Promise<GameResponse> {
//     try {
//       const response = await this.apiService.post<GameResponse>(
//         `/api/game/refresh`,
//         { gameId, uid },
//         ApiConfig.BaseUrlType.BBS_API
//       );
//       return response;
//     } catch (error) {
//       console.error('Failed to refresh game data:', error);
//       throw error;
//     }
//   }
// }

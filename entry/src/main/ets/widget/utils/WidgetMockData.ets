/**
 * WidgetMockData.ets — Widget Mock 数据
 *
 * 用于调试和测试，仅在数据为空时作为 fallback。
 * 生产环境不应依赖此数据。
 */

/**
 * 构建 Mock Payload
 *
 * 包含完整的原神便笺数据（含派遣头像、洞天宝钱等字段）
 * 用于验证数据链路是否正常工作
 */
export class WidgetMockData {
  /**
   * 构建 Mock Payload JSON 字符串
   */
  static buildPayload(): string {
    const rawJson = WidgetMockData.buildGenshinDailyNoteJson();
    const rawJsonEscaped = rawJson.replace(/"/g, '\\"');
    
    return '{"version":1,"updatedAt":' + Math.floor(Date.now() / 1000) + 
      ',"accounts":[{"accountId":"mock_account_1","accountName":"测试账号",' +
      '"games":[{"gameId":"genshin","roles":[{"roleId":"123456789",' +
      '"nickname":"旅行者","server":"cn_gf01","rawJson":"' + rawJsonEscaped + '"}]}]}]}';
  }

  /**
   * 构建原神便笺 Mock 数据
   */
  private static buildGenshinDailyNoteJson(): string {
    return '{"current_resin":152,"max_resin":200,"resin_recovery_time":"22825",' +
      '"finished_task_num":0,"total_task_num":4,"is_extra_task_reward_received":false,' +
      '"remain_resin_discount_num":3,"resin_discount_num_limit":3,' +
      '"current_expedition_num":5,"max_expedition_num":5,' +
      '"expeditions":[' +
      '{"avatar_side_icon":"https://fastcdn.mihoyo.com/static-resource-v2/2023/12/14/a273217a806ee130b0c0f51bc5542483_2404530785826539052.png","status":"Finished","remained_time":"0"},' +
      '{"avatar_side_icon":"https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f727/db95c5527a3b0f1a59743180e531be63.png","status":"Finished","remained_time":"0"},' +
      '{"avatar_side_icon":"https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f727/29021fd200fb4074bcb857668b406307.png","status":"Ongoing","remained_time":"12345"},' +
      '{"avatar_side_icon":"https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f727/2ad457efe47f31a54bd683286fd03144.png","status":"Ongoing","remained_time":"23456"},' +
      '{"avatar_side_icon":"https://act-webstatic.mihoyo.com/hk4e/e20200928calculate/item_icon/67c7f727/455ee1e4da29c15282faba8243bccdcc.png","status":"Ongoing","remained_time":"34567"}' +
      '],"current_home_coin":1230,"max_home_coin":2400,"home_coin_recovery_time":"139968",' +
      '"transformer":{"obtained":true,"recovery_time":{"Day":6,"Hour":0,"Minute":0,"Second":0,"reached":false}}}';
  }
}

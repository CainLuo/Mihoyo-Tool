/**
 * WidgetPreviewPayload.ets — 页面级 @Preview 的示例 payload
 *
 * 仅用于 DevEco Previewer：构造一份「单账号 + 原神单角色」的 payload，
 * 让 2×2 / 2×4 / 4×4 页面在预览器里直接显示真实布局，而不是空态。
 * 生产环境不会调用该文件。
 */

const GENSHIN_RAW_JSON: string =
  '{"current_resin":140,"max_resin":160,"resin_recovery_time":"16200",' +
    '"current_home_coin":1200,"max_home_coin":2400,' +
    '"finished_task_num":2,"total_task_num":4,' +
    '"expeditions":[{"status":"Finished"},{"status":"Finished"},{"status":"Ongoing"}]}';

/**
 * 构造预览 payload。
 *
 * @param updatedAtOffsetSec 数据时间距当前的秒数，默认 10 分钟前
 */
export function buildWidgetPreviewPayload(updatedAtOffsetSec: number = 600): string {
  const updatedAt: number = Math.floor(Date.now() / 1000) - updatedAtOffsetSec;
  return '{"version":2,"updatedAt":' + updatedAt + ',"widgetWidth":0,"widgetHeight":0,' +
    '"accounts":[{"accountId":"100000001","accountName":"预览账号","games":[' +
    '{"gameId":"genshin","roles":[{"roleId":"123456789","nickname":"旅行者",' +
    '"server":"天空岛","rawJson":' + JSON.stringify(GENSHIN_RAW_JSON) + '}]}]}]}';
}

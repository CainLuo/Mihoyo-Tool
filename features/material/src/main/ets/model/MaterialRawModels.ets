/**
 * MaterialRawModels.ets — 材料原始数据结构（跨页面共用）
 *
 * 材料计算页与材料汇总页都需要接收 Parser 返回的原始材料数组，
 * 此前两边各定义了一份完全相同的 `MaterialItemRaw`，这里统一为一份。
 */

/**
 * 材料项原始数据接口
 *
 * 注意：字段名使用驼峰命名，与 Parser 返回的字段名一致。
 *
 * 原神 API 返回 lack_num 字段，星铁/绝区零 API 不返回。
 */
export interface MaterialItemRaw {
  id: number | string;
  name: string;
  iconUrl: string;
  rarity: number | string;
  /** 从当前等级升到目标等级需要的总数量 */
  num: number;
  /** 缺少数量（原神专用，星铁/绝区零不使用此字段） */
  lackNum?: number;
}

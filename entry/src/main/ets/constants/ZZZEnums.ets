/**
 * ZZZEnums — 绝区零 API 返回值枚举
 *
 * 所有 ZZZ API 原始字符串值必须通过此文件的 enum 引用，
 * 禁止在业务代码中直接写 'SaleStateDone' 等字符串字面量。
 */

/** 录像店营业状态（对应 API 字段 vhs_sale.sale_state） */
export enum ZZZVideoStoreState {
  /** 已结算 */
  DONE = 'SaleStateDone',
  /** 营业中 */
  OPEN = 'SaleStateDoing',
  /** 未营业 */
  CLOSED = 'SaleStateNo',
  /** 未知/未获取 */
  UNKNOWN = '',
}

/** 刮刮卡/占卜状态（对应 API 字段 card_sign） */
export enum ZZZCardSign {
  /** 已完成 */
  DONE = 'CardSignDone',
  /** 未完成 */
  TODO = 'CardSignNo',
  /** 未知/未获取 */
  UNKNOWN = '',
}

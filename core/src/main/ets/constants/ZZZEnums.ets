/**
 * ZZZEnums — 绝区零 API 返回值枚举（字符串类型）
 *
 * 对应 ZZZDailyNoteRow 的 vhsSaleState 和 cardSign 字段。
 * 禁止在业务代码中直接写 'SaleStateDone' 等字符串字面量。
 * 转换函数在边界处（ViewModel）调用一次，之后全程使用 enum。
 */

/** 录像店营业状态（对应 API 字段 vhs_sale.sale_state） */
export enum ZZZVideoStoreState {
  /** 已结算 */
  DONE    = 'SaleStateDone',
  /** 营业中 */
  OPEN    = 'SaleStateDoing',
  /** 未营业 */
  CLOSED  = 'SaleStateNo',
  /** 未知/未获取 */
  UNKNOWN = '',
}

/** 刮刮卡/占卜状态（对应 API 字段 card_sign） */
export enum ZZZCardSign {
  /** 已完成 */
  DONE    = 'CardSignDone',
  /** 未完成 */
  TODO    = 'CardSignNo',
  /** 未知/未获取 */
  UNKNOWN = '',
}

/**
 * vhsSaleState 字符串 → ZZZVideoStoreState enum
 * 未知值返回 ZZZVideoStoreState.UNKNOWN
 */
export function zzzVideoStoreStateFromString(s: string): ZZZVideoStoreState {
  if (s === ZZZVideoStoreState.DONE)   { return ZZZVideoStoreState.DONE; }
  if (s === ZZZVideoStoreState.OPEN)   { return ZZZVideoStoreState.OPEN; }
  if (s === ZZZVideoStoreState.CLOSED) { return ZZZVideoStoreState.CLOSED; }
  return ZZZVideoStoreState.UNKNOWN;
}

/**
 * cardSign 字符串 → ZZZCardSign enum
 * 未知值返回 ZZZCardSign.UNKNOWN
 */
export function zzzCardSignFromString(s: string): ZZZCardSign {
  if (s === ZZZCardSign.DONE) { return ZZZCardSign.DONE; }
  if (s === ZZZCardSign.TODO) { return ZZZCardSign.TODO; }
  return ZZZCardSign.UNKNOWN;
}

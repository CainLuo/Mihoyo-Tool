/**
 * GenshinElement — 原神元素枚举
 *
 * API 返回的 element 字段为英文字符串（如 'Hydro'、'Pyro'）。
 * 禁止在任何组件或 ViewModel 中直接写元素字符串字面量。
 * 转换函数 genshinElementFromString() 在边界处（ViewModel）调用一次，之后全程使用 enum。
 */
export enum GenshinElement {
  /** 水元素 */
  HYDRO    = 'Hydro',
  /** 火元素 */
  PYRO     = 'Pyro',
  /** 雷元素 */
  ELECTRO  = 'Electro',
  /** 风元素 */
  ANEMO    = 'Anemo',
  /** 岩元素 */
  GEO      = 'Geo',
  /** 冰元素 */
  CRYO     = 'Cryo',
  /** 草元素 */
  DENDRO   = 'Dendro',
  /** 未知/无元素（API 返回空字符串时的兜底值） */
  UNKNOWN  = '',
}

/**
 * API element 字符串 → GenshinElement enum
 * 未知值返回 GenshinElement.UNKNOWN
 */
export function genshinElementFromString(s: string): GenshinElement {
  if (s === GenshinElement.HYDRO)   { return GenshinElement.HYDRO; }
  if (s === GenshinElement.PYRO)    { return GenshinElement.PYRO; }
  if (s === GenshinElement.ELECTRO) { return GenshinElement.ELECTRO; }
  if (s === GenshinElement.ANEMO)   { return GenshinElement.ANEMO; }
  if (s === GenshinElement.GEO)     { return GenshinElement.GEO; }
  if (s === GenshinElement.CRYO)    { return GenshinElement.CRYO; }
  if (s === GenshinElement.DENDRO)  { return GenshinElement.DENDRO; }
  return GenshinElement.UNKNOWN;
}

/**
 * GenshinElement — 原神元素枚举
 *
 * 禁止在任何组件或 ViewModel 中直接写元素字符串字面量（如 'Hydro'、'Pyro'）。
 * 所有元素判断必须使用此 enum，拼写错误会在编译期报错。
 *
 * 注意：API 返回的 element 字段为英文字符串，解析时用 GenshinElement.fromString() 转换。
 */
export enum GenshinElement {
  /** 水元素 */
  HYDRO = 'Hydro',
  /** 火元素 */
  PYRO = 'Pyro',
  /** 雷元素 */
  ELECTRO = 'Electro',
  /** 风元素 */
  ANEMO = 'Anemo',
  /** 岩元素 */
  GEO = 'Geo',
  /** 冰元素 */
  CRYO = 'Cryo',
  /** 草元素 */
  DENDRO = 'Dendro',
  /** 未知/无元素（API 返回空字符串时的兜底值） */
  UNKNOWN = '',
}

/** 将 API 返回的字符串转换为 GenshinElement enum */
export function elementFromString(s: string): GenshinElement {
  if (s === GenshinElement.HYDRO) { return GenshinElement.HYDRO; }
  if (s === GenshinElement.PYRO) { return GenshinElement.PYRO; }
  if (s === GenshinElement.ELECTRO) { return GenshinElement.ELECTRO; }
  if (s === GenshinElement.ANEMO) { return GenshinElement.ANEMO; }
  if (s === GenshinElement.GEO) { return GenshinElement.GEO; }
  if (s === GenshinElement.CRYO) { return GenshinElement.CRYO; }
  if (s === GenshinElement.DENDRO) { return GenshinElement.DENDRO; }
  return GenshinElement.UNKNOWN;
}

/** 根据元素枚举返回对应的 icon 资源 */
export function elementIcon(element: GenshinElement): Resource | null {
  if (element === GenshinElement.HYDRO)   { return $r('app.media.icn_element_hydro'); }
  if (element === GenshinElement.PYRO)    { return $r('app.media.icn_element_pyro'); }
  if (element === GenshinElement.ELECTRO) { return $r('app.media.icn_element_electro'); }
  if (element === GenshinElement.ANEMO)   { return $r('app.media.icn_element_anemo'); }
  if (element === GenshinElement.GEO)     { return $r('app.media.icn_element_geo'); }
  if (element === GenshinElement.CRYO)    { return $r('app.media.icn_element_cryo'); }
  if (element === GenshinElement.DENDRO)  { return $r('app.media.icn_element_dendro'); }
  return null;
}

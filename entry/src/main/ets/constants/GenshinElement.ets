/**
 * GenshinElement — 原神元素枚举（从 core 重新导出）+ 图标/颜色/标签工具函数
 *
 * enum 定义和转换函数在 core，此文件保留依赖 $r() 的图标、颜色、标签函数。
 */
import { GenshinElement } from 'core';
export { GenshinElement, genshinElementFromString } from 'core';

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

/** 根据元素字符串返回颜色资源 */
export function elementColor(element: string): Resource {
  if (element === GenshinElement.PYRO)    { return $r('app.color.element_pyro'); }
  if (element === GenshinElement.HYDRO)   { return $r('app.color.element_hydro'); }
  if (element === GenshinElement.ANEMO)   { return $r('app.color.element_anemo'); }
  if (element === GenshinElement.ELECTRO) { return $r('app.color.element_electro'); }
  if (element === GenshinElement.DENDRO)  { return $r('app.color.element_dendro'); }
  if (element === GenshinElement.CRYO)    { return $r('app.color.element_cryo'); }
  if (element === GenshinElement.GEO)     { return $r('app.color.element_geo'); }
  return $r('app.color.color_text_secondary');
}

/** 根据元素字符串返回多语言标签资源 */
export function elementLabel(element: string): Resource {
  if (element === GenshinElement.PYRO)    { return $r('app.string.character_element_Pyro'); }
  if (element === GenshinElement.HYDRO)   { return $r('app.string.character_element_Hydro'); }
  if (element === GenshinElement.ANEMO)   { return $r('app.string.character_element_Anemo'); }
  if (element === GenshinElement.ELECTRO) { return $r('app.string.character_element_Electro'); }
  if (element === GenshinElement.DENDRO)  { return $r('app.string.character_element_Dendro'); }
  if (element === GenshinElement.CRYO)    { return $r('app.string.character_element_Cryo'); }
  if (element === GenshinElement.GEO)     { return $r('app.string.character_element_Geo'); }
  return $r('app.string.character_element_Anemo');
}

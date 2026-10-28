/**
 * GenshinElement — 原神元素枚举（从 core 重新导出）+ 图标/颜色/标签工具函数
 *
 * enum 定义和转换函数在 core，此文件保留依赖 $r() 的图标、颜色、标签函数。
 */
import { GenshinElement } from 'core';
export { GenshinElement, genshinElementFromString } from 'core';

/** 根据元素枚举返回对应的 icon 资源 */
export function getGenshinElementIcon(element: GenshinElement): Resource | null {
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
export function getGenshinElementColor(element: string): Resource {
  if (element === GenshinElement.PYRO)    { return $r('app.color.element_pyro'); }
  if (element === GenshinElement.HYDRO)   { return $r('app.color.element_hydro'); }
  if (element === GenshinElement.ANEMO)   { return $r('app.color.element_anemo'); }
  if (element === GenshinElement.ELECTRO) { return $r('app.color.element_electro'); }
  if (element === GenshinElement.DENDRO)  { return $r('app.color.element_dendro'); }
  if (element === GenshinElement.CRYO)    { return $r('app.color.element_cryo'); }
  if (element === GenshinElement.GEO)     { return $r('app.color.element_geo'); }
  return $r('app.color.color_text_secondary');
}

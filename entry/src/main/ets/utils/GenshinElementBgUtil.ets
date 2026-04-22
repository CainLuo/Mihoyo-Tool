/**
 * GenshinElementBgUtil — 原神元素力背景渐变工具函数
 *
 * 三个立绘区组件（Wide/Portrait/Landscape）共用同一套元素背景色逻辑，
 * 仅渐变角度不同（Wide 用 a135，Portrait/Landscape 用 a150）。
 */
import { GenshinElement } from '../constants/GenshinElement';
import { Theme } from '../theme/AppTheme';

/**
 * 根据元素类型和渐变角度返回对应的背景渐变配置。
 * @param elem 原神元素枚举
 * @param t    当前主题 token
 * @param angle 渐变角度（使用 t.a135 或 t.a150）
 */
export function genshinElementBgGradient(elem: GenshinElement, t: Theme, angle: number): LinearGradient {
  if (elem === GenshinElement.HYDRO) {
    return { angle, colors: [[t.bgElementHydro1, 0], [t.bgElementHydro2, 0.5], [t.bgElementHydro3, 1.0]] };
  }
  if (elem === GenshinElement.PYRO) {
    return { angle, colors: [[t.bgElementPyro1, 0], [t.bgElementPyro2, 0.5], [t.bgElementPyro3, 1.0]] };
  }
  if (elem === GenshinElement.ELECTRO) {
    return { angle, colors: [[t.bgElementElectro1, 0], [t.bgElementElectro2, 0.5], [t.bgElementElectro3, 1.0]] };
  }
  if (elem === GenshinElement.ANEMO) {
    return { angle, colors: [[t.bgElementAnemo1, 0], [t.bgElementAnemo2, 0.5], [t.bgElementAnemo3, 1.0]] };
  }
  if (elem === GenshinElement.GEO) {
    return { angle, colors: [[t.bgElementGeo1, 0], [t.bgElementGeo2, 0.5], [t.bgElementGeo3, 1.0]] };
  }
  if (elem === GenshinElement.CRYO) {
    return { angle, colors: [[t.bgElementCryo1, 0], [t.bgElementCryo2, 0.5], [t.bgElementCryo3, 1.0]] };
  }
  if (elem === GenshinElement.DENDRO) {
    return { angle, colors: [[t.bgElementDendro1, 0], [t.bgElementDendro2, 0.5], [t.bgElementDendro3, 1.0]] };
  }
  return { angle, colors: [[t.bgPortrait1, 0], [t.bgPortrait2, 1.0]] };
}

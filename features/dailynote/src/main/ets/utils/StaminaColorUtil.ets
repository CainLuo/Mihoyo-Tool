/**
 * StaminaColorUtil — 体力/电量数值颜色
 *
 * 原神树脂、星铁开拓力、绝区零电量共用同一套阈值：
 * < 30% 危险色、< 70% 警告色、否则主色。
 */
import { ThemeManager } from 'basic'

export function getStaminaRatioColor(current: number, max: number, tm: ThemeManager): ResourceColor {
  if (max <= 0) {
    return tm.current.colorPrimary
  }
  const ratio = current / max
  if (ratio < 0.3) {
    return tm.current.colorDanger
  }
  if (ratio < 0.7) {
    return tm.current.colorWarning
  }
  return tm.current.colorPrimary
}

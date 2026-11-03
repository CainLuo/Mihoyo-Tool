/**
 * ExpeditionMapper — 原神 / 星铁派遣数据转换
 *
 * 两个游戏的派遣原始字段一致（avatarSideIcon / status / remainedTime），
 * 统一转换为 UI 使用的 ExpeditionVM。
 */
import { GenshinExpeditionData, StarRailExpeditionData } from 'core'
import { ExpeditionVM } from '../model/DailyNoteModels'

/** 原神 / 星铁派遣原始数据 */
export type ExpeditionSource = GenshinExpeditionData | StarRailExpeditionData

/** 将派遣原始数据转换为 UI 条目；remainedTime 为 "0" 或 status 为 Finished 视为已完成 */
export function toExpeditionVMs(raws: ExpeditionSource[]): ExpeditionVM[] {
  const result: ExpeditionVM[] = []
  for (const raw of raws) {
    const isFinished = raw.status === 'Finished' || raw.remainedTime === '0'
    const remainSeconds = parseInt(raw.remainedTime, 10) || 0
    result.push(new ExpeditionVM(raw.avatarSideIcon, remainSeconds, isFinished))
  }
  return result
}

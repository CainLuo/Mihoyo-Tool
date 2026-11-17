/**
 * DailyNoteLoader — 三游戏便笺详情页共用的加载流程
 *
 * 统一 LOADING / EMPTY / DATA / ERROR 状态流转与异常日志；
 * 各 ViewModel 只提供仓库读取与 Parser 转换。
 */
import { Logger } from 'core'
import { ViewState } from 'basic'

/** 加载结果：最终状态 + 解析后的 ViewModel（EMPTY / ERROR 时为 null） */
export class DailyNoteLoadResult<T> {
  viewState: ViewState = ViewState.LOADING
  note: T | null = null
}

/**
 * 读取 rawJson → Parser 解析 → 转换为 ViewModel。
 * @param tag 日志 TAG
 * @param readRawJson 读取数据库行，无数据时返回 null
 * @param parse 将 rawJson 转为 ViewModel
 */
export async function loadDailyNote<T>(
  tag: string,
  readRawJson: () => Promise<string | null>,
  parse: (rawJson: string) => T,
): Promise<DailyNoteLoadResult<T>> {
  const result = new DailyNoteLoadResult<T>()
  try {
    const rawJson = await readRawJson()
    if (rawJson === null) {
      result.viewState = ViewState.EMPTY
      return result
    }
    result.note = parse(rawJson)
    result.viewState = ViewState.DATA
  } catch (error) {
    const message = error instanceof Error ? error.message : `${error}`
    Logger.error(tag, `loadData failed: ${message}`)
    result.viewState = ViewState.ERROR
  }
  return result
}

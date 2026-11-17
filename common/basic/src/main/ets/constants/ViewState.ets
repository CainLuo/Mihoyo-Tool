/**
 * ViewStates — 页面 ViewModel 状态枚举
 *
 * 所有页面的 viewState 类型必须从此处引用，禁止在 ViewModel 中用字符串字面量 type。
 * 使用 enum 可避免拼写错误导致的状态判断失效。
 */

/** 通用三态（适用于大多数列表/详情页） */
export enum ViewState {
  /** 冷启动加载中，显示骨架屏 */
  LOADING = 'loading',
  /** 无数据，显示空态 Placeholder */
  EMPTY = 'empty',
  /** 有数据，正常展示 */
  DATA = 'data',
  /** 加载出错（部分页面使用） */
  ERROR = 'error',
}

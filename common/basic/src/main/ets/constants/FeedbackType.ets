/**
 * FeedbackType — 操作反馈类型枚举
 *
 * 用于 showFeedback 工具函数，决定 Snackbar 的图标和颜色。
 */
export enum FeedbackType {
  /** 操作成功，显示 ✓ 图标，颜色为 colorPrimary */
  SUCCESS = 'SUCCESS',
  /** 操作失败，显示 ✕ 图标，颜色为 colorDanger */
  ERROR = 'ERROR',
  /** 信息提示，显示 ℹ 图标，颜色为 colorPrimary */
  INFO = 'INFO',
}

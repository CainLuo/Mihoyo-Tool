/**
 * SnackbarParams — Snackbar 展示参数
 *
 * 携带展示所需的全部数据（类型、文案、图标、颜色），
 * 由 FeedbackUtil.showFeedback 填充后传给 SnackbarContent。
 */
import { FeedbackType } from '../constants/FeedbackType'
import { themeManager } from '../theme/ThemeManager'

export class SnackbarParams {
  type: FeedbackType = FeedbackType.INFO
  text: ResourceStr = ''
  onDismiss: () => void = () => {}

  /** 根据类型返回对应图标资源 */
  icon(): Resource {
    if (this.type === FeedbackType.SUCCESS) {
      return $r('sys.symbol.checkmark_circle')
    }
    if (this.type === FeedbackType.ERROR) {
      return $r('sys.symbol.xmark_circle')
    }
    return $r('sys.symbol.info_circle')
  }

  /** 根据类型返回对应颜色 */
  color(): ResourceColor {
    if (this.type === FeedbackType.ERROR) {
      return themeManager.current.colorDanger
    }
    return themeManager.current.colorPrimary
  }
}

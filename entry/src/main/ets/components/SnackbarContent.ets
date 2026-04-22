/**
 * SnackbarContent — 操作反馈 Snackbar 组件
 *
 * 纯渲染组件，通过 FeedbackUtil.showFeedback 调用。
 * 图标和颜色由 SnackbarParams 携带，组件只负责展示。
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { SnackbarParams } from '../models/SnackbarParams'
import { FeedbackType } from '../constants/FeedbackType'

@ComponentV2
export struct SnackbarContent {
  @Param params: SnackbarParams = new SnackbarParams()
  @Local private tm: ThemeManager = themeManager
  private timer: number = -1

  aboutToAppear(): void {
    const duration = this.params.type === FeedbackType.ERROR ? 4000 : 3000
    this.timer = setTimeout(() => {
      this.params.onDismiss()
    }, duration)
  }

  aboutToDisappear(): void {
    if (this.timer !== -1) {
      clearTimeout(this.timer)
      this.timer = -1
    }
  }

  build() {
    Row({ space: this.tm.current.value8 }) {
      SymbolGlyph(this.params.icon())
        .fontSize(this.tm.current.value20)
        .fontColor([this.params.color()])

      Text(this.params.text)
        .font(this.tm.current.body13)
        .fontColor(this.tm.current.colorTextPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .padding({
      left: this.tm.current.value16,
      right: this.tm.current.value16,
      top: this.tm.current.value12,
      bottom: this.tm.current.value12,
    })
    .margin({
      left: this.tm.current.value16,
      right: this.tm.current.value16,
      bottom: this.tm.current.value16,
    })
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .border({ width: this.tm.current.value1, color: this.tm.current.colorDivider })
    .borderRadius(this.tm.current.radius12)
    .shadow({ radius: this.tm.current.radius12, color: this.tm.current.colorMask, offsetX: 0, offsetY: 4 })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
struct SnackbarContentPreview {
  @Local private tm: ThemeManager = themeManager
  @Local private pSuccess: SnackbarParams = new SnackbarParams()
  @Local private pError: SnackbarParams = new SnackbarParams()
  @Local private pInfo: SnackbarParams = new SnackbarParams()

  aboutToAppear(): void {
    this.pSuccess.type = FeedbackType.SUCCESS
    this.pSuccess.text = '战绩数据已更新'
    this.pError.type = FeedbackType.ERROR
    this.pError.text = '刷新失败，请检查网络连接'
    this.pInfo.type = FeedbackType.INFO
    this.pInfo.text = '已释放 2.3 MB 缓存'
  }

  build() {
    Column({ space: this.tm.current.value12 }) {
      SnackbarContent({ params: this.pSuccess })

      SnackbarContent({ params: this.pError })

      SnackbarContent({ params: this.pInfo })
    }
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}

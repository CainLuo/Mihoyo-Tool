/**
 * SnackbarContent — 操作反馈 Snackbar 组件
 *
 * 通过 promptAction.openCustomDialog 渲染，显示在屏幕底部。
 * 根据 FeedbackType 显示对应图标和颜色，自动消失。
 */
import { FeedbackType } from '../constants/FeedbackType'
import { themeManager, ThemeManager } from '../theme/ThemeManager'

/** Snackbar 参数，由 showFeedback 工具函数填充 */
export class SnackbarParams {
  type: FeedbackType = FeedbackType.INFO
  text: ResourceStr = ''
  onDismiss: () => void = () => {}
}

@Builder
export function snackbarBuilder(params: SnackbarParams) {
  SnackbarContent({ params: params })
}

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

  private iconForType(): Resource {
    if (this.params.type === FeedbackType.SUCCESS) {
      return $r('sys.symbol.checkmark_circle')
    }
    if (this.params.type === FeedbackType.ERROR) {
      return $r('sys.symbol.xmark_circle')
    }
    return $r('sys.symbol.info_circle')
  }

  private colorForType(): ResourceColor {
    if (this.params.type === FeedbackType.ERROR) {
      return this.tm.current.colorDanger
    }
    return this.tm.current.colorPrimary
  }

  build() {
    Row({ space: this.tm.current.value8 }) {
      SymbolGlyph(this.iconForType())
        .fontSize(this.tm.current.value20)
        .fontColor([this.colorForType()])
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
    .border({ width: 1, color: this.tm.current.colorDivider })
    .borderRadius(this.tm.current.radius12)
    .shadow({ radius: this.tm.current.radius12, color: this.tm.current.colorMask, offsetX: 0, offsetY: 4 })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
struct SnackbarSuccessPreview {
  build() {
    Column({ space: 12 }) {
      SnackbarContent({ params: (() => {
        const p = new SnackbarParams()
        p.type = FeedbackType.SUCCESS
        p.text = '战绩数据已更新'
        return p
      })() })
      SnackbarContent({ params: (() => {
        const p = new SnackbarParams()
        p.type = FeedbackType.ERROR
        p.text = '刷新失败，请检查网络连接'
        return p
      })() })
      SnackbarContent({ params: (() => {
        const p = new SnackbarParams()
        p.type = FeedbackType.INFO
        p.text = '已释放 2.3 MB 缓存'
        return p
      })() })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}

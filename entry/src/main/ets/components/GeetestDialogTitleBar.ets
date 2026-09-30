/**
 * GeetestDialogTitleBar — Geetest 弹窗标题栏（标题 + 进度 + 关闭按钮）
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { ThemeFonts } from '../theme/ThemeFonts'
import { GeetestProgress } from './GeetestDialogHelper'

@ComponentV2
export struct GeetestDialogTitleBar {
  @Param onClose: () => void = () => {}
  /** 队列进度（可选，用于显示 "验证中 (1/3)"） */
  @Param progress: GeetestProgress | null = null
  /** 账号名（可选，用于 UI 显示） */
  @Param accountName: string = ''
  @Local private tm: ThemeManager = themeManager

  build() {
    Column() {
      Row() {
        // 标题区域
        Column() {
          Text($r('app.string.geetest_dialog_title'))
            .font(ThemeFonts.fontMedium17)
            .fontColor(this.tm.current.colorTextPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 进度和账号名信息
          if (this.progress !== null || this.accountName !== '') {
            Row({ space: this.tm.current.value8 }) {
              if (this.progress !== null && this.progress.total > 1) {
                Text($r('app.string.geetest_progress_format', this.progress.current, this.progress.total))
                  .font(ThemeFonts.font13)
                  .fontColor(this.tm.current.colorTextSecondary)
              }

              if (this.accountName !== '') {
                Text(this.accountName)
                  .font(ThemeFonts.font13)
                  .fontColor(this.tm.current.colorTextSecondary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
              }
            }
            .width(this.tm.current.full)
            .margin({ top: this.tm.current.value4 })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 关闭按钮
        Button({ type: ButtonType.Circle }) {
          Text($r('app.string.geetest_dialog_close'))
            .font(ThemeFonts.fontBold18)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .width(this.tm.current.value56)
        .height(this.tm.current.value56)
        .backgroundColor(Color.Transparent)
        .onClick(() => { this.onClose() })
      }
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.font16,
        right: this.tm.current.value8,
        top: this.tm.current.value12,
        bottom: this.tm.current.value12
      })
    }
    .width(this.tm.current.full)
  }
}

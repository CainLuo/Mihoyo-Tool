/**
 * WidgetSettingsBottomButtons — Widget 配置页底部按钮组件
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { WidgetConfigStep } from '../../viewmodel/WidgetConfigViewModel';

@ComponentV2
export struct WidgetSettingsBottomButtons {
  @Local private tm: ThemeManager = themeManager;
  /** 当前步骤 */
  @Param currentStep: WidgetConfigStep = WidgetConfigStep.SIZE;
  /** 是否可以后退 */
  @Param canGoPrev: boolean = false;
  /** 是否可以前进 */
  @Param canGoNext: boolean = true;
  /** 后退回调 */
  @Param onPrev: () => void = () => {};
  /** 前进回调 */
  @Param onNext: () => void = () => {};
  /** 完成回调 */
  @Param onComplete: () => void = () => {};

  build() {
    Row({ space: this.tm.current.value10 }) {
      if (this.canGoPrev) {
        Button($r('app.string.widget_btn_prev'))
          .height(this.tm.current.value44)
          .layoutWeight(1)
          .fontSize(this.tm.current.font14)
          .fontColor(this.tm.current.colorTextPrimary)
          .backgroundColor(this.tm.current.colorSurfaceCard)
          .border({ width: this.tm.current.value1, color: this.tm.current.colorDivider })
          .borderRadius(this.tm.current.radius12)
          .onClick(() => { this.onPrev(); })
      }

      if (this.currentStep === WidgetConfigStep.DONE) {
        Button($r('app.string.widget_btn_add'))
          .height(this.tm.current.value44)
          .layoutWeight(2)
          .fontSize(this.tm.current.fontBold14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor(this.tm.current.colorPrimary)
          .borderRadius(this.tm.current.radius12)
          .onClick(() => { this.onComplete(); })
      } else {
        Button($r('app.string.widget_btn_next'))
          .height(this.tm.current.value44)
          .layoutWeight(2)
          .fontSize(this.tm.current.fontBold14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor(this.tm.current.colorPrimary)
          .borderRadius(this.tm.current.radius12)
          .enabled(this.canGoNext)
          .opacity(this.canGoNext ? 1 : 0.5)
          .onClick(() => { this.onNext(); })
      }
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.font16,
      right: this.tm.current.font16,
      top: this.tm.current.value12,
      bottom: this.tm.current.font24
    })
  }
}

@Preview
@ComponentV2
struct WidgetSettingsBottomButtonsPreview {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value10 }) {
      WidgetSettingsBottomButtons({
        currentStep: WidgetConfigStep.SIZE,
        canGoPrev: false,
        canGoNext: true
      })
      WidgetSettingsBottomButtons({
        currentStep: WidgetConfigStep.SLOT,
        canGoPrev: true,
        canGoNext: true
      })
      WidgetSettingsBottomButtons({
        currentStep: WidgetConfigStep.DONE,
        canGoPrev: true,
        canGoNext: false
      })
    }
    .backgroundColor('#1a1a2e')
  }
}

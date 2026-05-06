/**
 * WidgetStepIndicator — 紧凑步骤指示器
 *
 * 只显示圆点+连接线，不显示文字标签，节省空间。
 * 新流程：SIZE → SLOT → DONE（3 步）
 *
 * 适配 Light/Dark Mode：未激活圆圈使用半透明边框，确保浅色模式下可见。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { WidgetConfigStep } from '../../viewmodel/WidgetConfigViewModel';

const STEP_COUNT = 3;

@ComponentV2
export struct WidgetStepIndicator {
  @Param currentStep: WidgetConfigStep = WidgetConfigStep.SIZE;
  @Local private tm: ThemeManager = themeManager;

  private get currentStepIndex(): number {
    const stepOrder = [WidgetConfigStep.SIZE, WidgetConfigStep.SLOT, WidgetConfigStep.DONE];
    return stepOrder.indexOf(this.currentStep);
  }

  build() {
    Row({ space: this.tm.current.value8 }) {
      ForEach(Array.from({ length: STEP_COUNT }), (_: Object, idx: number) => {
        Row() {
          if (this.isStepDone(idx)) {
            Text('✓')
              .fontSize(10)
              .fontColor(Color.White)
          }
        }
        .width(this.tm.current.value20)
        .height(this.tm.current.value20)
        .borderRadius(this.tm.current.value10)
        .backgroundColor(this.isStepDone(idx) || this.isCurrentStep(idx) ?
          this.tm.current.colorPrimary : Color.Transparent)
        .border({
          width: 2,
          color: this.isStepDone(idx) || this.isCurrentStep(idx) ?
            this.tm.current.colorPrimary : 'rgba(255, 255, 255, 0.3)'
        })
        .justifyContent(FlexAlign.Center)
      }, (_: Object, idx: number) => `step-${idx}`)
    }
    .width(this.tm.current.full)
    .justifyContent(FlexAlign.Center)
    .margin({ top: this.tm.current.value8, bottom: this.tm.current.value12 })
  }

  private isCurrentStep(stepIdx: number): boolean {
    return stepIdx === this.currentStepIndex;
  }

  private isStepDone(stepIdx: number): boolean {
    return stepIdx < this.currentStepIndex;
  }
}

@Preview
@ComponentV2
export struct WidgetStepIndicatorPreview {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: 24 }) {
      WidgetStepIndicator({ currentStep: WidgetConfigStep.SIZE })
      WidgetStepIndicator({ currentStep: WidgetConfigStep.SLOT })
      WidgetStepIndicator({ currentStep: WidgetConfigStep.DONE })
    }
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}

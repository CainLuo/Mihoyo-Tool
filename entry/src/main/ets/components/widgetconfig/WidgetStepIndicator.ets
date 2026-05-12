/**
 * WidgetStepIndicator — 紧凑步骤指示器
 *
 * 只显示圆点+连接线，不显示文字标签，节省空间。
 *
 * 流程：
 * - 1x2 卡片：SIZE → GAME → SLOT → DONE（4 步）
 * - 其他尺寸：SIZE → SLOT → DONE（3 步）
 *
 * 适配 Light/Dark Mode：未激活圆圈使用半透明边框，确保浅色模式下可见。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { WidgetConfigStep } from '../../viewmodel/WidgetConfigViewModel';
import { WidgetSize } from '../../widget/models/WidgetConfig';

@ComponentV2
export struct WidgetStepIndicator {
  @Param currentStep: WidgetConfigStep = WidgetConfigStep.SIZE;
  @Param selectedSize: WidgetSize = WidgetSize.SIZE_2x2;
  @Local private tm: ThemeManager = themeManager;

  private get stepCount(): number {
    // 1x2 卡片有 4 步，其他尺寸有 3 步
    return this.selectedSize === WidgetSize.SIZE_1x2 ? 4 : 3;
  }

  private get currentStepIndex(): number {
    if (this.selectedSize === WidgetSize.SIZE_1x2) {
      const stepOrder1x2 = [WidgetConfigStep.SIZE, WidgetConfigStep.GAME, WidgetConfigStep.SLOT, WidgetConfigStep.DONE];
      return stepOrder1x2.indexOf(this.currentStep);
    }
    const stepOrderOther = [WidgetConfigStep.SIZE, WidgetConfigStep.SLOT, WidgetConfigStep.DONE];
    return stepOrderOther.indexOf(this.currentStep);
  }

  build() {
    Row({ space: this.tm.current.value8 }) {
      ForEach(Array.from({ length: this.stepCount }), (_: Object, idx: number) => {
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
      WidgetStepIndicator({ currentStep: WidgetConfigStep.SIZE, selectedSize: WidgetSize.SIZE_2x2 })
      WidgetStepIndicator({ currentStep: WidgetConfigStep.SLOT, selectedSize: WidgetSize.SIZE_2x2 })
      WidgetStepIndicator({ currentStep: WidgetConfigStep.GAME, selectedSize: WidgetSize.SIZE_1x2 })
      WidgetStepIndicator({ currentStep: WidgetConfigStep.DONE, selectedSize: WidgetSize.SIZE_1x2 })
    }
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}

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
import { themeManager, ThemeManager } from 'basic';
import { WidgetSettingsStep } from '../viewmodel/WidgetSettingsViewModel';
import { WidgetSize } from '../model/WidgetConfigModels';

@ComponentV2
export struct WidgetStepIndicator {
  @Param currentStep: WidgetSettingsStep = WidgetSettingsStep.SIZE;
  @Param selectedSize: WidgetSize = WidgetSize.SIZE_2X2;
  @Local private tm: ThemeManager = themeManager;

  private get stepCount(): number {
    // 1x2 卡片有 4 步，其他尺寸有 3 步
    return this.selectedSize === WidgetSize.SIZE_1X2 ? 4 : 3;
  }

  private get currentStepIndex(): number {
    if (this.selectedSize === WidgetSize.SIZE_1X2) {
      const stepOrder1x2 = [WidgetSettingsStep.SIZE, WidgetSettingsStep.GAME, WidgetSettingsStep.SLOT, WidgetSettingsStep.DONE];
      return stepOrder1x2.indexOf(this.currentStep);
    }
    const stepOrderOther = [WidgetSettingsStep.SIZE, WidgetSettingsStep.SLOT, WidgetSettingsStep.DONE];
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
        .width(this.tm.current.font20)
        .height(this.tm.current.font20)
        .borderRadius(this.tm.current.value10)
        .backgroundColor(this.isStepDone(idx) || this.isCurrentStep(idx) ?
          this.tm.current.colorPrimary : this.tm.current.colorSurfaceCard)
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
    // DONE 步骤时，所有圆圈都显示勾（包括当前步骤）
    if (this.currentStep === WidgetSettingsStep.DONE) {
      return true;
    }
    // 其他步骤：只有已完成的步骤显示勾
    return stepIdx < this.currentStepIndex;
  }
}

@Preview
@ComponentV2
export struct WidgetStepIndicatorPreview {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: 24 }) {
      WidgetStepIndicator({ currentStep: WidgetSettingsStep.SIZE, selectedSize: WidgetSize.SIZE_2X2 })
      WidgetStepIndicator({ currentStep: WidgetSettingsStep.SLOT, selectedSize: WidgetSize.SIZE_2X2 })
      WidgetStepIndicator({ currentStep: WidgetSettingsStep.GAME, selectedSize: WidgetSize.SIZE_1X2 })
      WidgetStepIndicator({ currentStep: WidgetSettingsStep.DONE, selectedSize: WidgetSize.SIZE_1X2 })
    }
    .padding(this.tm.current.font16)
    .backgroundColor('#1a1a2e')
  }
}

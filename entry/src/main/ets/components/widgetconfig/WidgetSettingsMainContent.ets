/**
 * WidgetSettingsMainContent — Widget 配置页主要内容区域
 *
 * 包含：卡片预览、步骤指示器、步骤内容、底部按钮
 *
 * 参数说明：
 * - state: UI State 对象，包含所有渲染数据
 * - callbacks: 回调函数集合
 * - slotHelper: Slot 相关辅助方法
 */
import { ThemeManager, themeManager } from '../../theme/ThemeManager';
import { WidgetSettingsUIState, WidgetSettingsCallbacks, WidgetSettingsSlotHelper, WidgetConfigStep } from '../../models/WidgetSettingsModels';
import { WidgetStepIndicator } from './WidgetStepIndicator';
import { WidgetConfigDone } from './WidgetConfigDone';
import { WidgetConfigPreview } from './WidgetConfigPreview';
import { WidgetSettingsSizeStep } from './WidgetSettingsSizeStep';
import { WidgetSettingsGameStep } from './WidgetSettingsGameStep';
import { WidgetSettingsSlotStep } from './WidgetSettingsSlotStep';
import { WidgetSettingsBottomButtons } from './WidgetSettingsBottomButtons';

@ComponentV2
export struct WidgetSettingsMainContent {
  /** UI State 对象 */
  @Param state: WidgetSettingsUIState = new WidgetSettingsUIState();
  /** 回调函数集合 */
  @Param callbacks: WidgetSettingsCallbacks = new WidgetSettingsCallbacks();
  /** Slot 辅助方法 */
  @Param slotHelper: WidgetSettingsSlotHelper = new WidgetSettingsSlotHelper();

  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      Scroll() {
        Column() {
          // 卡片预览
          Column() {
            WidgetConfigPreview({
              selectedSize: this.state.selectedSize,
              selectedSlots: this.state.selectedSlots
            })
          }
          .width(this.tm.current.full)
          .padding({ top: this.tm.current.font16, bottom: this.tm.current.font16 })
          .justifyContent(FlexAlign.Center)

          // 步骤指示器
          WidgetStepIndicator({
            currentStep: this.state.currentStep,
            selectedSize: this.state.selectedSize
          })

          // 步骤内容
          if (this.state.currentStep === WidgetConfigStep.SLOT) {
            // SLOT 步骤：不加 padding，让组件自己管理（和首页战绩工具一致）
            WidgetSettingsSlotStep({
              selectedSize: this.state.selectedSize,
              allSlots: this.state.allSlots,
              accountGroups: this.state.accountGroups,
              selectedSlots: this.state.selectedSlots,
              maxSlots: this.state.maxSlots,
              isSlotSelected: this.slotHelper.isSlotSelected,
              onSlotToggle: this.callbacks.onSlotToggle
            })
          } else {
            // 其他步骤：统一加 padding
            Column() {
              if (this.state.currentStep === WidgetConfigStep.SIZE) {
                WidgetSettingsSizeStep({
                  selectedSize: this.state.selectedSize,
                  onSizeSelect: this.callbacks.onSizeSelect
                })
              } else if (this.state.currentStep === WidgetConfigStep.GAME) {
                WidgetSettingsGameStep({
                  selectedGameType: this.state.selectedGameType,
                  getSlotsForGame: this.slotHelper.getSlotsForGame,
                  hasDataForGame: this.slotHelper.hasDataForGame,
                  onGameSelect: this.callbacks.onGameSelect
                })
              } else if (this.state.currentStep === WidgetConfigStep.DONE) {
                WidgetConfigDone({
                  selectedSize: this.state.selectedSize,
                  selectedSummary: this.state.selectedSummary
                })
              }
            }
            .width(this.tm.current.full)
            .padding({ left: this.tm.current.font16, right: this.tm.current.font16 })
          }
        }
        .width(this.tm.current.full)
      }
      .scrollBar(BarState.Off)
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .layoutWeight(1)
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor(this.tm.current.colorPageBg)

      // 底部按钮
      WidgetSettingsBottomButtons({
        currentStep: this.state.currentStep,
        canGoPrev: this.state.canGoPrev,
        canGoNext: this.state.canGoNext,
        onPrev: this.callbacks.onPrev,
        onNext: this.callbacks.onNext,
        onComplete: this.callbacks.onComplete
      })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
  }
}

@Preview
@ComponentV2
export struct WidgetSettingsMainContentPreview {
  @Local private tm: ThemeManager = themeManager;
  @Local private state: WidgetSettingsUIState = new WidgetSettingsUIState();

  build() {
    Column() {
      WidgetSettingsMainContent({
        state: this.state,
        callbacks: new WidgetSettingsCallbacks(),
        slotHelper: new WidgetSettingsSlotHelper()
      })
    }
    .width(this.tm.current.value360)
    .height(this.tm.current.value600)
    .backgroundColor('#1a1a2e')
  }
}

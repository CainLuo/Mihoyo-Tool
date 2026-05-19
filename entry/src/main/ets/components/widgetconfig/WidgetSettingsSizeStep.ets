/**
 * WidgetSettingsSizeStep — Widget 配置步骤 1：卡片尺寸选择
 */
import { ThemeManager, themeManager } from '../../theme/ThemeManager';
import { WidgetSize } from '../../widget/models/WidgetConfig';
import { WidgetSizeOption, SizeConfig } from './WidgetSizeOption';

/** 尺寸配置列表 */
const SIZE_CONFIGS: SizeConfig[] = [
  { size: WidgetSize.SIZE_1x2, label: $r('app.string.widget_size_1x2'), desc: $r('app.string.widget_size_1x2_desc') },
  { size: WidgetSize.SIZE_2x2, label: $r('app.string.widget_size_2x2'), desc: $r('app.string.widget_size_2x2_desc') },
  { size: WidgetSize.SIZE_2x4, label: $r('app.string.widget_size_2x4'), desc: $r('app.string.widget_size_2x4_desc') },
  { size: WidgetSize.SIZE_4x4, label: $r('app.string.widget_size_4x4'), desc: $r('app.string.widget_size_4x4_desc') },
];

@ComponentV2
export struct WidgetSettingsSizeStep {
  @Param selectedSize: WidgetSize = WidgetSize.SIZE_2x2;
  @Param onSizeSelect: (size: WidgetSize) => void = (_size: WidgetSize) => {};

  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value10 }) {
      ForEach(SIZE_CONFIGS, (config: SizeConfig) => {
        WidgetSizeOption({
          config: config,
          isSelected: this.selectedSize === config.size,
          onTap: () => { this.onSizeSelect(config.size); }
        })
      }, (config: SizeConfig) => config.size)
    }
    .width(this.tm.current.full)
  }
}

@Preview
@ComponentV2
export struct WidgetSettingsSizeStepPreview {
  @Local private tm: ThemeManager = themeManager;
  @Local private selectedSize: WidgetSize = WidgetSize.SIZE_2x2;

  build() {
    Column() {
      WidgetSettingsSizeStep({
        selectedSize: this.selectedSize,
        onSizeSelect: (size: WidgetSize) => { this.selectedSize = size; }
      })
    }
    .width(this.tm.current.value360)
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}

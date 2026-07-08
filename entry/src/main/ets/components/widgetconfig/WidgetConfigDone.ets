/**
 * WidgetConfigDone — 步骤 3：配置完成
 *
 * 仅显示配置摘要。卡片预览由 WidgetSettings 页面顶部统一渲染。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { WidgetSize } from '../../widget/models/WidgetConfig';

/** 尺寸标签映射 */
const SIZE_LABELS: Record<string, ResourceStr> = {
  [WidgetSize.SIZE_1x2]: $r('app.string.widget_size_1x2'),
  [WidgetSize.SIZE_2x2]: $r('app.string.widget_size_2x2'),
  [WidgetSize.SIZE_2x4]: $r('app.string.widget_size_2x4'),
  [WidgetSize.SIZE_4x4]: $r('app.string.widget_size_4x4'),
};

@ComponentV2
export struct WidgetConfigDone {
  @Param selectedSize: WidgetSize = WidgetSize.SIZE_2x2;
  @Param selectedSummary: string = '';
  @Local private tm: ThemeManager = themeManager;

  private get sizeLabel(): ResourceStr {
    const label = SIZE_LABELS[this.selectedSize];
    return label !== undefined ? label : '';
  }

  build() {
    Column({ space: this.tm.current.font16 }) {
      // 完成图标
      Text('🎉')
        .fontSize(32)

      // 完成文字
      Text($r('app.string.widget_config_done_title'))
        .fontSize(this.tm.current.font17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tm.current.colorTextPrimary)

      Text($r('app.string.widget_config_done_desc'))
        .fontSize(this.tm.current.font13)
        .fontColor(this.tm.current.colorTextSecondary)

      // 配置摘要
      Column({ space: this.tm.current.value10 }) {
        WidgetConfigSummaryRow({
          label: $r('app.string.widget_summary_size'),
          value: this.sizeLabel
        })
        WidgetConfigSummaryRow({
          label: $r('app.string.widget_summary_roles'),
          value: this.selectedSummary
        })
      }
      .width(this.tm.current.full)
      .padding(this.tm.current.font14)
      .backgroundColor(this.tm.current.colorSurfaceCard)
      .borderRadius(this.tm.current.radius12)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: this.tm.current.value8, bottom: this.tm.current.font20 })
  }
}

/**
 * WidgetConfigSummaryRow — 配置摘要行
 */
@ComponentV2
struct WidgetConfigSummaryRow {
  @Param label: ResourceStr = '';
  @Param value: string | ResourceStr = '';
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row() {
      // 左侧标签：固定宽度
      Text(this.label)
        .fontSize(this.tm.current.font14)
        .fontColor(this.tm.current.colorTextSecondary)
        .width(this.tm.current.value80)
        .flexShrink(0)

      // 右侧值：可换行、可滚动
      Text(this.value)
        .fontSize(this.tm.current.font14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tm.current.colorTextPrimary)
        .layoutWeight(1)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.End)
    }
    .width(this.tm.current.full)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Top)
  }
}

@Preview
@ComponentV2
export struct WidgetConfigDonePreview {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: 16 }) {
      WidgetConfigDone({
        selectedSize: WidgetSize.SIZE_2x2,
        selectedSummary: '荧 (原神)、开拓者 (崩坏：星穹铁道)'
      })
    }
    .padding(this.tm.current.font16)
    .backgroundColor('#1a1a2e')
  }
}

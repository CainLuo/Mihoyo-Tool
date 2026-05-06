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

  build() {
    Column({ space: this.tm.current.value16 }) {
      // 完成图标
      Text('🎉')
        .fontSize(32)

      // 完成文字
      Text($r('app.string.widget_config_done_title'))
        .fontSize(this.tm.current.body16.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tm.current.colorTextPrimary)

      Text($r('app.string.widget_config_done_desc'))
        .fontSize(this.tm.current.body12.size)
        .fontColor(this.tm.current.colorTextSecondary)

      // 配置摘要
      Column({ space: this.tm.current.value10 }) {
        this.SummaryRow('尺寸', SIZE_LABELS[this.selectedSize])
        this.SummaryRow('已选角色', this.selectedSummary)
      }
      .width(this.tm.current.full)
      .padding(this.tm.current.value14)
      .backgroundColor(this.tm.current.colorSurfaceSubtle)
      .borderRadius(this.tm.current.radius12)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: this.tm.current.value8, bottom: this.tm.current.value20 })
  }

  @Builder
  SummaryRow(label: ResourceStr, value: string | ResourceStr) {
    Row() {
      Text(label)
        .fontSize(this.tm.current.body13.size)
        .fontColor(this.tm.current.colorTextSecondary)
        .layoutWeight(1)

      Text(typeof value === 'string' ? value : '')
        .fontSize(this.tm.current.body13.size)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tm.current.colorTextPrimary)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.End)
    }
    .width(this.tm.current.full)
    .justifyContent(FlexAlign.SpaceBetween)
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
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}

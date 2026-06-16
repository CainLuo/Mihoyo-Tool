/**
 * WidgetSizeOption — 卡片尺寸选项组件
 *
 * 用于 Widget 配置页的步骤 1，展示可选的卡片尺寸。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { WidgetSize } from '../../widget/models/WidgetConfig';

/** 尺寸配置 */
export interface SizeConfig {
  size: WidgetSize;
  label: ResourceStr;
  desc: ResourceStr;
}

@ComponentV2
export struct WidgetSizeOption {
  @Local private tm: ThemeManager = themeManager;
  /** 尺寸配置 */
  @Param config: SizeConfig = { size: WidgetSize.SIZE_2x2, label: '', desc: '' };
  /** 是否选中 */
  @Param isSelected: boolean = false;
  /** 点击回调 */
  @Param onTap: () => void = () => {};

  build() {
    Row() {
      this.SizeThumb()

      Column() {
        Text(this.config.label)
          .fontSize(this.tm.current.fontBold14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isSelected ? this.tm.current.colorPrimary : this.tm.current.colorTextPrimary)

        Text(this.config.desc)
          .fontSize(this.tm.current.font13)
          .fontColor(this.tm.current.colorTextSecondary)
          .margin({ top: this.tm.current.value2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: this.tm.current.value12 })

      if (this.isSelected) {
        Row() {
          Text('✓')
            .fontSize(this.tm.current.font13)
            .fontColor(Color.White)
        }
        .width(this.tm.current.font18)
        .height(this.tm.current.font18)
        .borderRadius(this.tm.current.value9)
        .backgroundColor(this.tm.current.colorPrimary)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.font14)
    .backgroundColor(this.isSelected ? '#263A6FD8' : this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .border({
      width: this.tm.current.value2,
      color: this.isSelected ? this.tm.current.colorPrimary : this.tm.current.colorDivider
    })
    .onClick(() => { this.onTap(); })
  }

  @Builder
  SizeThumb() {
    Column() {
      if (this.config.size === WidgetSize.SIZE_1x2) {
        this.Thumb1x2()
      } else if (this.config.size === WidgetSize.SIZE_2x2) {
        this.Thumb2x2()
      } else if (this.config.size === WidgetSize.SIZE_2x4) {
        this.Thumb2x4()
      } else {
        this.Thumb4x4()
      }
    }
    .width(this.tm.current.value40)
    .height(this.tm.current.value40)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  Thumb1x2() {
    Row({ space: this.tm.current.value2 }) {
      Column().width(this.tm.current.value10).height(this.tm.current.value10).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
      Column().width(this.tm.current.value10).height(this.tm.current.value10).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
    }
  }

  @Builder
  Thumb2x2() {
    Column({ space: this.tm.current.value2 }) {
      Row({ space: this.tm.current.value2 }) {
        Column().width(this.tm.current.value10).height(this.tm.current.value10).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value10).height(this.tm.current.value10).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
      }
      Row({ space: this.tm.current.value2 }) {
        Column().width(this.tm.current.value10).height(this.tm.current.value10).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value10).height(this.tm.current.value10).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
      }
    }
  }

  @Builder
  Thumb2x4() {
    Column({ space: this.tm.current.value2 }) {
      Row({ space: this.tm.current.value2 }) {
        Column().width(this.tm.current.value8).height(this.tm.current.value10).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value8).height(this.tm.current.value10).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value8).height(this.tm.current.value10).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value8).height(this.tm.current.value10).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
      }
      Row({ space: this.tm.current.value2 }) {
        Column().width(this.tm.current.value8).height(this.tm.current.value10).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value8).height(this.tm.current.value10).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value8).height(this.tm.current.value10).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value8).height(this.tm.current.value10).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
      }
    }
  }

  @Builder
  Thumb4x4() {
    Column({ space: this.tm.current.value2 }) {
      Row({ space: this.tm.current.value2 }) {
        Column().width(this.tm.current.value8).height(this.tm.current.value8).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value8).height(this.tm.current.value8).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value8).height(this.tm.current.value8).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value8).height(this.tm.current.value8).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
      }
      Row({ space: this.tm.current.value2 }) {
        Column().width(this.tm.current.value8).height(this.tm.current.value8).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value8).height(this.tm.current.value8).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value8).height(this.tm.current.value8).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value8).height(this.tm.current.value8).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
      }
      Row({ space: this.tm.current.value2 }) {
        Column().width(this.tm.current.value8).height(this.tm.current.value8).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value8).height(this.tm.current.value8).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value8).height(this.tm.current.value8).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value8).height(this.tm.current.value8).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
      }
      Row({ space: this.tm.current.value2 }) {
        Column().width(this.tm.current.value8).height(this.tm.current.value8).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value8).height(this.tm.current.value8).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value8).height(this.tm.current.value8).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
        Column().width(this.tm.current.value8).height(this.tm.current.value8).backgroundColor(this.thumbColor).borderRadius(this.tm.current.radius8)
      }
    }
  }

  private get thumbColor(): ResourceColor {
    return this.isSelected ? this.tm.current.colorPrimary : this.tm.current.colorTextSecondary;
  }
}

@Preview
@ComponentV2
struct WidgetSizeOptionPreview {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value10 }) {
      WidgetSizeOption({
        config: { size: WidgetSize.SIZE_1x2, label: $r('app.string.widget_size_1x2'), desc: $r('app.string.widget_size_1x2_desc') },
        isSelected: false
      })
      WidgetSizeOption({
        config: { size: WidgetSize.SIZE_2x2, label: $r('app.string.widget_size_2x2'), desc: $r('app.string.widget_size_2x2_desc') },
        isSelected: true
      })
    }
    .padding(this.tm.current.font16)
    .backgroundColor('#1a1a2e')
  }
}

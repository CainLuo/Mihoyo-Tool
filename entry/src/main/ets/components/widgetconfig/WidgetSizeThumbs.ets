/**
 * WidgetSizeThumbs — 卡片尺寸缩略图组件
 *
 * 用于 Widget 配置页展示不同尺寸的缩略图预览。
 */
import { ThemeManager, themeManager } from '../../theme/ThemeManager';
import { WidgetSize } from '../../widget/models/WidgetConfig';

/**
 * 1×2 缩略图
 */
@ComponentV2
export struct WidgetThumb1x2 {
  @Local private tm: ThemeManager = themeManager;
  @Param thumbColor: ResourceColor = Color.White;

  build() {
    Row({ space: this.tm.current.value2 }) {
      Column()
        .width(this.tm.current.value10)
        .height(this.tm.current.value10)
        .backgroundColor(this.thumbColor)
        .borderRadius(this.tm.current.radius8)

      Column()
        .width(this.tm.current.value10)
        .height(this.tm.current.value10)
        .backgroundColor(this.thumbColor)
        .borderRadius(this.tm.current.radius8)
    }
  }
}

/**
 * 2×2 缩略图
 */
@ComponentV2
export struct WidgetThumb2x2 {
  @Local private tm: ThemeManager = themeManager;
  @Param thumbColor: ResourceColor = Color.White;

  build() {
    Column({ space: this.tm.current.value2 }) {
      Row({ space: this.tm.current.value2 }) {
        Column()
          .width(this.tm.current.value10)
          .height(this.tm.current.value10)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value10)
          .height(this.tm.current.value10)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)
      }

      Row({ space: this.tm.current.value2 }) {
        Column()
          .width(this.tm.current.value10)
          .height(this.tm.current.value10)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value10)
          .height(this.tm.current.value10)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)
      }
    }
  }
}

/**
 * 2×4 缩略图
 */
@ComponentV2
export struct WidgetThumb2x4 {
  @Local private tm: ThemeManager = themeManager;
  @Param thumbColor: ResourceColor = Color.White;

  build() {
    Column({ space: this.tm.current.value2 }) {
      Row({ space: this.tm.current.value2 }) {
        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value10)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value10)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value10)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value10)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)
      }

      Row({ space: this.tm.current.value2 }) {
        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value10)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value10)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value10)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value10)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)
      }
    }
  }
}

/**
 * 4×4 缩略图
 */
@ComponentV2
export struct WidgetThumb4x4 {
  @Local private tm: ThemeManager = themeManager;
  @Param thumbColor: ResourceColor = Color.White;

  build() {
    Column({ space: this.tm.current.value2 }) {
      Row({ space: this.tm.current.value2 }) {
        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value8)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value8)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value8)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value8)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)
      }

      Row({ space: this.tm.current.value2 }) {
        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value8)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value8)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value8)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value8)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)
      }

      Row({ space: this.tm.current.value2 }) {
        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value8)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value8)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value8)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value8)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)
      }

      Row({ space: this.tm.current.value2 }) {
        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value8)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value8)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value8)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)

        Column()
          .width(this.tm.current.value8)
          .height(this.tm.current.value8)
          .backgroundColor(this.thumbColor)
          .borderRadius(this.tm.current.radius8)
      }
    }
  }
}

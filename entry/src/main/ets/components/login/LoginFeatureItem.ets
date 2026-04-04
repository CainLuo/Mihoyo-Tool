/**
 * LoginFeatureItem — 登录页品牌特性条目
 */
import { ThemeManager, themeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct LoginFeatureItem {
  @Param tm: ThemeManager = new ThemeManager()
  @Param label: Resource = $r('app.string.login_brand_feature1')

  build() {
    Row({ space: this.tm.current.value8 }) {
      Column()
        .width(this.tm.current.value5)
        .height(this.tm.current.value5)
        .borderRadius(this.tm.current.value5)
        .backgroundColor(this.tm.current.colorPrimary)
      Text(this.label)
        .font(this.tm.current.body13)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .alignItems(VerticalAlign.Center)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
struct LoginFeatureItemPreview {
  build() {
    Column({ space: 8 }) {
      LoginFeatureItem({ tm: themeManager, label: $r('app.string.login_brand_feature1') })
      LoginFeatureItem({ tm: themeManager, label: $r('app.string.login_brand_feature2') })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}

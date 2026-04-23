/**
 * LoginFeatureItem — 登录页品牌特性条目
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';

@ComponentV2
export struct LoginFeatureItem {
  @Param label: Resource = $r('app.string.login_brand_feature1');
  @Local private tm: ThemeManager = themeManager;

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
export struct LoginFeatureItemPreview {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value8 }) {
      LoginFeatureItem({ label: $r('app.string.login_brand_feature1') })
      LoginFeatureItem({ label: $r('app.string.login_brand_feature2') })
    }
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}

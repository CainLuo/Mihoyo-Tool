/**
 * LoginFeatureItem — 登录页品牌特性条目
 */
import { ThemeManager } from '../../theme/ThemeManager'

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

/**
 * AboutSection — 关于 Section
 *
 * 展示版本号、GitHub 链接、许可证信息。
 */
import BuildProfile from 'BuildProfile'
import { themeManager, ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct AboutSection {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column() {
      this.AboutRow($r('app.string.my_about_version'), BuildProfile.VERSION_NAME, false)
      Divider().color(this.tm.current.colorDivider).margin({ left: this.tm.current.value16 })
      this.AboutRow($r('app.string.my_about_github'), $r('app.string.my_about_github_url'), true)
      Divider().color(this.tm.current.colorDivider).margin({ left: this.tm.current.value16 })
      this.AboutRow($r('app.string.my_about_license'), $r('app.string.my_about_license_value'), false)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .clip(true)
  }

  @Builder
  private AboutRow(label: ResourceStr, value: ResourceStr | string, isLink: boolean) {
    Row() {
      Text(label)
        .font(this.tm.current.body16)
        .fontColor(this.tm.current.colorTextPrimary)
        .layoutWeight(1)
      Text(value)
        .font(this.tm.current.body16)
        .fontColor(isLink ? this.tm.current.colorPrimary : this.tm.current.colorTextSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.value50)
    .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
    .alignItems(VerticalAlign.Center)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct AboutSectionPreview {
  build() {
    Column() {
      AboutSection()
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}

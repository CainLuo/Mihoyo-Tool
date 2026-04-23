/**
 * CharactersEmptyView — 角色页有账号但无角色数据时的空态提示
 *
 * 仅在 Characters 页面 EMPTY 状态且账号列表非空时展示。
 * 提示用户点击刷新按钮触发同步。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';

@ComponentV2
export struct CharactersEmptyView {
  @Param onRefresh: () => void = () => {};
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value20 }) {
      Text('📋').fontSize(this.tm.current.value64)

      Column({ space: this.tm.current.value8 }) {
        Text($r('app.string.characters_placeholder_title'))
          .font(this.tm.current.title18Bold)
          .fontColor(this.tm.current.colorTextPrimary)
          .textAlign(TextAlign.Center)
        Text($r('app.string.characters_placeholder_desc'))
          .font(this.tm.current.body16)
          .fontColor(this.tm.current.colorTextSecondary)
          .textAlign(TextAlign.Center)
          .padding({ left: this.tm.current.value40, right: this.tm.current.value40 })
      }

      Button($r('app.string.characters_no_data_hint'))
        .fontSize(this.tm.current.body16Medium.size)
        .fontWeight(this.tm.current.body16Medium.weight)
        .fontColor(this.tm.current.textOnDarkHigh)
        .width(this.tm.current.pct90)
        .height(this.tm.current.value50)
        .borderRadius(this.tm.current.radius12)
        .backgroundColor(this.tm.current.colorPrimary)
        .onClick(() => { this.onRefresh() })
    }
    .width(this.tm.current.full)
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct CharactersEmptyViewPreview {
  build() {
    CharactersEmptyView()
      .height(600)
      .backgroundColor('#1a1a2e')
  }
}

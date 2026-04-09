/**
 * AccountSwitchDialog — 账号切换自定义对话框
 *
 * 通过 promptAction.openCustomDialog 弹出，显示账号列表。
 * 样式参考 My 页账号列表，显示头像 + 昵称 + UID。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { AccountOption } from '../../viewmodel/CharactersViewModel'

@ObservedV2
export class AccountSwitchDialogParams {
  @Trace options: AccountOption[] = [];
  @Trace selectedIdx: number = 0;
  onSelect: (idx: number) => void = (_idx: number) => {};
  onClose: () => void = () => {};
}

@ComponentV2
export struct AccountSwitchDialog {
  @Param params: AccountSwitchDialogParams = new AccountSwitchDialogParams()
  @Local private tm: ThemeManager = themeManager
  @Local private bottomSafeArea: number = 0

  aboutToAppear(): void {
    const ctx = this.getUIContext()
    const px = AppStorage.get<number>('bottomRectHeight') ?? 0
    this.bottomSafeArea = ctx.px2vp(px)
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text($r('app.string.characters_switch_account_title'))
          .font(this.tm.current.body16Medium)
          .fontColor(this.tm.current.colorTextPrimary)
          .layoutWeight(1)
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(this.tm.current.value16)
            .fontColor([this.tm.current.colorTextSecondary])
        }
        .width(this.tm.current.value32)
        .height(this.tm.current.value32)
        .backgroundColor(this.tm.current.colorTransparent)
        .onClick(() => { this.params.onClose() })
      }
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.value20,
        right: this.tm.current.value12,
        top: this.tm.current.value16,
        bottom: this.tm.current.value8
      })
      .alignItems(VerticalAlign.Center)

      Divider().color(this.tm.current.colorDivider)

      List() {
        ForEach(this.params.options, (opt: AccountOption, i: number) => {
          ListItem() {
            Row({ space: this.tm.current.value12 }) {
              // 头像
              if (opt.avatarUrl !== '') {
                Image(opt.avatarUrl)
                  .width(this.tm.current.value44)
                  .height(this.tm.current.value44)
                  .borderRadius(this.tm.current.value22)
                  .objectFit(ImageFit.Cover)
                  .flexShrink(0)
              } else {
                Row() {
                  SymbolGlyph($r('sys.symbol.person'))
                    .fontSize(this.tm.current.value28)
                    .fontColor([this.tm.current.colorTextSecondary])
                }
                .width(this.tm.current.value44)
                .height(this.tm.current.value44)
                .borderRadius(this.tm.current.value22)
                .backgroundColor(this.tm.current.colorSurfaceCard)
                .justifyContent(FlexAlign.Center)
                .alignItems(VerticalAlign.Center)
                .flexShrink(0)
              }

              // 昵称 + UID
              Column({ space: this.tm.current.value2 }) {
                Text(opt.nickname !== '' ? opt.nickname : opt.username)
                  .font(this.tm.current.body16Medium)
                  .fontColor(this.tm.current.colorTextPrimary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(opt.uid !== '' ? 'UID: ' + opt.uid : opt.username)
                  .font(this.tm.current.body13)
                  .fontColor(this.tm.current.colorTextSecondary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              // 选中勾
              if (i === this.params.selectedIdx) {
                SymbolGlyph($r('sys.symbol.checkmark'))
                  .fontSize(this.tm.current.value18)
                  .fontColor([this.tm.current.colorPrimary])
                  .flexShrink(0)
              }
            }
            .width(this.tm.current.full)
            .padding({
              left: this.tm.current.value20,
              right: this.tm.current.value20,
              top: this.tm.current.value12,
              bottom: this.tm.current.value12
            })
            .alignItems(VerticalAlign.Center)
            .backgroundColor(i === this.params.selectedIdx
              ? this.tm.current.surfaceActivePrimary
              : this.tm.current.colorTransparent)
            .onClick(() => {
              this.params.onSelect(i)
              this.params.onClose()
            })
          }
        }, (opt: AccountOption) => opt.accountId.toString())
      }
      .width(this.tm.current.full)
      .constraintSize({ maxHeight: this.tm.current.value400 })
      .divider({ strokeWidth: 1, color: this.tm.current.colorDivider })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // Safe Area 底部占位
      Row()
        .width(this.tm.current.full)
        .height(this.bottomSafeArea > 0 ? this.bottomSafeArea : this.tm.current.value8)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius({
      topLeft: this.tm.current.radius16,
      topRight: this.tm.current.radius16,
      bottomLeft: 0,
      bottomRight: 0
    })
  }
}

/**
 * AccountRoleCardHeader — 角色卡片顶部信息行
 *
 * 展示：游戏 logo + 游戏名 + 昵称 + 等级标签
 * logo 资源由 ViewModel 通过 MyGameRoleVM.logoResource 提供，Component 不做业务判断。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { MyGameRoleVM } from '../../models/MyModels'
import { GameId } from 'core'

@ComponentV2
export struct AccountRoleCardHeader {
  @Param role: MyGameRoleVM = new MyGameRoleVM(
    GameId.GENSHIN,
    $r('app.string.game_name_genshin'),
    $r('app.color.game_color_genshin'),
    '', '', '', 0, '', []
  )
  @Local private tm: ThemeManager = themeManager

  build() {
    Row({ space: this.tm.current.value10 }) {
      Image(this.role.logoResource)
        .width(this.tm.current.value32)
        .height(this.tm.current.value32)
        .borderRadius(this.tm.current.value8)
        .border({ width: this.tm.current.value1, color: this.tm.current.colorDivider })
        .objectFit(ImageFit.Cover)
        .flexShrink(0)

      Column({ space: this.tm.current.value2 }) {
        Text(this.role.gameName)
          .font(this.tm.current.body16Medium)
          .fontColor(this.tm.current.colorTextPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.role.nickname)
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextSecondary)
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.role.level > 0) {
        Text($r('app.string.character_level_value', this.role.level))
          .font(this.tm.current.body13Bold)
          .fontColor(this.role.gameColor)
          .padding({
            left: this.tm.current.value8,
            right: this.tm.current.value8,
            top: this.tm.current.value4,
            bottom: this.tm.current.value4
          })
          .borderRadius(this.tm.current.value8)
          .border({ width: this.tm.current.value1, color: this.role.gameColor })
          .backgroundColor(this.tm.current.colorPageBg)
      }
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.value16,
      right: this.tm.current.value16,
      top: this.tm.current.value12,
      bottom: this.tm.current.value10
    })
    .alignItems(VerticalAlign.Center)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct AccountRoleCardHeaderPreview {
  build() {
    Column() {
      AccountRoleCardHeader({
        role: new MyGameRoleVM(
          GameId.GENSHIN,
          $r('app.string.game_name_genshin'),
          $r('app.color.game_color_genshin'),
          '123456789', '旅行者', '天空岛', 60, '',
          [], $r('app.media.logo_genshin')
        )
      })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}

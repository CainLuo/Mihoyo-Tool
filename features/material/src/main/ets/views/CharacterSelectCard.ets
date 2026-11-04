/**
 * CharacterSelectCard.ets — 角色选择网格卡片
 *
 * 头像 + 等级遮罩 + 左上角元素 / 命途 / 特性图标 + 武器信息 + 选中标记。
 */

import {
  themeManager,
  ThemeManager,
  genshinElementFromString,
  getGenshinElementIcon,
  getStarRailElementIcon,
  getStarRailPathIcon,
  getZZZElementIcon,
  getZZZProfessionIcon
} from 'basic'
import { GameId } from 'core'
import { SelectableCharacterVM } from '../viewmodel/MaterialCharacterSelectViewModel'

@ComponentV2
export struct CharacterSelectCard {
  @Param character: SelectableCharacterVM = new SelectableCharacterVM()
  /** 当前游戏，决定头像左上角显示哪些图标 */
  @Param gameId: GameId = GameId.GENSHIN
  @Param onTap: () => void = () => {}
  @Local private tm: ThemeManager = themeManager

  /** 头像左上角要显示的图标（复用角色页的图标映射；取不到时不显示） */
  private getBadgeIcons(): Resource[] {
    const icons: Resource[] = []
    if (this.gameId === GameId.GENSHIN) {
      const e = getGenshinElementIcon(genshinElementFromString(this.character.element))
      if (e !== null) {
        icons.push(e)
      }
    } else if (this.gameId === GameId.STARRAIL) {
      const e = getStarRailElementIcon(this.character.element)
      if (e !== null) {
        icons.push(e)
      }
      const p = getStarRailPathIcon(this.character.pathOrProfession)
      if (p !== null) {
        icons.push(p)
      }
    } else if (this.gameId === GameId.ZZZ) {
      const e = getZZZElementIcon(parseInt(this.character.element, 10))
      if (e !== null) {
        icons.push(e)
      }
      const p = getZZZProfessionIcon(this.character.pathOrProfession)
      if (p !== null) {
        icons.push(p)
      }
    }
    return icons
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        // 角色头像：左上角元素图标（原神：元素；星铁：属性 + 命途；绝区零：属性 + 特性），底部渐变遮罩 + 角色等级
        Stack({ alignContent: Alignment.TopStart }) {
          Image(this.character.iconUrl)
            .width(this.tm.current.value56)
            .height(this.tm.current.value56)
            .borderRadius(this.tm.current.radius12)
            .backgroundColor(this.character.rarity === 5 ? $r('app.color.rarity_5star_bg') : $r('app.color.rarity_4star_bg'))

          // 底部渐变遮罩 + 角色等级
          Text(`Lv.${this.character.level}`)
            .fontSize(this.tm.current.font10)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tm.current.textOnDarkHigh)
            .textAlign(TextAlign.Center)
            .width(this.tm.current.value56)
            .padding({ top: this.tm.current.value8, bottom: this.tm.current.value2 })
            .linearGradient({
              angle: this.tm.current.a180,
              colors: [[Color.Transparent, 0.0], [this.tm.current.overlayGradientEnd, 1.0]]
            })
            .borderRadius({ bottomLeft: this.tm.current.radius12, bottomRight: this.tm.current.radius12 })
            .position({ x: 0, y: this.tm.current.full })
            .markAnchor({ x: 0, y: this.tm.current.full })

          // 左上角图标：加半透明深色底，避免和头像混在一起
          if (this.getBadgeIcons().length > 0) {
            Column({ space: this.tm.current.value2 }) {
              ForEach(this.getBadgeIcons(), (icon: Resource) => {
                Image(icon)
                  .width(this.tm.current.value14)
                  .height(this.tm.current.value14)
                  .objectFit(ImageFit.Contain)
              }, (icon: Resource, idx: number) => `${idx}_${icon.id}`)
            }
            .alignItems(HorizontalAlign.Center)
            .padding(this.tm.current.value2)
            .backgroundColor(this.tm.current.colorMask)
            .borderRadius(this.tm.current.radius8)
            .margin({ left: this.tm.current.value2, top: this.tm.current.value2 })
          }
        }
        .width(this.tm.current.value56)
        .height(this.tm.current.value56)
        .clip(true)
        .borderRadius(this.tm.current.radius12)

        // 武器（原神）/ 光锥（星铁）/ 音擎（绝区零）：图标 + 等级；没有装备时显示占位
        Row({ space: this.tm.current.value4 }) {
          if (this.character.weaponIconUrl.length > 0) {
            Image(this.character.weaponIconUrl)
              .width(this.tm.current.value22)
              .height(this.tm.current.value22)
              .borderRadius(this.tm.current.radius8)
              .objectFit(ImageFit.Cover)
              .backgroundColor(this.character.weaponRarity >= 5
                ? $r('app.color.rarity_5star_bg')
                : $r('app.color.rarity_4star_bg'))
            Text(`Lv.${this.character.weaponLevel}`)
              .fontSize(this.tm.current.font10)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.tm.current.colorTextSecondary)
          } else {
            Text('—')
              .fontSize(this.tm.current.font10)
              .fontColor(this.tm.current.colorTextSecondary)
          }
        }
        .height(this.tm.current.value22)
        .justifyContent(FlexAlign.Center)
        .margin({ top: this.tm.current.value8 })
      }
      .width(this.tm.current.full)
      .padding(this.tm.current.value12)
      .alignItems(HorizontalAlign.Center)

      // 选中标记（右上角）
      if (this.character.isSelected) {
        Text('✓')
          .fontSize(this.tm.current.fontBold16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.colorPrimary)
          .margin({ top: this.tm.current.value8, right: this.tm.current.value8 })
      }
    }
    .width(this.tm.current.full)
    .backgroundColor(this.character.isSelected ? this.tm.current.surfaceActivePrimary : this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .border({
      width: this.character.isSelected ? 2 : 0,
      color: this.tm.current.colorPrimary
    })
    .onClick(() => {
      this.onTap()
    })
  }
}

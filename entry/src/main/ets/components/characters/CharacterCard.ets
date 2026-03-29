/**
 * CharacterCard — 角色列表卡片（Phone 样式）
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { GameDataSummary } from 'core';
import { GenshinElement, elementFromString } from '../../constants/GenshinElement';

/** 根据元素字符串返回对应颜色资源 */
export function elementColor(element: string): Resource {
  if (element === 'Pyro') { return $r('app.color.element_pyro'); }
  if (element === 'Hydro') { return $r('app.color.element_hydro'); }
  if (element === 'Anemo') { return $r('app.color.element_anemo'); }
  if (element === 'Electro') { return $r('app.color.element_electro'); }
  if (element === 'Dendro') { return $r('app.color.element_dendro'); }
  if (element === 'Cryo') { return $r('app.color.element_cryo'); }
  if (element === 'Geo') { return $r('app.color.element_geo'); }
  return $r('app.color.color_text_secondary');
}

/** 根据元素字符串返回对应多语言标签资源 */
export function elementLabel(element: string): Resource {
  if (element === 'Pyro') { return $r('app.string.character_element_Pyro'); }
  if (element === 'Hydro') { return $r('app.string.character_element_Hydro'); }
  if (element === 'Anemo') { return $r('app.string.character_element_Anemo'); }
  if (element === 'Electro') { return $r('app.string.character_element_Electro'); }
  if (element === 'Dendro') { return $r('app.string.character_element_Dendro'); }
  if (element === 'Cryo') { return $r('app.string.character_element_Cryo'); }
  if (element === 'Geo') { return $r('app.string.character_element_Geo'); }
  return $r('app.string.character_element_Anemo');
}

@ComponentV2
export struct CharacterCard {
  @Param character: GameDataSummary = new GameDataSummary();
  @Param gameId: string = 'genshin';
  @Param roleUid: string = '';
  @Param onTap: (character: GameDataSummary) => void = (_c: GameDataSummary) => {};
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      // 图片区（1:1）+ 武器浮层
      Stack({ alignContent: Alignment.BottomEnd }) {
        Stack() {
          Column()
            .width(this.tm.current.full)
            .aspectRatio(1)
            .backgroundColor(this.character.rarity >= 5
              ? $r('app.color.rarity_5star_bg')
              : $r('app.color.rarity_4star_bg'))

          if (this.character.iconUrl) {
            Image(this.character.iconUrl)
              .width(this.tm.current.full)
              .aspectRatio(1)
              .objectFit(ImageFit.Cover)
          }

          // 底部渐变遮罩 + 角色名
          Column() {
            Text(this.character.name)
              .font(this.tm.current.body13Bold)
              .fontColor(Color.White)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width(this.tm.current.full)
              .padding({ left: this.tm.current.value8, right: this.tm.current.value8, bottom: this.tm.current.value8 })
          }
          .width(this.tm.current.full)
          .justifyContent(FlexAlign.End)
          .linearGradient({
            angle: this.tm.current.a180,
            colors: [[this.tm.current.colorTransparent, 0.0], [this.tm.current.overlayGradientEnd, 1.0]]
          })
          .padding({ top: this.tm.current.value20 })
          .position({ x: 0, y: '100%' })
          .markAnchor({ x: 0, y: '100%' })
          .zIndex(2)

          // 元素角标（左上角）
          Column() {
            Text(elementLabel(elementFromString(this.character.extraText1)))
              .fontSize(this.tm.current.body12.size)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
          .width(this.tm.current.value30)
          .height(this.tm.current.value30)
          .borderRadius(this.tm.current.value30 / 2)
          .backgroundColor(elementColor(elementFromString(this.character.extraText1)))
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .shadow({ radius: this.tm.current.value8, color: $r('app.color.color_mask'), offsetY: 2 })
          .position({ x: this.tm.current.value8, y: this.tm.current.value8 })
          .zIndex(3)

          // 命座徽章（右上角）
          Text(`${this.character.extraInt1}`)
            .fontSize(this.tm.current.body12.size)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.rarity_5star'))
            .width(this.tm.current.value22)
            .height(this.tm.current.value22)
            .borderRadius(this.tm.current.value22 / 2)
            .backgroundColor($r('app.color.color_mask'))
            .border({ width: this.tm.current.value1p5, color: $r('app.color.color_card_border') })
            .textAlign(TextAlign.Center)
            .position({ x: '100%', y: this.tm.current.value8 })
            .markAnchor({ x: '100%', y: 0 })
            .margin({ right: this.tm.current.value8 })
            .zIndex(3)
        }
        .width(this.tm.current.full)
        .aspectRatio(1)

        // 武器浮层（右下角）
        Column() {
          Stack() {
            if (this.character.weaponIconUrl) {
              Image(this.character.weaponIconUrl)
                .width(this.tm.current.full)
                .height(this.tm.current.full)
                .objectFit(ImageFit.Contain)
            } else {
              Column()
                .width(this.tm.current.full)
                .height(this.tm.current.full)
                .backgroundColor($r('app.color.color_placeholder'))
            }
          }
          .layoutWeight(1)
          .width(this.tm.current.full)

          Row({ space: this.tm.current.value2 }) {
            Text($r('app.string.character_weapon_level_prefix', this.character.weaponLevel))
              .fontSize(this.tm.current.body10.size)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.tm.current.textOnDarkGhost)
              .layoutWeight(1)
              .textAlign(TextAlign.Start)
            Text(`R${this.character.weaponAffix}`)
              .fontSize(this.tm.current.body10.size)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.tm.current.accentRefine)
              .backgroundColor(this.tm.current.accentRefineBg)
              .borderRadius(this.tm.current.value2)
              .padding({ left: this.tm.current.value2, right: this.tm.current.value2 })
          }
          .width(this.tm.current.full)
          .height(this.tm.current.value18)
          .padding({ left: this.tm.current.value4, right: this.tm.current.value4 })
          .alignItems(VerticalAlign.Center)
        }
        .width(this.tm.current.value64)
        .height(this.tm.current.value64)
        .backgroundColor($r('app.color.weapon_overlay_bg'))
        .borderRadius({ topLeft: this.tm.current.radius8, topRight: 0, bottomLeft: 0, bottomRight: 0 })
        .border({ width: { top: 1, left: 1 }, color: $r('app.color.color_card_border') })
        .clip(true)
        .zIndex(4)
      }
      .width(this.tm.current.full)
      .aspectRatio(1)
      .clip(true)

      // 信息区：等级 + 好感度
      Row({ space: this.tm.current.value8 }) {
        Text($r('app.string.character_level_value', this.character.level))
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextSecondary)
        Column()
          .width(1)
          .height(this.tm.current.value10)
          .backgroundColor(this.tm.current.colorDivider)
        Text($r('app.string.character_fetter_value', this.character.extraInt2))
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .width(this.tm.current.full)
      .alignItems(VerticalAlign.Center)
      .padding({
        top: this.tm.current.value8,
        bottom: this.tm.current.value8,
        left: this.tm.current.value10,
        right: this.tm.current.value10
      })
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .border({ width: this.tm.current.value1, color: this.tm.current.colorCardBorder })
    .clip(true)
    .shadow({
      radius: this.tm.current.shadowRadius,
      color: this.tm.current.shadowColor,
      offsetY: this.tm.current.shadowOffsetY
    })
    .onClick(() => { this.onTap(this.character) })
  }
}

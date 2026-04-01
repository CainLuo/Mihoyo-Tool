/**
 * CharacterCard — 角色列表卡片
 *
 * 根据 gameId 自动切换展示逻辑：
 *   - genshin：元素圆形角标（左上）+ 命座（右上）+ 好感度（底部）
 *   - starrail：属性+命途胶囊标签纵向（左上）+ 星魂（右上）+ 等级（底部）
 *   - zzz：稀有度+属性+特性胶囊标签纵向（左上）+ 影画（右上）+ 等级+阵营（底部）
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { GameDataSummary } from 'core';
import { GameId } from '../../constants/GameId';
import { elementFromString } from '../../constants/GenshinElement';
import { GenshinElement } from '../../constants/GenshinElement';
import {
  starRailElementLabel, starRailElementColor,
  starRailPathLabel, starRailPathColor
} from '../../constants/StarRailElement';
import { zzzElementLabel, zzzElementColor, zzzProfessionLabel } from '../../constants/ZZZElement';

/** 原神：根据元素字符串返回颜色资源 */
export function elementColor(element: string): Resource {
  if (element === GenshinElement.PYRO)    { return $r('app.color.element_pyro'); }
  if (element === GenshinElement.HYDRO)   { return $r('app.color.element_hydro'); }
  if (element === GenshinElement.ANEMO)   { return $r('app.color.element_anemo'); }
  if (element === GenshinElement.ELECTRO) { return $r('app.color.element_electro'); }
  if (element === GenshinElement.DENDRO)  { return $r('app.color.element_dendro'); }
  if (element === GenshinElement.CRYO)    { return $r('app.color.element_cryo'); }
  if (element === GenshinElement.GEO)     { return $r('app.color.element_geo'); }
  return $r('app.color.color_text_secondary');
}

/** 原神：根据元素字符串返回多语言标签资源 */
export function elementLabel(element: string): Resource {
  if (element === GenshinElement.PYRO)    { return $r('app.string.character_element_Pyro'); }
  if (element === GenshinElement.HYDRO)   { return $r('app.string.character_element_Hydro'); }
  if (element === GenshinElement.ANEMO)   { return $r('app.string.character_element_Anemo'); }
  if (element === GenshinElement.ELECTRO) { return $r('app.string.character_element_Electro'); }
  if (element === GenshinElement.DENDRO)  { return $r('app.string.character_element_Dendro'); }
  if (element === GenshinElement.CRYO)    { return $r('app.string.character_element_Cryo'); }
  if (element === GenshinElement.GEO)     { return $r('app.string.character_element_Geo'); }
  return $r('app.string.character_element_Anemo');
}

@ComponentV2
export struct CharacterCard {
  @Param character: GameDataSummary = new GameDataSummary();
  @Param gameId: string = GameId.GENSHIN;
  @Param roleUid: string = '';
  @Param onTap: (character: GameDataSummary) => void = (_c: GameDataSummary) => {};
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      // 图片区 + 武器浮层
      Stack({ alignContent: Alignment.BottomEnd }) {
        Stack() {
          // 背景色（按稀有度）
          Column()
            .width(this.tm.current.full)
            .aspectRatio(1)
            .backgroundColor(this.character.rarity >= 5
              ? $r('app.color.rarity_5star_bg')
              : $r('app.color.rarity_4star_bg'))

          // 角色图片（原神用 iconUrl，星铁/绝区零用 squareIconUrl 半身立绘）
          if (this.gameId === GameId.GENSHIN) {
            if (this.character.iconUrl) {
              Image(this.character.iconUrl)
                .width(this.tm.current.full)
                .aspectRatio(1)
                .objectFit(ImageFit.Cover)
            }
          } else {
            if (this.character.squareIconUrl) {
              Image(this.character.squareIconUrl)
                .width(this.tm.current.full)
                .aspectRatio(1)
                .objectFit(ImageFit.Cover)
            }
          }

          // 底部渐变遮罩 + 角色名
          Column() {
            Text(this.character.name)
              .font(this.tm.current.body13Bold)
              .fontColor(this.tm.current.textOnDarkHigh)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width(this.tm.current.full)
              .padding({
                left: this.tm.current.value8,
                right: this.tm.current.value8,
                bottom: this.tm.current.value8
              })
          }
          .width(this.tm.current.full)
          .justifyContent(FlexAlign.End)
          .linearGradient({
            angle: this.tm.current.a180,
            colors: [[this.tm.current.colorTransparent, 0.0], [this.tm.current.overlayGradientEnd, 1.0]]
          })
          .padding({ top: this.tm.current.value20 })
          .position({ x: 0, y: this.tm.current.full })
          .markAnchor({ x: 0, y: this.tm.current.full })
          .zIndex(2)

          // 左上角标签区（根据游戏不同）
          if (this.gameId === GameId.GENSHIN) {
            this.genshinTopLeft()
          } else if (this.gameId === GameId.STARRAIL) {
            this.starrailTopLeft()
          } else if (this.gameId === GameId.ZZZ) {
            this.zzzTopLeft()
          }

          // 右上角：命座/星魂/影画数字
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
            .position({ x: this.tm.current.full, y: this.tm.current.value8 })
            .markAnchor({ x: this.tm.current.full, y: 0 })
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
            // 原神用 R，星铁用 S，绝区零用 R
            Text(this.gameId === GameId.STARRAIL
              ? `S${this.character.weaponAffix}`
              : `R${this.character.weaponAffix}`)
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

      // 底部信息栏（根据游戏不同）
      if (this.gameId === GameId.GENSHIN) {
        this.genshinBottomBar()
      } else if (this.gameId === GameId.STARRAIL) {
        this.starrailBottomBar()
      } else {
        this.zzzBottomBar()
      }
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

  // ── 原神：左上元素圆形角标 ──────────────────────────────────
  @Builder
  private genshinTopLeft() {
    Column() {
      Text(elementLabel(elementFromString(this.character.extraText1)))
        .fontSize(this.tm.current.body12.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tm.current.textOnDarkHigh)
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
  }

  // ── 星穹铁道：属性 + 命途，纵向胶囊标签 ────────────────────
  @Builder
  private starrailTopLeft() {
    Column({ space: this.tm.current.value4 }) {
      // 属性标签
      Text(starRailElementLabel(this.character.extraText1))
        .fontSize(this.tm.current.body10.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(starRailElementColor(this.character.extraText1))
        .padding({
          left: this.tm.current.value5,
          right: this.tm.current.value5,
          top: this.tm.current.value2,
          bottom: this.tm.current.value2
        })
        .borderRadius(this.tm.current.value8)
        .border({ width: this.tm.current.value1, color: starRailElementColor(this.character.extraText1) })
        .backgroundColor($r('app.color.color_mask'))
      // 命途标签
      Text(starRailPathLabel(parseInt(this.character.extraText2)))
        .fontSize(this.tm.current.body10.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(starRailPathColor(parseInt(this.character.extraText2)))
        .padding({
          left: this.tm.current.value5,
          right: this.tm.current.value5,
          top: this.tm.current.value2,
          bottom: this.tm.current.value2
        })
        .borderRadius(this.tm.current.value8)
        .border({ width: this.tm.current.value1, color: starRailPathColor(parseInt(this.character.extraText2)) })
        .backgroundColor($r('app.color.color_mask'))
    }
    .alignItems(HorizontalAlign.Start)
    .position({ x: this.tm.current.value8, y: this.tm.current.value8 })
    .zIndex(3)
  }

  // ── 绝区零：稀有度 + 属性 + 特性，纵向胶囊标签 ─────────────
  @Builder
  private zzzTopLeft() {
    Column({ space: this.tm.current.value4 }) {
      // 稀有度（S/A）
      Text(this.character.rarity >= 5 ? 'S' : 'A')
        .fontSize(this.tm.current.body10.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.character.rarity >= 5 ? $r('app.color.rarity_5star') : $r('app.color.color_text_secondary'))
        .padding({
          left: this.tm.current.value5,
          right: this.tm.current.value5,
          top: this.tm.current.value2,
          bottom: this.tm.current.value2
        })
        .borderRadius(this.tm.current.value8)
        .border({
          width: this.tm.current.value1,
          color: this.character.rarity >= 5 ? $r('app.color.rarity_5star') : $r('app.color.color_text_secondary')
        })
        .backgroundColor($r('app.color.color_mask'))
      // 属性标签
      Text(zzzElementLabel(parseInt(this.character.extraText1)))
        .fontSize(this.tm.current.body10.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(zzzElementColor(parseInt(this.character.extraText1)))
        .padding({
          left: this.tm.current.value5,
          right: this.tm.current.value5,
          top: this.tm.current.value2,
          bottom: this.tm.current.value2
        })
        .borderRadius(this.tm.current.value8)
        .border({ width: this.tm.current.value1, color: zzzElementColor(parseInt(this.character.extraText1)) })
        .backgroundColor($r('app.color.color_mask'))
      // 特性标签
      Text(zzzProfessionLabel(parseInt(this.character.extraText2)))
        .fontSize(this.tm.current.body10.size)
        .fontColor(this.tm.current.textOnDarkSecondary)
        .padding({
          left: this.tm.current.value5,
          right: this.tm.current.value5,
          top: this.tm.current.value2,
          bottom: this.tm.current.value2
        })
        .borderRadius(this.tm.current.value8)
        .border({ width: this.tm.current.value1, color: this.tm.current.surfaceInactiveBorder })
        .backgroundColor($r('app.color.color_mask'))
    }
    .alignItems(HorizontalAlign.Start)
    .position({ x: this.tm.current.value8, y: this.tm.current.value8 })
    .zIndex(3)
  }

  // ── 原神底部：等级 | 好感度 ─────────────────────────────────
  @Builder
  private genshinBottomBar() {
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

  // ── 星穹铁道底部：等级 ──────────────────────────────────────
  @Builder
  private starrailBottomBar() {
    Row() {
      Text($r('app.string.character_level_value', this.character.level))
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

  // ── 绝区零底部：等级 | 阵营 icon ────────────────────────────
  @Builder
  private zzzBottomBar() {
    Row({ space: this.tm.current.value8 }) {
      Text($r('app.string.character_level_value', this.character.level))
        .font(this.tm.current.body13)
        .fontColor(this.tm.current.colorTextSecondary)
        .flexShrink(0)
      if (this.character.fullName) {
        Column()
          .width(1)
          .height(this.tm.current.value10)
          .backgroundColor(this.tm.current.colorDivider)
          .flexShrink(0)
        Image(this.character.fullName)
          .width(this.tm.current.value20)
          .height(this.tm.current.value20)
          .objectFit(ImageFit.Contain)
          .flexShrink(0)
      }
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
}

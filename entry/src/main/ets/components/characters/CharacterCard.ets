/**
 * CharacterCard — 角色列表卡片
 *
 * Phone（xs）：头像区（1:1）+ 信息栏（等级 + 好感度）
 * 非 Phone（sm/md/lg）：同上 + 圣遗物图标行 + 技能等级行
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { GameDataSummary } from 'core';
import { RouterUtil } from '../../utils/RouterUtil';
import { AppRoutes } from '../../constants/AppRoutes';
import { GenshinCharacterDetailParam } from '../../pages/GenshinCharacterDetail';
import { GenshinElement, elementFromString } from '../../constants/GenshinElement';

/** 构造 CharacterCard mock 数据的辅助函数 */
function makeMockChar(name: string, rarity: number, element: string, level: number, fetter: number, cons: number): GameDataSummary {
  const c = new GameDataSummary();
  c.name = name;
  c.rarity = rarity;
  c.level = level;
  c.extraInt1 = cons;
  c.extraInt2 = fetter;
  c.extraText1 = element;
  c.weaponLevel = 90;
  c.weaponAffix = 1;
  c.weaponRarity = 5;
  c.skillLevels = [10, 10, 10];
  return c;
}

// ── Preview：Phone 模式（xs，无圣遗物/技能行）──
@Preview
@ComponentV2
struct CharacterCardPreviewPhone {
  build() {
    Row({ space: 8 }) {
      CharacterCard({
        character: makeMockChar('钟离', 5, 'Geo', 90, 10, 6),
        isPhone: true,
        breakpoint: 'xs',
        gameId: 'genshin',
        roleUid: '100000001'
      })
      .width(160)
      CharacterCard({
        character: makeMockChar('雷电将军', 5, 'Electro', 80, 7, 0),
        isPhone: true,
        breakpoint: 'xs',
        gameId: 'genshin',
        roleUid: '100000001'
      })
      .width(160)
    }
    .padding(16)
    .backgroundColor($r('app.color.color_page_bg'))
  }
}

// ── Preview：非 Phone 模式（sm，含圣遗物/技能行）──
@Preview
@ComponentV2
struct CharacterCardPreviewTablet {
  build() {
    Row({ space: 8 }) {
      CharacterCard({
        character: makeMockChar('胡桃', 5, 'Pyro', 90, 10, 2),
        isPhone: false,
        breakpoint: 'sm',
        gameId: 'genshin',
        roleUid: '100000001'
      })
      .width(180)
      CharacterCard({
        character: makeMockChar('神里绫华', 5, 'Cryo', 90, 10, 6),
        isPhone: false,
        breakpoint: 'lg',
        gameId: 'genshin',
        roleUid: '100000001'
      })
      .width(180)
    }
    .padding(16)
    .backgroundColor($r('app.color.color_page_bg'))
  }
}

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
  @Param isPhone: boolean = true;
  /** 当前断点：xs/sm/md/lg，用于自适应图标尺寸 */
  @Param breakpoint: string = 'xs';
  /** 游戏 ID，用于跳转详情页 */
  @Param gameId: string = 'genshin';
  /** 游戏内 UID，用于跳转详情页 */
  @Param roleUid: string = '';
  @Local private tm: ThemeManager = themeManager;

  /** 根据断点返回圣遗物图标尺寸 */
  private relicSize(): number {
    if (this.breakpoint === 'lg') { return this.tm.current.relicIconSizeLG; }
    return this.tm.current.relicIconSizeSM;
  }

  /** 根据断点返回技能图标尺寸 */
  private skillSize(): number {
    if (this.breakpoint === 'lg') { return this.tm.current.skillIconSizeLG; }
    return this.tm.current.skillIconSizeSM;
  }

  build() {
    Column() {
      // ── 图片区（1:1 正方形）+ 武器浮层（外层 Stack 统一管理）──
      Stack({ alignContent: Alignment.BottomEnd }) {
        // 内层图片 Stack（头像、元素角标、命座、渐变遮罩）
        Stack() {
          // 星级背景色
          Column()
            .width(this.tm.current.widthFull)
            .aspectRatio(1)
            .backgroundColor(this.character.rarity >= 5
              ? $r('app.color.rarity_5star_bg')
              : $r('app.color.rarity_4star_bg'))

          // 角色头像
          if (this.character.iconUrl) {
            Image(this.character.iconUrl)
              .width(this.tm.current.widthFull)
              .aspectRatio(1)
              .objectFit(ImageFit.Cover)
          }

          // 底部渐变遮罩 + 角色名
          Column() {
            Text(this.character.name)
              .font(this.isPhone ? this.tm.current.body13Bold : this.tm.current.body15Bold)
              .fontColor(Color.White)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width(this.tm.current.widthFull)
              .padding({ left: this.tm.current.value8, right: this.tm.current.value8, bottom: this.tm.current.value8 })
          }
          .width(this.tm.current.widthFull)
          .justifyContent(FlexAlign.End)
          .linearGradient({
            angle: this.tm.current.gradientAngle180,
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
          .width(this.tm.current.elementBadgeSize)
          .height(this.tm.current.elementBadgeSize)
          .borderRadius(this.tm.current.elementBadgeSize / 2)
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
            .width(this.tm.current.constellationBadgeSize)
            .height(this.tm.current.constellationBadgeSize)
            .borderRadius(this.tm.current.constellationBadgeSize / 2)
            .backgroundColor($r('app.color.color_mask'))
            .border({ width: this.tm.current.borderWidthMedium, color: $r('app.color.color_card_border') })
            .textAlign(TextAlign.Center)
            .position({ x: '100%', y: this.tm.current.value8 })
            .markAnchor({ x: '100%', y: 0 })
            .margin({ right: this.tm.current.value8 })
            .zIndex(3)
        }
        .width(this.tm.current.widthFull)
        .aspectRatio(1)

        // 武器浮层（右下角，由外层 Stack alignContent: BottomEnd 定位）
        Column() {
          // 上：武器图标铺满
          Stack() {
            if (this.character.weaponIconUrl) {
              Image(this.character.weaponIconUrl)
                .width(this.tm.current.widthFull)
                .height(this.tm.current.widthFull)
                .objectFit(ImageFit.Contain)
            } else {
              Column()
                .width(this.tm.current.widthFull)
                .height(this.tm.current.widthFull)
                .backgroundColor($r('app.color.color_placeholder'))
            }
          }
          .layoutWeight(1)
          .width(this.tm.current.widthFull)

          // 下：等级 + 精炼标签
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
          .width(this.tm.current.widthFull)
          .height(this.tm.current.weaponInfoBarH)
          .padding({ left: this.tm.current.value4, right: this.tm.current.value4 })
          .alignItems(VerticalAlign.Center)
        }
        .width(this.tm.current.weaponOverlaySize)
        .height(this.tm.current.weaponOverlaySize)
        .backgroundColor($r('app.color.weapon_overlay_bg'))
        .borderRadius({ topLeft: this.tm.current.radius8, topRight: 0, bottomLeft: 0, bottomRight: 0 })
        .border({ width: { top: 1, left: 1 }, color: $r('app.color.color_card_border') })
        .clip(true)
        .zIndex(4)
      }
      .width(this.tm.current.widthFull)
      .aspectRatio(1)
      .clip(true)

      // ── 信息区：等级 + 好感度 ──
      Row({ space: this.tm.current.value8 }) {
        Text($r('app.string.character_level_value', this.character.level))
          .font(this.isPhone ? this.tm.current.body13 : this.tm.current.body16)
          .fontColor(this.tm.current.colorTextSecondary)
        Column()
          .width(1)
          .height(this.tm.current.dividerHeightSM)
          .backgroundColor(this.tm.current.colorDivider)
        Text($r('app.string.character_fetter_value', this.character.extraInt2))
          .font(this.isPhone ? this.tm.current.body13 : this.tm.current.body16)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .width(this.tm.current.widthFull)
      .alignItems(VerticalAlign.Center)
      .padding({
        top: this.tm.current.value8,
        bottom: this.isPhone ? this.tm.current.value8 : this.tm.current.value4,
        left: this.tm.current.value10,
        right: this.tm.current.value10
      })

      // ── 非 Phone 扩展区：圣遗物图标 + 技能等级 ──
      if (!this.isPhone) {
        Divider()
          .color(this.tm.current.colorDivider)
          .strokeWidth(this.tm.current.cardBorderWidth)
          .margin({ left: this.tm.current.value8, right: this.tm.current.value8 })

        // 圣遗物图标行
        Row() {
          if (this.character.relicIcons.length > 0) {
            ForEach(this.character.relicIcons, (icon: string) => {
              Image(icon)
                .width(this.relicSize())
                .height(this.relicSize())
                .objectFit(ImageFit.Contain)
            }, (icon: string) => icon)
          } else {
            Text($r('app.string.character_no_relics'))
              .fontSize(this.tm.current.body12.size)
              .fontColor(this.tm.current.colorTextSecondary)
              .textAlign(TextAlign.Center)
              .width(this.tm.current.widthFull)
          }
        }
        .width(this.tm.current.widthFull)
        .height(this.relicSize())
        .justifyContent(FlexAlign.SpaceAround)
        .alignItems(VerticalAlign.Center)
        .padding({
          top: this.tm.current.value4,
          bottom: this.tm.current.value4,
          left: this.tm.current.value8,
          right: this.tm.current.value8
        })

        Divider()
          .color(this.tm.current.colorDivider)
          .strokeWidth(this.tm.current.cardBorderWidth)
          .margin({ left: this.tm.current.value8, right: this.tm.current.value8 })

        // 技能等级行
        Row() {
          if (this.character.skillIcons.length > 0) {
            ForEach(this.character.skillIcons, (icon: string, index: number) => {
              Column({ space: this.tm.current.value2 }) {
                Image(icon)
                  .width(this.skillSize())
                  .height(this.skillSize())
                  .objectFit(ImageFit.Contain)
                Text(`${this.character.skillLevels[index] ?? 0}`)
                  .fontSize(this.tm.current.body13Bold.size)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.tm.current.colorTextPrimary)
              }
              .alignItems(HorizontalAlign.Center)
            }, (icon: string) => icon)
          } else {
            Text($r('app.string.character_no_skills'))
              .fontSize(this.tm.current.body12.size)
              .fontColor(this.tm.current.colorTextSecondary)
              .textAlign(TextAlign.Center)
              .width(this.tm.current.widthFull)
          }
        }
        .width(this.tm.current.widthFull)
        .height(this.breakpoint === 'lg'
          ? this.tm.current.skillLevelRowHeightLG
          : this.tm.current.skillLevelRowHeightSM)
        .justifyContent(FlexAlign.SpaceAround)
        .alignItems(VerticalAlign.Center)
        .padding({
          top: this.tm.current.value4,
          bottom: this.tm.current.value8,
          left: this.tm.current.value8,
          right: this.tm.current.value8
        })
      }
    }
    .width(this.tm.current.widthFull)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .border({ width: this.tm.current.cardBorderWidth, color: this.tm.current.colorCardBorder })
    .clip(true)
    .shadow({
      radius: this.tm.current.shadowRadius,
      color: this.tm.current.shadowColor,
      offsetY: this.tm.current.shadowOffsetY
    })
    .onClick(() => {
      const param = new GenshinCharacterDetailParam();
      param.gameId = this.gameId;
      param.roleUid = this.roleUid;
      param.entityId = this.character.entityId;
      RouterUtil.push(AppRoutes.GENSHIN_CHARACTER_DETAIL, param);
    })
  }
}

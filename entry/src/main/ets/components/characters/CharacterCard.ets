/**
 * CharacterCard — 角色列表卡片
 *
 * 根据 gameId 自动切换展示逻辑：
 *   - genshin：元素圆形角标（左上）+ 命座（右上）+ 好感度（底部）
 *   - starrail：属性+命途胶囊标签纵向（左上）+ 星魂（右上）+ 等级（底部）
 *   - zzz：稀有度+属性+特性胶囊标签纵向（左上）+ 影画（右上）+ 等级+阵营（底部）
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { ThemeFonts } from '../../theme/ThemeFonts'
import { GameDataSummary, GameId } from 'core';
import { genshinElementFromString, elementIcon } from '../../constants/GenshinElement';
import { starRailElementIcon, starRailPathIcon } from '../../constants/StarRailElement';
import { zzzElementIcon, zzzProfessionIcon } from '../../constants/ZZZElement';

@ComponentV2
export struct CharacterCard {
  @Param character: GameDataSummary = new GameDataSummary();
  @Param gameId: GameId = GameId.GENSHIN;
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
              ? $r('app.color.dark_400')
              : $r('app.color.dark_400'))

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
              .font(ThemeFonts.fontBold14)
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
            colors: [[Color.Transparent, 0.0], [this.tm.current.overlayGradientEnd, 1.0]]
          })
          .padding({ top: this.tm.current.font20 })
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
            .fontSize(this.tm.current.font13)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.gold'))
            .width(this.tm.current.value22)
            .height(this.tm.current.value22)
            .borderRadius(this.tm.current.value22 / 2)
            .backgroundColor($r('app.color.black'))
            .border({ width: this.tm.current.value1p5, color: $r('app.color.gray_200') })
            .textAlign(TextAlign.Center)
            .position({ x: this.tm.current.full, y: this.tm.current.value8 })
            .markAnchor({ x: this.tm.current.full, y: 0 })
            .margin({ right: this.tm.current.value8 })
            .zIndex(3)
        }
        .width(this.tm.current.full)
        .aspectRatio(1)

        // 武器浮层（右下角）—— 无武器槽位时不显示
        if (this.character.hasWeaponSlot) {
          Column() {
            if (this.character.weaponLevel > 0 || this.character.weaponIconUrl !== '') {
              // 有武器：显示图标 + 等级 + 精炼
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
                    .backgroundColor($r('app.color.gray_600'))
                }
              }
              .layoutWeight(1)
              .width(this.tm.current.full)

              Row({ space: this.tm.current.value2 }) {
                Text($r('app.string.character_weapon_level_prefix', this.character.weaponLevel))
                  .fontSize(this.tm.current.font11)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.tm.current.textOnDarkGhost)
                  .layoutWeight(1)
                  .textAlign(TextAlign.Start)
                Text(this.gameId === GameId.STARRAIL
                  ? `S${this.character.weaponAffix}`
                  : `R${this.character.weaponAffix}`)
                  .fontSize(this.tm.current.font11)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.tm.current.accentRefine)
                  .backgroundColor(this.tm.current.accentRefineBg)
                  .borderRadius(this.tm.current.value2)
                  .padding({ left: this.tm.current.value2, right: this.tm.current.value2 })
              }
              .width(this.tm.current.full)
              .height(this.tm.current.font18)
              .padding({ left: this.tm.current.value4, right: this.tm.current.value4 })
              .alignItems(VerticalAlign.Center)
            } else {
              // 无武器：禁止圆圈 + "未装备"提示
              Column({ space: this.tm.current.value4 }) {
                // 禁止圆圈图标
                Stack() {
                  Column()
                    .width(this.tm.current.value22)
                    .height(this.tm.current.value22)
                    .borderRadius(this.tm.current.value22 / 2)
                    .border({ width: 2, color: $r('app.color.gray_700') })
                  Column()
                    .width(2)
                    .height(this.tm.current.font24)
                    .backgroundColor($r('app.color.gray_700'))
                    .rotate({ angle: 45 })
                }
                .width(this.tm.current.value22)
                .height(this.tm.current.value22)
                .opacity(0.4)

                Text($r('app.string.character_weapon_none'))
                  .fontSize(this.tm.current.font11)
                  .fontColor(this.tm.current.colorTextSecondary)
                  .opacity(0.5)
              }
              .width(this.tm.current.full)
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
            }
          }
          .width(this.tm.current.value64)
          .height(this.tm.current.value64)
          .backgroundColor($r('app.color.black'))
          .borderRadius({ topLeft: this.tm.current.radius8, topRight: 0, bottomLeft: 0, bottomRight: 0 })
          .border({ width: { top: 1, left: 1 }, color: $r('app.color.gray_200') })
          .clip(true)
          .zIndex(4)
        }
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
    .border({ width: this.tm.current.value1, color: this.tm.current.colorDivider })
    .clip(true)
    .shadow({
      radius: this.tm.current.shadowRadius,
      color: this.tm.current.shadowColor,
      offsetY: this.tm.current.shadowOffsetY
    })
    .onClick(() => { this.onTap(this.character) })
  }

  // ── 原神：左上元素图标 ──────────────────────────────────────
  @Builder
  private genshinTopLeft() {
    if (elementIcon(genshinElementFromString(this.character.extraText1)) !== null) {
      Image(elementIcon(genshinElementFromString(this.character.extraText1)) as Resource)
        .width(this.tm.current.font24)
        .height(this.tm.current.font24)
        .objectFit(ImageFit.Contain)
        .position({ x: this.tm.current.value8, y: this.tm.current.value8 })
        .zIndex(3)
    }
  }

  // ── 星穹铁道：属性 + 命途，纵向图标 ───────────────────────
  @Builder
  private starrailTopLeft() {
    Column({ space: this.tm.current.value4 }) {
      // 属性图标
      if (starRailElementIcon(this.character.extraText1) !== null) {
        Image(starRailElementIcon(this.character.extraText1) as Resource)
          .width(this.tm.current.value22)
          .height(this.tm.current.value22)
          .objectFit(ImageFit.Contain)
      }
      // 命途图标
      if (starRailPathIcon(parseInt(this.character.extraText2)) !== null) {
        Image(starRailPathIcon(parseInt(this.character.extraText2)) as Resource)
          .width(this.tm.current.value22)
          .height(this.tm.current.value22)
          .objectFit(ImageFit.Contain)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .position({ x: this.tm.current.value8, y: this.tm.current.value8 })
    .zIndex(3)
  }

  // ── 绝区零：稀有度 + 属性 + 特性，纵向图标 ─────────────────
  @Builder
  private zzzTopLeft() {
    Column({ space: this.tm.current.value4 }) {
      // 稀有度图标（S/A）
      Image(this.character.rarity >= 5
        ? $r('app.media.zzz_rarity_s')
        : $r('app.media.zzz_rarity_a'))
        .width(this.tm.current.value22)
        .height(this.tm.current.value22)
        .objectFit(ImageFit.Contain)
      // 属性图标
      if (zzzElementIcon(parseInt(this.character.extraText1)) !== null) {
        Image(zzzElementIcon(parseInt(this.character.extraText1)) as Resource)
          .width(this.tm.current.value22)
          .height(this.tm.current.value22)
          .objectFit(ImageFit.Contain)
      }
      // 特性图标
      if (zzzProfessionIcon(parseInt(this.character.extraText2)) !== null) {
        Image(zzzProfessionIcon(parseInt(this.character.extraText2)) as Resource)
          .width(this.tm.current.value22)
          .height(this.tm.current.value22)
          .objectFit(ImageFit.Contain)
      }
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
        .font(ThemeFonts.font14)
        .fontColor(this.tm.current.colorTextSecondary)
      Column()
        .width(1)
        .height(this.tm.current.value10)
        .backgroundColor(this.tm.current.colorDivider)
      Text($r('app.string.character_fetter_value', this.character.extraInt2))
        .font(ThemeFonts.font14)
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
        .font(ThemeFonts.font14)
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
        .font(ThemeFonts.font14)
        .fontColor(this.tm.current.colorTextSecondary)
        .flexShrink(0)
      if (this.character.groupIconUrl) {
        Column()
          .width(1)
          .height(this.tm.current.value10)
          .backgroundColor(this.tm.current.colorDivider)
          .flexShrink(0)
        Image(this.character.groupIconUrl)
          .width(this.tm.current.font20)
          .height(this.tm.current.font20)
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

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct CharacterCardPreview {
  build() {
    GridRow({
      columns: { xs: 2, sm: 3, md: 4, lg: 5 },
      gutter: 8
    }) {
      // 原神角色
      GridCol() {
        CharacterCard({
          character: (() => {
            const c = new GameDataSummary();
            c.gameId = GameId.GENSHIN;
            c.name = '纳西妲';
            c.rarity = 5;
            c.level = 90;
            c.extraInt1 = 6;
            c.extraInt2 = 10;
            c.extraText1 = 'Dendro';
            c.extraText2 = '10';
            c.weaponLevel = 90;
            c.weaponAffix = 1;
            c.weaponRarity = 5;
            return c;
          })(),
          gameId: GameId.GENSHIN
        })
      }
      // 星铁角色
      GridCol() {
        CharacterCard({
          character: (() => {
            const c = new GameDataSummary();
            c.gameId = GameId.STARRAIL;
            c.name = '黑天鹅';
            c.rarity = 5;
            c.level = 80;
            c.extraInt1 = 4;
            c.extraText1 = 'wind';
            c.extraText2 = '4';
            c.weaponLevel = 80;
            c.weaponAffix = 1;
            c.weaponRarity = 5;
            return c;
          })(),
          gameId: GameId.STARRAIL
        })
      }
      // 绝区零角色
      GridCol() {
        CharacterCard({
          character: (() => {
            const c = new GameDataSummary();
            c.gameId = GameId.ZZZ;
            c.name = '柏妮思';
            c.rarity = 5;
            c.level = 60;
            c.extraInt1 = 3;
            c.extraText1 = '200';
            c.extraText2 = '1';
            c.weaponLevel = 60;
            c.weaponAffix = 1;
            c.weaponRarity = 5;
            return c;
          })(),
          gameId: GameId.ZZZ
        })
      }
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}

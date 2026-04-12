/**
 * ZZZCharDetailContent — 绝区零角色详情内容区
 *
 * 包含：技能、音擎、属性面板、驱动盘
 * 标题在卡片外面，与原神保持一致
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { ZZZCharacterDetailViewModel } from '../../viewmodel/ZZZCharacterDetailViewModel'
import {
  ZZZCharDetailSkill,
  ZZZCharDetailEquip,
  ZZZSubStat,
  ZZZSuitSummary,
  ZZZCharDetailProperty
} from './CharDetailModels'

@ComponentV2
export struct ZZZCharDetailContent {
  @Param vm: ZZZCharacterDetailViewModel = new ZZZCharacterDetailViewModel()
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value8 }) {
      this.SkillsSection()
      this.WeaponSection()
      this.PropsSection()
      this.EquipSection()
      Row().height(this.tm.current.value16)
    }
    .width(this.tm.current.full)
    .padding({ left: this.tm.current.value12, right: this.tm.current.value12, top: this.tm.current.value8 })
  }

  @Builder
  SectionLabel(title: Resource) {
    Text(title)
      .fontSize(this.tm.current.body12.size)
      .fontColor(this.tm.current.textOnDarkSecondary)
      .width(this.tm.current.full)
      .padding({ bottom: this.tm.current.value4 })
  }

  @Builder
  SkillsSection() {
    Column({ space: this.tm.current.value4 }) {
      this.SectionLabel($r('app.string.zzz_char_detail_skills_title'))
      Column() {
        ForEach(this.vm.skills, (skill: ZZZCharDetailSkill, idx: number) => {
          Column({ space: this.tm.current.value4 }) {
            if (skill.items.length > 0) {
              Row({ space: this.tm.current.value8 }) {
                Column()
                  .width(this.tm.current.value4)
                  .height(this.tm.current.value16)
                  .borderRadius(this.tm.current.value2)
                  .backgroundColor(this.tm.current.accentPrimaryStrong)
                Text(skill.items[0].title)
                  .fontSize(this.tm.current.body12.size)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.tm.current.textOnDarkHigh)
                  .layoutWeight(1)
                Text(`Lv.${skill.level}`)
                  .fontSize(this.tm.current.body12.size)
                  .fontColor(this.tm.current.accentRefine)
                  .backgroundColor(this.tm.current.accentRefineBg)
                  .borderRadius(this.tm.current.value4)
                  .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
              }
              .width(this.tm.current.full)
              .alignItems(VerticalAlign.Center)
            }
          }
          .width(this.tm.current.full)
          .border({ width: { bottom: idx < this.vm.skills.length - 1 ? this.tm.current.value1 : 0 }, color: this.tm.current.surfaceOverlaySm })
          .padding({ top: this.tm.current.value8, bottom: this.tm.current.value8 })
        }, (skill: ZZZCharDetailSkill, idx: number) => `skill_${idx}`)
      }
      .width(this.tm.current.full)
      .backgroundColor(this.tm.current.surfaceDarkXl)
      .border({ width: this.tm.current.value1, color: this.tm.current.surfaceOverlayMd })
      .borderRadius(this.tm.current.radius12)
      .alignItems(HorizontalAlign.Start)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  WeaponSection() {
    Column({ space: this.tm.current.value4 }) {
      this.SectionLabel($r('app.string.zzz_char_detail_weapon_title'))
      Column() {
        if (this.vm.weapon !== null) {
          Row({ space: this.tm.current.value10 }) {
            if (this.vm.weapon.iconUrl !== '') {
              Image(this.vm.weapon.iconUrl)
                .width(this.tm.current.value52)
                .height(this.tm.current.value52)
                .objectFit(ImageFit.Contain)
                .borderRadius(this.tm.current.value8)
                .backgroundColor(this.tm.current.surfaceGlassSm)
            }
            Column({ space: this.tm.current.value4 }) {
              Text(this.vm.weapon.name)
                .fontSize(this.tm.current.body13Bold.size)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.tm.current.textOnDarkHigh)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Row({ space: this.tm.current.value8 }) {
                Text(`Lv.${this.vm.weapon.level}`)
                  .fontSize(this.tm.current.body10.size)
                  .fontColor(this.tm.current.textOnDarkMuted)
                Text(this.vm.weapon.rarity)
                  .fontSize(this.tm.current.body10.size)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.tm.current.accentRefine)
                  .backgroundColor(this.tm.current.accentRefineBg)
                  .borderRadius(this.tm.current.value4)
                  .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
              }
              if (this.vm.weapon.talentTitle !== '') {
                Text(this.vm.weapon.talentTitle)
                  .fontSize(this.tm.current.body12.size)
                  .fontColor(this.tm.current.textOnDarkSecondary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width(this.tm.current.full)
          .padding(this.tm.current.value12)
          .alignItems(VerticalAlign.Center)
        } else {
          Row({ space: this.tm.current.value8 }) {
            Column()
              .width(this.tm.current.value44)
              .height(this.tm.current.value44)
              .borderRadius(this.tm.current.value8)
              .backgroundColor(this.tm.current.surfaceDark2xl)
              .border({ width: this.tm.current.value1, color: this.tm.current.surfaceInactiveBorder, style: BorderStyle.Dashed })
            Text($r('app.string.zzz_char_detail_no_weapon'))
              .fontSize(this.tm.current.body13.size)
              .fontColor(this.tm.current.textOnDarkMuted)
          }
          .width(this.tm.current.full)
          .padding(this.tm.current.value12)
          .alignItems(VerticalAlign.Center)
        }
      }
      .width(this.tm.current.full)
      .backgroundColor(this.tm.current.surfaceDarkXl)
      .border({ width: this.tm.current.value1, color: this.tm.current.surfaceOverlayMd })
      .borderRadius(this.tm.current.radius12)
      .alignItems(HorizontalAlign.Start)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  PropsSection() {
    Column({ space: this.tm.current.value4 }) {
      this.SectionLabel($r('app.string.zzz_char_detail_props_title'))
      Column() {
        ForEach(this.vm.properties, (prop: ZZZCharDetailProperty, idx: number) => {
          Row() {
            Text(prop.name)
              .fontSize(this.tm.current.body13.size)
              .fontColor(this.tm.current.textOnDarkSecondary)
              .layoutWeight(1)
            Text(prop.final)
              .fontSize(this.tm.current.body13Bold.size)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.tm.current.textOnDarkHigh)
          }
          .width(this.tm.current.full)
          .padding({ left: this.tm.current.value12, right: this.tm.current.value12, top: this.tm.current.value8, bottom: this.tm.current.value8 })
          .border({ width: { bottom: idx < this.vm.properties.length - 1 ? this.tm.current.value1 : 0 }, color: this.tm.current.surfaceOverlaySm })
        }, (prop: ZZZCharDetailProperty, idx: number) => `prop_${idx}`)
      }
      .width(this.tm.current.full)
      .backgroundColor(this.tm.current.surfaceDarkXl)
      .border({ width: this.tm.current.value1, color: this.tm.current.surfaceOverlayMd })
      .borderRadius(this.tm.current.radius12)
      .alignItems(HorizontalAlign.Start)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  EquipSection() {
    Column({ space: this.tm.current.value4 }) {
      this.SectionLabel($r('app.string.zzz_char_detail_equip_title'))
      // 套装摘要
      if (this.vm.suitSummaries.length > 0) {
        Column() {
          ForEach(this.vm.suitSummaries, (suit: ZZZSuitSummary, idx: number) => {
            Row({ space: this.tm.current.value8 }) {
              Text(suit.suitName)
                .fontSize(this.tm.current.body13Bold.size)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.tm.current.textOnDarkHigh)
                .layoutWeight(1)
              Text($r('app.string.zzz_char_detail_suit_pieces', 2))
                .fontSize(this.tm.current.body10.size)
                .fontColor(suit.count >= 2 ? this.tm.current.accentRefine : this.tm.current.textOnDarkMuted)
                .backgroundColor(suit.count >= 2 ? this.tm.current.accentRefineBg : this.tm.current.surfaceDark2xl)
                .border({ width: this.tm.current.value1, color: suit.count >= 2 ? this.tm.current.accentRefine : this.tm.current.surfaceInactiveBorder })
                .borderRadius(this.tm.current.value4)
                .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
              if (suit.suitOwn >= 4) {
                Text($r('app.string.zzz_char_detail_suit_pieces', 4))
                  .fontSize(this.tm.current.body10.size)
                  .fontColor(suit.count >= 4 ? this.tm.current.accentRefine : this.tm.current.textOnDarkMuted)
                  .backgroundColor(suit.count >= 4 ? this.tm.current.accentRefineBg : this.tm.current.surfaceDark2xl)
                  .border({ width: this.tm.current.value1, color: suit.count >= 4 ? this.tm.current.accentRefine : this.tm.current.surfaceInactiveBorder })
                  .borderRadius(this.tm.current.value4)
                  .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
              }
              Text(`${suit.count}/${suit.suitOwn}`)
                .fontSize(this.tm.current.body13Bold.size)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.tm.current.accentRefine)
            }
            .width(this.tm.current.full)
            .padding({ left: this.tm.current.value12, right: this.tm.current.value12, top: this.tm.current.value8, bottom: this.tm.current.value8 })
            .border({ width: { bottom: idx < this.vm.suitSummaries.length - 1 ? this.tm.current.value1 : 0 }, color: this.tm.current.surfaceOverlaySm })
          }, (suit: ZZZSuitSummary, idx: number) => `suit_${suit.suitId}`)
        }
        .width(this.tm.current.full)
        .backgroundColor(this.tm.current.surfaceDarkXl)
        .border({ width: this.tm.current.value1, color: this.tm.current.surfaceOverlayMd })
        .borderRadius(this.tm.current.radius12)
        .alignItems(HorizontalAlign.Start)
      }
      // 驱动盘网格
      Column({ space: this.tm.current.value8 }) {
        ForEach([0, 2, 4], (startIdx: number) => {
          Row({ space: this.tm.current.value8 }) {
            if (startIdx < this.vm.equips.length) {
              this.EquipCard(this.vm.equips[startIdx])
            } else {
              this.EquipPlaceholder(startIdx + 1)
            }
            if (startIdx + 1 < this.vm.equips.length) {
              this.EquipCard(this.vm.equips[startIdx + 1])
            } else {
              this.EquipPlaceholder(startIdx + 2)
            }
          }
          .width(this.tm.current.full)
          .alignItems(VerticalAlign.Top)
        }, (startIdx: number) => `row_${startIdx}`)
      }
      .width(this.tm.current.full)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  EquipPlaceholder(pos: number) {
    Column({ space: this.tm.current.value4 }) {
      SymbolGlyph($r('sys.symbol.lock'))
        .fontSize(this.tm.current.value20)
        .fontColor([this.tm.current.textOnDarkMuted])
      Text(`${pos}`)
        .fontSize(this.tm.current.body12.size)
        .fontColor(this.tm.current.textOnDarkMuted)
    }
    .layoutWeight(1)
    .height(this.tm.current.value80)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.tm.current.surfaceDarkMd)
    .border({ width: this.tm.current.value1, color: this.tm.current.surfaceInactiveBorder, style: BorderStyle.Dashed })
    .borderRadius(this.tm.current.radius8)
  }

  @Builder
  EquipCard(equip: ZZZCharDetailEquip) {
    Column({ space: this.tm.current.value4 }) {
      // 顶部：图标 + 套装名 + 强化等级
      Row({ space: this.tm.current.value4 }) {
        if (equip.iconUrl !== '') {
          Image(equip.iconUrl)
            .width(this.tm.current.value32)
            .height(this.tm.current.value32)
            .objectFit(ImageFit.Contain)
        }
        Text(equip.suitName)
          .fontSize(this.tm.current.body12.size)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text(`+${equip.level}`)
          .fontSize(this.tm.current.value9)
          .fontColor(this.tm.current.textOnDarkGhost)
          .backgroundColor(this.tm.current.surfaceGlassMd)
          .borderRadius(this.tm.current.value4)
          .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
      }
      .width(this.tm.current.full)
      .alignItems(VerticalAlign.Center)
      // 主词条行
      Row() {
        Text(equip.mainStatName)
          .fontSize(this.tm.current.body10.size)
          .fontColor(this.tm.current.accentPrimaryStrong)
          .layoutWeight(1)
        Text(equip.mainStatValue)
          .fontSize(this.tm.current.body13Bold.size)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
      }
      .width(this.tm.current.full)
      .padding({ top: this.tm.current.value2, bottom: this.tm.current.value2 })
      .border({ width: { bottom: this.tm.current.value1 }, color: this.tm.current.surfaceGlassSm })
      // 副词条列表
      Column() {
        ForEach(equip.subStats, (sub: ZZZSubStat) => {
          Row() {
            Text(sub.name)
              .fontSize(this.tm.current.body10.size)
              .fontColor(sub.valid ? this.tm.current.accentRefine : this.tm.current.textOnDarkGhost)
              .layoutWeight(1)
            Text(sub.value)
              .fontSize(this.tm.current.body10.size)
              .fontColor(sub.valid ? this.tm.current.accentRefine : this.tm.current.textOnDarkHigh)
          }
          .width(this.tm.current.full)
          .padding({ top: this.tm.current.value1, bottom: this.tm.current.value1 })
        }, (_sub: ZZZSubStat, idx: number) => `sub_${idx}`)
      }
      .width(this.tm.current.full)
    }
    .layoutWeight(1)
    .padding(this.tm.current.value8)
    .backgroundColor(this.tm.current.surfaceGlassXs)
    .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlassMd })
    .borderRadius(this.tm.current.radius8)
  }
}

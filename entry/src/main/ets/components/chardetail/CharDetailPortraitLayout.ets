/**
 * CharDetailPortraitLayout — 角色详情 Phone 竖屏布局
 *
 * 布局：英雄区 → 技能 → 武器 → 属性（单列）→ 圣遗物
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { GenshinCharacterDetailViewModel } from '../../viewmodel/GenshinCharacterDetailViewModel'
import { CharDetailHeroPanel } from './CharDetailHeroPanel'
import { CharDetailRelicsPanel } from './CharDetailRelicsPanel'
import { HeroPanelMode } from '../../constants/HeroPanelMode'
import { CharDetailSkill, CharDetailStat, CharDetailWeapon } from './CharDetailModels'
import { elementColor } from '../characters/CharacterCard'

@ComponentV2
export struct CharDetailPortraitLayout {
  @Param tm: ThemeManager = themeManager
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel()

  // 技能类型颜色（普攻/战技/爆发）
  private skillColor(idx: number): Resource {
    if (idx === 0) { return $r('app.color.color_text_secondary'); }
    return elementColor(this.vm.charElement) as Resource;
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          // 英雄区
          CharDetailHeroPanel({ vm: this.vm, mode: HeroPanelMode.PORTRAIT })
            .height(this.tm.current.value260)
            .width(this.tm.current.full)

          Column({ space: this.tm.current.value8 }) {
            // 技能 section
            this.SkillsSection()
            // 武器 section
            this.WeaponSection()
            // 属性 section（单列）
            this.StatsSection()
            // 圣遗物 section
            this.RelicsSection()
            Row().height(this.tm.current.value8)
          }
          .width(this.tm.current.full)
          .padding({ left: this.tm.current.value12, right: this.tm.current.value12, top: this.tm.current.value8 })
        }
        .width(this.tm.current.full)
      }
      .scrollBar(BarState.Off)
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
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
      this.SectionLabel($r('app.string.char_detail_section_skills'))
      Column() {
        ForEach(this.vm.skills, (skill: CharDetailSkill, idx: number) => {
          Row({ space: this.tm.current.value8 }) {
            if (skill.iconUrl !== '') {
              Image(skill.iconUrl)
                .width(this.tm.current.value28)
                .height(this.tm.current.value28)
                .objectFit(ImageFit.Contain)
                .borderRadius(this.tm.current.value14)
                .backgroundColor(this.tm.current.surfaceDarkLg)
                .border({ width: this.tm.current.value1p5, color: elementColor(this.vm.charElement) })
                .flexShrink(0)
            }
            Text(skill.name !== '' ? skill.name : `技能${idx + 1}`)
              .fontSize(this.tm.current.body12.size)
              .fontColor(this.tm.current.textOnDarkHigh)
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(`Lv.${skill.level}`)
              .fontSize(this.tm.current.body12.size)
              .fontWeight(FontWeight.Bold)
              .fontColor(idx === 0 ? this.tm.current.textOnDarkSecondary :
                idx === 1 ? elementColor(this.vm.charElement) : elementColor(this.vm.charElement))
              .backgroundColor(this.tm.current.surfaceDarkLg)
              .borderRadius(this.tm.current.value4)
              .padding({ left: this.tm.current.value8, right: this.tm.current.value8, top: this.tm.current.value2, bottom: this.tm.current.value2 })
              .flexShrink(0)
          }
          .width(this.tm.current.full)
          .padding({ top: this.tm.current.value8, bottom: this.tm.current.value8 })
          .border({ width: { bottom: idx < this.vm.skills.length - 1 ? this.tm.current.value1 : 0 }, color: this.tm.current.surfaceGlass })
          .alignItems(VerticalAlign.Center)
        }, (_skill: CharDetailSkill, idx: number) => `skill_${idx}`)
      }
      .width(this.tm.current.full)
      .padding({ left: this.tm.current.value12, right: this.tm.current.value12 })
      .backgroundColor(this.tm.current.surfaceDarkLg)
      .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
      .borderRadius(this.tm.current.radius12)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  WeaponSection() {
    Column({ space: this.tm.current.value4 }) {
      this.SectionLabel($r('app.string.char_detail_section_weapon'))
      if (this.vm.weapon.name !== '') {
        Row({ space: this.tm.current.value10 }) {
          if (this.vm.weapon.iconUrl !== '') {
            Image(this.vm.weapon.iconUrl)
              .width(this.tm.current.value52)
              .height(this.tm.current.value52)
              .objectFit(ImageFit.Contain)
              .borderRadius(this.tm.current.value8)
              .backgroundColor(this.tm.current.surfaceGlass)
              .flexShrink(0)
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
              Text($r('app.string.char_detail_weapon_refine_prefix', this.vm.weapon.affix))
                .fontSize(this.tm.current.body10.size)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.tm.current.accentRefine)
                .backgroundColor(this.tm.current.accentRefineBg)
                .borderRadius(this.tm.current.value4)
                .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
              // 星级
              Text(this.starsText(this.vm.weapon.rarity))
                .fontSize(this.tm.current.body10.size)
                .fontColor(this.tm.current.accentRefine)
            }
            // 基础攻击力 · 副词条（金色）
            if (this.vm.weapon.baseAtk > 0 || this.vm.weapon.subLabel !== null) {
              Row({ space: this.tm.current.value2 }) {
                if (this.vm.weapon.baseAtk > 0) {
                  Text($r('app.string.char_detail_weapon_atk'))
                    .fontSize(this.tm.current.body10.size)
                    .fontColor(this.tm.current.accentRefine)
                  Text(`${this.vm.weapon.baseAtk}`)
                    .fontSize(this.tm.current.body10.size)
                    .fontColor(this.tm.current.accentRefine)
                }
                if (this.vm.weapon.subLabel !== null) {
                  Text('·')
                    .fontSize(this.tm.current.body10.size)
                    .fontColor(this.tm.current.accentRefine)
                  Text(this.vm.weapon.subLabel)
                    .fontSize(this.tm.current.body10.size)
                    .fontColor(this.tm.current.accentRefine)
                  Text(this.vm.weapon.subVal)
                    .fontSize(this.tm.current.body10.size)
                    .fontColor(this.tm.current.accentRefine)
                }
              }
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width(this.tm.current.full)
        .padding(this.tm.current.value12)
        .backgroundColor(this.tm.current.surfaceDarkLg)
        .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
        .borderRadius(this.tm.current.radius12)
        .alignItems(VerticalAlign.Center)
      } else {
        // 未装备武器占位
        Row({ space: this.tm.current.value8 }) {
          SymbolGlyph($r('sys.symbol.lock'))
            .fontSize(this.tm.current.value16)
            .fontColor([this.tm.current.textOnDarkMuted])
          Text($r('app.string.char_detail_no_weapon'))
            .fontSize(this.tm.current.body13.size)
            .fontColor(this.tm.current.textOnDarkMuted)
        }
        .width(this.tm.current.full)
        .height(this.tm.current.value56)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .backgroundColor(this.tm.current.surfaceDarkLg)
        .border({ width: this.tm.current.value1, color: this.tm.current.surfaceInactiveBorder, style: BorderStyle.Dashed })
        .borderRadius(this.tm.current.radius12)
      }
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  StatsSection() {
    Column({ space: this.tm.current.value4 }) {
      this.SectionLabel($r('app.string.char_detail_section_stats'))
      Column() {
        ForEach(this.vm.stats, (stat: CharDetailStat, idx: number) => {
          Row() {
            Text(stat.labelKey)
              .fontSize(this.tm.current.body13.size)
              .fontColor(this.tm.current.textOnDarkSecondary)
              .layoutWeight(1)
            Text(stat.value)
              .fontSize(this.tm.current.body13Bold.size)
              .fontWeight(FontWeight.Bold)
              .fontColor(stat.isHighlight ? elementColor(this.vm.charElement) : this.tm.current.textOnDarkHigh)
          }
          .width(this.tm.current.full)
          .padding({ left: this.tm.current.value12, right: this.tm.current.value12, top: this.tm.current.value8, bottom: this.tm.current.value8 })
          .border({ width: { bottom: idx < this.vm.stats.length - 1 ? this.tm.current.value1 : 0 }, color: this.tm.current.surfaceGlass })
        }, (stat: CharDetailStat, idx: number) => `stat_${idx}`)
      }
      .width(this.tm.current.full)
      .backgroundColor(this.tm.current.surfaceDarkLg)
      .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
      .borderRadius(this.tm.current.radius12)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  RelicsSection() {
    Column({ space: this.tm.current.value4 }) {
      this.SectionLabel($r('app.string.char_detail_section_relics'))
      CharDetailRelicsPanel({ vm: this.vm, isPhone: true })
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }

  private starsText(n: number): string {
    let s = '';
    for (let i = 0; i < n; i++) { s += '★'; }
    return s;
  }
}

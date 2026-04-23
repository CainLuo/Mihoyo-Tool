/**
 * CharDetailPortraitLayout — 角色详情 Phone 竖屏布局
 *
 * 布局：英雄区 → 技能 → 武器 → 属性（单列）→ 圣遗物
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailHeroPanel } from './CharDetailHeroPanel';
import { CharDetailRelicsPanel } from './CharDetailRelicsPanel';
import { CharDetailSectionLabel } from '../common/CharDetailSectionLabel';
import { CharDetailPortraitSkillItem } from './CharDetailPortraitSkillItem';
import { CharDetailPortraitWeaponCard } from './CharDetailPortraitWeaponCard';
import { CharDetailStatRow } from '../common/CharDetailStatRow';
import { HeroPanelMode } from '../../../constants/HeroPanelMode';
import { CharDetailSkill, CharDetailStat } from '../../../models/CharDetailModels';

@ComponentV2
export struct CharDetailPortraitLayout {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      Scroll() {
        Column() {
          CharDetailHeroPanel({ vm: this.vm, mode: HeroPanelMode.PORTRAIT })
            .height(this.tm.current.value260)
            .width(this.tm.current.full)

          Column({ space: this.tm.current.value8 }) {
            this.SkillsSection()
            this.WeaponSection()
            this.StatsSection()
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
  SkillsSection() {
    Column({ space: this.tm.current.value4 }) {
      CharDetailSectionLabel({ title: $r('app.string.char_detail_section_skills') })
      Column() {
        ForEach(this.vm.skills, (skill: CharDetailSkill, idx: number) => {
          CharDetailPortraitSkillItem({
            skill: skill,
            skillIndex: idx,
            charElement: this.vm.charElement,
            isHighlight: idx > 0
          })
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
      CharDetailSectionLabel({ title: $r('app.string.char_detail_section_weapon') })
      if (this.vm.weapon.name !== '') {
        CharDetailPortraitWeaponCard({ weapon: this.vm.weapon })
      } else {
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
      CharDetailSectionLabel({ title: $r('app.string.char_detail_section_stats') })
      Column() {
        ForEach(this.vm.stats, (stat: CharDetailStat, idx: number) => {
          CharDetailStatRow({ stat: stat, charElement: this.vm.charElement })
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
      CharDetailSectionLabel({ title: $r('app.string.char_detail_section_relics') })
      CharDetailRelicsPanel({ vm: this.vm, isPhone: true })
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}

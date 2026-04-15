/**
 * StarRailCharDetailContent — 星穹铁道角色详情内容区
 *
 * 包含：行迹、光锥、属性面板、遗器/饰品
 * 标题在卡片外面，与原神保持一致
 */
import { LengthMetrics } from '@kit.ArkUI'
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { StarRailCharacterDetailViewModel } from '../../viewmodel/StarRailCharacterDetailViewModel'
import { starRailPropertyTypeToName } from '../../utils/StarRailPropertyUtil'
import {
  StarRailCharDetailSkillNode,
  StarRailCharDetailRelic,
  StarRailCharDetailProperty,
  StarRailRelicSubStat
} from './CharDetailModels'

@ComponentV2
export struct StarRailCharDetailContent {
  @Param vm: StarRailCharacterDetailViewModel = new StarRailCharacterDetailViewModel()
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value8 }) {
      this.SkillsSection()
      this.EquipSection()
      this.PropsSection()
      this.RelicsSection()
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
      this.SectionLabel($r('app.string.starrail_char_detail_skills_main'))
      Column({ space: this.tm.current.value8 }) {
        if (this.vm.skillsMain.length > 0) {
          Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(this.tm.current.value8), cross: LengthMetrics.vp(this.tm.current.value8) } }) {
            ForEach(this.vm.skillsMain, (skill: StarRailCharDetailSkillNode) => {
              Column({ space: this.tm.current.value4 }) {
                if (skill.iconUrl !== '') {
                  Image(skill.iconUrl)
                    .width(this.tm.current.value44)
                    .height(this.tm.current.value44)
                    .objectFit(ImageFit.Contain)
                    .borderRadius(this.tm.current.value22)
                    .backgroundColor(skill.isActivated ? this.tm.current.surfaceActivePrimary : this.tm.current.surfaceDarkLg)
                    .border({ width: this.tm.current.value1p5, color: skill.isActivated ? this.tm.current.surfaceActiveBorder : this.tm.current.surfaceInactiveBorder })
                    .opacity(skill.isActivated ? 1.0 : this.tm.current.charDetailConsInactiveOpacity)
                }
                Text(`${skill.level}`)
                  .fontSize(this.tm.current.body12.size)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(skill.isActivated ? this.tm.current.accentRefine : this.tm.current.textOnDarkMuted)
                Text(skill.remake)
                  .fontSize(this.tm.current.body10.size)
                  .fontColor(this.tm.current.textOnDarkMuted)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width(this.tm.current.value56)
              .alignItems(HorizontalAlign.Center)
            }, (skill: StarRailCharDetailSkillNode) => `main_${skill.pointId}`)
          }
          .width(this.tm.current.full)
        }
        if (this.vm.skillsExtra.length > 0) {
          Column({ space: this.tm.current.value4 }) {
            Text($r('app.string.starrail_char_detail_skills_extra'))
              .fontSize(this.tm.current.body12.size)
              .fontColor(this.tm.current.textOnDarkSecondary)
            Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(this.tm.current.value8), cross: LengthMetrics.vp(this.tm.current.value8) } }) {
              ForEach(this.vm.skillsExtra, (skill: StarRailCharDetailSkillNode) => {
                Column({ space: this.tm.current.value4 }) {
                  if (skill.iconUrl !== '') {
                    Image(skill.iconUrl)
                      .width(this.tm.current.value36)
                      .height(this.tm.current.value36)
                      .objectFit(ImageFit.Contain)
                      .borderRadius(this.tm.current.value18)
                      .backgroundColor(skill.isActivated ? this.tm.current.surfaceActivePrimary : this.tm.current.surfaceDarkLg)
                      .border({ width: this.tm.current.value1, color: skill.isActivated ? this.tm.current.surfaceActiveBorder : this.tm.current.surfaceInactiveBorder })
                      .opacity(skill.isActivated ? 1.0 : this.tm.current.charDetailConsInactiveOpacity)
                  }
                }
                .width(this.tm.current.value44)
                .alignItems(HorizontalAlign.Center)
              }, (skill: StarRailCharDetailSkillNode) => `extra_${skill.pointId}`)
            }
          }
          .width(this.tm.current.full)
          .alignItems(HorizontalAlign.Start)
        }
        if (this.vm.skillsAttr.length > 0) {
          Column({ space: this.tm.current.value4 }) {
            Text($r('app.string.starrail_char_detail_skills_attr'))
              .fontSize(this.tm.current.body12.size)
              .fontColor(this.tm.current.textOnDarkSecondary)
            Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(this.tm.current.value8), cross: LengthMetrics.vp(this.tm.current.value8) } }) {
              ForEach(this.vm.skillsAttr, (skill: StarRailCharDetailSkillNode) => {
                Column({ space: this.tm.current.value2 }) {
                  if (skill.iconUrl !== '') {
                    Image(skill.iconUrl)
                      .width(this.tm.current.value28)
                      .height(this.tm.current.value28)
                      .objectFit(ImageFit.Contain)
                      .borderRadius(this.tm.current.value14)
                      .backgroundColor(skill.isActivated ? this.tm.current.surfaceActivePrimary : this.tm.current.surfaceDarkLg)
                      .opacity(skill.isActivated ? 1.0 : this.tm.current.charDetailConsInactiveOpacity)
                  }
                }
                .width(this.tm.current.value36)
                .alignItems(HorizontalAlign.Center)
              }, (skill: StarRailCharDetailSkillNode) => `attr_${skill.pointId}`)
            }
          }
          .width(this.tm.current.full)
          .alignItems(HorizontalAlign.Start)
        }
      }
      .width(this.tm.current.full)
      .padding(this.tm.current.value12)
      .backgroundColor(this.tm.current.surfaceDarkLg)
      .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
      .borderRadius(this.tm.current.radius12)
      .alignItems(HorizontalAlign.Start)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  EquipSection() {
    Column({ space: this.tm.current.value4 }) {
      this.SectionLabel($r('app.string.starrail_char_detail_equip_title'))
      Column() {
        if (this.vm.equip !== null) {
          Row({ space: this.tm.current.value10 }) {
            if (this.vm.equip.iconUrl !== '') {
              Image(this.vm.equip.iconUrl)
                .width(this.tm.current.value52)
                .height(this.tm.current.value52)
                .objectFit(ImageFit.Contain)
                .borderRadius(this.tm.current.value8)
                .backgroundColor(this.tm.current.surfaceGlass)
            }
            Column({ space: this.tm.current.value4 }) {
              Text(this.vm.equip.name)
                .fontSize(this.tm.current.body13Bold.size)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.tm.current.textOnDarkHigh)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Row({ space: this.tm.current.value8 }) {
                Text(`Lv.${this.vm.equip.level}`)
                  .fontSize(this.tm.current.body10.size)
                  .fontColor(this.tm.current.textOnDarkMuted)
                Text(`S${this.vm.equip.rank}`)
                  .fontSize(this.tm.current.body10.size)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.tm.current.accentRefine)
                  .backgroundColor(this.tm.current.accentRefineBg)
                  .borderRadius(this.tm.current.value4)
                  .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
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
              .backgroundColor(this.tm.current.surfaceDarkLg)
              .border({ width: this.tm.current.value1, color: this.tm.current.surfaceInactiveBorder, style: BorderStyle.Dashed })
            Text($r('app.string.starrail_char_detail_no_equip'))
              .fontSize(this.tm.current.body13.size)
              .fontColor(this.tm.current.textOnDarkMuted)
          }
          .width(this.tm.current.full)
          .padding(this.tm.current.value12)
          .alignItems(VerticalAlign.Center)
        }
      }
      .width(this.tm.current.full)
      .backgroundColor(this.tm.current.surfaceDarkLg)
      .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
      .borderRadius(this.tm.current.radius12)
      .alignItems(HorizontalAlign.Start)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  PropsSection() {
    Column({ space: this.tm.current.value4 }) {
      this.SectionLabel($r('app.string.starrail_char_detail_props_title'))
      Column() {
        ForEach(this.vm.properties, (prop: StarRailCharDetailProperty, idx: number) => {
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
          .border({ width: { bottom: idx < this.vm.properties.length - 1 ? this.tm.current.value1 : 0 }, color: this.tm.current.surfaceGlass })
        }, (prop: StarRailCharDetailProperty, idx: number) => `prop_${idx}`)
      }
      .width(this.tm.current.full)
      .backgroundColor(this.tm.current.surfaceDarkLg)
      .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
      .borderRadius(this.tm.current.radius12)
      .alignItems(HorizontalAlign.Start)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  RelicsSection() {
    Column({ space: this.tm.current.value4 }) {
      this.SectionLabel($r('app.string.starrail_char_detail_relics_title'))
      Column({ space: this.tm.current.value8 }) {
        ForEach([0, 2], (startIdx: number) => {
          Row({ space: this.tm.current.value8 }) {
            if (startIdx < this.vm.relics.length) {
              this.RelicCard(this.vm.relics[startIdx])
            } else {
              this.RelicPlaceholder(startIdx + 1)
            }
            if (startIdx + 1 < this.vm.relics.length) {
              this.RelicCard(this.vm.relics[startIdx + 1])
            } else {
              this.RelicPlaceholder(startIdx + 2)
            }
          }
          .width(this.tm.current.full)
          .alignItems(VerticalAlign.Top)
        }, (startIdx: number) => `relicrow_${startIdx}`)
        Row({ space: this.tm.current.value8 }) {
          if (this.vm.ornaments.length > 0) {
            this.RelicCard(this.vm.ornaments[0])
          } else {
            this.RelicPlaceholder(5)
          }
          if (this.vm.ornaments.length > 1) {
            this.RelicCard(this.vm.ornaments[1])
          } else {
            this.RelicPlaceholder(6)
          }
        }
        .width(this.tm.current.full)
        .alignItems(VerticalAlign.Top)
      }
      .width(this.tm.current.full)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  RelicPlaceholder(pos: number) {
    Column({ space: this.tm.current.value4 }) {
      SymbolGlyph($r('sys.symbol.lock'))
        .fontSize(this.tm.current.value20)
        .fontColor([this.tm.current.textOnDarkMuted])
      Text(this.relicPosName(pos))
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

  private relicPosName(pos: number): string {
    if (pos === 1) { return '头部'; }
    if (pos === 2) { return '手部'; }
    if (pos === 3) { return '躯干'; }
    if (pos === 4) { return '脚部'; }
    if (pos === 5) { return '位面球'; }
    if (pos === 6) { return '连结绳'; }
    return `${pos}`;
  }

  @Builder
  RelicCard(relic: StarRailCharDetailRelic) {
    Column({ space: this.tm.current.value4 }) {
      // 顶部：图标 + 名称 + 强化等级
      Row({ space: this.tm.current.value4 }) {
        if (relic.iconUrl !== '') {
          Image(relic.iconUrl)
            .width(this.tm.current.value32)
            .height(this.tm.current.value32)
            .objectFit(ImageFit.Contain)
        }
        Text(relic.name)
          .fontSize(this.tm.current.body12.size)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text(`+${relic.level}`)
          .fontSize(this.tm.current.value9)
          .fontColor(this.tm.current.textOnDarkGhost)
          .backgroundColor(this.tm.current.surfaceGlass)
          .borderRadius(this.tm.current.value4)
          .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
      }
      .width(this.tm.current.full)
      .alignItems(VerticalAlign.Center)
      // 主词条行
      Row() {
        Text(starRailPropertyTypeToName(relic.mainPropertyType))
          .fontSize(this.tm.current.body10.size)
          .fontColor(this.tm.current.accentPrimaryStrong)
          .layoutWeight(1)
        Text(relic.mainPropertyValue)
          .fontSize(this.tm.current.body13Bold.size)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
      }
      .width(this.tm.current.full)
      .padding({ top: this.tm.current.value2, bottom: this.tm.current.value2 })
      .border({ width: { bottom: this.tm.current.value1 }, color: this.tm.current.surfaceGlass })
      // 副词条列表
      Column() {
        ForEach(relic.subStats, (sub: StarRailRelicSubStat) => {
          Row() {
            Text(sub.name)
              .fontSize(this.tm.current.body10.size)
              .fontColor(this.tm.current.textOnDarkGhost)
              .layoutWeight(1)
            Text(sub.value)
              .fontSize(this.tm.current.body10.size)
              .fontColor(this.tm.current.textOnDarkHigh)
            if (sub.times > 0) {
              Text(`  ×${sub.times}`)
                .fontSize(this.tm.current.body10.size)
                .fontColor(this.tm.current.accentRefine)
            }
          }
          .width(this.tm.current.full)
          .padding({ top: this.tm.current.value1, bottom: this.tm.current.value1 })
        }, (_sub: StarRailRelicSubStat, idx: number) => `sub_${idx}`)
      }
      .width(this.tm.current.full)
    }
    .layoutWeight(1)
    .padding(this.tm.current.value8)
    .backgroundColor(this.tm.current.surfaceGlass)
    .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
    .borderRadius(this.tm.current.radius8)
  }
}

/**
 * CharDetailStatsPanel — 武器 + 属性列表区
 *
 * 宽屏中栏：武器卡片 + 属性列表（可滚动）
 * Phone：武器行 + 属性网格（嵌入滚动区）
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import {
  GenshinCharacterDetailViewModel,
  CharDetailStat
} from '../../viewmodel/GenshinCharacterDetailViewModel';
import { elementColor } from '../characters/CharacterCard';

@ComponentV2
export struct CharDetailStatsPanel {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  /** true = Phone 紧凑模式（横向属性网格），false = 宽屏列表模式 */
  @Param isPhone: boolean = false;
  /** Phone 属性网格列数 */
  @Param phoneCols: number = 2;
  @Local private tm: ThemeManager = themeManager;

  /** 构建星级数组（避免 Array.from，ArkTS 严格模式禁止） */
  private buildStarArray(count: number): number[] {
    const arr: number[] = [];
    for (let i = 0; i < count; i++) {
      arr[arr.length] = i;
    }
    return arr;
  }

  /** 武器区（宽屏卡片样式） */
  @Builder
  WeaponCard() {
    Column({ space: this.tm.current.value8 }) {
      Row({ space: this.tm.current.value10 }) {
        // 武器图标
        if (this.vm.weapon.iconUrl !== '') {
          Image(this.vm.weapon.iconUrl)
            .width(this.tm.current.charDetailWeaponIconSizeLG)
            .height(this.tm.current.charDetailWeaponIconSizeLG)
            .objectFit(ImageFit.Contain)
            .borderRadius(this.tm.current.value8)
            .backgroundColor('rgba(255,255,255,0.06)')
        } else {
          Column()
            .width(this.tm.current.charDetailWeaponIconSizeLG)
            .height(this.tm.current.charDetailWeaponIconSizeLG)
            .borderRadius(this.tm.current.value8)
            .backgroundColor('rgba(255,255,255,0.06)')
        }

        Column({ space: this.tm.current.value4 }) {
          Text(this.vm.weapon.name)
            .fontSize(this.tm.current.body13Bold.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Row({ space: this.tm.current.value8 }) {
            Text($r('app.string.char_detail_weapon_refine_prefix', this.vm.weapon.affix))
              .fontSize(this.tm.current.body10.size)
              .fontWeight(FontWeight.Bold)
              .fontColor('#ffca28')
              .backgroundColor('rgba(255,202,40,0.15)')
              .borderRadius(this.tm.current.value4)
              .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: 1, bottom: 1 })
            Text($r('app.string.char_detail_weapon_lv_prefix', this.vm.weapon.level, this.vm.weapon.maxLevel))
              .fontSize(this.tm.current.body10.size)
              .fontColor('rgba(255,255,255,0.5)')
          }
          if (this.vm.weapon.subLabel !== '') {
            Row({ space: this.tm.current.value4 }) {
              Text(this.vm.weapon.subLabel)
                .fontSize(this.tm.current.body12.size)
                .fontColor('rgba(255,255,255,0.6)')
              Text(this.vm.weapon.subVal)
                .fontSize(this.tm.current.body12.size)
                .fontColor(elementColor(this.vm.charElement))
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width(this.tm.current.widthFull)
      .alignItems(VerticalAlign.Center)

      // 星级
      Row({ space: 1 }) {
        ForEach(this.buildStarArray(this.vm.weapon.rarity), (_: number, idx: number) => {
          Text('★')
            .fontSize(this.tm.current.body12.size)
            .fontColor('#ffca28')
        }, (_: number, idx: number) => `star_${idx}`)
      }
    }
    .width(this.tm.current.widthFull)
    .padding(this.tm.current.value12)
    .backgroundColor('rgba(255,255,255,0.04)')
    .border({ width: { bottom: 1 }, color: 'rgba(255,255,255,0.07)' })
  }

  /** 武器行（Phone 紧凑样式） */
  @Builder
  WeaponRow() {
    Row({ space: this.tm.current.value8 }) {
      if (this.vm.weapon.iconUrl !== '') {
        Image(this.vm.weapon.iconUrl)
          .width(this.tm.current.charDetailWeaponIconSizeSM)
          .height(this.tm.current.charDetailWeaponIconSizeSM)
          .objectFit(ImageFit.Contain)
          .borderRadius(this.tm.current.value8)
          .backgroundColor('rgba(255,255,255,0.08)')
      }
      Column({ space: this.tm.current.value2 }) {
        Text(this.vm.weapon.name)
          .fontSize(this.tm.current.body13.size)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: this.tm.current.value4 }) {
          Text(`Lv.${this.vm.weapon.level}`)
            .fontSize(this.tm.current.body10.size)
            .fontColor('rgba(255,255,255,0.6)')
          Text($r('app.string.char_detail_weapon_refine_prefix', this.vm.weapon.affix))
            .fontSize(this.tm.current.body10.size)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ffca28')
            .backgroundColor('rgba(255,202,40,0.15)')
            .borderRadius(this.tm.current.value4)
            .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: 1, bottom: 1 })
          if (this.vm.weapon.subLabel !== '') {
            Row({ space: this.tm.current.value4 }) {
              Text(this.vm.weapon.subLabel)
                .fontSize(this.tm.current.body10.size)
                .fontColor('rgba(255,255,255,0.5)')
              Text(this.vm.weapon.subVal)
                .fontSize(this.tm.current.body10.size)
                .fontColor(elementColor(this.vm.charElement))
            }
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width(this.tm.current.widthFull)
    .padding({ left: this.tm.current.value10, right: this.tm.current.value10, top: this.tm.current.value8, bottom: this.tm.current.value8 })
    .backgroundColor('rgba(255,255,255,0.03)')
    .border({ width: { bottom: 1 }, color: 'rgba(255,255,255,0.06)' })
  }

  /** 属性列表（宽屏，每行一条） */
  @Builder
  StatsList() {
    Column() {
      ForEach(this.vm.stats, (stat: CharDetailStat) => {
        Row() {
          Text(stat.labelKey)
            .fontSize(this.tm.current.body13.size)
            .fontColor('rgba(255,255,255,0.7)')
            .layoutWeight(1)
          Text(stat.value)
            .fontSize(this.tm.current.body13Bold.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(stat.isHighlight ? elementColor(this.vm.charElement) : Color.White)
        }
        .width(this.tm.current.widthFull)
        .padding({
          left: this.tm.current.value16,
          right: this.tm.current.value16,
          top: this.tm.current.value8,
          bottom: this.tm.current.value8
        })
        .border({ width: { bottom: 1 }, color: 'rgba(255,255,255,0.05)' })
      }, (stat: CharDetailStat, idx: number) => `stat_${idx}`)
    }
    .width(this.tm.current.widthFull)
  }

  /** 属性网格（Phone，多列） */
  @Builder
  StatsGrid() {
    Grid() {
      ForEach(this.vm.stats, (stat: CharDetailStat) => {
        GridItem() {
          Row() {
            Text(stat.labelKey)
              .fontSize(this.tm.current.body12.size)
              .fontColor('rgba(255,255,255,0.6)')
              .layoutWeight(1)
            Text(stat.value)
              .fontSize(this.tm.current.body12.size)
              .fontWeight(FontWeight.Bold)
              .fontColor(stat.isHighlight ? elementColor(this.vm.charElement) : Color.White)
          }
          .width(this.tm.current.widthFull)
          .padding({ left: this.tm.current.value8, right: this.tm.current.value8, top: 5, bottom: 5 })
          .border({ width: { right: 1, bottom: 1 }, color: 'rgba(255,255,255,0.05)' })
        }
      }, (stat: CharDetailStat, idx: number) => `pstat_${idx}`)
    }
    .columnsTemplate(this.phoneCols === 4 ? '1fr 1fr 1fr 1fr' : '1fr 1fr')
    .width(this.tm.current.widthFull)
    .backgroundColor('rgba(0,0,0,0.25)')
  }

  build() {
    if (this.isPhone) {
      // Phone 模式：武器行 + 属性网格，直接输出（由父级 Scroll 包裹）
      Column() {
        this.WeaponRow()
        this.StatsGrid()
      }
      .width(this.tm.current.widthFull)
    } else {
      // 宽屏模式：武器卡片 + 可滚动属性列表
      Column() {
        this.WeaponCard()
        Scroll() {
          this.StatsList()
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .align(Alignment.Top)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width(this.tm.current.widthFull)
      .height(this.tm.current.heightFull)
      .borderRadius(this.tm.current.radius8)
      .backgroundColor('rgba(0,0,0,0.35)')
      .clip(true)
    }
  }
}

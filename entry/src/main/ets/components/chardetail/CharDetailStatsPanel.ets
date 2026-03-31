/**
 * CharDetailStatsPanel — 武器 + 属性列表区
 *
 * 宽屏中栏：武器卡片 + 属性列表（可滚动）
 * Phone：武器行 + 属性网格（嵌入滚动区）
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import {
  GenshinCharacterDetailViewModel,
  CharDetailStat,
  CharDetailWeapon
} from '../../viewmodel/GenshinCharacterDetailViewModel';
import { elementColor } from '../characters/CharacterCard';
import { GenshinElement } from '../../constants/GenshinElement';
import { ViewState } from '../../constants/ViewStates';

function makeMockStatsPanelVM(): GenshinCharacterDetailViewModel {
  const vm = new GenshinCharacterDetailViewModel();
  vm.viewState = ViewState.DATA;
  vm.charElement = GenshinElement.HYDRO;
  const w = new CharDetailWeapon();
  w.name = '苇海信标';
  w.level = 90;
  w.maxLevel = 90;
  w.affix = 1;
  w.rarity = 5;
  w.subLabel = $r('app.string.prop_crit_rate');
  w.subVal = '22.1%';
  vm.weapon = w;
  const stats: CharDetailStat[] = [];
  const rows: Array<[Resource, string, boolean]> = [
    [$r('app.string.char_detail_hp'), '38450', false],
    [$r('app.string.char_detail_atk'), '2847', false],
    [$r('app.string.char_detail_def'), '1024', false],
    [$r('app.string.char_detail_em'), '86', false],
    [$r('app.string.char_detail_cr'), '72.4%', true],
    [$r('app.string.char_detail_cd'), '198.6%', true],
    [$r('app.string.char_detail_er'), '132.0%', false],
  ];
  for (let i = 0; i < rows.length; i++) {
    stats[stats.length] = new CharDetailStat(rows[i][0], rows[i][1], rows[i][2]);
  }
  vm.stats = stats;
  return vm;
}

// ── Preview：宽屏模式（武器卡片 + 属性列表）──
@Preview
@ComponentV2
struct CharDetailStatsPanelPreviewWide {
  build() {
    CharDetailStatsPanel({
      vm: makeMockStatsPanelVM(),
      isPhone: false
    })
    .width(themeManager.current.value280)
    .height(themeManager.current.value480)
    .backgroundColor(themeManager.current.bgPageDeep)
  }
}

// ── Preview：Phone 模式（武器行 + 属性网格）──
@Preview
@ComponentV2
struct CharDetailStatsPanelPreviewPhone {
  build() {
    CharDetailStatsPanel({
      vm: makeMockStatsPanelVM(),
      isPhone: true,
      phoneCols: 2
    })
    .width(themeManager.current.value360)
    .backgroundColor(themeManager.current.bgPageDeep)
  }
}

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
            .width(this.tm.current.value52)
            .height(this.tm.current.value52)
            .objectFit(ImageFit.Contain)
            .borderRadius(this.tm.current.value8)
            .backgroundColor(this.tm.current.surfaceGlassSm)
        } else {
          Column()
            .width(this.tm.current.value52)
            .height(this.tm.current.value52)
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
            Text($r('app.string.char_detail_weapon_refine_prefix', this.vm.weapon.affix))
              .fontSize(this.tm.current.body10.size)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.tm.current.accentRefine)
              .backgroundColor(this.tm.current.accentRefineBg)
              .borderRadius(this.tm.current.value4)
              .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
            Text($r('app.string.char_detail_weapon_lv_prefix', this.vm.weapon.level, this.vm.weapon.maxLevel))
              .fontSize(this.tm.current.body10.size)
              .fontColor(this.tm.current.textOnDarkMuted)
          }
          if (this.vm.weapon.subLabel !== null) {
            Row({ space: this.tm.current.value4 }) {
              Text(this.vm.weapon.subLabel)
                .fontSize(this.tm.current.body12.size)
                .fontColor(this.tm.current.textOnDarkMuted)
              Text(this.vm.weapon.subVal)
                .fontSize(this.tm.current.body12.size)
                .fontColor(elementColor(this.vm.charElement))
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width(this.tm.current.full)
      .alignItems(VerticalAlign.Center)

      // 星级
      Row({ space: 1 }) {
        ForEach(this.buildStarArray(this.vm.weapon.rarity), (_: number, idx: number) => {
          Text('★')
            .fontSize(this.tm.current.body12.size)
            .fontColor(this.tm.current.accentRefine)
        }, (_: number, idx: number) => `star_${idx}`)
      }
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value12)
    .backgroundColor(this.tm.current.surfaceGlassXs)
    .border({ width: { bottom: this.tm.current.value1 }, color: this.tm.current.surfaceOverlayMd })
  }

  /** 武器行（Phone 紧凑样式） */
  @Builder
  WeaponRow() {
    Row({ space: this.tm.current.value8 }) {
      if (this.vm.weapon.iconUrl !== '') {
        Image(this.vm.weapon.iconUrl)
          .width(this.tm.current.value36)
          .height(this.tm.current.value36)
          .objectFit(ImageFit.Contain)
          .borderRadius(this.tm.current.value8)
          .backgroundColor(this.tm.current.surfaceGlassMd)
      }
      Column({ space: this.tm.current.value2 }) {
        Text(this.vm.weapon.name)
          .fontSize(this.tm.current.body13.size)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: this.tm.current.value4 }) {
          Text(`Lv.${this.vm.weapon.level}`)
            .fontSize(this.tm.current.body10.size)
            .fontColor(this.tm.current.textOnDarkGhost)
          Text($r('app.string.char_detail_weapon_refine_prefix', this.vm.weapon.affix))
            .fontSize(this.tm.current.body10.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tm.current.accentRefine)
            .backgroundColor(this.tm.current.accentRefineBg)
            .borderRadius(this.tm.current.value4)
            .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
          if (this.vm.weapon.subLabel !== null) {
            Row({ space: this.tm.current.value4 }) {
              Text(this.vm.weapon.subLabel)
                .fontSize(this.tm.current.body10.size)
                .fontColor(this.tm.current.textOnDarkMuted)
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
    .width(this.tm.current.full)
    .padding({ left: this.tm.current.value10, right: this.tm.current.value10, top: this.tm.current.value8, bottom: this.tm.current.value8 })
    .backgroundColor(this.tm.current.surfaceDarkXs)
    .border({ width: { bottom: this.tm.current.value1 }, color: this.tm.current.surfaceGlassSm })
  }

  /** 属性列表（宽屏，每行一条） */
  @Builder
  StatsList() {
    Column() {
      ForEach(this.vm.stats, (stat: CharDetailStat) => {
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
        .padding({
          left: this.tm.current.value16,
          right: this.tm.current.value16,
          top: this.tm.current.value8,
          bottom: this.tm.current.value8
        })
        .border({ width: { bottom: this.tm.current.value1 }, color: this.tm.current.surfaceOverlaySm })
      }, (stat: CharDetailStat, idx: number) => `stat_${idx}`)
    }
    .width(this.tm.current.full)
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
              .fontColor(this.tm.current.textOnDarkSecondary)
              .layoutWeight(1)
            Text(stat.value)
              .fontSize(this.tm.current.body12.size)
              .fontWeight(FontWeight.Bold)
              .fontColor(stat.isHighlight ? elementColor(this.vm.charElement) : this.tm.current.textOnDarkHigh)
          }
          .width(this.tm.current.full)
          .padding({ left: this.tm.current.value8, right: this.tm.current.value8, top: this.tm.current.value5, bottom: this.tm.current.value5 })
          .border({ width: { right: this.tm.current.value1, bottom: this.tm.current.value1 }, color: this.tm.current.surfaceOverlaySm })
        }
      }, (stat: CharDetailStat, idx: number) => `pstat_${idx}`)
    }
    .columnsTemplate(this.phoneCols === 4 ? '1fr 1fr 1fr 1fr' : '1fr 1fr')
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.surfaceDarkLg)
  }

  build() {
    if (this.isPhone) {
      // Phone 模式：武器行 + 属性网格，直接输出（由父级 Scroll 包裹）
      Column() {
        this.WeaponRow()
        this.StatsGrid()
      }
      .width(this.tm.current.full)
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
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .borderRadius(this.tm.current.radius8)
      .backgroundColor(this.tm.current.surfaceDarkXl)
      .clip(true)
    }
  }
}

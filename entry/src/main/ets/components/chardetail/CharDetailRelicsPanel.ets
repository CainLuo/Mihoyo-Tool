/**
 * CharDetailRelicsPanel — 圣遗物区
 *
 * 宽屏右栏：5个圣遗物等分高度，每条左侧图标+主词条+星级+强化，右侧2列×2行副词条
 * Phone：2列网格卡片，始终显示5个位置，未装备的显示占位
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailRelic, RelicSubStat } from './CharDetailModels';
import { GenshinElement } from '../../constants/GenshinElement';
import { ViewState } from '../../constants/ViewStates';

function makeSub(label: Resource, value: string): RelicSubStat {
  const s = new RelicSubStat();
  s.label = label;
  s.value = value;
  return s;
}

function makeMockRelicsPanelVM(): GenshinCharacterDetailViewModel {
  const vm = new GenshinCharacterDetailViewModel();
  vm.viewState = ViewState.DATA;
  vm.charElement = GenshinElement.HYDRO;
  const relicDefs: Array<[number, string, Resource, string]> = [
    [1, '花', $r('app.string.prop_hp_flat'), '4780'],
    [2, '羽', $r('app.string.prop_atk_flat'), '311'],
    [3, '沙', $r('app.string.prop_atk_pct'), '46.6%'],
    [4, '杯', $r('app.string.prop_hydro_dmg'), '46.6%'],
    [5, '冠', $r('app.string.prop_crit_rate'), '31.1%'],
  ];
  const relics: CharDetailRelic[] = [];
  for (let i = 0; i < relicDefs.length; i++) {
    const r = new CharDetailRelic();
    r.pos = relicDefs[i][0];
    r.setName = '追忆之注连';
    r.level = 20;
    r.rarity = 5;
    r.mainStatLabel = relicDefs[i][2];
    r.mainStatValue = relicDefs[i][3];
    r.subStats = [
      makeSub($r('app.string.prop_crit_rate'), '7.8%'),
      makeSub($r('app.string.prop_crit_dmg'), '15.6%'),
      makeSub($r('app.string.prop_atk_pct'), '5.8%'),
      makeSub($r('app.string.prop_energy_recharge'), '11.0%'),
    ];
    relics[relics.length] = r;
  }
  vm.relics = relics;
  return vm;
}

@Preview
@ComponentV2
export struct CharDetailRelicsPanelPreviewWide {
  build() {
    CharDetailRelicsPanel({ vm: makeMockRelicsPanelVM(), isPhone: false })
      .width(themeManager.current.value280)
      .height(themeManager.current.value480)
      .backgroundColor(themeManager.current.bgPageDeep)
  }
}

@Preview
@ComponentV2
export struct CharDetailRelicsPanelPreviewPhone {
  build() {
    Scroll() {
      CharDetailRelicsPanel({ vm: makeMockRelicsPanelVM(), isPhone: true })
        .padding(themeManager.current.value8)
    }
    .width(themeManager.current.value360)
    .height(themeManager.current.value600)
    .backgroundColor(themeManager.current.bgPageDeep)
  }
}

@ComponentV2
export struct CharDetailRelicsPanel {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  @Param isPhone: boolean = false;
  @Local private tm: ThemeManager = themeManager;

  private starsText(n: number): string {
    let s = '';
    for (let i = 0; i < n; i++) { s += '★'; }
    return s;
  }

  private relicPosName(pos: number): string {
    if (pos === 1) { return '生之花'; }
    if (pos === 2) { return '死之羽'; }
    if (pos === 3) { return '时之沙'; }
    if (pos === 4) { return '空之杯'; }
    if (pos === 5) { return '理之冠'; }
    return `${pos}`;
  }

  private findRelicByPos(pos: number): CharDetailRelic | null {
    for (let i = 0; i < this.vm.relics.length; i++) {
      if (this.vm.relics[i].pos === pos) { return this.vm.relics[i]; }
    }
    return null;
  }

  @Builder
  RelicRow(relic: CharDetailRelic) {
    Row() {
      Column({ space: this.tm.current.value2 }) {
        if (relic.iconUrl !== '') {
          Image(relic.iconUrl)
            .width(this.tm.current.value40)
            .height(this.tm.current.value40)
            .objectFit(ImageFit.Contain)
        } else {
          Column()
            .width(this.tm.current.value40)
            .height(this.tm.current.value40)
            .backgroundColor(this.tm.current.surfaceGlass)
            .borderRadius(this.tm.current.value4)
        }
        Text(relic.mainStatLabel ?? $r('app.string.char_detail_no_data'))
          .fontSize(this.tm.current.value9)
          .fontColor(this.tm.current.textOnDarkMuted)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(relic.mainStatValue)
          .fontSize(this.tm.current.body16.size)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
          .maxLines(1)
        Text(this.starsText(relic.rarity))
          .fontSize(this.tm.current.body10.size)
          .fontColor(this.tm.current.accentRefine)
        Text($r('app.string.char_detail_relic_lv_prefix', relic.level))
          .fontSize(this.tm.current.value9)
          .fontColor(this.tm.current.textOnDarkFaint)
      }
      .width(this.tm.current.value90)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding({ top: this.tm.current.value4, bottom: this.tm.current.value4 })
      .border({ width: { right: this.tm.current.value1 }, color: this.tm.current.surfaceGlass })
      Grid() {
        ForEach(relic.subStats, (sub: RelicSubStat) => {
          GridItem() {
            Row() {
              Text(sub.label ?? $r('app.string.char_detail_no_data'))
                .fontSize(this.tm.current.body10.size)
                .fontColor(this.tm.current.textOnDarkTertiary)
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(sub.value)
                .fontSize(this.tm.current.body12.size)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.tm.current.textOnDarkHigh)
            }
            .width(this.tm.current.full)
            .padding({ left: this.tm.current.value8, right: this.tm.current.value4, top: this.tm.current.value2, bottom: this.tm.current.value2 })
          }
        }, (sub: RelicSubStat, idx: number) => `sub_${relic.pos}_${idx}`)
      }
      .columnsTemplate('1fr 1fr')
      .layoutWeight(1)
    }
    .width(this.tm.current.full)
    .layoutWeight(1)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.tm.current.surfaceDarkMd)
    .border({ width: { bottom: this.tm.current.value1 }, color: this.tm.current.surfaceGlass })
  }

  @Builder
  RelicCard(relic: CharDetailRelic) {
    Column({ space: this.tm.current.value4 }) {
      Row({ space: this.tm.current.value4 }) {
        if (relic.iconUrl !== '') {
          Image(relic.iconUrl)
            .width(this.tm.current.value32)
            .height(this.tm.current.value32)
            .objectFit(ImageFit.Contain)
        }
        Column({ space: this.tm.current.value2 }) {
          Text(relic.setName !== '' ? relic.setName : (relic.mainStatLabel ?? $r('app.string.char_detail_no_data')))
            .fontSize(this.tm.current.body12.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tm.current.textOnDarkHigh)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(relic.mainStatLabel ?? $r('app.string.char_detail_no_data'))
            .fontSize(this.tm.current.value9)
            .fontColor(this.tm.current.textOnDarkMuted)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text($r('app.string.char_detail_relic_lv_prefix', relic.level))
          .fontSize(this.tm.current.value9)
          .fontColor(this.tm.current.textOnDarkGhost)
          .backgroundColor(this.tm.current.surfaceGlass)
          .borderRadius(this.tm.current.value4)
          .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
      }
      .width(this.tm.current.full)
      .alignItems(VerticalAlign.Center)
      Row() {
        Text(relic.mainStatLabel ?? $r('app.string.char_detail_no_data'))
          .fontSize(this.tm.current.body10.size)
          .fontColor(this.tm.current.accentPrimaryStrong)
          .layoutWeight(1)
        Text(relic.mainStatValue)
          .fontSize(this.tm.current.body13Bold.size)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
      }
      .width(this.tm.current.full)
      .padding({ top: this.tm.current.value2, bottom: this.tm.current.value2 })
      .border({ width: { bottom: this.tm.current.value1 }, color: this.tm.current.surfaceGlass })
      Column() {
        ForEach(relic.subStats, (sub: RelicSubStat) => {
          Row() {
            Text(sub.label ?? $r('app.string.char_detail_no_data'))
              .fontSize(this.tm.current.body10.size)
              .fontColor(this.tm.current.textOnDarkGhost)
              .layoutWeight(1)
            Text(sub.value)
              .fontSize(this.tm.current.body10.size)
              .fontColor(this.tm.current.textOnDarkHigh)
          }
          .width(this.tm.current.full)
          .padding({ top: this.tm.current.value1, bottom: this.tm.current.value1 })
        }, (sub: RelicSubStat, idx: number) => `psub_${relic.pos}_${idx}`)
      }
      .width(this.tm.current.full)
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value8)
    .backgroundColor(this.tm.current.surfaceGlass)
    .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
    .borderRadius(this.tm.current.radius8)
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
    .width(this.tm.current.full)
    .height(this.tm.current.value80)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.tm.current.surfaceGlass)
    .border({ width: this.tm.current.value1, color: this.tm.current.surfaceInactiveBorder, style: BorderStyle.Dashed })
    .borderRadius(this.tm.current.radius8)
  }

  /** Phone：pos1+pos2 一行 */
  @Builder
  RelicRow12() {
    Row({ space: this.tm.current.value8 }) {
      if (this.findRelicByPos(1) !== null) {
        Column() { this.RelicCard(this.vm.relics[this.relicIdx(1)]) }.layoutWeight(1)
      } else {
        Column() { this.RelicPlaceholder(1) }.layoutWeight(1)
      }
      if (this.findRelicByPos(2) !== null) {
        Column() { this.RelicCard(this.vm.relics[this.relicIdx(2)]) }.layoutWeight(1)
      } else {
        Column() { this.RelicPlaceholder(2) }.layoutWeight(1)
      }
    }
    .width(this.tm.current.full)
    .alignItems(VerticalAlign.Top)
  }

  /** Phone：pos3+pos4 一行 */
  @Builder
  RelicRow34() {
    Row({ space: this.tm.current.value8 }) {
      if (this.findRelicByPos(3) !== null) {
        Column() { this.RelicCard(this.vm.relics[this.relicIdx(3)]) }.layoutWeight(1)
      } else {
        Column() { this.RelicPlaceholder(3) }.layoutWeight(1)
      }
      if (this.findRelicByPos(4) !== null) {
        Column() { this.RelicCard(this.vm.relics[this.relicIdx(4)]) }.layoutWeight(1)
      } else {
        Column() { this.RelicPlaceholder(4) }.layoutWeight(1)
      }
    }
    .width(this.tm.current.full)
    .alignItems(VerticalAlign.Top)
  }

  /** Phone：pos5 单独一行（居左，右侧空白） */
  @Builder
  RelicRow5() {
    Row({ space: this.tm.current.value8 }) {
      if (this.findRelicByPos(5) !== null) {
        Column() { this.RelicCard(this.vm.relics[this.relicIdx(5)]) }.layoutWeight(1)
      } else {
        Column() { this.RelicPlaceholder(5) }.layoutWeight(1)
      }
      Column().layoutWeight(1)
    }
    .width(this.tm.current.full)
    .alignItems(VerticalAlign.Top)
  }

  private relicIdx(pos: number): number {
    for (let i = 0; i < this.vm.relics.length; i++) {
      if (this.vm.relics[i].pos === pos) { return i; }
    }
    return 0;
  }

  build() {
    if (this.isPhone) {
      Column({ space: this.tm.current.value8 }) {
        this.RelicRow12()
        this.RelicRow34()
        this.RelicRow5()
      }
      .width(this.tm.current.full)
    } else {
      Column() {
        ForEach(this.vm.relics, (relic: CharDetailRelic) => {
          this.RelicRow(relic)
        }, (relic: CharDetailRelic) => `relic_${relic.pos}`)
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .borderRadius(this.tm.current.radius8)
      .backgroundColor(this.tm.current.surfaceDarkMd)
      .clip(true)
    }
  }
}

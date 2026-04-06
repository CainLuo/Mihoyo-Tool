/**
 * CharDetailRelicsPanel — 圣遗物区
 *
 * 宽屏右栏：5个圣遗物等分高度，每条左侧图标+主词条+星级+强化，右侧2列×2行副词条
 * Phone：2列网格卡片（嵌入滚动区）
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import {
  GenshinCharacterDetailViewModel
} from '../../viewmodel/GenshinCharacterDetailViewModel';
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

// ── Preview：宽屏模式（5行等分）──
@Preview
@ComponentV2
struct CharDetailRelicsPanelPreviewWide {
  build() {
    CharDetailRelicsPanel({
      vm: makeMockRelicsPanelVM(),
      isPhone: false
    })
    .width(themeManager.current.value280)
    .height(themeManager.current.value480)
    .backgroundColor(themeManager.current.bgPageDeep)
  }
}

// ── Preview：Phone 模式（2列网格卡片）──
@Preview
@ComponentV2
struct CharDetailRelicsPanelPreviewPhone {
  build() {
    Scroll() {
      CharDetailRelicsPanel({
        vm: makeMockRelicsPanelVM(),
        isPhone: true
      })
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
  /** true = Phone 卡片模式，false = 宽屏等分行模式 */
  @Param isPhone: boolean = false;
  @Local private tm: ThemeManager = themeManager;

  /** 星级文字 */
  private starsText(n: number): string {
    let s = '';
    for (let i = 0; i < n; i++) {
      s += '★';
    }
    return s;
  }

  /** 宽屏：单条圣遗物行（flex:1 等分高度） */
  @Builder
  RelicRow(relic: CharDetailRelic) {
    Row() {
      // 左侧：图标 + 主词条 + 星级 + 强化
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
            .backgroundColor(this.tm.current.surfaceGlassMd)
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
      .border({ width: { right: this.tm.current.value1 }, color: this.tm.current.surfaceGlassSm })

      // 右侧：2列×2行副词条
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
    .border({ width: { bottom: this.tm.current.value1 }, color: this.tm.current.surfaceGlassSm })
  }

  /** Phone：单个圣遗物卡片 */
  @Builder
  RelicCard(relic: CharDetailRelic) {
    Column({ space: this.tm.current.value4 }) {
      // 头部：图标 + 名称 + 强化等级
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
          .backgroundColor(this.tm.current.surfaceGlassMd)
          .borderRadius(this.tm.current.value4)
          .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
      }
      .width(this.tm.current.full)
      .alignItems(VerticalAlign.Center)

      // 主词条
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
      .border({ width: { bottom: this.tm.current.value1 }, color: this.tm.current.surfaceGlassSm })

      // 副词条
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
    .backgroundColor(this.tm.current.surfaceGlassXs)
    .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlassMd })
    .borderRadius(this.tm.current.radius8)
  }

  build() {
    if (this.isPhone) {
      // Phone：2列网格，由父级 Scroll 包裹
      Grid() {
        ForEach(this.vm.relics, (relic: CharDetailRelic) => {
          GridItem() {
            this.RelicCard(relic)
          }
        }, (relic: CharDetailRelic) => `relic_${relic.pos}`)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(this.tm.current.value8)
      .rowsGap(this.tm.current.value8)
      .width(this.tm.current.full)
    } else {
      // 宽屏：5行等分，Column + layoutWeight(1)
      Column() {
        ForEach(this.vm.relics, (relic: CharDetailRelic) => {
          this.RelicRow(relic)
        }, (relic: CharDetailRelic) => `relic_${relic.pos}`)
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .borderRadius(this.tm.current.radius8)
      .backgroundColor(this.tm.current.surfaceDarkLg)
      .clip(true)
    }
  }
}

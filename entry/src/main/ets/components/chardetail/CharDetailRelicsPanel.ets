/**
 * CharDetailRelicsPanel — 圣遗物区
 *
 * 宽屏右栏：5个圣遗物等分高度，每条左侧图标+主词条+星级+强化，右侧2列×2行副词条
 * Phone：2列网格卡片（嵌入滚动区）
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import {
  GenshinCharacterDetailViewModel,
  CharDetailRelic,
  RelicSubStat
} from '../../viewmodel/GenshinCharacterDetailViewModel';

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
            .width(this.tm.current.relicIconSizeLG)
            .height(this.tm.current.relicIconSizeLG)
            .objectFit(ImageFit.Contain)
        } else {
          Column()
            .width(this.tm.current.relicIconSizeLG)
            .height(this.tm.current.relicIconSizeLG)
            .backgroundColor('rgba(255,255,255,0.08)')
            .borderRadius(this.tm.current.value4)
        }
        Text(relic.mainStatLabel)
          .fontSize(9)
          .fontColor('rgba(255,255,255,0.5)')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(relic.mainStatValue)
          .fontSize(this.tm.current.body16.size)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .maxLines(1)
        Text(this.starsText(relic.rarity))
          .fontSize(this.tm.current.body10.size)
          .fontColor('#ffca28')
        Text($r('app.string.char_detail_relic_lv_prefix', relic.level))
          .fontSize(9)
          .fontColor('rgba(255,255,255,0.4)')
      }
      .width(this.tm.current.charDetailRelicLeftColWidth)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding({ top: this.tm.current.value4, bottom: this.tm.current.value4 })
      .border({ width: { right: 1 }, color: 'rgba(255,255,255,0.06)' })

      // 右侧：2列×2行副词条
      Grid() {
        ForEach(relic.subStats, (sub: RelicSubStat) => {
          GridItem() {
            Row() {
              Text(sub.label)
                .fontSize(this.tm.current.body10.size)
                .fontColor('rgba(255,255,255,0.55)')
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(sub.value)
                .fontSize(this.tm.current.body12.size)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
            .width(this.tm.current.widthFull)
            .padding({ left: this.tm.current.value8, right: this.tm.current.value4, top: 2, bottom: 2 })
          }
        }, (sub: RelicSubStat, idx: number) => `sub_${relic.pos}_${idx}`)
      }
      .columnsTemplate('1fr 1fr')
      .layoutWeight(1)
    }
    .width(this.tm.current.widthFull)
    .layoutWeight(1)
    .alignItems(VerticalAlign.Center)
    .backgroundColor('rgba(0,0,0,0.15)')
    .border({ width: { bottom: 1 }, color: 'rgba(255,255,255,0.06)' })
  }

  /** Phone：单个圣遗物卡片 */
  @Builder
  RelicCard(relic: CharDetailRelic) {
    Column({ space: this.tm.current.value4 }) {
      // 头部：图标 + 名称 + 强化等级
      Row({ space: this.tm.current.value4 }) {
        if (relic.iconUrl !== '') {
          Image(relic.iconUrl)
            .width(this.tm.current.relicIconSizeSM)
            .height(this.tm.current.relicIconSizeSM)
            .objectFit(ImageFit.Contain)
        }
        Column({ space: 2 }) {
          Text(relic.setName !== '' ? relic.setName : relic.mainStatLabel)
            .fontSize(this.tm.current.body12.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(relic.mainStatLabel)
            .fontSize(9)
            .fontColor('rgba(255,255,255,0.5)')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text($r('app.string.char_detail_relic_lv_prefix', relic.level))
          .fontSize(9)
          .fontColor('rgba(255,255,255,0.6)')
          .backgroundColor('rgba(255,255,255,0.08)')
          .borderRadius(this.tm.current.value4)
          .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: 1, bottom: 1 })
      }
      .width(this.tm.current.widthFull)
      .alignItems(VerticalAlign.Center)

      // 主词条
      Row() {
        Text(relic.mainStatLabel)
          .fontSize(this.tm.current.body10.size)
          .fontColor('rgba(79,195,247,0.9)')
          .layoutWeight(1)
        Text(relic.mainStatValue)
          .fontSize(this.tm.current.body13Bold.size)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width(this.tm.current.widthFull)
      .padding({ top: 2, bottom: 2 })
      .border({ width: { bottom: 1 }, color: 'rgba(255,255,255,0.06)' })

      // 副词条
      Column() {
        ForEach(relic.subStats, (sub: RelicSubStat) => {
          Row() {
            Text(sub.label)
              .fontSize(this.tm.current.body10.size)
              .fontColor('rgba(255,255,255,0.6)')
              .layoutWeight(1)
            Text(sub.value)
              .fontSize(this.tm.current.body10.size)
              .fontColor('#dddddd')
          }
          .width(this.tm.current.widthFull)
          .padding({ top: 1, bottom: 1 })
        }, (sub: RelicSubStat, idx: number) => `psub_${relic.pos}_${idx}`)
      }
      .width(this.tm.current.widthFull)
    }
    .width(this.tm.current.widthFull)
    .padding(this.tm.current.value8)
    .backgroundColor('rgba(255,255,255,0.04)')
    .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
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
      .width(this.tm.current.widthFull)
    } else {
      // 宽屏：5行等分，Column + layoutWeight(1)
      Column() {
        ForEach(this.vm.relics, (relic: CharDetailRelic) => {
          this.RelicRow(relic)
        }, (relic: CharDetailRelic) => `relic_${relic.pos}`)
      }
      .width(this.tm.current.widthFull)
      .height(this.tm.current.heightFull)
      .borderRadius(this.tm.current.radius8)
      .backgroundColor('rgba(0,0,0,0.25)')
      .clip(true)
    }
  }
}

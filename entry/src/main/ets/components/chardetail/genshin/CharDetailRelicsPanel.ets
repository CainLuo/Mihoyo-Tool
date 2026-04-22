/**
 * CharDetailRelicsPanel — 圣遗物区
 *
 * 宽屏右栏：5个圣遗物等分高度，每条左侧图标+主词条+星级+强化，右侧2列×2行副词条
 * Phone：2列网格卡片，始终显示5个位置，未装备的显示占位
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailRelic } from '../../../models/CharDetailModels';
import { GenshinElement } from '../../../constants/GenshinElement';
import { CharDetailRelicRow } from './CharDetailRelicRow';
import { CharDetailRelicCard } from './CharDetailRelicCard';
import { CharDetailRelicPlaceholder } from '../common/CharDetailRelicPlaceholder';
import { ViewState } from '../../../constants/ViewStates';

function makeMockRelicsPanelVM(): GenshinCharacterDetailViewModel {
  const vm = new GenshinCharacterDetailViewModel();
  vm.viewState = ViewState.DATA;
  vm.charElement = GenshinElement.HYDRO;
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

  private relicPosName(pos: number): Resource {
    if (pos === 1) { return $r('app.string.char_detail_relic_pos_flower'); }
    if (pos === 2) { return $r('app.string.char_detail_relic_pos_plume'); }
    if (pos === 3) { return $r('app.string.char_detail_relic_pos_sands'); }
    if (pos === 4) { return $r('app.string.char_detail_relic_pos_goblet'); }
    if (pos === 5) { return $r('app.string.char_detail_relic_pos_circlet'); }
    return $r('app.string.char_detail_relic_pos_flower');
  }

  private findRelicByPos(pos: number): CharDetailRelic | null {
    for (let i = 0; i < this.vm.relics.length; i++) {
      if (this.vm.relics[i].pos === pos) { return this.vm.relics[i]; }
    }
    return null;
  }

  private relicIdx(pos: number): number {
    for (let i = 0; i < this.vm.relics.length; i++) {
      if (this.vm.relics[i].pos === pos) { return i; }
    }
    return 0;
  }

  @Builder
  RelicPlaceholder(pos: number) {
    CharDetailRelicPlaceholder({ posName: this.relicPosName(pos) })
  }

  @Builder
  RelicPair(pos1: number, pos2: number) {
    Row({ space: this.tm.current.value8 }) {
      if (this.findRelicByPos(pos1) !== null) {
        Column() { CharDetailRelicCard({ relic: this.vm.relics[this.relicIdx(pos1)] }) }.layoutWeight(1)
      } else {
        Column() { this.RelicPlaceholder(pos1) }.layoutWeight(1)
      }
      if (this.findRelicByPos(pos2) !== null) {
        Column() { CharDetailRelicCard({ relic: this.vm.relics[this.relicIdx(pos2)] }) }.layoutWeight(1)
      } else {
        Column() { this.RelicPlaceholder(pos2) }.layoutWeight(1)
      }
    }
    .width(this.tm.current.full)
    .alignItems(VerticalAlign.Top)
  }

  build() {
    if (this.isPhone) {
      Column({ space: this.tm.current.value8 }) {
        this.RelicPair(1, 2)
        this.RelicPair(3, 4)
        // pos5 单独一行（居左，右侧空白）
        Row({ space: this.tm.current.value8 }) {
          if (this.findRelicByPos(5) !== null) {
            Column() { CharDetailRelicCard({ relic: this.vm.relics[this.relicIdx(5)] }) }.layoutWeight(1)
          } else {
            Column() { this.RelicPlaceholder(5) }.layoutWeight(1)
          }
          Column().layoutWeight(1)
        }
        .width(this.tm.current.full)
        .alignItems(VerticalAlign.Top)
      }
      .width(this.tm.current.full)
    } else {
      Column() {
        ForEach(this.vm.relics, (relic: CharDetailRelic) => {
          CharDetailRelicRow({ relic: relic })
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

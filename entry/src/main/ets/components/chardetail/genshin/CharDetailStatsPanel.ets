/**
 * CharDetailStatsPanel — 武器 + 属性列表区
 *
 * 宽屏中栏：武器卡片 + 属性列表（可滚动）
 * Phone：武器行 + 属性网格（嵌入滚动区）
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailStat } from '../../../models/CharDetailModels';
import { GenshinElement } from '../../../constants/GenshinElement';
import { CharDetailWeaponCard } from './CharDetailWeaponCard';
import { CharDetailWeaponRow } from './CharDetailWeaponRow';
import { CharDetailStatRow } from '../common/CharDetailStatRow';
import { ViewState } from '../../../constants/ViewStates';

function makeMockStatsPanelVM(): GenshinCharacterDetailViewModel {
  const vm = new GenshinCharacterDetailViewModel();
  vm.viewState = ViewState.DATA;
  vm.charElement = GenshinElement.HYDRO;
  return vm;
}

// ── Preview：宽屏模式 ──
@Preview
@ComponentV2
export struct CharDetailStatsPanelPreviewWide {
  build() {
    CharDetailStatsPanel({ vm: makeMockStatsPanelVM(), isPhone: false })
      .width(themeManager.current.value280)
      .height(themeManager.current.value480)
      .backgroundColor(themeManager.current.bgPageDeep)
  }
}

// ── Preview：Phone 模式 ──
@Preview
@ComponentV2
export struct CharDetailStatsPanelPreviewPhone {
  build() {
    CharDetailStatsPanel({ vm: makeMockStatsPanelVM(), isPhone: true, phoneCols: 2 })
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

  build() {
    if (this.isPhone) {
      Column() {
        CharDetailWeaponRow({ weapon: this.vm.weapon, charElement: this.vm.charElement })
        this.StatsGrid()
      }
      .width(this.tm.current.full)
      .backgroundColor(this.tm.current.surfaceDarkLg)
      .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
      .borderRadius(this.tm.current.radius12)
      .clip(true)
    } else {
      Column() {
        CharDetailWeaponCard({ weapon: this.vm.weapon, charElement: this.vm.charElement })
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
      .backgroundColor(this.tm.current.surfaceDarkLg)
      .clip(true)
    }
  }

  /** 属性列表（宽屏，每行一条） */
  @Builder
  StatsList() {
    Column() {
      ForEach(this.vm.stats, (stat: CharDetailStat) => {
        CharDetailStatRow({ stat: stat, charElement: this.vm.charElement })
          .padding({
            left: this.tm.current.font16, right: this.tm.current.font16,
            top: this.tm.current.value8, bottom: this.tm.current.value8
          })
          .border({ width: { bottom: this.tm.current.value1 }, color: this.tm.current.surfaceGlass })
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
          CharDetailStatRow({ stat: stat, charElement: this.vm.charElement, isCompact: true })
            .padding({ left: this.tm.current.value8, right: this.tm.current.value8, top: this.tm.current.value5, bottom: this.tm.current.value5 })
            .border({ width: { right: this.tm.current.value1, bottom: this.tm.current.value1 }, color: this.tm.current.surfaceGlass })
        }
      }, (stat: CharDetailStat, idx: number) => `pstat_${idx}`)
    }
    .columnsTemplate(this.phoneCols === 4 ? '1fr 1fr 1fr 1fr' : '1fr 1fr')
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.surfaceDarkMd)
    .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
    .borderRadius(this.tm.current.radius8)
  }
}

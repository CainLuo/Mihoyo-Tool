/**
 * CharDetailWideLayout — 角色详情宽屏三栏布局
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailHeroPanel } from './CharDetailHeroPanel';
import { CharDetailStatsPanel } from './CharDetailStatsPanel';
import { CharDetailRelicsPanel } from './CharDetailRelicsPanel';
import { CharDetailMaterialCalcEntry } from '../common/CharDetailMaterialCalcEntry';
import { HeroPanelMode } from '../../../constants/HeroPanelMode';
import { GameId } from 'core';

@ComponentV2
export struct CharDetailWideLayout {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  @Param onMaterialCalcTap: () => void = () => {};
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: this.tm.current.value8 }) {
      CharDetailHeroPanel({ vm: this.vm, mode: HeroPanelMode.WIDE })
        .layoutWeight(1)
        .height(this.tm.current.full)
        .borderRadius(this.tm.current.radius8)
        .clip(true)

      Column({ space: this.tm.current.value8 }) {
        CharDetailStatsPanel({ vm: this.vm, isPhone: false })
          .layoutWeight(1)
        
        // 材料计算入口
        CharDetailMaterialCalcEntry({ 
          gameId: GameId.GENSHIN,
          onTap: this.onMaterialCalcTap 
        })
      }
      .layoutWeight(1)
      .height(this.tm.current.full)

      CharDetailRelicsPanel({ vm: this.vm, isPhone: false })
        .layoutWeight(1)
        .height(this.tm.current.full)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .padding(this.tm.current.value8)
  }
}

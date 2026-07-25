/**
 * CharDetailPortraitLayout — 角色详情 Phone 竖屏布局
 *
 * 布局：英雄区 → 技能 → 武器 → 属性（单列）→ 圣遗物 → 材料计算入口
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailHeroPanel } from './CharDetailHeroPanel';
import { CharDetailPortraitSkillsSection } from './CharDetailPortraitSkillsSection';
import { CharDetailPortraitWeaponSection } from './CharDetailPortraitWeaponSection';
import { CharDetailPortraitStatsSection } from './CharDetailPortraitStatsSection';
import { CharDetailPortraitRelicsSection } from './CharDetailPortraitRelicsSection';
import { CharDetailMaterialCalcEntry } from '../common/CharDetailMaterialCalcEntry';
import { HeroPanelMode } from '../../../constants/HeroPanelMode';
import { GameId } from 'core';

@ComponentV2
export struct CharDetailPortraitLayout {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  @Param onMaterialCalcTap: () => void = () => {};
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      Scroll() {
        Column() {
          CharDetailHeroPanel({ vm: this.vm, mode: HeroPanelMode.PORTRAIT })
            .height(this.tm.current.value260)
            .width(this.tm.current.full)

          Column({ space: this.tm.current.value8 }) {
            CharDetailPortraitSkillsSection({ vm: this.vm })

            CharDetailPortraitWeaponSection({ vm: this.vm })

            CharDetailPortraitStatsSection({ vm: this.vm })

            CharDetailPortraitRelicsSection({ vm: this.vm })

            // 材料计算入口
            CharDetailMaterialCalcEntry({ 
              gameId: GameId.GENSHIN,
              onTap: this.onMaterialCalcTap 
            })

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
}

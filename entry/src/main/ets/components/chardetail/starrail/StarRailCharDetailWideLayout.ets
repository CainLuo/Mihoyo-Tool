/**
 * StarRailCharDetailWideLayout — 星穹铁道角色详情宽屏两栏布局
 *
 * 左栏：立绘 + 行迹
 * 右栏：光锥 + 属性 + 遗器/饰品（可滚动）
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { StarRailCharacterDetailViewModel } from '../../../viewmodel/StarRailCharacterDetailViewModel';
import { StarRailCharDetailHero } from './StarRailCharDetailHero';
import { StarRailSkillsSection } from './StarRailSkillsSection';
import { StarRailEquipSection } from './StarRailEquipSection';
import { StarRailPropsSection } from './StarRailPropsSection';
import { StarRailRelicsSection } from './StarRailRelicsSection';

@ComponentV2
export struct StarRailCharDetailWideLayout {
  @Param vm: StarRailCharacterDetailViewModel = new StarRailCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: this.tm.current.value8 }) {
      // 左栏：立绘 + 行迹
      Column({ space: this.tm.current.value8 }) {
        StarRailCharDetailHero({ vm: this.vm, heroHeight: this.tm.current.value260 })
          .borderRadius(this.tm.current.radius8)
          .clip(true)

        StarRailSkillsSection({ vm: this.vm })
      }
      .layoutWeight(1)
      .height(this.tm.current.full)

      // 右栏：光锥 + 属性 + 遗器（可滚动）
      Scroll() {
        Column({ space: this.tm.current.value8 }) {
          StarRailEquipSection({ vm: this.vm })

          StarRailPropsSection({ vm: this.vm })

          StarRailRelicsSection({ vm: this.vm })

          Row().height(this.tm.current.value16)
        }
        .width(this.tm.current.full)
        .padding({ left: this.tm.current.value12, right: this.tm.current.value12 })
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
      .height(this.tm.current.full)
      .align(Alignment.Top)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .padding(this.tm.current.value8)
    .alignItems(VerticalAlign.Top)
  }
}

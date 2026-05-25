/**
 * ZZZCharDetailWideLayout — 绝区零角色详情宽屏两栏布局
 *
 * 左栏：立绘 + 技能
 * 右栏：音擎 + 属性 + 驱动盘（可滚动）
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ZZZCharacterDetailViewModel } from '../../../viewmodel/ZZZCharacterDetailViewModel';
import { ZZZCharDetailHero } from './ZZZCharDetailHero';
import { ZZZSkillsSection } from './ZZZSkillsSection';
import { ZZZWeaponSection } from './ZZZWeaponSection';
import { ZZZPropsSection } from './ZZZPropsSection';
import { ZZZEquipSection } from './ZZZEquipSection';

@ComponentV2
export struct ZZZCharDetailWideLayout {
  @Param vm: ZZZCharacterDetailViewModel = new ZZZCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: this.tm.current.value8 }) {
      // 左栏：立绘 + 技能
      Column({ space: this.tm.current.value8 }) {
        ZZZCharDetailHero({ vm: this.vm, heroHeight: this.tm.current.value260 })
          .borderRadius(this.tm.current.radius8)
          .clip(true)

        ZZZSkillsSection({ vm: this.vm })
      }
      .layoutWeight(1)
      .height(this.tm.current.full)

      // 右栏：音擎 + 属性 + 驱动盘（可滚动）
      Scroll() {
        Column({ space: this.tm.current.value8 }) {
          ZZZWeaponSection({ vm: this.vm })

          ZZZPropsSection({ vm: this.vm })

          ZZZEquipSection({ vm: this.vm })

          Row().height(this.tm.current.font16)
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

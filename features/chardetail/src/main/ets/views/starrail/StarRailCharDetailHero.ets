/**
 * StarRailCharDetailHero — 星穹铁道角色详情英雄区
 *
 * 立绘贴右，左侧渐变遮罩，左下角名字+等级+星魂，左侧命座纵列居中。
 * 通用骨架见 `CharDetailHeroScaffold`。
 */
import { themeManager, ThemeManager } from 'basic';
import { StarRailCharacterDetailViewModel } from '../../viewmodel/StarRailCharacterDetailViewModel';
import { CharDetailHeroScaffold } from '../common/CharDetailHeroScaffold';
import { StarRailCharDetailHeroProfile } from './StarRailCharDetailHeroProfile';

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct StarRailCharDetailHeroPreview {
  build() {
    StarRailCharDetailHero({
      vm: new StarRailCharacterDetailViewModel(),
      heroHeight: 260
    })
    .backgroundColor('#1a1a2e')
  }
}

@ComponentV2
export struct StarRailCharDetailHero {
  @Param vm: StarRailCharacterDetailViewModel = new StarRailCharacterDetailViewModel();
  @Param heroHeight: number = 260;
  @Local private tm: ThemeManager = themeManager;

  @Builder
  heroInfo() {
    StarRailCharDetailHeroProfile({ vm: this.vm })
  }

  build() {
    CharDetailHeroScaffold({
      imageUrl: this.vm.charImageUrl,
      constellations: this.vm.ranks,
      charName: this.vm.charName,
      heroHeight: this.heroHeight,
      strongOverlay: this.tm.current.overlayPortraitStrong,
      midOverlay: this.tm.current.overlayPortraitMid,
      infoContent: () => { this.heroInfo() }
    })
  }
}

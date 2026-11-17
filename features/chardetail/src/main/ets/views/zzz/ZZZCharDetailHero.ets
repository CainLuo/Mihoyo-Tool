/**
 * ZZZCharDetailHero — 绝区零角色详情英雄区
 *
 * 立绘贴右，左侧渐变遮罩，左下角名字+全名+等级+稀有度+影画数，左侧影画纵列居中。
 * 通用骨架见 `CharDetailHeroScaffold`。
 */
import { themeManager, ThemeManager } from 'basic';
import { ZZZCharacterDetailViewModel } from '../../viewmodel/ZZZCharacterDetailViewModel';
import { CharDetailHeroScaffold } from '../common/CharDetailHeroScaffold';
import { ZZZCharDetailHeroProfile } from './ZZZCharDetailHeroProfile';

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct ZZZCharDetailHeroPreview {
  build() {
    ZZZCharDetailHero({
      vm: new ZZZCharacterDetailViewModel(),
      heroHeight: 260
    })
    .backgroundColor('#1a1a2e')
  }
}

@ComponentV2
export struct ZZZCharDetailHero {
  @Param vm: ZZZCharacterDetailViewModel = new ZZZCharacterDetailViewModel();
  @Param heroHeight: number = 260;
  @Local private tm: ThemeManager = themeManager;

  @Builder
  heroInfo() {
    ZZZCharDetailHeroProfile({ vm: this.vm })
  }

  build() {
    CharDetailHeroScaffold({
      imageUrl: this.vm.charVerticalPaintingUrl,
      constellations: this.vm.ranks,
      charName: this.vm.charName,
      heroHeight: this.heroHeight,
      // 与重构前一致：ZZZ 使用固定黑色遮罩，不跟随主题色
      strongOverlay: '#99000000',
      midOverlay: '#66000000',
      infoContent: () => { this.heroInfo() }
    })
  }
}

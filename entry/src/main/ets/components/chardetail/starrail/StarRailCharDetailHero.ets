/**
 * StarRailCharDetailHero — 星穹铁道角色详情英雄区
 *
 * 立绘贴右，左侧渐变遮罩，左下角名字+等级+星魂，左侧命座纵列居中。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { StarRailCharacterDetailViewModel } from '../../../viewmodel/StarRailCharacterDetailViewModel';
import { CharDetailConsColumn } from '../common/CharDetailConsColumn';
import { CharDetailHeroNameOverlay } from '../common/CharDetailHeroNameOverlay';
import { StarRailCharDetailHeroInfo } from './StarRailCharDetailHeroInfo';

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
    StarRailCharDetailHeroInfo({ vm: this.vm })
  }

  build() {
    Stack() {
      // 背景渐变
      Column()
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .linearGradient({
          angle: this.tm.current.a150,
          colors: [[this.tm.current.bgPortrait1, 0], [this.tm.current.bgPortrait2, 1.0]]
        })

      // 立绘：贴右边
      if (this.vm.charImageUrl !== '') {
        Image(this.vm.charImageUrl)
          .width('60%')
          .height(this.tm.current.full)
          .objectFit(ImageFit.Cover)
          .position({ x: '100%', y: 0 })
          .markAnchor({ x: '100%', y: 0 })
      }

      // 左侧渐变遮罩
      Column()
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .linearGradient({
          angle: this.tm.current.a90,
          colors: [
            [this.tm.current.overlayPortraitBase, 0],
            [this.tm.current.overlayPortraitStrong, 0.32],
            [this.tm.current.overlayPortraitMid, 0.55],
            [Color.Transparent, 1.0]
          ]
        })

      // 底部渐变
      Column()
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .linearGradient({
          angle: this.tm.current.a0,
          colors: [[this.tm.current.overlayPortraitBot, 0], [Color.Transparent, 0.45]]
        })

      // 左侧命座纵列（垂直居中）
      Column() {
        CharDetailConsColumn({ constellations: this.vm.ranks })
      }
      .position({ x: this.tm.current.value12, y: 0 })
      .height(this.tm.current.full)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .zIndex(3)

      // 左下角：名字 + 等级 + 星魂
      CharDetailHeroNameOverlay({
        charName: this.vm.charName,
        extraContent: () => { this.heroInfo() }
      })
    }
    .width(this.tm.current.full)
    .height(this.heroHeight)
    .clip(true)
  }
}

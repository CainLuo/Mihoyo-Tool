/**
 * StarRailCharDetailHeroInfo — 星铁英雄区左下角等级+星魂行
 *
 * 仅在 StarRailCharDetailHero 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { StarRailCharacterDetailViewModel } from '../../../viewmodel/StarRailCharacterDetailViewModel';

@ComponentV2
export struct StarRailCharDetailHeroInfo {
  @Param vm: StarRailCharacterDetailViewModel = new StarRailCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: this.tm.current.value8 }) {
      Text(`Lv.${this.vm.charLevel}`)
        .fontSize(this.tm.current.body12.size)
        .fontColor(this.tm.current.textOnDarkMedium)
      Text($r('app.string.starrail_char_detail_rank_prefix', this.vm.charRank))
        .fontSize(this.tm.current.body10.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tm.current.accentRefine)
        .backgroundColor(this.tm.current.accentRefineBg)
        .borderRadius(this.tm.current.value4)
        .padding({
          left: this.tm.current.value4, right: this.tm.current.value4,
          top: this.tm.current.value1, bottom: this.tm.current.value1
        })
    }
  }
}

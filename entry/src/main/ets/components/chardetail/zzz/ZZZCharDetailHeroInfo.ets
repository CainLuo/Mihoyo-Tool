/**
 * ZZZCharDetailHeroInfo — 绝区零英雄区左下角信息行
 *
 * 全名（可选）+ 等级/稀有度/影画数行。
 * 仅在 ZZZCharDetailHero 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ZZZCharacterDetailViewModel } from '../../../viewmodel/ZZZCharacterDetailViewModel';

@ComponentV2
export struct ZZZCharDetailHeroInfo {
  @Param vm: ZZZCharacterDetailViewModel = new ZZZCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      if (this.vm.charFullName !== '' && this.vm.charFullName !== this.vm.charName) {
        Text(this.vm.charFullName)
          .fontSize(this.tm.current.font13)
          .fontColor(this.tm.current.textOnDarkMedium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      Row({ space: this.tm.current.value8 }) {
        Text(`Lv.${this.vm.charLevel}`)
          .fontSize(this.tm.current.font13)
          .fontColor(this.tm.current.textOnDarkMedium)
        Text(this.vm.charRarity)
          .fontSize(this.tm.current.font11)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.accentRefine)
          .backgroundColor('#33FFCA28')
          .borderRadius(this.tm.current.value4)
          .padding({
            left: this.tm.current.value4, right: this.tm.current.value4,
            top: this.tm.current.value1, bottom: this.tm.current.value1
          })
        Text($r('app.string.zzz_char_detail_rank_prefix', this.vm.charRank))
          .fontSize(this.tm.current.font11)
          .fontColor('#59FFFFFF')
      }
    }
  }
}

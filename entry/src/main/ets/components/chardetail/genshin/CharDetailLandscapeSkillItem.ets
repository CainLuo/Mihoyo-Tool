/**
 * CharDetailLandscapeSkillItem — 横屏立绘区技能图标+等级单项
 *
 * 复用 CharDetailSkillItem，横屏用较小图标（value34）。
 * 仅在 CharDetailHeroPanelLandscape 的技能横行中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { CharDetailSkill } from '../../../models/CharDetailModels';
import { GenshinElement } from '../../../constants/GenshinElement';
import { CharDetailSkillItem } from '../common/CharDetailSkillItem';

@ComponentV2
export struct CharDetailLandscapeSkillItem {
  @Param skill: CharDetailSkill = new CharDetailSkill();
  @Param charElement: GenshinElement = GenshinElement.UNKNOWN;
  @Local private tm: ThemeManager = themeManager;

  build() {
    CharDetailSkillItem({
      skill: this.skill,
      charElement: this.charElement,
      iconSize: this.tm.current.value34
    })
  }
}

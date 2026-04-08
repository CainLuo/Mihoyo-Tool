/**
 * CharDetailSkillsColumn — 技能纵列组件（宽屏用）
 *
 * 宽屏三栏布局右下角使用，技能图标较大，纵向排列。
 * Phone 布局的横向技能行因尺寸和方向差异较大，在各自布局组件中内联。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { CharDetailSkill } from './CharDetailModels';
import { elementColor } from '../characters/CharacterCard';
import { GenshinElement } from '../../constants/GenshinElement';

function makeMockSkills(): CharDetailSkill[] {
  const levels = [10, 10, 10];
  const skills: CharDetailSkill[] = [];
  for (let i = 0; i < 3; i++) {
    const s = new CharDetailSkill();
    s.iconUrl = '';
    s.level = levels[i];
    skills[skills.length] = s;
  }
  return skills;
}

// ── Preview：水元素技能列 ──
@Preview
@ComponentV2
export struct CharDetailSkillsColumnPreview {
  build() {
    CharDetailSkillsColumn({
      skills: makeMockSkills(),
      charElement: GenshinElement.HYDRO
    })
    .padding(themeManager.current.value16)
    .backgroundColor(themeManager.current.bgPageDeep)
  }
}

@ComponentV2
export struct CharDetailSkillsColumn {
  @Param skills: CharDetailSkill[] = [];
  @Param charElement: GenshinElement = GenshinElement.UNKNOWN;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value8 }) {
      ForEach(this.skills, (skill: CharDetailSkill) => {
        Column({ space: this.tm.current.value2 }) {
          if (skill.iconUrl !== '') {
            Image(skill.iconUrl)
              .width(this.tm.current.value40)
              .height(this.tm.current.value40)
              .objectFit(ImageFit.Contain)
              .borderRadius(this.tm.current.value40 / 2)
              .backgroundColor(this.tm.current.surfaceDark2xl)
              .border({ width: this.tm.current.value1p5, color: this.tm.current.surfaceGlassSm })
          }
          Text(`${skill.level}`)
            .fontSize(this.tm.current.body12.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(elementColor(this.charElement))
        }
        .alignItems(HorizontalAlign.Center)
      }, (_skill: CharDetailSkill, idx: number) => `skill_${idx}`)
    }
  }
}

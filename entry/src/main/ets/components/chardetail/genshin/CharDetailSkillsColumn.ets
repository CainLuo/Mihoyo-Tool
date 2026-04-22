/**
 * CharDetailSkillsColumn — 技能纵列组件（宽屏用）
 *
 * 宽屏三栏布局右下角使用，技能图标较大（value40），纵向排列。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { CharDetailSkill } from '../../../models/CharDetailModels';
import { GenshinElement } from '../../../constants/GenshinElement';
import { CharDetailSkillItem } from '../common/CharDetailSkillItem';

function makeMockSkills(): CharDetailSkill[] {
  const skills: CharDetailSkill[] = [];
  for (let i = 0; i < 3; i++) {
    const s = new CharDetailSkill();
    s.iconUrl = '';
    s.level = 10;
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
        CharDetailSkillItem({
          skill: skill,
          charElement: this.charElement,
          iconSize: this.tm.current.value40
        })
      }, (_skill: CharDetailSkill, idx: number) => `skill_${idx}`)
    }
  }
}

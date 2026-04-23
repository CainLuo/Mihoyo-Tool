/**
 * StarRailCharDetailContent — 星穹铁道角色详情内容区
 *
 * 包含：行迹、光锥、属性面板、遗器/饰品
 * build() 只做各 Section 组件的组合，不含任何内联布局代码。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { StarRailCharacterDetailViewModel } from '../../../viewmodel/StarRailCharacterDetailViewModel';
import { StarRailSkillsSection } from './StarRailSkillsSection';
import { StarRailEquipSection } from './StarRailEquipSection';
import { StarRailPropsSection } from './StarRailPropsSection';
import { StarRailRelicsSection } from './StarRailRelicsSection';

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct StarRailCharDetailContentPreview {
  build() {
    StarRailCharDetailContent({ vm: new StarRailCharacterDetailViewModel() })
      .backgroundColor('#1a1a2e')
  }
}

@ComponentV2
export struct StarRailCharDetailContent {
  @Param vm: StarRailCharacterDetailViewModel = new StarRailCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value8 }) {
      StarRailSkillsSection({ vm: this.vm })
      StarRailEquipSection({ vm: this.vm })
      StarRailPropsSection({ vm: this.vm })
      StarRailRelicsSection({ vm: this.vm })
      Row().height(this.tm.current.value16)
    }
    .width(this.tm.current.full)
    .padding({ left: this.tm.current.value12, right: this.tm.current.value12, top: this.tm.current.value8 })
  }
}

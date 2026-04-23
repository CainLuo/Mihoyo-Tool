/**
 * ZZZCharDetailContent — 绝区零角色详情内容区
 *
 * 包含：技能、音擎、属性面板、驱动盘
 * build() 只做各 Section 组件的组合，不含任何内联布局代码。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ZZZCharacterDetailViewModel } from '../../../viewmodel/ZZZCharacterDetailViewModel';
import { ZZZSkillsSection } from './ZZZSkillsSection';
import { ZZZWeaponSection } from './ZZZWeaponSection';
import { ZZZPropsSection } from './ZZZPropsSection';
import { ZZZEquipSection } from './ZZZEquipSection';

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct ZZZCharDetailContentPreview {
  build() {
    ZZZCharDetailContent({ vm: new ZZZCharacterDetailViewModel() })
      .backgroundColor('#1a1a2e')
  }
}

@ComponentV2
export struct ZZZCharDetailContent {
  @Param vm: ZZZCharacterDetailViewModel = new ZZZCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value8 }) {
      ZZZSkillsSection({ vm: this.vm })
      ZZZWeaponSection({ vm: this.vm })
      ZZZPropsSection({ vm: this.vm })
      ZZZEquipSection({ vm: this.vm })
      Row().height(this.tm.current.value16)
    }
    .width(this.tm.current.full)
    .padding({ left: this.tm.current.value12, right: this.tm.current.value12, top: this.tm.current.value8 })
  }
}

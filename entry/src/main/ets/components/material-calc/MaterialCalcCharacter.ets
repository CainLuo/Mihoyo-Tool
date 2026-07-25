/**
 * MaterialCalcCharacter.ets — 材料计算页角色信息组件
 *
 * 显示角色信息和可点击的等级目标按钮。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { MaterialCalcCharacterVM } from '../../models/MaterialCalcModels';

@ComponentV2
export struct MaterialCalcCharacter {
  @Param character: MaterialCalcCharacterVM = new MaterialCalcCharacterVM();
  @Param onLevelTap: () => void = () => {};

  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: 12 }) {
      // 角色头像
      Row() {
        if (this.character.iconUrl.length > 0) {
          Image(this.character.iconUrl)
            .width(40)
            .height(40)
            .borderRadius(20)
            .objectFit(ImageFit.Cover)
        } else {
          Text('👤')
            .fontSize(22)
        }
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .backgroundColor(this.rarityBackgroundColor(this.character.rarity))
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // 角色信息
      Column({ space: 2 }) {
        Text(this.character.name)
          .fontSize(this.tm.current.fontBold16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.colorTextPrimary)

        Text('★'.repeat(this.character.rarity))
          .fontSize(this.tm.current.font10)
          .fontColor(this.rarityTextColor(this.character.rarity))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 等级目标按钮
      Button() {
        Row({ space: 6 }) {
          Text(`Lv.${this.character.currentLevel} → ${this.character.targetLevel}`)
            .fontSize(this.tm.current.font14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.tm.current.colorPrimary)

          Text('▼')
            .fontSize(10)
            .fontColor(this.tm.current.colorPrimary)
        }
      }
      .type(ButtonType.Normal)
      .backgroundColor(this.tm.current.surfaceActivePrimary)
      .borderRadius(this.tm.current.radius8)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .onClick(() => {
        this.onLevelTap();
      })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .border({ width: 1, color: this.tm.current.colorDivider })
  }

  /**
   * 根据稀有度获取背景色
   */
  private rarityBackgroundColor(rarity: number): ResourceColor {
    switch (rarity) {
      case 5:
        return $r('app.color.rarity_5star_bg');
      case 4:
        return $r('app.color.rarity_4star_bg');
      default:
        return this.tm.current.colorDivider;
    }
  }

  /**
   * 根据稀有度获取文字颜色
   */
  private rarityTextColor(rarity: number): ResourceColor {
    switch (rarity) {
      case 5:
        return $r('app.color.rarity_5star');
      case 4:
        return $r('app.color.rarity_4star_bg');
      default:
        return this.tm.current.colorTextSecondary;
    }
  }
}

@Preview
@ComponentV2
export struct MaterialCalcCharacterPreview {
  @Local character: MaterialCalcCharacterVM = new MaterialCalcCharacterVM();

  aboutToAppear(): void {
    this.character.characterId = '10000122';
    this.character.name = '甘雨';
    this.character.rarity = 5;
    this.character.currentLevel = 80;
    this.character.targetLevel = 90;
  }

  build() {
    Column() {
      MaterialCalcCharacter({
        character: this.character,
        onLevelTap: () => {}
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}

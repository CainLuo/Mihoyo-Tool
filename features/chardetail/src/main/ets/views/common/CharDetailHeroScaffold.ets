/**
 * CharDetailHeroScaffold — 星铁 / 绝区零角色详情英雄区骨架
 *
 * 背景渐变 + 右侧立绘 + 左侧与底部遮罩 + 命座纵列 + 左下角名字叠加层。
 * 游戏差异通过参数注入：立绘 URL、遮罩颜色、名字下方信息 Builder。
 *
 * 使用方：StarRailCharDetailHero、ZZZCharDetailHero
 */
import { themeManager, ThemeManager } from 'basic';
import { CharDetailRankItem } from '../../model/CharDetailModels';
import { CharDetailConsColumn } from './CharDetailConsColumn';
import { CharDetailHeroNameOverlay } from './CharDetailHeroNameOverlay';

@ComponentV2
export struct CharDetailHeroScaffold {
  /** 立绘 URL */
  @Param imageUrl: string = '';
  /** 命座 / 影画列表 */
  @Param constellations: CharDetailRankItem[] = [];
  /** 角色名 */
  @Param charName: string = '';
  /** 英雄区高度（vp） */
  @Param heroHeight: number = 260;
  /** 左侧遮罩强色（0.32 处） */
  @Param strongOverlay: ResourceColor = '#99000000';
  /** 左侧遮罩中间色（0.55 处） */
  @Param midOverlay: ResourceColor = '#66000000';
  /** 名字下方的游戏差异信息 */
  @BuilderParam infoContent: () => void = this.defaultInfoContent;
  @Local private tm: ThemeManager = themeManager;

  @Builder
  defaultInfoContent() {}

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
      if (this.imageUrl !== '') {
        Image(this.imageUrl)
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
            [this.strongOverlay, 0.32],
            [this.midOverlay, 0.55],
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
        CharDetailConsColumn({ constellations: this.constellations })
      }
      .position({ x: this.tm.current.value12, y: 0 })
      .height(this.tm.current.full)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .zIndex(3)

      // 左下角：名字 + 游戏差异信息
      CharDetailHeroNameOverlay({
        charName: this.charName,
        extraContent: () => { this.infoContent() }
      })
    }
    .width(this.tm.current.full)
    .height(this.heroHeight)
    .clip(true)
  }
}

/**
 * CharDetailHeroPanel — 角色立绘区
 *
 * 宽屏（三栏布局）：
 *   立绘铺满，左上角名字+等级+好感，左下角命座1→6，右下角技能3个
 *
 * Phone 竖屏：
 *   立绘固定高度，图片贴右，左侧渐变，左下角名字+等级+好感+技能，右侧命座纵列
 *
 * Phone 横屏：
 *   立绘固定宽度，图片铺满，左下角文字+技能，右侧命座纵列
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import {
  GenshinCharacterDetailViewModel,
  CharDetailSkill,
  CharDetailConstellation
} from '../../viewmodel/GenshinCharacterDetailViewModel';
import { elementColor } from '../characters/CharacterCard';

@ComponentV2
export struct CharDetailHeroPanel {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  /** 布局模式：wide = 宽屏三栏 | portrait = Phone 竖屏 | landscape = Phone 横屏 */
  @Param mode: string = 'wide';
  @Local private tm: ThemeManager = themeManager;

  /** 根据元素返回背景渐变色（深色调） */
  private elementBgColors(): LinearGradient {
    const elem = this.vm.charElement;
    if (elem === 'Hydro') {
      return { angle: 135, colors: [['#0a2a4a', 0], ['#0d1e3a', 0.4], ['#081428', 1.0]] };
    }
    if (elem === 'Pyro') {
      return { angle: 135, colors: [['#3a1008', 0], ['#2a0e0a', 0.4], ['#180808', 1.0]] };
    }
    if (elem === 'Electro') {
      return { angle: 135, colors: [['#2a1040', 0], ['#1e0a30', 0.4], ['#100818', 1.0]] };
    }
    if (elem === 'Anemo') {
      return { angle: 135, colors: [['#083a2a', 0], ['#062a1e', 0.4], ['#041810', 1.0]] };
    }
    if (elem === 'Geo') {
      return { angle: 135, colors: [['#2a1e04', 0], ['#1e1604', 0.4], ['#100e02', 1.0]] };
    }
    if (elem === 'Cryo') {
      return { angle: 135, colors: [['#0a1e3a', 0], ['#081628', 0.4], ['#040e18', 1.0]] };
    }
    if (elem === 'Dendro') {
      return { angle: 135, colors: [['#0a2a08', 0], ['#081e06', 0.4], ['#040e02', 1.0]] };
    }
    return { angle: 135, colors: [['#0a2a4a', 0], ['#0d1e3a', 0.4], ['#081428', 1.0]] };
  }

  /** 命座列（1→6 从上到下） */
  @Builder
  ConsColumn() {
    Column({ space: this.tm.current.value4 }) {
      ForEach(this.vm.constellations, (c: CharDetailConstellation) => {
        if (c.iconUrl !== '') {
          // 有图标时显示命座图标，未解锁时叠加锁图标
          Stack() {
            Image(c.iconUrl)
              .width(this.tm.current.charDetailConsBadgeSize)
              .height(this.tm.current.charDetailConsBadgeSize)
              .objectFit(ImageFit.Contain)
              .borderRadius(this.tm.current.charDetailConsBadgeSize / 2)
              .backgroundColor(c.isActived ? 'rgba(79,195,247,0.25)' : 'rgba(0,0,0,0.5)')
              .border({
                width: this.tm.current.borderWidthMedium,
                color: c.isActived ? 'rgba(79,195,247,0.8)' : 'rgba(255,255,255,0.2)'
              })
              .opacity(c.isActived ? 1.0 : 0.3)
            if (!c.isActived) {
              SymbolGlyph($r('sys.symbol.lock'))
                .fontSize(this.tm.current.charDetailConsBadgeSize * 0.45)
                .fontColor(['rgba(255,255,255,0.75)'])
            }
          }
          .width(this.tm.current.charDetailConsBadgeSize)
          .height(this.tm.current.charDetailConsBadgeSize)
        } else {
          // 无图标时显示序号（兼容旧数据）
          Text(`${c.pos}`)
            .fontSize(this.tm.current.body13Bold.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(c.isActived ? $r('app.color.element_hydro') : '#444444')
            .width(this.tm.current.charDetailConsBadgeSize)
            .height(this.tm.current.charDetailConsBadgeSize)
            .borderRadius(this.tm.current.charDetailConsBadgeSize / 2)
            .backgroundColor(c.isActived ? 'rgba(79,195,247,0.25)' : 'rgba(0,0,0,0.5)')
            .border({
              width: this.tm.current.borderWidthMedium,
              color: c.isActived ? 'rgba(79,195,247,0.8)' : 'rgba(255,255,255,0.2)'
            })
            .textAlign(TextAlign.Center)
        }
      }, (c: CharDetailConstellation) => `cons_${c.pos}`)
    }
  }

  /** 技能列（普攻/战技/爆发，从上到下） */
  @Builder
  SkillsColumn() {
    Column({ space: this.tm.current.value8 }) {
      ForEach(this.vm.skills, (skill: CharDetailSkill) => {
        Column({ space: this.tm.current.value2 }) {
          if (skill.iconUrl !== '') {
            Image(skill.iconUrl)
              .width(this.tm.current.skillIconSize)
              .height(this.tm.current.skillIconSize)
              .objectFit(ImageFit.Contain)
              .borderRadius(this.tm.current.skillIconSize / 2)
              .backgroundColor('rgba(0,0,0,0.5)')
              .border({ width: this.tm.current.borderWidthMedium, color: 'rgba(255,255,255,0.25)' })
          }
          Text(`${skill.level}`)
            .fontSize(this.tm.current.body12.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(elementColor(this.vm.charElement))
        }
        .alignItems(HorizontalAlign.Center)
      }, (_skill: CharDetailSkill, idx: number) => `skill_${idx}`)
    }
  }

  /** 宽屏三栏布局：立绘铺满，四角信息 */
  @Builder
  WideLayout() {
    Stack() {
      // 背景渐变
      Column()
        .width(this.tm.current.widthFull)
        .height(this.tm.current.heightFull)
        .linearGradient(this.elementBgColors())

      // 立绘
      if (this.vm.charImageUrl !== '') {
        Image(this.vm.charImageUrl)
          .width(this.tm.current.widthFull)
          .height(this.tm.current.heightFull)
          .objectFit(ImageFit.Cover)
          .objectRepeat(ImageRepeat.NoRepeat)
      }

      // 上下渐变遮罩
      Column()
        .width(this.tm.current.widthFull)
        .height(this.tm.current.heightFull)
        .linearGradient({
          angle: 180,
          colors: [['rgba(0,0,0,0.6)', 0], ['rgba(0,0,0,0)', 0.3],
            ['rgba(0,0,0,0)', 0.55], ['rgba(0,0,0,0.75)', 1.0]]
        })

      // 左上角：名字 + 等级 + 好感
      Column({ space: this.tm.current.value4 }) {
        Text(this.vm.charName)
          .fontSize(this.tm.current.title18Bold.size)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textShadow({ radius: this.tm.current.value8, color: 'rgba(0,0,0,0.9)', offsetY: 2 })
        Text(`Lv.${this.vm.charLevel}/${this.vm.charMaxLevel}`)
          .fontSize(this.tm.current.body12.size)
          .fontColor('rgba(255,255,255,0.75)')
        Text($r('app.string.char_detail_fetter_label'))
          .fontSize(this.tm.current.body12.size)
          .fontColor(elementColor(this.vm.charElement))
      }
      .alignItems(HorizontalAlign.Start)
      .position({ x: this.tm.current.value12, y: this.tm.current.value12 })
      .zIndex(2)

      // 左下角：命座
      Column() {
        this.ConsColumn()
      }
      .position({ x: this.tm.current.value12, y: '100%' })
      .markAnchor({ x: 0, y: '100%' })
      .margin({ bottom: this.tm.current.value12 })
      .zIndex(2)

      // 右下角：技能
      Column() {
        this.SkillsColumn()
      }
      .position({ x: '100%', y: '100%' })
      .markAnchor({ x: '100%', y: '100%' })
      .margin({ right: this.tm.current.value12, bottom: this.tm.current.value12 })
      .zIndex(2)
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .clip(true)
  }

  /** Phone 竖屏：固定高度，图片贴右，左侧渐变 */
  @Builder
  PortraitLayout() {
    Stack() {
      // 背景
      Column()
        .width(this.tm.current.widthFull)
        .height(this.tm.current.heightFull)
        .linearGradient({ angle: 150, colors: [['#0a1e38', 0], ['#0e0e22', 1.0]] })

      // 立绘贴右
      if (this.vm.charImageUrl !== '') {
        Image(this.vm.charImageUrl)
          .height(this.tm.current.heightFull)
          .objectFit(ImageFit.Cover)
          .position({ x: '100%', y: 0 })
          .markAnchor({ x: '100%', y: 0 })
      }

      // 左侧渐变遮罩
      Column()
        .width(this.tm.current.widthFull)
        .height(this.tm.current.heightFull)
        .linearGradient({
          angle: 90,
          colors: [['#0c1a30', 0], ['rgba(12,26,48,0.88)', 0.32],
            ['rgba(12,26,48,0.4)', 0.55], ['rgba(0,0,0,0)', 1.0]]
        })

      // 底部渐变
      Column()
        .width(this.tm.current.widthFull)
        .height(this.tm.current.heightFull)
        .linearGradient({
          angle: 0,
          colors: [['rgba(10,16,30,0.9)', 0], ['rgba(0,0,0,0)', 0.45]]
        })

      // 右侧命座纵列（垂直居中）
      // 用全宽 Column 靠右对齐，避免 position+margin 在绝对定位下失效
      Column() {
        this.ConsColumn()
      }
      .width(this.tm.current.widthFull)
      .height(this.tm.current.heightFull)
      .alignItems(HorizontalAlign.End)
      .justifyContent(FlexAlign.Center)
      .padding({ right: this.tm.current.charDetailConsMarginRight })
      .zIndex(3)

      // 左下角：名字 + 等级 + 好感 + 技能行
      // 用全宽 Column 靠左对齐，padding({ bottom }) 控制底部间距
      Column({ space: this.tm.current.value4 }) {
        Text(this.vm.charName)
          .fontSize(this.tm.current.charDetailNameFontSizePortrait)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textShadow({ radius: this.tm.current.value8, color: 'rgba(0,0,0,0.9)', offsetY: 2 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: this.tm.current.value8 }) {
          Text(`Lv.${this.vm.charLevel}`)
            .fontSize(this.tm.current.body12.size)
            .fontColor('#cccccc')
          Text($r('app.string.character_fetter_value', this.vm.charFetter))
            .fontSize(this.tm.current.body10.size)
            .fontColor(elementColor(this.vm.charElement))
            .backgroundColor('rgba(79,195,247,0.12)')
            .border({ width: 1, color: 'rgba(79,195,247,0.2)' })
            .borderRadius(this.tm.current.value4)
            .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: 1, bottom: 1 })
        }
        // 技能行（横向）
        Row({ space: this.tm.current.value10 }) {
          ForEach(this.vm.skills, (skill: CharDetailSkill) => {
            Column({ space: this.tm.current.value2 }) {
              if (skill.iconUrl !== '') {
                Image(skill.iconUrl)
                  .width(this.tm.current.charDetailSkillIconSize)
                  .height(this.tm.current.charDetailSkillIconSize)
                  .objectFit(ImageFit.Contain)
                  .borderRadius(this.tm.current.charDetailSkillIconRadius)
                  .backgroundColor('rgba(0,0,0,0.5)')
                  .border({ width: this.tm.current.borderWidthMedium, color: 'rgba(79,195,247,0.35)' })
              }
              Text(`${skill.level}`)
                .fontSize(this.tm.current.body12.size)
                .fontWeight(FontWeight.Bold)
                .fontColor(elementColor(this.vm.charElement))
            }
            .alignItems(HorizontalAlign.Center)
          }, (_skill: CharDetailSkill, idx: number) => `pskill_${idx}`)
        }
      }
      .width(this.tm.current.widthFull)
      .height(this.tm.current.heightFull)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.End)
      .padding({
        left: this.tm.current.value12,
        right: '40%',
        bottom: this.tm.current.charDetailSkillBottomOffset
      })
      .zIndex(2)
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .clip(true)
  }

  /** Phone 横屏：固定宽度，图片铺满，左下角文字，右侧命座 */
  @Builder
  LandscapeLayout() {
    Stack() {
      // 背景
      Column()
        .width(this.tm.current.widthFull)
        .height(this.tm.current.heightFull)
        .linearGradient({ angle: 150, colors: [['#0a1e38', 0], ['#0e0e22', 1.0]] })

      // 立绘铺满
      if (this.vm.charImageUrl !== '') {
        Image(this.vm.charImageUrl)
          .width(this.tm.current.widthFull)
          .height(this.tm.current.heightFull)
          .objectFit(ImageFit.Cover)
          .objectRepeat(ImageRepeat.NoRepeat)
      }

      // 底部渐变遮罩
      Column()
        .width(this.tm.current.widthFull)
        .height(this.tm.current.heightFull)
        .linearGradient({
          angle: 0,
          colors: [['rgba(10,16,30,1)', 0], ['rgba(10,16,30,0.7)', 0.4],
            ['rgba(10,16,30,0.1)', 0.65], ['rgba(0,0,0,0)', 1.0]]
        })

      // 右侧命座纵列（垂直居中）
      Column() {
        this.ConsColumn()
      }
      .width(this.tm.current.widthFull)
      .height(this.tm.current.heightFull)
      .alignItems(HorizontalAlign.End)
      .justifyContent(FlexAlign.Center)
      .padding({ right: this.tm.current.charDetailConsMarginRight })
      .zIndex(3)

      // 左下角：名字 + 等级 + 好感 + 技能行
      Column({ space: this.tm.current.value4 }) {
        Text(this.vm.charName)
          .fontSize(this.tm.current.charDetailNameFontSizeLandscape)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textShadow({ radius: this.tm.current.value8, color: 'rgba(0,0,0,0.9)', offsetY: 2 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: this.tm.current.value4 }) {
          Text(`Lv.${this.vm.charLevel}`)
            .fontSize(this.tm.current.body10.size)
            .fontColor('#cccccc')
          Text($r('app.string.char_detail_fetter_label'))
            .fontSize(this.tm.current.body10.size)
            .fontColor(elementColor(this.vm.charElement))
            .backgroundColor('rgba(79,195,247,0.12)')
            .border({ width: 1, color: 'rgba(79,195,247,0.2)' })
            .borderRadius(this.tm.current.value4)
            .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: 1, bottom: 1 })
        }
        Row({ space: this.tm.current.value8 }) {
          ForEach(this.vm.skills, (skill: CharDetailSkill) => {
            Column({ space: this.tm.current.value2 }) {
              if (skill.iconUrl !== '') {
                Image(skill.iconUrl)
                  .width(this.tm.current.charDetailSkillIconSize)
                  .height(this.tm.current.charDetailSkillIconSize)
                  .objectFit(ImageFit.Contain)
                  .borderRadius(this.tm.current.charDetailSkillIconRadius)
                  .backgroundColor('rgba(0,0,0,0.5)')
                  .border({ width: this.tm.current.borderWidthMedium, color: 'rgba(79,195,247,0.35)' })
              }
              Text(`${skill.level}`)
                .fontSize(this.tm.current.body12.size)
                .fontWeight(FontWeight.Bold)
                .fontColor(elementColor(this.vm.charElement))
            }
            .alignItems(HorizontalAlign.Center)
          }, (_skill: CharDetailSkill, idx: number) => `lskill_${idx}`)
        }
      }
      .width(this.tm.current.widthFull)
      .height(this.tm.current.heightFull)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.End)
      .padding({
        left: this.tm.current.value10,
        right: '35%',
        bottom: this.tm.current.value16
      })
      .zIndex(2)
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .clip(true)
  }

  build() {
    if (this.mode === 'portrait') {
      this.PortraitLayout()
    } else if (this.mode === 'landscape') {
      this.LandscapeLayout()
    } else {
      this.WideLayout()
    }
  }
}

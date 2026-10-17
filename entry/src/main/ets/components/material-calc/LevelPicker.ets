/**
 * LevelPicker.ets — 等级选择器弹窗组件
 *
 * 使用 CustomDialog 展示等级选项列表。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { LevelOptionVM } from '../../models/MaterialCalcModels';

@ComponentV2
export struct LevelPicker {
  @Param currentLevel: number = 1;
  @Param options: LevelOptionVM[] = [];
  @Param onSelect: (level: number) => void = (_: number) => {};
  @Param visible: boolean = false;
  @Param onDismiss: () => void = () => {};

  @Local private tm: ThemeManager = themeManager;

  build() {
    if (this.visible) {
      Column() {
        // 遮罩层
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.onDismiss();
          })

        // 弹窗内容
        Column({ space: 8 }) {
          // 标题
          Text($r('app.string.level_picker_title'))
            .fontSize(this.tm.current.fontBold16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tm.current.colorTextPrimary)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 16, bottom: 8 })

          // 选项列表
          ForEach(this.options, (opt: LevelOptionVM) => {
            LevelPickerItem({
              opt: opt,
              isSelected: this.currentLevel === opt.level,
              onSelect: (level: number) => {
                this.onSelect(level);
                this.onDismiss();
              }
            })
          }, (opt: LevelOptionVM) => `${opt.level}`)
        }
        .width('80%')
        .backgroundColor(this.tm.current.colorSurfaceCard)
        .borderRadius(this.tm.current.radius12)
        .padding({ bottom: 16 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
  }
}

/**
 * LevelPickerItem — 等级选择器选项项
 *
 * 单个等级选项，显示等级标签并根据 isSelected 决定样式。
 */
@ComponentV2
struct LevelPickerItem {
  @Param opt: LevelOptionVM = { level: 1, label: '' };
  @Param isSelected: boolean = false;
  @Param onSelect: (level: number) => void = (_: number) => {};

  @Local private tm: ThemeManager = themeManager;

  build() {
    Row() {
      Text(this.opt.label)
        .fontSize(this.tm.current.font14)
        .fontWeight(this.isSelected ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.isSelected ? this.tm.current.colorPrimary : this.tm.current.colorTextPrimary)
    }
    .width('100%')
    .height(44)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.isSelected ? this.tm.current.surfaceActivePrimary : Color.Transparent)
    .borderRadius(this.tm.current.radius8)
    .margin({ left: 16, right: 16 })
    .onClick(() => {
      this.onSelect(this.opt.level);
    })
  }
}

@Preview
@ComponentV2
export struct LevelPickerPreview {
  @Local visible: boolean = true;
  @Local currentLevel: number = 80;
  @Local options: LevelOptionVM[] = [];

  aboutToAppear(): void {
    this.options = [
      { level: 1, label: 'Lv.1' } as LevelOptionVM,
      { level: 20, label: 'Lv.20' } as LevelOptionVM,
      { level: 40, label: 'Lv.40' } as LevelOptionVM,
      { level: 60, label: 'Lv.60' } as LevelOptionVM,
      { level: 70, label: 'Lv.70' } as LevelOptionVM,
      { level: 80, label: 'Lv.80' } as LevelOptionVM,
      { level: 90, label: 'Lv.90' } as LevelOptionVM,
    ];
  }

  build() {
    Column() {
      LevelPicker({
        currentLevel: this.currentLevel,
        options: this.options,
        visible: this.visible,
        onSelect: (level: number) => {
          this.currentLevel = level;
        },
        onDismiss: () => {
          this.visible = false;
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1a1a2e')
  }
}

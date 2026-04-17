/**
 * AboutSection — 关于 Section
 *
 * 展示「导出日志」、「清理缓存」和版本号。
 * 导出日志：通过 DocumentViewPicker 让用户选择保存位置。
 * 清理缓存：删除所有本地日志文件，右侧实时显示日志大小。
 */
import BuildProfile from 'BuildProfile'
import { common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { ApiLogSystem, LogFileManager, LogExporter } from 'core'
import { themeManager, ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct AboutSection {
  @Local private tm: ThemeManager = themeManager
  @Local private logSize: string = '0 KB'

  aboutToAppear(): void {
    this.refreshLogSize();
  }

  private refreshLogSize(): void {
    ApiLogSystem.getInstance().getFileManager().getTotalLogSize()
      .then((bytes: number) => {
        this.logSize = LogFileManager.formatSize(bytes);
      })
      .catch((_: Error | object) => {
        this.logSize = '0 KB';
      });
  }

  private showSnackBar(message: ResourceStr): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  private onExportLogs(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const version = BuildProfile.VERSION_NAME ?? '1.0.0';
    LogExporter.export(ctx, version)
      .then((_success: boolean) => {
        // 成功或用户取消，无需额外提示
      })
      .catch((_e: Error | object) => {
        this.showSnackBar($r('app.string.my_export_logs_failed'));
      });
  }

  private onClearCache(): void {
    const ctx = this.getUIContext();
    ctx.getPromptAction().showDialog({
      title: $r('app.string.my_clear_cache_confirm_title'),
      message: $r('app.string.my_clear_cache_confirm_msg'),
      buttons: [
        { text: $r('app.string.dialog_cancel'), color: '#999999' },
        { text: $r('app.string.dialog_confirm'), color: '#E8534A' },
      ],
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      if (result.index !== 1) {
        return;
      }
      ApiLogSystem.getInstance().getFileManager().deleteAllLogs()
        .then((deleteResult) => {
          this.logSize = '0 B';
          if (deleteResult.failedCount > 0) {
            this.showSnackBar($r('app.string.my_clear_cache_failed', deleteResult.failedCount));
          } else {
            const freed = LogFileManager.formatSize(deleteResult.freedBytes);
            this.showSnackBar($r('app.string.my_clear_cache_success', freed));
          }
        })
        .catch((_e: Error | object) => {});
    }).catch((_: Error | object) => {});
  }

  build() {
    Column() {
      // 导出日志
      this.ActionRow($r('app.string.my_export_logs'), '', () => { this.onExportLogs(); })
      Divider()
        .color(this.tm.current.colorDivider)
        .margin({ left: this.tm.current.value16 })
      // 清理缓存（右侧直接读 this.logSize，确保响应式更新）
      Row() {
        Text($r('app.string.my_clear_cache'))
          .font(this.tm.current.body16)
          .fontColor(this.tm.current.colorTextPrimary)
          .layoutWeight(1)
        Text(this.logSize)
          .font(this.tm.current.body16)
          .fontColor(this.tm.current.colorTextSecondary)
          .margin({ right: this.tm.current.value8 })
        Text($r('app.string.common_arrow_right'))
          .font(this.tm.current.body16)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .width(this.tm.current.full)
      .height(this.tm.current.value50)
      .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.onClearCache(); })
      Divider()
        .color(this.tm.current.colorDivider)
        .margin({ left: this.tm.current.value16 })
      // 版本号
      this.AboutRow($r('app.string.my_about_version'), BuildProfile.VERSION_NAME, false)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .clip(true)
    .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean, _ratio: number) => {
      if (isVisible) {
        this.refreshLogSize();
      }
    })
  }

  @Builder
  private ActionRow(label: ResourceStr, value: string, onTap: () => void) {
    Row() {
      Text(label)
        .font(this.tm.current.body16)
        .fontColor(this.tm.current.colorTextPrimary)
        .layoutWeight(1)
      if (value !== '') {
        Text(value)
          .font(this.tm.current.body16)
          .fontColor(this.tm.current.colorTextSecondary)
          .margin({ right: this.tm.current.value8 })
      }
      Text($r('app.string.common_arrow_right'))
        .font(this.tm.current.body16)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.value50)
    .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
    .alignItems(VerticalAlign.Center)
    .onClick(onTap)
  }

  @Builder
  private AboutRow(label: ResourceStr, value: ResourceStr | string, isLink: boolean) {
    Row() {
      Text(label)
        .font(this.tm.current.body16)
        .fontColor(this.tm.current.colorTextPrimary)
        .layoutWeight(1)
      Text(value)
        .font(this.tm.current.body16)
        .fontColor(isLink ? this.tm.current.colorPrimary : this.tm.current.colorTextSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.value50)
    .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
    .alignItems(VerticalAlign.Center)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct AboutSectionPreview {
  build() {
    Column() {
      AboutSection()
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}

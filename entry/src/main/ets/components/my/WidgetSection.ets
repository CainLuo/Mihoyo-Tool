/**
 * WidgetSection — My 页面的 Widget 卡片入口区域
 */
import { formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from 'core';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { MyAccountVM } from '../../models/MyModels';
import { gameIdToFormName, formNameToDimension, gameIdToLabel } from '../../widget/utils/WidgetFormUtils';

const TAG = 'WIDGET';
const BUNDLE_NAME = 'com.cainluo.miyoyo.tools';
const ABILITY_NAME = 'EntryFormAbility';
const MODULE_NAME = 'entry';

@ComponentV2
export struct WidgetSection {
  @Param accounts: MyAccountVM[] = [];
  @Local private tm: ThemeManager = themeManager;

  private openFormManager(accountId: string, formName: string, selectedGames: string[]): void {
    const want: Want = {
      bundleName: BUNDLE_NAME,
      abilityName: ABILITY_NAME,
      parameters: {
        'ohos.extra.param.key.form_dimension': formNameToDimension(formName),
        'ohos.extra.param.key.form_name': formName,
        'ohos.extra.param.key.module_name': MODULE_NAME,
        'accountId': accountId,
        'selectedGames': selectedGames.join(','),
      },
    };
    try {
      formProvider.openFormManager(want);
    } catch (e) {
      const err = e as BusinessError;
      Logger.error(TAG, `openFormManager failed: code=${err.code} msg=${err.message}`);
    }
  }

  private getGameIds(account: MyAccountVM): string[] {
    const gameIds: string[] = [];
    for (let i = 0; i < account.roles.length; i++) {
      const gid = account.roles[i].gameId;
      if (gameIds.indexOf(gid) < 0) {
        gameIds.push(gid);
      }
    }
    return gameIds;
  }

  build() {
    Column() {
      ForEach(this.accounts, (account: MyAccountVM) => {
        this.AccountWidgetBlock(account)
      }, (account: MyAccountVM) => account.uid)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .clip(true)
  }

  @Builder
  AccountWidgetBlock(account: MyAccountVM) {
    Column({ space: 0 }) {
      Row() {
        Text(account.nickname.length > 0 ? account.nickname : account.username)
          .fontSize(this.tm.current.font14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tm.current.colorTextPrimary)
          .layoutWeight(1)
        Text(account.uid)
          .fontSize(this.tm.current.font11)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .width(this.tm.current.full)
      .padding({
        top: this.tm.current.value12,
        bottom: this.tm.current.value8,
        left: this.tm.current.font16,
        right: this.tm.current.font16,
      })

      Row({ space: this.tm.current.value8 }) {
        ForEach(this.getGameIds(account), (gameId: string) => {
          Button({ type: ButtonType.Normal }) {
            Text(gameIdToLabel(gameId))
              .fontSize(this.tm.current.font13)
              .fontColor(this.tm.current.colorTextPrimary)
          }
          .height(this.tm.current.value36)
          .padding({ left: this.tm.current.value12, right: this.tm.current.value12 })
          .backgroundColor(this.tm.current.colorSurfaceSubtle)
          .borderRadius(this.tm.current.radius8)
          .onClick(() => {
            this.openFormManager(account.uid, gameIdToFormName(gameId), [gameId]);
          })
        }, (gameId: string) => gameId)

        if (this.getGameIds(account).length >= 2) {
          Button({ type: ButtonType.Normal }) {
            Text($r('app.string.widget_add_all_games'))
              .fontSize(this.tm.current.font13)
              .fontColor(this.tm.current.colorPrimary)
          }
          .height(this.tm.current.value36)
          .padding({ left: this.tm.current.value12, right: this.tm.current.value12 })
          .backgroundColor('rgba(58,111,216,0.15)')
          .borderRadius(this.tm.current.radius8)
          .onClick(() => {
            this.openFormManager(account.uid, 'widget_2x2', this.getGameIds(account));
          })
        }
      }
      .width(this.tm.current.full)
      .padding({
        bottom: this.tm.current.value12,
        left: this.tm.current.font16,
        right: this.tm.current.font16,
      })
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}

@Preview
@ComponentV2
export struct WidgetSectionPreview {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: 16 }) {
      WidgetSection({ accounts: [] })
    }
    .padding(this.tm.current.font16)
    .backgroundColor('#1a1a2e')
  }
}

/**
 * ZZZDailyDetailPage — 绝区零实时便笺详情页（View 层）
 */

import { themeManager, ThemeManager } from 'basic'
import { DailyNoteZZZ } from '../views/zzz/DailyNoteZZZ'
import { ZZZDailyDetailViewModel } from '../viewmodel/ZZZDailyDetailViewModel'
import { DailyDetailScaffold } from '../views/common/DailyDetailScaffold'

/** 系统 Navigation 传入的路由参数 */
export class ZZZDailyDetailParam {
  accountId: string = '';
  roleUid: string = '';
}

@ComponentV2
export struct ZZZDailyDetailPage {
  @Param routerParam: ZZZDailyDetailParam = new ZZZDailyDetailParam()
  @Local private tm: ThemeManager = themeManager
  @Local private vm: ZZZDailyDetailViewModel = new ZZZDailyDetailViewModel()

  aboutToAppear(): void {
    this.vm.init(this.routerParam.accountId, this.routerParam.roleUid)
    this.vm.loadData()
  }

  @Builder
  gameContent() {
    DailyNoteZZZ({ data: this.vm.note })
      .padding({ left: this.tm.current.font16, right: this.tm.current.font16 })
  }

  build() {
    DailyDetailScaffold({
      title: $r('app.string.zzz_daily_title'),
      viewState: this.vm.viewState,
      content: () => { this.gameContent() }
    })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct ZZZDailyDetailPagePreview {
  build() {
    ZZZDailyDetailPage({ routerParam: new ZZZDailyDetailParam() })
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function ZZZDailyDetailPageBuilder(_name: string, param: Object) {
  ZZZDailyDetailPage({ routerParam: param as ZZZDailyDetailParam })
}

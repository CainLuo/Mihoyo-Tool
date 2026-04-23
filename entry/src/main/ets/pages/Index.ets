import { AppRoutes } from '../constants/AppRoutes';
import { RouterUtil } from '../utils/RouterUtil';
import { Launch } from './Launch';
import { Main } from './Main';
import { Login } from './Login';
import { GenshinDailyDetail, GenshinDailyDetailParam } from './GenshinDailyDetail';
import { GenshinCharacterDetail, GenshinCharacterDetailParam } from './GenshinCharacterDetail';
import { StarRailCharacterDetail } from './StarRailCharacterDetail';
import { ZZZCharacterDetail } from './ZZZCharacterDetail';
import { AccountDetail } from './AccountDetail';
import { MyAccountVM } from '../models/MyModels';
import { CharDetailRouterParam } from '../models/CharDetailModels';
import { StarRailDailyDetail, StarRailDailyDetailParam } from './StarRailDailyDetail';
import { ZZZDailyDetail, ZZZDailyDetailParam } from './ZZZDailyDetail';

@Builder
function pageBuilder(name: string, param: Object) {
  if (name === AppRoutes.LAUNCH) {
    Launch()
  } else if (name === AppRoutes.MAIN) {
    Main()
  } else if (name === AppRoutes.LOGIN) {
    Login()
  } else if (name === AppRoutes.GENSHIN_DAILY_DETAIL) {
    GenshinDailyDetail({ routerParam: param as GenshinDailyDetailParam })
  } else if (name === AppRoutes.STARRAIL_DAILY_DETAIL) {
    StarRailDailyDetail({ routerParam: param as StarRailDailyDetailParam })
  } else if (name === AppRoutes.ZZZ_DAILY_DETAIL) {
    ZZZDailyDetail({ routerParam: param as ZZZDailyDetailParam })
  } else if (name === AppRoutes.GENSHIN_CHARACTER_DETAIL) {
    GenshinCharacterDetail({ routerParam: param as GenshinCharacterDetailParam })
  } else if (name === AppRoutes.STARRAIL_CHARACTER_DETAIL) {
    StarRailCharacterDetail({ routerParam: param as CharDetailRouterParam })
  } else if (name === AppRoutes.ZZZ_CHARACTER_DETAIL) {
    ZZZCharacterDetail({ routerParam: param as CharDetailRouterParam })
  } else if (name === AppRoutes.ACCOUNT_DETAIL) {
    AccountDetail({ account: param as MyAccountVM })
  }
}

@Entry
@ComponentV2
struct Index {
  private pathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    RouterUtil.init(this.pathStack);
    this.pathStack.pushPathByName(AppRoutes.LAUNCH, null);
  }

  build() {
    Navigation(this.pathStack) {}
    .navDestination(pageBuilder)
    .mode(NavigationMode.Auto)
    .hideNavBar(true)
  }
}

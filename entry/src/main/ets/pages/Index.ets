import { AppRoutes } from '../constants/AppRoutes';
import { RouterUtil } from '../utils/RouterUtil';
import { Launch } from './Launch';
import { Main } from './Main';
import { Login } from './Login';
import { GenshinDailyDetail, GenshinDailyDetailParam } from './GenshinDailyDetail';
import { GenshinCharacterDetail, GenshinCharacterDetailParam } from './GenshinCharacterDetail';
import { AccountDetail } from './AccountDetail';
import { MyAccountVM } from '../components/my/MyModels';

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
  } else if (name === AppRoutes.GENSHIN_CHARACTER_DETAIL) {
    GenshinCharacterDetail({ routerParam: param as GenshinCharacterDetailParam })
  } else if (name === AppRoutes.ACCOUNT_DETAIL) {
    AccountDetail({ account: param as MyAccountVM })
  }
}

@Entry
@Component
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

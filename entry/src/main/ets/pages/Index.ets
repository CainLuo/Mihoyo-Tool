import { AppRoutes } from '../constants/AppRoutes';
import { RouterUtil } from '../utils/RouterUtil';
import { LaunchBuilder } from './router/LaunchBuilder';
import { MainBuilder } from './router/MainBuilder';
import { LoginBuilder } from './router/LoginBuilder';
import { GenshinDailyDetailBuilder } from './router/GenshinDailyDetailBuilder';
import { GenshinCharacterDetailBuilder } from './router/GenshinCharacterDetailBuilder';
import { AccountDetailBuilder } from './router/AccountDetailBuilder';

@Builder
function pageBuilder(name: string, param: Object) {
  if (name === AppRoutes.LAUNCH) {
    LaunchBuilder(name, param)
  } else if (name === AppRoutes.MAIN) {
    MainBuilder(name, param)
  } else if (name === AppRoutes.LOGIN) {
    LoginBuilder(name, param)
  } else if (name === AppRoutes.GENSHIN_DAILY_DETAIL) {
    GenshinDailyDetailBuilder(name, param)
  } else if (name === AppRoutes.GENSHIN_CHARACTER_DETAIL) {
    GenshinCharacterDetailBuilder(name, param)
  } else if (name === AppRoutes.ACCOUNT_DETAIL) {
    AccountDetailBuilder(name, param)
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
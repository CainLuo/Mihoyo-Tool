import { AppRoutes } from '../constants/AppRoutes';
import { RouterUtil } from '../utils/RouterUtil';
import { Launch } from './Launch';
import { Main } from './Main';
import { PrivacyConsentPageBuilder } from './PrivacyConsentPage';

@Builder
function pageBuilder(name: string, param: Object) {
  if (name === AppRoutes.LAUNCH) {
    Launch()
  } else if (name === AppRoutes.MAIN) {
    Main()
  } else if (name === AppRoutes.PRIVACY_CONSENT) {
    PrivacyConsentPageBuilder(name, param)
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

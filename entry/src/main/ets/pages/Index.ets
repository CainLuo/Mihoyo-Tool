import { AppRoutes, RouterUtil } from 'basic';
import { LaunchPage } from './LaunchPage';
import { MainPage } from './MainPage';
import { PrivacyConsentPageBuilder } from 'legal';

@Builder
function pageBuilder(name: string, param: Object) {
  if (name === AppRoutes.LAUNCH) {
    LaunchPage()
  } else if (name === AppRoutes.MAIN) {
    MainPage()
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

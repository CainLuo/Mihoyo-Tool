import { HMDefaultGlobalAnimator, HMNavigation } from '@hadss/hmrouter';
import { AttributeUpdater } from '@kit.ArkUI';
import { AppRoutes } from '../constants/AppRoutes';
import { themeManager } from '../theme/ThemeManager';
import './Main';
import './Setting';
import './Login';
import './router/MainBuilder';
import './router/GenshinDailyDetailBuilder';
import './router/GenshinCharacterDetailBuilder';
import './router/LoginBuilder';
import './router/SettingBuilder';

class MyNavModifier extends AttributeUpdater<NavigationAttribute> {
  initializeModifier(instance: NavigationAttribute): void {
    instance.hideNavBar(true);
  }
}

@Entry
@Component
struct Index {
  modifier: MyNavModifier = new MyNavModifier();

  build() {
    Column() {
      HMNavigation({
        navigationId: 'mainNavigationId',
        homePageUrl: AppRoutes.MAIN,
        options: {
          standardAnimator: HMDefaultGlobalAnimator.STANDARD_ANIMATOR,
          modifier: this.modifier
        }
      });
    }
    .backgroundColor(Color.Transparent)
    .height(themeManager.current.heightFull)
    .width(themeManager.current.widthFull)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM]);
  }
}
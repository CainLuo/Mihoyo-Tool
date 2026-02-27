import { Setting } from "../pages/Setting";
import { Login } from "../pages/Login";

// src/main/ets/constants/AppRoute.ets
export enum AppRoute {
  Home = 'HomePage',
  My = 'MyPage',
  Setting = 'SettingPage',
  Login = 'LoginPage'
}

@Builder
export function PageMap(name: string) {
  // const route = name as AppRoute;

  // switch (route) {
  //   case AppRoute.Setting:
  //     Setting();
  //     break;
  //   case AppRoute.Login:
  //     Login();
  //     break;
  //   default:
  //     break;
  // }
}
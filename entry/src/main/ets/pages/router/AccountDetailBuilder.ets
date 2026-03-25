import { AccountDetail } from '../AccountDetail';
import { MyAccountVM } from '../../components/my/MyModels';

@Builder
export function AccountDetailBuilder(_name: string, param: Object) {
  AccountDetailDestination({ account: param as MyAccountVM })
}

@Component
struct AccountDetailDestination {
  account: MyAccountVM = new MyAccountVM(0, '', []);

  build() {
    NavDestination() {
      AccountDetail({ account: this.account })
    }
    .title($r('app.string.account_detail_title'))
    .hideTitleBar(false)
  }
}

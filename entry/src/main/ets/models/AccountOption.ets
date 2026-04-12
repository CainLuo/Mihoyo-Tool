/**
 * AccountOption — 账号切换 Menu 的选项数据
 *
 * 由 CharactersViewModel.buildAccountOptions() 从 AccountRow[] 转换而来，
 * 用于 Characters 页右上角账号切换 Menu 的列表展示。
 *
 * 显示内容：nickname（优先）或 username，以及 uid。
 */
export class AccountOption {
  /** 账号在本地 DB 中的自增 id（保留用于 UI 标识） */
  accountId: string = '';
  /** 米游社账号 ID（即 Cookie 里的 account_id） */
  username: string = '';
  /** 米游社昵称 */
  nickname: string = '';
  /** 米游社头像 URL */
  avatarUrl: string = '';
  /** 米游社 uid（与 username 相同） */
  uid: string = '';

  constructor(
    accountId: string,
    username: string,
    nickname: string = '',
    avatarUrl: string = '',
    uid: string = ''
  ) {
    this.accountId = accountId;
    this.username = username;
    this.nickname = nickname;
    this.avatarUrl = avatarUrl;
    this.uid = uid;
  }
}

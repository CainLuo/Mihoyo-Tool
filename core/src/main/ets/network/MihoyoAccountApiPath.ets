export enum MihoyoAccountApiPath {
  /** 游戏战绩卡片（含背景图、统计数据）— Domain: TAKUMI_RECORD */
  GET_GAME_RECORD_CARD = '/game_record/app/card/wapi/getGameRecordCard',
  /** BBS 账号详情（昵称、头像、简介）— Domain: BBS */
  GET_USER_FULL_INFO = '/user/wapi/getUserFullInfo',
  /** 游戏角色绑定列表 — Domain: TAKUMI */
  GET_GAME_ROLES = '/binding/api/getUserGameRolesByCookie',
  /** 申请 Geetest 验证任务 — Domain: BBS */
  CREATE_VERIFICATION = '/misc/api/createVerification',
  /** 提交 Geetest 验证结果，换取新 challenge — Domain: BBS */
  VERIFY_VERIFICATION = '/misc/api/verifyVerification',
}

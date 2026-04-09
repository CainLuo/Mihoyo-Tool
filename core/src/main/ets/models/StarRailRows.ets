export class StarRailAvatarBasicRow {
  id: number = 0;
  accountId: number = 0;
  roleUid: string = '';
  avatarId: string = '';
  name: string = '';
  element: string = '';
  rarity: number = 0;
  level: number = 0;
  rank: number = 0;
  baseType: number = 0;
  equipId: string = '';
  equipName: string = '';
  equipRarity: number = 0;
  equipLevel: number = 0;
  equipRank: number = 0;
  equipIconUrl: string = '';
  /** 是否被选中（0=否，1=是） */
  isChosen: number = 0;
  icon: string = '';
  figurePath: string = '';
  elementId: number = 0;
  rawJson: string = '';
  updateTime: number = 0;
}

export class StarRailDailyNoteRow {
  id: number = 0;
  accountId: number = 0;
  roleUid: string = '';
  currentStamina: number = 0;
  maxStamina: number = 0;
  staminaRecoverTime: number = 0;
  staminaFullTs: number = 0;
  currentReserveStamina: number = 0;
  acceptedExpeditionNum: number = 0;
  totalExpeditionNum: number = 0;
  currentTrainScore: number = 0;
  maxTrainScore: number = 0;
  currentRogueScore: number = 0;
  maxRogueScore: number = 0;
  weeklyCocoonCnt: number = 0;
  weeklyCocoonLimit: number = 0;
  rogueTournWeeklyCur: number = 0;
  rogueTournWeeklyMax: number = 0;
  gridFightWeeklyCur: number = 0;
  gridFightWeeklyMax: number = 0;
  rawJson: string = '';
  updateTime: number = 0;
}

export class StarRailAvatarInfoRow {
  id: number = 0;
  accountId: number = 0;
  roleUid: string = '';
  avatarId: string = '';
  equipId: string = '';
  equipLevel: number = 0;
  equipRank: number = 0;
  relicIds: string = '';
  skillTreeJson: string = '';
  rawJson: string = '';
  updateTime: number = 0;
}

export class StarRailAvatarComputeRow {
  id: number = 0;
  accountId: number = 0;
  roleUid: string = '';
  avatarId: string = '';
  avatarConsumeJson: string = '';
  skillConsumeJson: string = '';
  equipmentConsumeJson: string = '';
  updateTime: number = 0;
}

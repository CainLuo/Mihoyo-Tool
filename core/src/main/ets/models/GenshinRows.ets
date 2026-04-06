export class GenshinCharacterListRow {
  id: number = 0;
  accountId: number = 0;
  roleUid: string = '';
  avatarId: string = '';
  name: string = '';
  element: string = '';
  rarity: number = 0;
  level: number = 0;
  fetter: number = 0;
  activedConstellationNum: number = 0;
  weaponType: number = 0;
  weaponId: string = '';
  weaponName: string = '';
  weaponRarity: number = 0;
  weaponLevel: number = 0;
  weaponAffixLevel: number = 0;
  icon: string = '';
  sideIcon: string = '';
  rawJson: string = '';
  updateTime: number = 0;
}

export class GenshinDailyNoteRow {
  id: number = 0;
  accountId: number = 0;
  roleUid: string = '';
  currentResin: number = 0;
  maxResin: number = 0;
  resinRecoveryTime: number = 0;
  finishedTaskNum: number = 0;
  totalTaskNum: number = 0;
  remainResinDiscountNum: number = 0;
  currentExpeditionNum: number = 0;
  maxExpeditionNum: number = 0;
  currentHomeCoin: number = 0;
  maxHomeCoin: number = 0;
  transformerRecoveryDay: number = 0;
  rawJson: string = '';
  updateTime: number = 0;
}

export class GenshinCharacterDetailRow {
  id: number = 0;
  accountId: number = 0;
  roleUid: string = '';
  avatarId: string = '';
  weaponId: string = '';
  weaponLevel: number = 0;
  weaponAffixLevel: number = 0;
  relicIds: string = '';
  skillLevels: string = '';
  rawJson: string = '';
  updateTime: number = 0;
}

export class GenshinCharacterComputeRow {
  id: number = 0;
  accountId: number = 0;
  roleUid: string = '';
  avatarId: string = '';
  avatarConsumeJson: string = '';
  skillConsumeJson: string = '';
  weaponConsumeJson: string = '';
  updateTime: number = 0;
}

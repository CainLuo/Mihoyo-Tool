export class ZZZAvatarBasicRow {
  id: number = 0;
  accountId: number = 0;
  roleUid: string = '';
  avatarId: string = '';
  nameMi18n: string = '';
  fullNameMi18n: string = '';
  elementType: number = 0;
  subElementType: number = 0;
  avatarProfession: number = 0;
  rarity: string = '';
  level: number = 0;
  rank: number = 0;
  campNameMi18n: string = '';
  groupIconPath: string = '';
  hollowIconPath: string = '';
  roleSquareUrl: string = '';
  /** 觉醒状态（DB 存 TEXT，读取时 parseInt 转 number；0=未知/不可见） */
  awakenState: number = 0;
  /** 是否被选中（0=否，1=是） */
  isChosen: number = 0;
  rawJson: string = '';
  updateTime: number = 0;
}

export class ZZZDailyNoteRow {
  id: number = 0;
  accountId: number = 0;
  roleUid: string = '';
  energyCurrent: number = 0;
  energyMax: number = 0;
  energyRestore: number = 0;
  vitalityCurrent: number = 0;
  vitalityMax: number = 0;
  vhsSaleState: string = '';
  cardSign: string = '';
  rawJson: string = '';
  updateTime: number = 0;
}

export class ZZZAvatarInfoRow {
  id: number = 0;
  accountId: number = 0;
  roleUid: string = '';
  avatarId: string = '';
  weaponId: string = '';
  weaponLevel: number = 0;
  weaponStar: number = 0;
  equipIds: string = '';
  skillLevelsJson: string = '';
  verticalPaintingUrl: string = '';
  rawJson: string = '';
  updateTime: number = 0;
}

export class ZZZAvatarComputeRow {
  id: number = 0;
  accountId: number = 0;
  roleUid: string = '';
  avatarId: string = '';
  avatarConsumeJson: string = '';
  weaponConsumeJson: string = '';
  skillConsumeJson: string = '';
  updateTime: number = 0;
}

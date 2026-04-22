/**
 * ZZZElement — 绝区零属性/职业枚举
 *
 * element_type 和 avatar_profession 均为数字，来自 avatar/basic API。
 * 特殊属性（ZHEN_ZHEN_ASSAULT/FIRE_FROST/AURIC_ETHER）通过 sub_element_type 区分，
 * 与基础属性共享 element_type 数字段，CharacterCard 目前只用 element_type 显示图标。
 * 转换函数在边界处（ViewModel）调用一次，之后全程使用 enum。
 */
export enum ZZZElementType {
  PHYSICS           = 200,   // 物理
  FIRE              = 201,   // 火
  ICE               = 202,   // 冰
  ELECTRIC          = 203,   // 电
  ETHER             = 205,   // 以太
  /** 凛刃（真真专属，基础为物理，通过 sub_element_type=2001 区分） */
  ZHEN_ZHEN_ASSAULT = 2001,
  /** 烈霜（Unagi 专属，基础为冰，通过 sub_element_type=2002 区分） */
  FIRE_FROST        = 2002,
  /** 玄墨（基础为以太，通过 sub_element_type=2003 区分） */
  AURIC_ETHER       = 2003,
  UNKNOWN           = 0,
}

export enum ZZZProfession {
  ATTACK  = 1,  // 强攻（PowerfulAttack）
  STUN    = 2,  // 击破（BreakStun）
  ANOMALY = 3,  // 异常（ElementAbnormal）
  SUPPORT = 4,  // 支援（Support）
  DEFENSE = 5,  // 防护（Defence）
  RUPTURE = 6,  // 命破（Rupture）
  UNKNOWN = 0,
}

/**
 * element_type 数字 → ZZZElementType enum
 * 未知值返回 ZZZElementType.UNKNOWN
 */
export function zzzElementTypeFromNumber(n: number): ZZZElementType {
  if (n === ZZZElementType.PHYSICS)           { return ZZZElementType.PHYSICS; }
  if (n === ZZZElementType.FIRE)              { return ZZZElementType.FIRE; }
  if (n === ZZZElementType.ICE)               { return ZZZElementType.ICE; }
  if (n === ZZZElementType.ELECTRIC)          { return ZZZElementType.ELECTRIC; }
  if (n === ZZZElementType.ETHER)             { return ZZZElementType.ETHER; }
  if (n === ZZZElementType.ZHEN_ZHEN_ASSAULT) { return ZZZElementType.ZHEN_ZHEN_ASSAULT; }
  if (n === ZZZElementType.FIRE_FROST)        { return ZZZElementType.FIRE_FROST; }
  if (n === ZZZElementType.AURIC_ETHER)       { return ZZZElementType.AURIC_ETHER; }
  return ZZZElementType.UNKNOWN;
}

/**
 * avatar_profession 数字 → ZZZProfession enum
 * 未知值返回 ZZZProfession.UNKNOWN
 */
export function zzzProfessionFromNumber(n: number): ZZZProfession {
  if (n === ZZZProfession.ATTACK)  { return ZZZProfession.ATTACK; }
  if (n === ZZZProfession.STUN)    { return ZZZProfession.STUN; }
  if (n === ZZZProfession.ANOMALY) { return ZZZProfession.ANOMALY; }
  if (n === ZZZProfession.SUPPORT) { return ZZZProfession.SUPPORT; }
  if (n === ZZZProfession.DEFENSE) { return ZZZProfession.DEFENSE; }
  if (n === ZZZProfession.RUPTURE) { return ZZZProfession.RUPTURE; }
  return ZZZProfession.UNKNOWN;
}

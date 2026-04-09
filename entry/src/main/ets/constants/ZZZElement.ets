/**
 * ZZZElement — 绝区零属性/职业枚举
 *
 * element_type 为数字，avatar_profession 为数字。
 * 属性映射来源：DamageElementConfigTemplateTb.json（游戏数据解包）
 * 职业映射来源：AvatarProfessionTemplateTb.json（游戏数据解包）
 *
 * 注意：特殊属性（ZhenZhenAssault/FireFrost/AuricEther）与基础属性共享 element_type 数字，
 * 通过 sub_element_type 字段区分，但 CharacterCard 目前只用 element_type 显示图标。
 */

export enum ZZZElementType {
  PHYSICS            = 200,  // 物理
  FIRE               = 201,  // 火
  ICE                = 202,  // 冰
  ELECTRIC           = 203,  // 电
  ETHER              = 205,  // 以太
  // 特殊属性（sub_element_type 区分，与基础属性共享 element_type）
  ZHEN_ZHEN_ASSAULT  = 2001, // 凛刃（真真专属，基础为物理）
  FIRE_FROST         = 2002, // 烈霜（Unagi 专属，基础为冰）
  AURIC_ETHER        = 2003, // 玄墨（基础为以太）
  UNKNOWN            = 0,
}

export enum ZZZProfession {
  ATTACK   = 1,  // 强攻（PowerfulAttack）
  STUN     = 2,  // 击破（BreakStun）
  ANOMALY  = 3,  // 异常（ElementAbnormal）
  SUPPORT  = 4,  // 支援（Support）
  DEFENSE  = 5,  // 防护（Defence）
  RUPTURE  = 6,  // 命破（Rupture）
  UNKNOWN  = 0,
}

/** element_type 数字 → 属性图标资源，未知属性返回 null */
export function zzzElementIcon(elementType: number): Resource | null {
  if (elementType === ZZZElementType.PHYSICS)           { return $r('app.media.zzz_element_physics'); }
  if (elementType === ZZZElementType.FIRE)              { return $r('app.media.zzz_element_fire'); }
  if (elementType === ZZZElementType.ICE)               { return $r('app.media.zzz_element_ice'); }
  if (elementType === ZZZElementType.ELECTRIC)          { return $r('app.media.zzz_element_elec'); }
  if (elementType === ZZZElementType.ETHER)             { return $r('app.media.zzz_element_ether'); }
  if (elementType === ZZZElementType.ZHEN_ZHEN_ASSAULT) { return $r('app.media.zzz_element_zhen_zhen_assault'); }
  if (elementType === ZZZElementType.FIRE_FROST)        { return $r('app.media.zzz_element_fire_frost'); }
  if (elementType === ZZZElementType.AURIC_ETHER)       { return $r('app.media.zzz_element_auric_ether'); }
  return null;
}

/** avatar_profession 数字 → 特性图标资源，未知职业返回 null */
export function zzzProfessionIcon(profession: number): Resource | null {
  if (profession === ZZZProfession.ATTACK)  { return $r('app.media.zzz_avatar_profession_powerful_attack'); }
  if (profession === ZZZProfession.STUN)    { return $r('app.media.zzz_avatar_profession_break_stun'); }
  if (profession === ZZZProfession.ANOMALY) { return $r('app.media.zzz_avatar_profession_element_abnormal'); }
  if (profession === ZZZProfession.SUPPORT) { return $r('app.media.zzz_avatar_profession_support'); }
  if (profession === ZZZProfession.DEFENSE) { return $r('app.media.zzz_avatar_profession_defense'); }
  if (profession === ZZZProfession.RUPTURE) { return $r('app.media.zzz_avatar_profession_rupture'); }
  return null;
}

/** element_type 数字 → 颜色资源 */
export function zzzElementColor(elementType: number): Resource {
  if (elementType === ZZZElementType.PHYSICS)  { return $r('app.color.zzz_element_physical'); }
  if (elementType === ZZZElementType.FIRE)     { return $r('app.color.zzz_element_fire'); }
  if (elementType === ZZZElementType.ICE)      { return $r('app.color.zzz_element_ice'); }
  if (elementType === ZZZElementType.ELECTRIC) { return $r('app.color.zzz_element_electric'); }
  if (elementType === ZZZElementType.ETHER)    { return $r('app.color.zzz_element_ether'); }
  return $r('app.color.color_text_secondary');
}

/**
 * CharacterSort — 角色列表统一排序（角色页 / 材料计算角色选择页共用）
 *
 * 规则：星级高的在前（五星 > 四星）；同星级按角色 ID 从大到小。
 * 星级优先：四星角色 ID 再大，也排在所有五星之后。
 */

/** 角色 ID 转数字（原神 10000xxx / 星铁 1xxx / 绝区零 1xxx），非数字按 0 处理 */
function idToNumber(id: string): number {
  const n = parseInt(id, 10)
  return isNaN(n) ? 0 : n
}

/** 原神联动角色（埃洛伊）接口返回的星级是 105，按五星处理 */
function normalizeRarity(rarity: number): number {
  return rarity > 5 ? 5 : rarity
}

/**
 * 比较函数，用于 Array.sort。
 * @param rarityA / rarityB 星级（绝区零请先换算：S = 5，A = 4）
 * @param idA / idB 角色 ID
 */
export function compareCharacter(rarityA: number, idA: string, rarityB: number, idB: string): number {
  const ra = normalizeRarity(rarityA)
  const rb = normalizeRarity(rarityB)
  if (ra !== rb) {
    return rb - ra
  }
  return idToNumber(idB) - idToNumber(idA)
}

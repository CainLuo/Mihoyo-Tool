/**
 * MaterialAmountUtil.ets — 材料数量格式化
 *
 * 摩拉 / 经验书 / 魔矿等货币类材料的数量较大，统一按「万 / 亿」折算显示。
 */

const WAN: number = 10000;
const YI: number = 100000000;

/**
 * 格式化货币类材料数量。
 * - < 1万：显示具体数字（如 5000）
 * - >= 1万 且 < 1亿：显示「万」，< 10万保留一位小数，>= 10万取整
 * - >= 1亿：显示「亿」，保留一位小数
 */
export function formatCurrencyAmount(amount: number): string {
  if (amount < WAN) {
    return `${amount}`;
  }

  if (amount >= YI) {
    return formatScaled(amount / YI, '亿');
  }

  const wanValue = amount / WAN;
  if (wanValue < 10) {
    return formatScaled(wanValue, '万');
  }
  return `${Math.floor(wanValue)}万`;
}

/** 保留一位小数；整数结果去掉多余的 `.0` */
function formatScaled(value: number, unit: string): string {
  const formatted = value.toFixed(1);
  if (formatted.endsWith('.0')) {
    return `${formatted.substring(0, formatted.length - 2)}${unit}`;
  }
  return `${formatted}${unit}`;
}

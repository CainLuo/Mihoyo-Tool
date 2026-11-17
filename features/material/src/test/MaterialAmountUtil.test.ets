import { describe, it, expect } from '@ohos/hypium';
import { formatCurrencyAmount } from '../main/ets/utils/MaterialAmountUtil';

export default function materialAmountUtilTest() {
  describe('formatCurrencyAmount', () => {

    it('小于 1 万显示原数字', 0, () => {
      expect(formatCurrencyAmount(0)).assertEqual('0');
      expect(formatCurrencyAmount(500)).assertEqual('500');
      expect(formatCurrencyAmount(9999)).assertEqual('9999');
    });

    it('1 万到 10 万之间保留一位小数', 0, () => {
      expect(formatCurrencyAmount(10000)).assertEqual('1万');
      expect(formatCurrencyAmount(12000)).assertEqual('1.2万');
      expect(formatCurrencyAmount(12345)).assertEqual('1.2万');
      expect(formatCurrencyAmount(99999)).assertEqual('10万');
    });

    it('10 万以上取整', 0, () => {
      expect(formatCurrencyAmount(100000)).assertEqual('10万');
      expect(formatCurrencyAmount(123456)).assertEqual('12万');
      expect(formatCurrencyAmount(98765432)).assertEqual('9876万');
    });

    it('1 亿以上按亿显示并保留一位小数', 0, () => {
      expect(formatCurrencyAmount(100000000)).assertEqual('1亿');
      expect(formatCurrencyAmount(150000000)).assertEqual('1.5亿');
      expect(formatCurrencyAmount(1000000000)).assertEqual('10亿');
    });

  });
}

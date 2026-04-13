/**
 * RsaUtil.ets
 *
 * 米游社手机号登录 RSA 加密工具。
 * 使用 HarmonyOS cryptoFramework 对手机号和区号进行 RSA-PKCS1 加密。
 *
 * 米游社公钥（固定值，来自 mihoyo-api-collect）：
 * MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDDvekdPMHN3AYhm/vktJT+Z0HmR48r
 * 2mCe8wkdtq7AiBh2ridKsauabNqKDJK2vierBn1drV7QjNNqIXZqvo4MHT0HoNjtrSoS
 * aq9n5+Aur9Ndw5Vnr4tDkf8hvenflyc9D5q2sNiiq9tu2NNgAh49uNQqFZh6ghTcs3wD
 * AQAB
 */

import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { buffer } from '@kit.ArkTS';

/** 米游社手机号登录 RSA 公钥（PKCS#8 DER 格式，Base64 编码） */
const MIHOYO_RSA_PUBLIC_KEY =
  'MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDDvekdPMHN3AYhm/vktJT+Z0HmR48r' +
  '2mCe8wkdtq7AiBh2ridKsauabNqKDJK2vierBn1drV7QjNNqIXZqvo4MHT0HoNjtrSoS' +
  'aq9n5+Aur9Ndw5Vnr4tDkf8hvenflyc9D5q2sNiiq9tu2NNgAh49uNQqFZh6ghTcs3wD' +
  'AQAB';

export class RsaUtil {
  /**
   * 用米游社公钥对字符串进行 RSA/ECB/PKCS1Padding 加密，返回 Base64 字符串。
   * 用于加密手机号和区号。
   * 仅在支持 CryptoArchitectureKit 的设备上可用（Phone/Tablet）。
   */
  static async encrypt(plainText: string): Promise<string> {
    if (!canIUse('SystemCapability.Security.CryptoFramework')) {
      throw new Error('RsaUtil: CryptoFramework not supported on this device');
    }
    try {
      // 将 Base64 公钥转为 Uint8Array
      const pubKeyBytes = buffer.from(MIHOYO_RSA_PUBLIC_KEY, 'base64').buffer;
      const pubKeyData: cryptoFramework.DataBlob = { data: new Uint8Array(pubKeyBytes) };

      // 创建 RSA 密钥生成器并导入公钥
      const keyGenerator = cryptoFramework.createAsyKeyGenerator('RSA1024');
      const keyPair = await keyGenerator.convertKey(pubKeyData, null);

      // 创建加密器
      const cipher = cryptoFramework.createCipher('RSA1024|PKCS1');
      await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, keyPair.pubKey, null);

      // 加密
      const plainBytes = new Uint8Array(buffer.from(plainText, 'utf-8').buffer);
      const plainData: cryptoFramework.DataBlob = { data: plainBytes };
      const encryptedData = await cipher.doFinal(plainData);

      // 转为 Base64
      return buffer.from(encryptedData.data.buffer).toString('base64');
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`RsaUtil.encrypt failed: ${msg}`);
    }
  }
}

/**
 * LegalI18nRouter — 根据系统语言返回对应的协议 rawfile 路径
 *
 * 语言映射：
 *   zh-Hant / zh-HK / zh-TW / zh-MO → -zh-hant（繁体中文）
 *   zh（其余）                        → -zh（简体中文）
 *   en                               → -en（英文）
 *   其他                              → ''（fallback，无后缀）
 */
import { i18n } from '@kit.LocalizationKit';

export class LegalI18nRouter {
  private static langSuffix(): string {
    const lang = i18n.System.getSystemLanguage();
    if (lang.startsWith('zh-Hant') || lang === 'zh-HK' || lang === 'zh-TW' || lang === 'zh-MO') {
      return '-zh-hant';
    }
    if (lang.startsWith('zh')) {
      return '-zh';
    }
    if (lang.startsWith('en')) {
      return '-en';
    }
    return '';
  }

  /** 返回隐私政策的 rawfile 路径，如 'legal/privacy-zh.html' */
  static privacyPath(): string {
    return `legal/privacy${LegalI18nRouter.langSuffix()}.html`;
  }

  /** 返回用户协议的 rawfile 路径，如 'legal/terms-zh.html' */
  static termsPath(): string {
    return `legal/terms${LegalI18nRouter.langSuffix()}.html`;
  }
}

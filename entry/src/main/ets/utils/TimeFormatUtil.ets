/**
 * TimeFormatUtil — 时间格式化工具（View 层使用）
 *
 * 所有格式化方法使用 getStringSync 读取多语言资源，
 * 禁止在此文件中直接写中文/英文字符串字面量。
 *
 * 调用方必须传入 UIContext（通过 this.getUIContext() 获取）。
 */
import { common } from '@kit.AbilityKit';

export class TimeFormatUtil {

  /**
   * 将剩余恢复秒数转为首页卡片用的描述文字。
   * 例："将于 1 小时 30 分钟后全部恢复" / "将于 10 分钟后全部恢复"
   * 秒数 <= 0 时返回空字符串。
   */
  static recoveryDesc(seconds: number, ctx: common.UIAbilityContext): string {
    if (seconds <= 0) {
      return '';
    }
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    if (h > 0) {
      return ctx.resourceManager.getStringSync($r('app.string.time_hours_minutes_recovery').id, h, m);
    }
    return ctx.resourceManager.getStringSync($r('app.string.time_minutes_recovery').id, m);
  }

  /**
   * 将秒数格式化为详情页用的描述文字。
   * 例："1小时30分钟后恢复" / "10分钟后恢复" / "即将恢复"
   */
  static formatSeconds(seconds: number, ctx: common.UIAbilityContext): string {
    if (seconds <= 0) {
      return '';
    }
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    if (h > 0) {
      return ctx.resourceManager.getStringSync($r('app.string.time_hours_minutes_after').id, h, m);
    }
    if (m > 0) {
      return ctx.resourceManager.getStringSync($r('app.string.time_minutes_after').id, m);
    }
    return ctx.resourceManager.getStringSync($r('app.string.time_soon').id);
  }

  /**
   * 将天/时/分格式化为参量质变仪等倒计时描述。
   * 例："1天2小时后可用" / "3小时30分钟后可用" / "即将可用"
   */
  static formatTransformer(day: number, hour: number, minute: number, ctx: common.UIAbilityContext): string {
    if (day > 0) {
      return ctx.resourceManager.getStringSync($r('app.string.time_days_hours_available').id, day, hour);
    }
    if (hour > 0) {
      return ctx.resourceManager.getStringSync($r('app.string.time_hours_minutes_available').id, hour, minute);
    }
    if (minute > 0) {
      return ctx.resourceManager.getStringSync($r('app.string.time_minutes_available').id, minute);
    }
    return ctx.resourceManager.getStringSync($r('app.string.time_soon_available').id);
  }
}

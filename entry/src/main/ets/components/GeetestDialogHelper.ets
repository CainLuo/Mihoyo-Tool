/**
 * GeetestDialogHelper — showGeetestDialog 全局调用入口
 *
 * 使用 ComponentContent + openCustomDialog 方案（API 12+ 推荐）。
 *
 * 使用方式：
 *   import { showGeetestDialog } from '../components/GeetestDialogHelper';
 *   import { GeetestService } from 'core';
 *
 *   const createResult = await GeetestService.createVerification(cookie);
 *   const verifyInput = await showGeetestDialog(this.getUIContext(), createResult);
 *   if (!verifyInput) return; // 用户取消
 */
import { UIContext, ComponentContent, promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { GeetestCreateResult, GeetestVerifyInput } from 'core';
import { Logger } from 'core';
import { themeManager } from '../theme/ThemeManager';
import { GeetestDialog } from './GeetestDialog';

/** 内部用于传递参数给 @Builder 的数据容器（ArkTS 要求 wrapBuilder 参数为单一对象） */
export class GeetestDialogParams {
  createResult: GeetestCreateResult;
  onResult: (result: GeetestVerifyInput | null) => void;

  constructor(
    createResult: GeetestCreateResult,
    onResult: (result: GeetestVerifyInput | null) => void
  ) {
    this.createResult = createResult;
    this.onResult = onResult;
  }
}

/** 供 ComponentContent + wrapBuilder 使用的模块级 @Builder 函数 */
@Builder
function buildGeetestDialogContent(params: GeetestDialogParams) {
  GeetestDialog({
    createResult: params.createResult,
    onResult: params.onResult,
  })
}

/**
 * 展示 Geetest 验证码弹窗，返回 Promise<GeetestVerifyInput | null>
 * @param uiContext 当前页面的 UIContext，通过 this.getUIContext() 获取
 * @param createResult GeetestService.createVerification() 返回的参数
 * @returns 用户完成验证后的结果，用户取消时返回 null
 */
export function showGeetestDialog(
  uiContext: UIContext,
  createResult: GeetestCreateResult
): Promise<GeetestVerifyInput | null> {
  return new Promise<GeetestVerifyInput | null>((resolve) => {
    let contentNode: ComponentContent<GeetestDialogParams> | null = null;

    const params = new GeetestDialogParams(createResult, (result) => {
      if (contentNode !== null) {
        uiContext.getPromptAction().closeCustomDialog(contentNode)
          .then(() => {
            if (contentNode !== null) {
              contentNode.dispose();
              contentNode = null;
            }
          })
          .catch((e: BusinessError) => {
            Logger.warn('GeetestDialog', 'close failed: ' + e.message);
          });
      }
      resolve(result);
    });

    contentNode = new ComponentContent<GeetestDialogParams>(
      uiContext,
      wrapBuilder(buildGeetestDialogContent),
      params
    );

    const dialogOptions: promptAction.BaseDialogOptions = {
      autoCancel: false,
      alignment: DialogAlignment.Center,
      maskColor: themeManager.current.colorMask,
    };

    uiContext.getPromptAction().openCustomDialog(contentNode, dialogOptions)
      .catch((e: BusinessError) => {
        Logger.error('GeetestDialog', 'open failed: ' + e.message);
        resolve(null);
      });
  });
}

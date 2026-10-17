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
import { GeetestDialog } from './GeetestDialog';

/** 队列进度信息 */
export class GeetestProgress {
  /** 当前项序号（1-based） */
  current: number = 0;
  /** 总数 */
  total: number = 0;
}

/** 内部用于传递参数给 @Builder 的数据容器（ArkTS 要求 wrapBuilder 参数为单一对象） */
export class GeetestDialogParams {
  createResult: GeetestCreateResult;
  onResult: (result: GeetestVerifyInput | null) => void;
  /** 队列进度（可选，用于显示 "验证中 (1/3)"） */
  progress: GeetestProgress | null;
  /** 账号名（可选，用于 UI 显示） */
  accountName: string;

  constructor(
    createResult: GeetestCreateResult,
    onResult: (result: GeetestVerifyInput | null) => void,
    progress: GeetestProgress | null = null,
    accountName: string = ''
  ) {
    this.createResult = createResult;
    this.onResult = onResult;
    this.progress = progress;
    this.accountName = accountName;
  }
}

/** 供 ComponentContent + wrapBuilder 使用的模块级 @Builder 函数 */
@Builder
function buildGeetestDialogContent(params: GeetestDialogParams) {
  GeetestDialog({
    createResult: params.createResult,
    onResult: params.onResult,
    progress: params.progress,
    accountName: params.accountName,
  })
}

/**
 * 展示 Geetest 验证码弹窗，返回 Promise<GeetestVerifyInput | null>
 * @param uiContext 当前页面的 UIContext，通过 this.getUIContext() 获取
 * @param createResult GeetestService.createVerification() 返回的参数
 * @param progress 队列进度（可选，用于显示 "验证中 (1/3)"）
 * @param accountName 账号名（可选，用于 UI 显示）
 * @returns 用户完成验证后的结果，用户取消时返回 null
 */
export function showGeetestDialog(
  uiContext: UIContext,
  createResult: GeetestCreateResult,
  progress: GeetestProgress | null = null,
  accountName: string = ''
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
    }, progress, accountName);

    contentNode = new ComponentContent<GeetestDialogParams>(
      uiContext,
      wrapBuilder(buildGeetestDialogContent),
      params
    );

    const dialogOptions: promptAction.BaseDialogOptions = {
      autoCancel: false,
      alignment: DialogAlignment.Center,
      maskColor: '#80000000',
    };

    uiContext.getPromptAction().openCustomDialog(contentNode, dialogOptions)
      .catch((e: BusinessError) => {
        Logger.error('GeetestDialog', 'open failed: ' + e.message);
        resolve(null);
      });
  });
}

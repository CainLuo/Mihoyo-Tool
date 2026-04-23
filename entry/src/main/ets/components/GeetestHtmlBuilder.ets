/**
 * GeetestHtmlBuilder — 生成 Geetest 内嵌 HTML 的工厂函数
 *
 * v3：使用 initGeetest()，需要 gt + challenge 参数
 * v4：使用 initGeetest4()，需要 captchaId(gt) + riskType 参数
 *
 * HTML 内的 window.geetestBridge 对象会被 registerJavaScriptProxy 注入，
 * 验证完成后调用 window.geetestBridge.onSuccess(challenge, validate, seccode)
 * 验证取消后调用 window.geetestBridge.onCancel()
 */
import { GeetestCreateResult } from 'core';

/**
 * 根据 Geetest 版本生成对应的内嵌 HTML 字符串（data URI 格式）
 * @param createResult createVerification 返回的参数
 */
export function buildGeetestHtml(createResult: GeetestCreateResult): string {
  const isV3 = createResult.challenge !== undefined;
  const gt = createResult.gt;
  const challenge = createResult.challenge ?? '';
  const riskType = createResult.risk_type ?? 'slide';

  // Geetest JS SDK URL（来源：TeyvatGuide geetest.vue）
  const sdkUrl = isV3
    ? 'https://static.geetest.com/static/js/gt.0.4.9.js'
    : 'https://static.geetest.com/v4/gt4.js';

  // v3 初始化脚本（纯字符串拼接，避免模板字符串内 CSS/JS 关键字被 ArkTS 误判）
  const v3Script = isV3
    ? 'initGeetest({gt:"' + gt + '",challenge:"' + challenge + '",' +
      'offline:false,new_captcha:true,product:"popup",width:"100%",https:true},' +
      'function(o){o.appendTo("#geetest-box");' +
      'o.onReady(function(){document.getElementById("loading").style.display="none";});' +
      'o.onClose(function(){var v=o.getValidate();if(v){' +
      'window.geetestBridge.onSuccess(v.geetest_challenge,v.geetest_validate,v.geetest_seccode);}' +
      'else{window.geetestBridge.onCancel();}});});'
    : '';

  // v4 初始化脚本
  const v4Script = !isV3
    ? 'initGeetest4({captchaId:"' + gt + '",riskType:"' + riskType + '",' +
      'product:"popup",nextWidth:"100%",lang:"zho",https:true,protocol:"https"},' +
      'function(o){o.appendTo("#geetest-box");' +
      'o.onReady(function(){document.getElementById("loading").style.display="none";});' +
      'o.onClose(function(){window.geetestBridge.onCancel();});' +
      'o.onSuccess(function(){var v=o.getValidate();if(v){' +
      'window.geetestBridge.onSuccess(v.geetest_challenge,v.geetest_validate,v.geetest_seccode);}' +
      'else{window.geetestBridge.onCancel();}});});'
    : '';

  // 用字符串拼接构造 HTML，避免模板字符串内 CSS 属性被 ArkTS 误判为关键字
  const style = 'body{margin:0;padding:16px;background:transparent;display:flex;' +
    'flex-direction:column;align-items:center;}' +
    '#loading{color:#888;font-size:14px;margin-top:20px;}' +
    '#geetest-box{width:100%;}';

  const html = '<!DOCTYPE html><html><head>' +
    '<meta charset="utf-8">' +
    '<meta name="viewport" content="width=device-width,initial-scale=1.0">' +
    '<style>' + style + '</style>' +
    '</head><body>' +
    '<div id="loading">\u52a0\u8f7d\u9a8c\u8bc1\u7801\u4e2d...</div>' +
    '<div id="geetest-box"></div>' +
    '<script src="' + sdkUrl + '"></script>' +
    '<script>window.onload=function(){' + v3Script + v4Script + '};</script>' +
    '</body></html>';

  return 'data:text/html;charset=utf-8,' + encodeURIComponent(html);
}

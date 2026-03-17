import { GeetestService, GeetestCreateResult } from 'core';
import { showGeetestDialog } from '../components/GeetestDialog';

// ⚠️ 方式一：替换为你自己账号的真实 Cookie
const TEST_COOKIE = 'YOUR_COOKIE_HERE';

@Preview
@Component
export struct Home {
  @State resultText: string = '等待测试...';

  build() {
    Column({ space: 16 }) {
      Text('GeetestDialog 测试')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)

      Text(this.resultText)
        .fontSize(13)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
        .padding({ left: 16, right: 16 })

      // 方式一：真实网络请求，需要有效 Cookie
      Button('方式一：真实请求 (需 Cookie)')
        .width('80%')
        .onClick(async () => {
          this.resultText = '正在请求 createVerification...';
          try {
            const createResult = await GeetestService.createVerification(TEST_COOKIE);
            this.resultText = `createVerification 成功，版本: ${GeetestService.getGeetestVersion(createResult)}\n等待用户完成验证...`;
            const verifyInput = await showGeetestDialog(this.getUIContext(), createResult);
            if (verifyInput) {
              this.resultText = `验证成功!\nchallenge: ${verifyInput.geetest_challenge}\nvalidate: ${verifyInput.geetest_validate}`;
            } else {
              this.resultText = '用户取消了验证';
            }
          } catch (e) {
            this.resultText = `失败: ${(e as Error).message}`;
          }
        })

      // 方式二：Mock 数据，跳过网络，直接测试 UI
      Button('方式二：Mock v3 (无需 Cookie)')
        .width('80%')
        .onClick(async () => {
          this.resultText = '打开 Mock v3 弹窗...';
          const mockResult: GeetestCreateResult = {
            gt: 'test_gt_id_mock',
            challenge: 'test_challenge_mock_123',
          };
          const verifyInput = await showGeetestDialog(this.getUIContext(), mockResult);
          if (verifyInput) {
            this.resultText = `验证成功!\nchallenge: ${verifyInput.geetest_challenge}`;
          } else {
            this.resultText = '用户取消了验证';
          }
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

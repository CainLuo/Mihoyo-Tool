import { describe, it, expect, beforeAll } from '@ohos/hypium';
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { Want, common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * 主链路 UI 冒烟测试骨架。
 *
 * 运行条件：
 * 1. 已连接真机 / 模拟器（hdc list targets 非空）
 * 2. 通过 `hvigorw --mode module -p module=entry@ohosTest -p product=default onDeviceTest`
 *    或 DevEco 运行
 *
 * 首次安装时应用会先停在「用户协议」页，不会进入主框架。测试在启动 EntryAbility
 * 之前写入 entry 模块的隐私同意标记，保证启动页直接 replace 到主框架。
 *
 * 当前只验证应用能启动，并落在首页或登录页；后续按 docs/ui-test-plan.md
 * 补充「首页 → 角色详情 → 材料计算」的完整点击链路。
 */
const TAG: string = 'MainFlowUi';
/** 与 features/legal 的 LegalPreferences 保持一致 */
const LEGAL_STORE: string = 'legal_prefs';
const LEGAL_KEY: string = 'hasAgreedPrivacy';
const LEGAL_XML: string =
  '<?xml version="1.0" encoding="UTF-8"?>\n' +
  '<preferences version="1.0"><bool key="hasAgreedPrivacy" value="true"/></preferences>';
/** 被测应用模块名（EntryAbility 所在模块） */
const APP_MODULE: string = 'entry';

let driver: Driver = Driver.create();

/**
 * 拼出 entry 模块的 preferences 目录。
 *
 * preferences 按模块隔离：/data/storage/el2/base/haps/<module>/preferences。
 * 测试代码运行在 entry_test 模块，createModuleContext('entry') 拿到的是应用级目录，
 * 应用实际读的是 entry 模块目录，因此直接按沙箱布局拼路径。
 */
function entryPrefsDir(testCtx: common.Context): string {
  const marker: string = '/haps/';
  const filesDir: string = testCtx.filesDir;
  const idx: number = filesDir.indexOf(marker);
  const base: string = idx >= 0 ? filesDir.substring(0, idx) : filesDir;
  return `${base}${marker}${APP_MODULE}/preferences`;
}

/** 把 entry 模块的隐私协议同意标记置为 true（直接写 preferences 的 XML 落盘格式） */
function markPrivacyAgreed(testCtx: common.Context): void {
  const dir: string = entryPrefsDir(testCtx);
  if (!fs.accessSync(dir)) {
    fs.mkdirSync(dir, true);
  }
  const filePath: string = `${dir}/${LEGAL_STORE}`;
  const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
  try {
    fs.writeSync(file.fd, LEGAL_XML);
  } finally {
    fs.closeSync(file);
  }
  hilog.info(0x0000, TAG, 'privacy agreed flag written: %{public}s', filePath);
}

export default function mainFlowUiTest() {
  describe('MainFlowUi', () => {

    beforeAll(async () => {
      const delegator = abilityDelegatorRegistry.getAbilityDelegator();
      const ability = await delegator.getCurrentTopAbility();
      try {
        markPrivacyAgreed(ability.context);
      } catch (e) {
        // 写标记失败不阻断用例，交给下面的断言暴露真实落点
        hilog.error(0x0000, TAG, 'markPrivacyAgreed failed: %{public}s',
          JSON.stringify(e as BusinessError) ?? '');
      }
      const args = abilityDelegatorRegistry.getArguments();
      const want: Want = {
        bundleName: args.bundleName,
        // EntryAbility 在 entry 模块，测试跑在 entry_test 模块，必须显式指定 moduleName，
        // 否则系统只在当前模块里找，报 16000001（The specified ability does not exist）
        moduleName: APP_MODULE,
        abilityName: 'EntryAbility'
      };
      await delegator.startAbility(want);
      driver = Driver.create();
      await driver.delayMs(2000);
    });

    it('应用启动后落在首页或登录页', 0, async () => {
      const main = await driver.waitForComponent(ON.id('main_navigation'), 10000);
      if (main !== null) {
        expect(true).assertTrue();
        return;
      }
      const login = await driver.waitForComponent(ON.id('login_page'), 2000);
      expect(login !== null).assertTrue();
    });

  });
}

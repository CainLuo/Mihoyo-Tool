import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';
import { Logger } from 'core';

const TAG: string = 'EntryBackupAbility';

export default class EntryBackupAbility extends BackupExtensionAbility {
  async onBackup() {
    Logger.info(TAG, 'onBackup ok');
    await Promise.resolve();
  }

  async onRestore(bundleVersion: BundleVersion) {
    Logger.info(TAG, `onRestore ok: ${JSON.stringify(bundleVersion)}`);
    await Promise.resolve();
  }
}

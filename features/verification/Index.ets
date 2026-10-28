// verification 导出文件：人机验证、设备指纹
// 只导出模块外（entry、其他模块、测试）实际用到的符号

export { DeviceFpCenter, DeviceFpInvalidSignal } from './src/main/ets/model/service/DeviceFpCenter';
export { GeetestCenter } from './src/main/ets/model/service/GeetestCenter';
export { GeetestQueueItem, GeetestSignal } from './src/main/ets/signals/GeetestSignal';
export { showGeetestDialog } from './src/main/ets/utils/GeetestDialogUtil';

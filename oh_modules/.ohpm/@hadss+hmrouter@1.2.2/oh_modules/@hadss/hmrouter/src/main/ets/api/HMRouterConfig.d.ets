import { common } from '@kit.AbilityKit';
import { IHMLog } from '../log/HMLogger';
export interface HMRouterConfig {
    context: common.Context;
    initWithTaskPool?: boolean;
    logLevel?: 'DEBUG' | 'INFO';
    customLog?: IHMLog;
}

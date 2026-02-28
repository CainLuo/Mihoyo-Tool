import { HMServiceResp } from '../api/IHMService';
import { HMServiceData } from '../store/entity/HMService';
import { HashMap } from '@kit.ArkTS';
export interface IHMServiceMgr {
    saveServiceConfig(data: HashMap<string, HMServiceData>): void;
    getService<T>(serviceName: string, ...args: Object[]): T | undefined;
    request(serviceName: string, ...args: Object[]): HMServiceResp;
    requestWithCallback(serviceName: string, callback: Callback<HMServiceResp, void>, ...args: Object[]): void;
}

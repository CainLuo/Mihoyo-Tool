import { HMServiceResp } from '../api/IHMService';
import { HMServiceInstance } from '../store/ComponentInstance';
import { HMServiceData } from '../store/entity/HMService';
import { IHMServiceMgr } from './IHMServiceMgr';
import { HashMap } from '@kit.ArkTS';
export declare class HMServiceMgrImpl implements IHMServiceMgr {
    serviceConfig: HashMap<string, HMServiceData>;
    serviceLoadMap: HashMap<string, HMServiceInstance>;
    private loadService;
    private getServiceInstance;
    saveServiceConfig(data: HashMap<string, HMServiceData>): void;
    getService<T>(serviceName: string, ...args: Object[]): T | undefined;
    /**
     * Method of synchronously calling HMService decoration
     * @returns
     */
    request(serviceName: string, ...args: Object[]): HMServiceResp;
    requestWithCallback(serviceName: string, callback: Callback<HMServiceResp, void>, ...args: Object[]): void;
}

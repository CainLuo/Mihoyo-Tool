import { IHMServiceMgr } from './IHMServiceMgr';
export declare class HMServiceFactory {
    private static serviceMgr;
    static getServiceMgr(): IHMServiceMgr;
    static setServiceMgr(mgr: IHMServiceMgr): void;
}

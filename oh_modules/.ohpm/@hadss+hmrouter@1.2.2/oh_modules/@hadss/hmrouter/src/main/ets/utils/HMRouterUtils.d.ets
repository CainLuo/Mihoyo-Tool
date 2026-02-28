import { common } from '@kit.AbilityKit';
import { collections } from '@kit.ArkTS';
import { HMNavPathStack } from '../router/HMNavPathStack';
import { BundleInfo } from '../store/entity/BundleInfo';
import { HMComponent } from '../store/entity/HMComponent';
import { HMRouterStoreData } from '../store/entity/HMRouter';
export declare namespace HMRouterUtils {
    const hmBavBarPageName: string;
    /**
     * When routing pop operations, the names of the constructed target and source pages and the location information
     * of the routing stack
     */
    interface PageInfo {
        name: string;
        index: number;
    }
    /**
     * Check the pageURL parameter
     * @param pathInfo
     * @returns
     */
    function checkPageUrl(pageUrl?: string): boolean;
    /**
     * Get page configuration information based on pageURL
     * @param pageUrl
     * @param errType
     * @param onLost
     * @returns
     */
    function getPageInfoByPageUrl(pageUrl: string): HMRouterStoreData | null;
    function getSrcPage(pathStack: HMNavPathStack): PageInfo;
    /**
     * Get target page information
     * @param pathStack
     * @param pageUrl
     * @param skipedLayerNumber
     * @returns
     */
    function getTargetPage(pathStack: HMNavPathStack, pageUrl?: string, skipedLayerNumber?: number): PageInfo | undefined;
    function getBundleInfoFromRawFile(context: common.Context): string | undefined;
    function parseBundleInfo(bundleInfo: BundleInfo, hmComponentInfos: collections.Array<HMComponent>): void;
}

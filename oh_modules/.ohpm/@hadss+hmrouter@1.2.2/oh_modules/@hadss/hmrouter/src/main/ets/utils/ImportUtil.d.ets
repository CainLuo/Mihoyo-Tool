/**
 * Dynamic import util
 */
export declare class ImportUtil {
    private static readonly ETS_SUFFIX;
    private static readonly TS_SUFFIX;
    private static readonly SEPARATOR;
    private static readonly OHM_URL_FIRST_SEPARATOR;
    private static readonly OHM_URL_SECOND_SEPARATOR;
    private static readonly ETS_SEPARATOR;
    /**
     * Splicing module and path
     * eg:
     * input: entry,src/main/ets/pages/Index.ets
     * output: entry/src/main/ets/pages/Index
     * @param module moduleName
     * @param path path
     * @returns splice result
     */
    static spliceModuleAndPath(module: string, path: string): string;
    static getModulePathByUhmUrl(ohmUrl: string): void;
    /**
     * Get import path in the HAP package
     * har import hap : ets/pages/Index1
     * har import har : har/src/main/ets/components/MainPage
     * har import hsp : hsp/src/main/ets/utils/Calc
     * #param module moduleName
     * @param path path
     * @returns splice result
     */
    static getHapImportPath(path: string): string;
    /**
     * dynamic import from path
     * @param modulePath
     * @param resultClassName
     * @returns
     */
    static importFile<T>(modulePath: string, resultClassName: string): Promise<any>;
    /**
     * Retrieve the content of ohmUrl
     * eg:@normalized:N&&&entry/src/main/ets/component/live/LiveHome&
     *    =>entry/src/main/ets/component/live/LiveHome
     * @param ohmUrl
     */
    static getModuleInfoFromOhmUrl(ohmUrl: string): string | undefined;
}

export declare class HMRouterConst {
    static readonly ANIMATOR_PREFIX = "__animator__";
    static readonly INTERCEPTOR_PREFIX = "__interceptor__";
    static readonly LIFECYCLE_PREFIX = "__lifecycle__";
    static readonly SERVICE_PREFIX = "__service__";
    static readonly SERVICE_PROVIDE_PREFIX = "__service_provider__";
    static readonly PAGE_URL_PREFIX = "";
    /**
     * Store JSON strings in data.data and router_map.json
     */
    static readonly HM_ROUTER_MAP_JSON_DATA_NAME = "data";
    static readonly FILE_SEPARATOR = "/";
    static readonly HM_ROUTER_TEMP_JSON_DATA_FILE = "hm_temp_json_file.json";
    /**
     * Default priority
     */
    static readonly HM_ROUTER_INTERCEPTOR_DEFAULT_PRIORITY = 9;
    static readonly HM_ROUTER_LIFECYCLE_DEFAULT_PRIORITY = 9;
    static readonly HM_ROUTER_ANNOTATION_GLOBAL_DEFAULT_VALUE: boolean;
    static readonly HM_ROUTER_MAP_KEY_SEPARATOR = "-";
    static readonly HM_ROUTER_DEFAULT_LIFECYCLE_NAME = "hm_router_default_lifecycle";
    static readonly MODULE_INFO_SEPARATOR = "/";
    static readonly METADATA_HM_ROUTER_KEY = "router_map";
    static readonly HM_ROUTER_MAP_FILE_NAME = "hm_router_map.json";
    /**
     * HMRouterAnnotationHandler
     */
    static readonly HM_ROUTER_INTERCEPTOR_NAME = "interceptorName";
    static readonly HM_ROUTER_ANNOTATION_NAME = "name";
    static readonly HM_ROUTER_ANNOTATION_PRIORITY = "priority";
    static readonly HM_ROUTER_ANNOTATION_GLOBAL = "global";
    static readonly HM_ROUTER_LIFECYCLE_NAME = "lifecycleName";
    static readonly HM_ROUTER_ANIMATOR_NAME = "animatorName";
    /**
     * page info
     */
    static readonly HM_ROUTER_PAGE_INTERCEPTORS = "interceptors";
    static readonly HM_ROUTER_PAGE_LIFECYCLE = "lifecycle";
    static readonly HM_ROUTER_PAGE_ANIMATOR = "animator";
    static readonly HM_ROUTER_PAGE_SINGLETON = "singleton";
    static readonly HM_ROUTER_PAGE_DIALOG = "dialog";
    static readonly HM_ROUTER_PAGE_IS_REGEX = "isRegex";
    static readonly HM_ROUTER_PAGE_PRIORITY = "regexPriority";
    /**
     *HMRouterService
     */
    static readonly HM_ROUTER_SERVICE_NAME = "serviceName";
    static readonly HM_ROUTER_SERVICE_FUNCTION = "functionName";
    static readonly HM_ROUTER_SERVICE_SINGLETON = "singleton";
    static readonly HM_ROUTER_SERVICE_CLASS = "name";
    /**
     * Animator
     */
    static readonly NAV_MODE_DIALOG = "dialog";
    static readonly NAV_MODE_STANDARD = "standard";
}

declare class EventBus {
    private handlers;
    on<T>(event: string, handler: Callback<T>): Callback<void>;
    off<T>(event: string, handler: Callback<T>): void;
    emit(event: string, param: Object): Promise<void>;
    once<T>(event: string, handler: Callback<T>): Callback<void>;
}
export declare const globalEventBus: EventBus;
export {};

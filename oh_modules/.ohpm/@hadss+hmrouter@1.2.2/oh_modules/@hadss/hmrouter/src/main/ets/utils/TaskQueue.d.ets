declare class TaskQueue {
    private queue;
    private isProcessing;
    constructor();
    /**
     * Synchronous methods，Returns after the task is added to the queue
     * @param task
     */
    enqueue(task: Callback<void, void>): void;
    /**
     * Asynchronous methods，Task execution completed and returned
     * @param task
     * @returns
     */
    enqueueAsync<T>(task: Callback<void, Promise<T>>): Promise<T>;
    private process;
    get length(): number;
    clear(): void;
}
export declare const queue: TaskQueue;
export {};

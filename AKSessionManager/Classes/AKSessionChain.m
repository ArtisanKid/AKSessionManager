//
//  AKSessionChain.m
//  Pods
//
//  Created by 李翔宇 on 2016/12/11.
//
//

#import "AKSessionChain.h"
#import "AKSessionBatch.h"

@interface AKSessionChain ()

@property (nonatomic, copy) dispatch_queue_t serialQueue;
@property (nonatomic, assign, readonly) dispatch_semaphore_t semaphore;

//chain中的请求总数
@property (nonatomic, assign) NSUInteger totalCount;

//chain中的请求完成数
@property (nonatomic, assign) NSUInteger completeCount;

//chain中的task数组
@property (nonatomic, strong) NSHashTable<id/*AKSessionTask/AKSessionBatch*/> *tasks;

@end

@implementation AKSessionChain

- (instancetype)init {
    self = [super init];
    if(self) {
        _serialQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
        _semaphore = dispatch_semaphore_create(1);
        _tasks = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)chainTask:(AKSessionTask *)task {
    __weak typeof(self) weak_self = self;
    dispatch_async(self.serialQueue, ^{
        __strong typeof(weak_self) strong_self = weak_self;
        dispatch_semaphore_wait(strong_self.semaphore, DISPATCH_TIME_FOREVER);
        
        //链接的task不允许是serial类型
        task.serial = NO;
        [strong_self.tasks addObject:task];
        
        strong_self.totalCount++;
        NSUInteger current = strong_self.totalCount;
        
        void (^baseHandleBlock)() = ^{
            self.completeCount++;
            !self.progress ?: self.progress(self.totalCount, self.completeCount);
            dispatch_semaphore_signal(self.semaphore);
            
            if(self.completeCount >= self.totalCount) {
                !self.complete ?: self.complete();
            }
        };
        
        AKSessionTaskSuccess success = task.success;
        task.success = ^(id result) {
            baseHandleBlock();
            !success ?: success(result);
        };
        
        AKSessionTaskFailure failure = task.failure;
        task.failure = ^(NSError *error) {
            baseHandleBlock();
            !failure ?: failure(error);
        };
    });
}

- (void)chainBatch:(AKSessionBatch *)batch {
    __weak typeof(self) weak_self = self;
    dispatch_async(self.serialQueue, ^{
        __strong typeof(weak_self) strong_self = weak_self;
        dispatch_semaphore_wait(strong_self.semaphore, DISPATCH_TIME_FOREVER);
        [strong_self.tasks addObject:batch];
        
        strong_self.totalCount++;
        NSUInteger current = strong_self.totalCount;
        
        void (^baseHandleBlock)() = ^{
            self.completeCount++;
            !self.progress ?: self.progress(self.totalCount, self.completeCount);
            dispatch_semaphore_signal(self.semaphore);
            
            if(self.completeCount >= self.totalCount) {
                !self.complete ?: self.complete();
            }
        };
        
        AKSessionBatchComplete complete = batch.complete;
        batch.complete = ^{
            baseHandleBlock();
            !complete ?: complete();
        };
    });
}

- (void)chainChain:(AKSessionChain *)chain {
    __weak typeof(self) weak_self = self;
    dispatch_async(self.serialQueue, ^{
        __strong typeof(weak_self) strong_self = weak_self;
        dispatch_semaphore_wait(strong_self.semaphore, DISPATCH_TIME_FOREVER);
        [strong_self.tasks addObject:chain];
        
        strong_self.totalCount++;
        NSUInteger current = strong_self.totalCount;
        
        void (^baseHandleBlock)() = ^{
            self.completeCount++;
            !self.progress ?: self.progress(self.totalCount, self.completeCount);
            dispatch_semaphore_signal(self.semaphore);
            
            if(self.completeCount >= self.totalCount) {
                !self.complete ?: self.complete();
            }
        };
        
        AKSessionBatchComplete complete = chain.complete;
        chain.complete = ^{
            baseHandleBlock();
            !complete ?: complete();
        };
    });
}

- (void)resume {
    [self.tasks.allObjects enumerateObjectsUsingBlock:^(id _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
        [task resume];
    }];
}

+ (AKSessionChain *)chainTasks:(NSArray<AKSessionTask *> *)tasks
                      progress:(AKSessionChainProgress)progress
                      complete:(AKSessionChainComplete)complete {
    AKSessionChain *chain = [[AKSessionChain alloc] init];
    for(AKSessionTask *task in tasks) {
        [chain chainTask:task];
    }
    chain.progress = progress;
    chain.complete = complete;
    return chain;
}

@end

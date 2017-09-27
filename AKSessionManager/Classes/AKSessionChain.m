//
//  AKSessionChain.m
//  Pods
//
//  Created by 李翔宇 on 2016/12/11.
//
//

#import "AKSessionChain.h"
#import "AKSessionManagerMacros.h"
#import "AKSessionBatch.h"

@interface AKSessionChain ()

@property (nonatomic, assign, getter=isResumed) BOOL resumed;

//串行队列
@property (nonatomic, copy) dispatch_queue_t serialQueue;
//信号量
@property (nonatomic, strong, readonly) dispatch_semaphore_t semaphore;
//用于管理chain的group
@property (nonatomic, strong) dispatch_group_t group;

//chain中的task数组
@property (nonatomic, strong) NSHashTable<id/*AKSessionTask/AKSessionBatch*/> *tasks;

//chain中的请求总数
@property (nonatomic, assign) NSUInteger totalCount;

//chain中的请求完成数
@property (nonatomic, assign) NSUInteger completeCount;

@end

@implementation AKSessionChain

- (instancetype)init {
    self = [super init];
    if(self) {
        _serialQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
        _semaphore = dispatch_semaphore_create(1);
        _group = dispatch_group_create();
        __weak typeof(self) weak_self = self;
        dispatch_group_notify(_group, dispatch_get_main_queue(), ^{
            __strong typeof(weak_self) strong_self = weak_self;
            !strong_self.complete ?: strong_self.complete();
        });
        _tasks = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)chainTask:(AKSessionTask *)task {
    if(task.isResumed) {
        AKSessionManagerLog(@"不可添加到Chain! 任务锁定");
        return;
    }
    
    dispatch_group_enter(self.group);
    self.totalCount++;
    
    __weak typeof(self) weak_self = self;
    dispatch_async(self.serialQueue, ^{
        __strong typeof(weak_self) strong_self = weak_self;
        dispatch_semaphore_wait(strong_self.semaphore, DISPATCH_TIME_FOREVER);
        
        //链接的task不允许是serial类型
        task.serial = NO;
        [strong_self.tasks addObject:task];

        void (^baseHandleBlock)() = ^{
            self.completeCount++;
            !self.progress ?: self.progress(self.totalCount, self.completeCount);
            dispatch_group_leave(self.group);
            dispatch_semaphore_signal(self.semaphore);
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
    if(batch.isResumed) {
        AKSessionManagerLog(@"不可添加到Chain! Batch is resumed");
        return;
    }
    
    dispatch_group_enter(self.group);
    self.totalCount++;
    
    __weak typeof(self) weak_self = self;
    dispatch_async(self.serialQueue, ^{
        __strong typeof(weak_self) strong_self = weak_self;
        dispatch_semaphore_wait(strong_self.semaphore, DISPATCH_TIME_FOREVER);
        
        [strong_self.tasks addObject:batch];
        
        void (^baseHandleBlock)() = ^{
            self.completeCount++;
            !self.progress ?: self.progress(self.totalCount, self.completeCount);
            dispatch_group_leave(self.group);
            dispatch_semaphore_signal(self.semaphore);
        };
        
        AKSessionBatchComplete complete = batch.complete;
        batch.complete = ^{
            baseHandleBlock();
            !complete ?: complete();
        };
    });
}

- (void)chainChain:(AKSessionChain *)chain {
    if(chain.isResumed) {
        AKSessionManagerLog(@"不可添加到Chain! Target Chain is resumed");
        return;
    }
    
    __weak typeof(self) weak_self = self;
    dispatch_async(self.serialQueue, ^{
        __strong typeof(weak_self) strong_self = weak_self;
        dispatch_semaphore_wait(strong_self.semaphore, DISPATCH_TIME_FOREVER);
        
        [strong_self.tasks addObject:chain];
        
        void (^baseHandleBlock)() = ^{
            self.completeCount++;
            !self.progress ?: self.progress(self.totalCount, self.completeCount);
            dispatch_group_leave(self.group);
            dispatch_semaphore_signal(self.semaphore);
        };
        
        AKSessionBatchComplete complete = chain.complete;
        chain.complete = ^{
            baseHandleBlock();
            !complete ?: complete();
        };
    });
}

- (void)resume {
    if(self.isResumed) {
        return;
    }
    self.resumed = YES;
    
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

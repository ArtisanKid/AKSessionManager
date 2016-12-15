//
//  AKSessionBatch.m
//  Pods
//
//  Created by 李翔宇 on 2016/12/11.
//
//

#import "AKSessionBatch.h"
#import "AKSessionChain.h"

@interface AKSessionBatch ()

/**
 *  用于管理batch的group
 */
@property (nonatomic, strong) dispatch_group_t group;

//batch中的请求总数
@property (nonatomic, assign) NSUInteger totalCount;

//batch中的请求完成数
@property (atomic, assign) NSUInteger completeCount;

//batch中的task数组
@property (nonatomic, strong) NSHashTable<id/*AKSessionTask/AKSessionChain*/> *tasks;

@end

@implementation AKSessionBatch

- (instancetype)init {
    self = [super init];
    if(self) {
        _group = dispatch_group_create();
        dispatch_group_notify(_group, dispatch_get_main_queue(), ^{
            !self.complete ?: self.complete();
        });
        _tasks = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)batchTask:(AKSessionTask *)task {
    //绑定的task不允许是serial类型
    task.serial = NO;
    [self.tasks addObject:task];
    
    dispatch_group_enter(self.group);
    self.totalCount++;
    NSUInteger current = self.totalCount;
    
    void (^baseHandleBlock)() = ^{
        self.completeCount++;
        !self.progress ?: self.progress(self.totalCount, self.completeCount, current);
        dispatch_group_leave(self.group);
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
}

- (void)batchChain:(AKSessionChain *)chain {
    [self.tasks addObject:chain];
    
    dispatch_group_enter(self.group);
    self.totalCount++;
    NSUInteger current = self.totalCount;
    
    void (^baseHandleBlock)() = ^{
        self.completeCount++;
        !self.progress ?: self.progress(self.totalCount, self.completeCount, current);
        dispatch_group_leave(self.group);
    };
    
    AKSessionChainComplete complete = chain.complete;
    chain.complete = ^{
        baseHandleBlock();
        !complete ?: complete();
    };
}

- (void)batchBatch:(AKSessionBatch *)batch {
    [self.tasks addObject:batch];
    
    dispatch_group_enter(self.group);
    self.totalCount++;
    NSUInteger current = self.totalCount;
    
    void (^baseHandleBlock)() = ^{
        self.completeCount++;
        !self.progress ?: self.progress(self.totalCount, self.completeCount, current);
        dispatch_group_leave(self.group);
    };
    
    AKSessionBatchComplete complete = batch.complete;
    batch.complete = ^{
        baseHandleBlock();
        !complete ?: complete();
    };
}

- (void)resume {
    [self.tasks.allObjects enumerateObjectsUsingBlock:^(id _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
        [task resume];
    }];
}

+ (AKSessionBatch *)batchTasks:(NSArray<AKSessionTask *> *)tasks
                      progress:(AKSessionBatchProgress)progress
                      complete:(AKSessionBatchComplete)complete {
    AKSessionBatch *batch = [[AKSessionBatch alloc] init];
    for(AKSessionTask *task in tasks) {
        [batch batchTask:task];
    }
    batch.progress = progress;
    batch.complete = complete;
    return batch;
}

@end

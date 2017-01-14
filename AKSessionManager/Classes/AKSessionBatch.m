//
//  AKSessionBatch.m
//  Pods
//
//  Created by 李翔宇 on 2016/12/11.
//
//

#import "AKSessionBatch.h"
#import "AKSessionManagerMacro.h"
#import "AKSessionChain.h"

@interface AKSessionBatch ()

@property (nonatomic, assign, getter=isResumed) BOOL resumed;

//用于管理batch的group
@property (nonatomic, strong) dispatch_group_t group;

//batch中的task数组
@property (nonatomic, strong) NSHashTable<id/*AKSessionTask/AKSessionChain*/> *tasks;

//batch中的请求总数
//不能信赖tasks.count，因为在weak情况下，task随时可能释放，导致tasks.count不准确
@property (nonatomic, assign) NSUInteger totalCount;

//batch中的请求完成数
@property (atomic, assign) NSUInteger completeCount;

@end

@implementation AKSessionBatch

- (instancetype)init {
    self = [super init];
    if(self) {
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

- (void)batchTask:(AKSessionTask *)task {
    if(task.isResumed) {
        AKSessionManagerLog(@"不可添加到Batch 任务锁定");
        return;
    }
    
    dispatch_group_enter(self.group);
    self.totalCount++;
    NSUInteger current = self.totalCount;
    
    //绑定的task不允许是serial类型
    task.serial = NO;
    [self.tasks addObject:task];
    
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
    if(chain.isResumed) {
        AKSessionManagerLog(@"不可添加到Batch Chain is resumed");
        return;
    }
    
    dispatch_group_enter(self.group);
    self.totalCount++;
    NSUInteger current = self.totalCount;
    
    [self.tasks addObject:chain];
    
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
    if(batch.isResumed) {
        AKSessionManagerLog(@"不可添加到Batch Target Batch is resumed");
        return;
    }
    
    dispatch_group_enter(self.group);
    self.totalCount++;
    NSUInteger current = self.totalCount;
    
    [self.tasks addObject:batch];
    
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
    if(self.isResumed) {
        return;
    }
    self.resumed = YES;
    
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

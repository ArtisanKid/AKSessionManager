//
//  AKSessionBatch.h
//  Pods
//
//  Created by 李翔宇 on 2016/12/11.
//
//

#import <Foundation/Foundation.h>
#import "AKSessionTask.h"

@class AKSessionChain;
//绑定到一起的请求的进度指示
typedef void (^AKSessionBatchProgress)(NSUInteger total, NSUInteger complete, NSUInteger current);
typedef void (^AKSessionBatchComplete)();

@interface AKSessionBatch : NSObject

@property (nonatomic, copy) AKSessionBatchProgress progress;
@property (nonatomic, copy) AKSessionBatchComplete complete;

- (void)batchTask:(AKSessionTask *)task;
- (void)batchChain:(AKSessionChain *)chain;
- (void)batchBatch:(AKSessionBatch *)batch;
- (void)resume;

+ (AKSessionBatch *)batchTasks:(NSArray<AKSessionTask *> *)tasks
                      progress:(AKSessionBatchProgress)progress
                      complete:(AKSessionBatchComplete)complete;

@end

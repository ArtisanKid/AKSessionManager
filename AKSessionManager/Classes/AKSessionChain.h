//
//  AKSessionChain.h
//  Pods
//
//  Created by 李翔宇 on 2016/12/11.
//
//

#import <Foundation/Foundation.h>
#import "AKSessionTask.h"

@class AKSessionBatch;
//连接到到一起的请求的进度指示
typedef void (^AKSessionChainProgress)(NSUInteger total, NSUInteger current);
typedef void (^AKSessionChainComplete)();

@interface AKSessionChain : NSObject

@property (nonatomic, copy) AKSessionChainProgress progress;
@property (nonatomic, copy) AKSessionChainComplete complete;

- (void)chainTask:(AKSessionTask *)task;
- (void)chainBatch:(AKSessionBatch *)batch;
- (void)chainChain:(AKSessionChain *)chain;
- (void)resume;

+ (AKSessionChain *)chainTasks:(NSArray<AKSessionTask *> *)tasks
                      progress:(AKSessionChainProgress)progress
                      complete:(AKSessionChainComplete)complete;

@end

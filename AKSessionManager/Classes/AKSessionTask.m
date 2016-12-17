//
//  AKSessionTask.m
//  Pods
//
//  Created by 李翔宇 on 2016/12/11.
//
//

#import "AKSessionTask.h"
#import "AKSessionManager.h"
#import "AFHTTPSessionManager+AKExtension.h"
#import "AFURLRequestSerialization+AKExtension.h"

@interface AKSessionTask ()

//内部的系统会话任务
@property (nonatomic, strong) NSURLSessionTask *task;

@end

@implementation AKSessionTask

- (AKSessionTask *)construct {
    AKSessionManager *manager = AKSessionManager.manager;
    __weak typeof(manager) weak_manager = manager;
    dispatch_async(manager.serialQueue, ^{
        __strong typeof(weak_manager) strong_manager = weak_manager;
        
        //串行下不重复发送同一参数请求，总是保留不同参数的最后一个请求
        NSTimeInterval startTimestamp = NSDate.date.timeIntervalSince1970;
        NSString *taskID = [NSString stringWithFormat:@"%@:%@", self.url, self.body ? self.body() : @""];
        if(self.isSerial) {
            strong_manager.taskTimestampDicM[taskID] = @(startTimestamp);
        }
        
        //获取信号量，如果不是barrier类型的请求，立刻释放信号量
        dispatch_semaphore_wait(strong_manager.semaphore, DISPATCH_TIME_FOREVER);
        if(!self.isBarrier) {
            dispatch_semaphore_signal(strong_manager.semaphore);
        }
        
        switch (self.serialize) {
            case AKRequestSerializeNormal: {
                strong_manager.sessionManager.requestSerializer = strong_manager.HTTPRequestSerializer;
                break;
            }
            case AKRequestSerializeJSON: {
                strong_manager.sessionManager.requestSerializer = strong_manager.JSONRequestSerializer;
                break;
            }
            case AKRequestSerializePropertyList: {
                strong_manager.sessionManager.requestSerializer = strong_manager.propertyListRequestSerializer;
                break;
            }
        }
        
        if(self.isContainURL) {//参数中包含URL
            [strong_manager.sessionManager.requestSerializer setQueryStringSerializationWithBlock:^NSString * _Nonnull(NSURLRequest * _Nonnull request, id  _Nonnull parameters, NSError * _Nullable __autoreleasing * _Nullable error) {
                //TODO:这里不知道应该产生什么样的错误，因为全部逻辑都是直接照抄AF的，所以这里的错误处理暂时放弃
                *error = nil;
                
                NSMutableArray *mutablePairs = [NSMutableArray array];
                for (AFQueryStringPair *pair in AFQueryStringPairsFromDictionary(parameters)) {
                    if (!pair.value || [pair.value isEqual:[NSNull null]]) {
                        [mutablePairs addObject:AFPercentEscapedStringFromString([pair.field description])];
                    } else {
                        [mutablePairs addObject:[NSString stringWithFormat:@"%@=%@", AKPercentEscapedStringFromString([pair.field description]), AKPercentEscapedStringFromString([pair.value description])]];
                    }
                }
                return [mutablePairs componentsJoinedByString:@"&"];
            }];
        } else {
            [strong_manager.sessionManager.requestSerializer setQueryStringSerializationWithBlock:nil];
        }
        
        /**
         *  请求无论是成功还是失败都需要处理的逻辑
         *  返回值的意义：用于区分serial模式下，是否最后一个请求
         */
        BOOL (^baseHandleBlock)() = ^BOOL {
            if(self.isBarrier) {
                dispatch_semaphore_signal(strong_manager.semaphore);
            }
            
            NSTimeInterval finishTimestamp = NSDate.date.timeIntervalSince1970;
            NSTimeInterval requestTime = finishTimestamp - startTimestamp;
            if(self.isSerial) {
                if(strong_manager.taskTimestampDicM[taskID].doubleValue != startTimestamp) {
                    return NO;
                }
                strong_manager.taskTimestampDicM[taskID] = nil;
            }
            
            return YES;
        };
        
        void (^innerSuccess)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) = ^(NSURLSessionDataTask * _Nonnull task, id responseObject) {
            if(!baseHandleBlock()) {
                return;
            }
            !self.success ? : self.success(responseObject ? : nil);
        };
        
        void (^innerFailure)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) = ^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if(!baseHandleBlock()) {
                return;
            }
            !self.failure ? : self.failure(error);
        };
        
        NSDictionary *parameters = self.body ? self.body() : nil;
        NSString *methodName = nil;
        switch (self.method) {
            case AKRequestMethodGET: {
                methodName = @"GET";
                break;
            }
            case AKRequestMethodHEAD: {
                methodName = @"HEAD";
                break;
            }
            case AKRequestMethodPOST: {
                methodName = @"POST";
                break;
            }
            case AKRequestMethodPUT: {
                methodName = @"PUT";
                break;
            }
            case AKRequestMethodPATCH: {
                methodName = @"PATCH";
                break;
            }
            case AKRequestMethodDELETE: {
                methodName = @"DELETE";
                break;
            }
                
            case AKRequestMethodFORM: {
                methodName = @"POST";
                break;
            }
                
            default:
                methodName = @"POST";
                break;
        }
        
        if(!methodName.length) {
            return;
        }
        
        if(self.method != AKRequestMethodFORM) {
            self.task = [strong_manager.sessionManager dataTaskWithHTTPMethod:methodName
                                                                  URLString:self.url
                                                                 parameters:parameters
                                                             uploadProgress:self.requestProgress
                                                           downloadProgress:self.responseProgress
                                                                    success:innerSuccess
                                                                    failure:innerFailure];
        } else {
            self.task = [strong_manager.sessionManager FORM:self.url
                                               parameters:parameters
                                constructingBodyWithBlock:self.form
                                                 progress:self.requestProgress
                                                  success:innerSuccess
                                                  failure:innerFailure];
        }
        
        switch (self.priority) {
            case AKSessionTaskPriorityDefault: {
                self.task.priority = NSURLSessionTaskPriorityDefault;
                break;
            }
            case AKSessionTaskPriorityLow: {
                self.task.priority = NSURLSessionTaskPriorityLow;
                break;
            }
            case AKSessionTaskPriorityHigh: {
                self.task.priority = NSURLSessionTaskPriorityHigh;
                break;
            }
            default:
                self.task.priority = NSURLSessionTaskPriorityDefault;
                break;
        }
    });
}

- (void)resume {
    [self.task resume];
}

@end

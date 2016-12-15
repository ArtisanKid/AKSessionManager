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
//当请求被绑定到一起后，将会具有一个绑定ID
@property (nonatomic, copy) NSString *batchID;

@end

@implementation AKSessionTask

- (AKSessionTask *)construct {
    __weak AKSessionManager *weak_manager = AKSessionManager.manager;
    
    dispatch_async(weak_manager.serialQueue, ^{
        //串行下不重复发送同一参数请求，总是保留不同参数的最后一个请求
        NSTimeInterval startTimestamp = NSDate.date.timeIntervalSince1970;
        NSString *taskID = [NSString stringWithFormat:@"%@:%@", self.url, self.body()];
        if(self.isSerial) {
            weak_manager.taskTimestampDicM[taskID] = @(startTimestamp);
        }
        
        //获取信号量，如果不是barrier类型的请求，立刻释放信号量
        dispatch_semaphore_wait(weak_manager.semaphore, DISPATCH_TIME_FOREVER);
        if(!self.isBarrier) {
            dispatch_semaphore_signal(weak_manager.semaphore);
        }
        
        switch (self.serialize) {
            case AKRequestSerializeNormal: {
                weak_manager.sessionManager.requestSerializer = weak_manager.HTTPRequestSerializer;
                break;
            }
            case AKRequestSerializeJSON: {
                weak_manager.sessionManager.requestSerializer = weak_manager.JSONRequestSerializer;
                break;
            }
            case AKRequestSerializePropertyList: {
                weak_manager.sessionManager.requestSerializer = weak_manager.propertyListRequestSerializer;
                break;
            }
        }
        
        if(self.isContainURL) {//参数中包含URL
            [weak_manager.sessionManager.requestSerializer setQueryStringSerializationWithBlock:^NSString * _Nonnull(NSURLRequest * _Nonnull request, id  _Nonnull parameters, NSError * _Nullable __autoreleasing * _Nullable error) {
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
            [weak_manager.sessionManager.requestSerializer setQueryStringSerializationWithBlock:nil];
        }
        
        
        //__weak typeof(self) weak_self = self;
        typeof(self) strong_self = self;
        /**
         *  请求无论是成功还是失败都需要处理的逻辑
         *  返回值的意义：用于区分serial模式下，是否最后一个请求
         */
        BOOL (^baseHandleBlock)() = ^BOOL {
            //__strong typeof(weak_self) strong_self = weak_self;
            
            if(strong_self.isBarrier) {
                dispatch_semaphore_signal(weak_manager.semaphore);
            }
            
            NSTimeInterval finishTimestamp = NSDate.date.timeIntervalSince1970;
            NSTimeInterval requestTime = finishTimestamp - startTimestamp;
            if(self.isSerial) {
                if(weak_manager.taskTimestampDicM[taskID].doubleValue != startTimestamp) {
                    return NO;
                }
                weak_manager.taskTimestampDicM[taskID] = nil;
            }
            
            return YES;
        };
        
        void (^innerSuccess)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) = ^(NSURLSessionDataTask * _Nonnull task, id responseObject) {
            if(!baseHandleBlock()) {
                return;
            }
            //__strong typeof(weak_self) strong_self = weak_self;
            !strong_self.success ? : strong_self.success(responseObject ? : nil);
        };
        
        void (^innerFailure)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) = ^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if(!baseHandleBlock()) {
                return;
            }
            //__strong typeof(weak_self) strong_self = weak_self;
            !strong_self.failure ? : strong_self.failure(error);
        };
        
        NSDictionary *parameters = self.body ? self.body() : nil;
        NSString *methodName = nil;
        switch (self.method) {
            case AKRequestMethodGET: { methodName = @"GET"; break; }
            case AKRequestMethodHEAD: { methodName = @"HEAD"; break; }
            case AKRequestMethodPOST: { methodName = @"POST"; break; }
            case AKRequestMethodPUT: { methodName = @"PUT"; break; }
            case AKRequestMethodPATCH: { methodName = @"PATCH"; break; }
            case AKRequestMethodDELETE: { methodName = @"DELETE"; break; }
                
            case AKRequestMethodFORM: { methodName = @"POST"; break; }
        }
        
        if(!methodName.length) {
            return;
        }
        
        if(self.method != AKRequestMethodFORM) {
            self.task = [weak_manager.sessionManager dataTaskWithHTTPMethod:methodName
                                                                  URLString:self.url
                                                                 parameters:parameters
                                                             uploadProgress:self.requestProgress
                                                           downloadProgress:self.responseProgress
                                                                    success:innerSuccess
                                                                    failure:innerFailure];
        } else {
            self.task = [weak_manager.sessionManager FORM:self.url
                                               parameters:parameters
                                constructingBodyWithBlock:self.form
                                                 progress:self.requestProgress
                                                  success:innerSuccess
                                                  failure:innerFailure];
        }
    });
}

- (void)resume {
    [self.task resume];
}

@end

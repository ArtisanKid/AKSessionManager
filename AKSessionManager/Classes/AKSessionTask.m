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

@property (nonatomic, assign, getter=isResumed) BOOL resumed;

@end

@implementation AKSessionTask

- (void)setUrl:(NSString *)url {
    if(self.isResumed) {
        return;
    }
    
    _url = [url copy];
}

- (void)setMethod:(AKRequestMethod)method {
    if(self.isResumed) {
        return;
    }
    
    _method = method;
}

- (void)setBody:(AKRequestBody)body {
    if(self.isResumed) {
        return;
    }
    
    _body = [body copy];
}

- (void)setForm:(AKRequestForm)form {
    if(self.isResumed) {
        return;
    }
    
    _form = [form copy];
}

- (void)setRequestProgress:(AKSessionTaskProgress)requestProgress {
    if(self.isResumed) {
        return;
    }
    
    _requestProgress = [requestProgress copy];
}

- (void)setResponseProgress:(AKSessionTaskProgress)responseProgress {
    if(self.isResumed) {
        return;
    }
    
    _responseProgress = [responseProgress copy];
}

- (void)setSuccess:(AKSessionTaskSuccess)success {
    if(self.isResumed) {
        return;
    }
    
    _success = [success copy];
}

- (void)setFailure:(AKSessionTaskFailure)failure {
    if(self.isResumed) {
        return;
    }
    
    _failure = [failure copy];
}

- (void)setPriority:(AKSessionTaskPriority)priority {
    if(self.isResumed) {
        return;
    }
    
    _priority = priority;
    switch (_priority) {
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
}

- (void)setContainURL:(BOOL)containURL {
    if(self.isResumed) {
        return;
    }
    
    _containURL = containURL;
}

- (void)setSerialize:(AKRequestSerialize)serialize {
    if(self.isResumed) {
        return;
    }
    
    _serialize = serialize;
}

- (void)setBarrier:(BOOL)barrier {
    if(self.isResumed) {
        return;
    }
    
    _barrier = barrier;
}

- (void)setSerial:(BOOL)serial {
    if(self.isResumed) {
        return;
    }
    
    _serial = serial;
}

#pragma mark - Private Method

- (NSString *)taskID {
    //serial模式下不重复发送同一参数请求，总是保留相同参数的最后一个请求
    NSString *urlID = self.url.length ? @(self.url.hash).description : @"";
    NSString *bodyID = self.body ? self.body(nil) : @"";
    NSString *formID = self.form ? self.form(nil) : @"";
    
    NSString *taskID = [NSString stringWithFormat:@"%@:%@:%@", urlID, bodyID, formID];
    return taskID;
}

- (NSString *)methodName {
    NSString *methodName = nil;
    switch (self.method) {
        case AKRequestMethodGET: methodName = @"GET"; break;
        case AKRequestMethodHEAD: methodName = @"HEAD"; break;
        case AKRequestMethodPOST: methodName = @"POST"; break;
        case AKRequestMethodPUT: methodName = @"PUT"; break;
        case AKRequestMethodPATCH: methodName = @"PATCH"; break;
        case AKRequestMethodDELETE: methodName = @"DELETE"; break;
        case AKRequestMethodFORM: methodName = @"POST"; break;
        default: methodName = @"POST"; break;
    }
}

#pragma mark - Public Method
- (void)construct {
    self.resumed = YES;//锁定所有属性更改
    
    AKSessionManager *manager = AKSessionManager.manager;
    
    NSTimeInterval startTimestamp = NSDate.date.timeIntervalSince1970;
    if(self.isSerial) {
        manager.taskTimestampDicM[self.taskID] = @(startTimestamp);
    }
    
    switch (self.serialize) {
        case AKRequestSerializeNormal: {
            manager.sessionManager.requestSerializer = manager.HTTPRequestSerializer;
            break;
        }
        case AKRequestSerializeJSON: {
            manager.sessionManager.requestSerializer = manager.JSONRequestSerializer;
            break;
        }
        case AKRequestSerializePropertyList: {
            manager.sessionManager.requestSerializer = manager.propertyListRequestSerializer;
            break;
        }
        default:
            manager.sessionManager.requestSerializer = manager.HTTPRequestSerializer;
            break;
    }
    
    if(self.containURL) {//参数中包含URL
        [manager.sessionManager.requestSerializer setQueryStringSerializationWithBlock:^NSString * _Nonnull(NSURLRequest * _Nonnull request, id  _Nonnull parameters, NSError * _Nullable __autoreleasing * _Nullable error) {
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
        [manager.sessionManager.requestSerializer setQueryStringSerializationWithBlock:nil];
    }
    
    /**
     *  请求无论是成功还是失败都需要处理的逻辑
     *  返回值的意义：用于区分serial模式下，是否最后一个请求
     */
    BOOL (^baseHandleBlock)() = ^BOOL {
        if(self.isBarrier) {
            dispatch_semaphore_signal(manager.semaphore);
        }

        if(self.isSerial) {
            if(manager.taskTimestampDicM[self.taskID].doubleValue != startTimestamp) {
                return NO;
            }
            manager.taskTimestampDicM[self.taskID] = nil;
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
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    self.body ? self.body(parameters) : nil;
    if(self.method != AKRequestMethodFORM) {
        self.task = [manager.sessionManager dataTaskWithHTTPMethod:self.methodName
                                                         URLString:self.url
                                                        parameters:[parameters copy]
                                                    uploadProgress:self.requestProgress
                                                  downloadProgress:self.responseProgress
                                                           success:innerSuccess
                                                           failure:innerFailure];
    } else {
        void (^innerForm)(id<AFMultipartFormData> formData) = ^(id<AFMultipartFormData> formData) {
            self.form ? self.form(formData) : nil;
        };
        self.task = [manager.sessionManager FORM:self.url
                                      parameters:parameters
                       constructingBodyWithBlock:innerForm
                                        progress:self.requestProgress
                                         success:innerSuccess
                                         failure:innerFailure];
    }
}

- (void)resume {
    [self construct];
    
    AKSessionManager *manager = AKSessionManager.manager;
    __weak typeof(manager) weak_manager = manager;
    dispatch_async(manager.serialQueue, ^{
        __strong typeof(weak_manager) strong_manager = weak_manager;

        //获取信号量，如果不是barrier类型的请求，立刻释放信号量
        dispatch_semaphore_wait(strong_manager.semaphore, DISPATCH_TIME_FOREVER);
        if(!self.isBarrier) {
            dispatch_semaphore_signal(strong_manager.semaphore);
        }
        
        [self.task resume];
    });
}

@end

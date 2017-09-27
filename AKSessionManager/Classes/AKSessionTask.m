//
//  AKSessionTask.m
//  Pods
//
//  Created by 李翔宇 on 2016/12/11.
//
//

#import "AKSessionTask.h"
#import "AKSessionManagerMacros.h"
#import "AKSessionManager.h"
#import "AFHTTPSessionManager+AKExtension.h"
#import "AFURLRequestSerialization+AKExtension.h"

@interface AKSessionTask ()

@property (nonatomic, strong) NSURLSessionTask *task;
@property (nonatomic, strong) NSMutableDictionary *parametersM;
@property (nonatomic, assign, getter=isResumed) BOOL resumed;

@end

@implementation AKSessionTask

- (instancetype)init {
    self = [super init];
    if(self) {
        _parametersM = [NSMutableDictionary dictionary];
    }
    return self;
}

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

- (void)setParam:(id _Nullable)param forName:(NSString *)name {
    if(self.isResumed) {
        return;
    }
    
    if(![name isKindOfClass:[NSString class]]
       || !name.length) {
        AKSessionManagerLog(@"参数名不可为空");
        return;
    }
    
    self.parametersM[name] = param;
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
    if(_taskID) {
        return _taskID;
    }
    
    _taskID = @([NSDate date].timeIntervalSinceNow * 1000).description;
    return _taskID;
}

- (NSString *)methodName {
    NSString *method = nil;
    switch (self.method) {
        case AKRequestMethodGET: method = @"GET"; break;
        case AKRequestMethodHEAD: method = @"HEAD"; break;
        case AKRequestMethodPOST: method = @"POST"; break;
        case AKRequestMethodPUT: method = @"PUT"; break;
        case AKRequestMethodPATCH: method = @"PATCH"; break;
        case AKRequestMethodDELETE: method = @"DELETE"; break;
        case AKRequestMethodFORM: method = @"POST"; break;
        default: method = @"POST"; break;
    }
    return method;
}

#pragma mark - Public Method

- (void)resume {
    self.resumed = YES;//锁定所有属性更改
    
    AKSessionManager *manager = AKSessionManager.manager;
    
    [self serialHandle];
    [self serializeHandle];
    [self containURLHandle];
    [self createHandle];
    
    //启动请求
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

#pragma mark - Private Method

- (void)serialHandle {
    AKSessionManager *manager = AKSessionManager.manager;
    
    if(!self.isSerial) {
        return;
    }
    
    [[manager.serialTasksM allObjects] enumerateObjectsUsingBlock:^(AKSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
        if(![task isKindOfClass:[self class]]) {
            return;
        }
        
        if(![task.taskID isEqualToString:self.taskID]) {
            return;
        }
        
        *stop = YES;
        [manager.serialTasksM removeObject:task];
    }];
    
    [manager.serialTasksM addObject:self];
}

- (void)serializeHandle {
    AKSessionManager *manager = AKSessionManager.manager;
    
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
}

- (void)containURLHandle {
    AKSessionManager *manager = AKSessionManager.manager;
    
    if(!self.isContainURL) {//参数中包含URL
        [manager.sessionManager.requestSerializer setQueryStringSerializationWithBlock:nil];
        return;
    }
    
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
}

- (void)createHandle {
    AKSessionManager *manager = AKSessionManager.manager;
    
    //拼装参数字典
    !self.body ? : self.body(self.parametersM);
    
    void (^innerSuccess)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) = ^(NSURLSessionDataTask * _Nonnull task, id responseObject) {
        [self finishWithHandler:^{
            !self.success ? : self.success(responseObject ? : nil);
        }];
    };
    
    void (^innerFailure)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) = ^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self finishWithHandler:^{
            !self.failure ? : self.failure(error);
        }];
    };
    
    if(self.method != AKRequestMethodFORM) {
        self.task = [manager.sessionManager dataTaskWithHTTPMethod:self.methodName
                                                         URLString:self.url
                                                        parameters:[self.parametersM copy]
                                                    uploadProgress:self.requestProgress
                                                  downloadProgress:self.responseProgress
                                                           success:innerSuccess
                                                           failure:innerFailure];
    } else {
        void (^innerForm)(id<AFMultipartFormData> formData) = ^(id<AFMultipartFormData> formData) {
            self.form ? self.form(formData) : nil;
        };
        self.task = [manager.sessionManager FORM:self.url
                                      parameters:[self.parametersM copy]
                       constructingBodyWithBlock:innerForm
                                        progress:self.requestProgress
                                         success:innerSuccess
                                         failure:innerFailure];
    }
}

/**
 *  请求无论是成功还是失败都需要处理的逻辑
 *  返回值的意义：用于区分serial模式下，是否最后一个请求
 */
- (void)finishWithHandler:(dispatch_block_t)handler {
    AKSessionManager *manager = AKSessionManager.manager;
    
    if(self.isSerial) {
        if([manager.serialTasksM containsObject:self]) {
            return;
        }
        
        [manager.serialTasksM removeObject:self];
    }
    
    !handler ? : handler();
    
    if(self.isBarrier) {
        dispatch_semaphore_signal(manager.semaphore);
    }
}

@end

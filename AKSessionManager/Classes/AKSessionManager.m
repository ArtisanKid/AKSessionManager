//
//  AKSessionManager.m
//  Pods
//
//  Created by 李翔宇 on 2016/12/11.
//
//

#import "AKSessionManager.h"

@interface AKSessionManager ()

@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, assign) dispatch_semaphore_t semaphore;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *taskTimestampDicM;

@property (nonatomic, strong) AFHTTPRequestSerializer *HTTPRequestSerializer;
@property (nonatomic, strong) AFJSONRequestSerializer *JSONRequestSerializer;
@property (nonatomic, strong) AFPropertyListRequestSerializer *propertyListRequestSerializer;

@end

@implementation AKSessionManager

#pragma mark- Singleton Method
+ (AKSessionManager *)manager {
    static AKSessionManager *sessionManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sessionManager = [[super allocWithZone:NULL] init];
        sessionManager.serialQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
        sessionManager.semaphore = dispatch_semaphore_create(1);
        sessionManager.taskTimestampDicM = [NSMutableDictionary dictionary];
        sessionManager.HTTPRequestSerializer = [AFHTTPRequestSerializer serializer];
        sessionManager.JSONRequestSerializer = [AFJSONRequestSerializer serializer];
        sessionManager.propertyListRequestSerializer = [AFPropertyListRequestSerializer serializer];
    });
    return sessionManager;
}

+ (id)alloc {
    return [self manager];
}

+ (id)allocWithZone:(NSZone * _Nullable)zone {
    return [self manager];
}

- (id)copy {
    return self;
}

- (id)copyWithZone:(NSZone * _Nullable)zone {
    return self;
}

@end

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
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *taskTimestampDicM;

@property (nonatomic, strong) AFHTTPRequestSerializer *HTTPRequestSerializer;
@property (nonatomic, strong) AFJSONRequestSerializer *JSONRequestSerializer;
@property (nonatomic, strong) AFPropertyListRequestSerializer *propertyListRequestSerializer;

@end

@implementation AKSessionManager

#pragma mark- Singleton Method
+ (AKSessionManager *)manager {
    static AKSessionManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
        sharedInstance.serialQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
        sharedInstance.semaphore = dispatch_semaphore_create(1);
        sharedInstance.taskTimestampDicM = [NSMutableDictionary dictionary];
        sharedInstance.sessionManager = [AFHTTPSessionManager manager];
        sharedInstance.HTTPRequestSerializer = [AFHTTPRequestSerializer serializer];
        sharedInstance.JSONRequestSerializer = [AFJSONRequestSerializer serializer];
        sharedInstance.propertyListRequestSerializer = [AFPropertyListRequestSerializer serializer];
    });
    return sharedInstance;
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

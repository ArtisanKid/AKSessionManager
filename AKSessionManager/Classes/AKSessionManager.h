//
//  AKSessionManager.h
//  Pods
//
//  Created by 李翔宇 on 2016/12/11.
//
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@interface AKSessionManager : NSObject

+ (AKSessionManager *)manager;

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@property (nonatomic, strong, readonly) dispatch_queue_t serialQueue;
@property (nonatomic, strong, readonly) dispatch_semaphore_t semaphore;

//@{TaskID : Timestamp}
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSNumber *> *taskTimestampDicM;

@property (nonatomic, strong, readonly) AFHTTPRequestSerializer *HTTPRequestSerializer;
@property (nonatomic, strong, readonly) AFJSONRequestSerializer *JSONRequestSerializer;
@property (nonatomic, strong, readonly) AFPropertyListRequestSerializer *propertyListRequestSerializer;

@end

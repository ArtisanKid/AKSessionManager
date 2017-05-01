//
//  AKSessionTask.h
//  Pods
//
//  Created by 李翔宇 on 2016/12/11.
//
//

//需要解决的问题
//（1）支持序列方式发送请求，支持相同URL与Param时，最后一次请求有效
//（2）支持Barrier方式发送请求

//使用继承的形式能够隔离开每个请求
//如果使用类方法构建会话，会出现因微小差异而必须使用全量参数接口的问题，否则无法体现请求需求

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

typedef NS_ENUM (NSUInteger, AKRequestMethod) {
    AKRequestMethodGET = 0,
    AKRequestMethodHEAD,
    AKRequestMethodPOST,
    AKRequestMethodPUT,
    AKRequestMethodPATCH,
    AKRequestMethodDELETE,
    
    AKRequestMethodFORM,
};

typedef NS_ENUM (NSUInteger, AKRequestSerialize) {
    AKRequestSerializeNormal = 0,
    AKRequestSerializeJSON,
    AKRequestSerializePropertyList
};

 typedef NS_ENUM (NSUInteger, AKSessionTaskPriority) {
    AKSessionTaskPriorityDefault = 0,
    AKSessionTaskPriorityLow,
    AKSessionTaskPriorityHigh
};

NS_ASSUME_NONNULL_BEGIN

typedef void (^AKSessionTaskProgress)(NSProgress *progress);
typedef void (^AKSessionTaskSuccess)(NSDictionary *result);
typedef void (^AKSessionTaskFailure)(NSError *error);

//返回值为业务设定的Hash唯一值
typedef NSString * _Nullable (^AKRequestBody)(NSMutableDictionary * body);
typedef NSString * _Nullable (^AKRequestForm)(id<AFMultipartFormData> formData);

/*
 AKSessionTask的设计说明
 我们定义AKSessionTask为NSURLSessionTask的容器
 NSURLSessionTask本身定义为任务，将request和response同等对待，但是由于NSURLSessionTask由NSURLSession生成，所以NSURLSessionTask不支持差异化配置（只有只读公共属性），不支持设置任务相关的Block。（任务前后的配置都不支持）
 AKSessionTask支持差异化配置，支持设置任务相关的Block，而且AKSessionTask支持子类化，可以在业务层再次添加新的差异化配置
 */

@interface AKSessionTask : NSObject

@property (nonatomic, strong) NSString *url;
@property (nonatomic, assign) AKRequestMethod method;

//子类需要设置创建body或者创建form的block
@property (nonatomic, copy) AKRequestBody body;
@property (nonatomic, copy) AKRequestForm form;

@property (nonatomic, copy) AKSessionTaskProgress requestProgress;
@property (nonatomic, copy) AKSessionTaskProgress responseProgress;
@property (nonatomic, copy) AKSessionTaskSuccess success;
@property (nonatomic, copy) AKSessionTaskFailure failure;

//请求序列化类型
@property (nonatomic, assign) AKSessionTaskPriority priority NS_AVAILABLE(10_10, 8_0);

//参数中包含URL，编码时需要额外处理
@property (nonatomic, assign, getter=isContainURL) BOOL containURL;

//请求序列化类型
@property (nonatomic, assign) AKRequestSerialize serialize;

//是否阻塞请求
@property (nonatomic, assign, getter=isBarrier) BOOL barrier;

//是否串行请求
@property (nonatomic, assign, getter=isSerial) BOOL serial;

#pragma mark - Readonly Property

@property (nonatomic, assign, readonly, getter=isResumed) BOOL resumed;

#pragma mark - Overridable Method

/**
 子类可重载方法，用于构建NSURLSessionTask
 construct方法调用的时机非常晚，在resume开始前一刻才会调用
 construct方法末尾必须设置task属性
 */
- (void)construct;

//内部的系统会话任务
@property (nonatomic, strong) NSURLSessionTask *task;

- (void)resume;

@end

NS_ASSUME_NONNULL_END

//
//  AFURLRequestSerialization+AKExtension.h
//  Pods
//
//  Created by 李翔宇 on 2016/12/15.
//
//

#import <AFNetworking/AFNetworking.h>

@interface AFQueryStringPair : NSObject

@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (instancetype)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValue;

@end

extern NSArray * AFQueryStringPairsFromDictionary(NSDictionary *dictionary);
extern NSString * AFPercentEscapedStringFromString(NSString *string);

//同AFPercentEscapedStringFromString的区别是，添加了对于URL类型参数的支持
//所谓支持就是添加了对“?”和“/”的转义
extern NSString * AKPercentEscapedStringFromString(NSString *string);

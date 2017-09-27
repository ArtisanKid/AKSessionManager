//
//  AKSessionTaskPluginProtocol.h
//  AFNetworking
//
//  Created by 李翔宇 on 2017/9/27.
//

#import <Foundation/Foundation.h>
@class AKSessionTask;

@protocol AKSessionTaskPluginProtocol <NSObject>

@optional

- (void)task:(AKSessionTask *)task didFailWithError:(NSError *)error;

- (void)task:(AKSessionTask *)task willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

- (nullable NSURLRequest *)task:(AKSessionTask *)task willSendRequest:(NSURLRequest *)request redirectResponse:(nullable NSURLResponse *)response;

- (void)task:(AKSessionTask *)task didReceiveResponse:(NSURLResponse *)response;

- (void)task:(AKSessionTask *)task didReceiveData:(NSData *)data;

- (void)task:(AKSessionTask *)task didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;

- (void)taskDidFinishLoading:(AKSessionTask *)connection;

- (void)task:(AKSessionTask *)task didWriteData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long) expectedTotalBytes;

- (void)taskDidResumeDownloading:(AKSessionTask *)connection totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long) expectedTotalBytes;

- (void)taskDidFinishDownloading:(AKSessionTask *)connection destinationURL:(NSURL *) destinationURL;

@end

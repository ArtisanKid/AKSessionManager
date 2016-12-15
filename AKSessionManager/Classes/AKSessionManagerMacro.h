//
//  AKSessionManagerMacro.h
//  Pods
//
//  Created by 李翔宇 on 2016/12/11.
//
//

#ifndef AKSessionManagerMacro_h
#define AKSessionManagerMacro_h

static BOOL AKSessionManagerLogState;

#define AKSessionManagerLogFormat(INFO, ...) [NSString stringWithFormat:(@"\n[Date:%s]\n[Time:%s]\n[File:%s]\n[Line:%d]\n[Function:%s]\n" INFO @"\n"), __DATE__, __TIME__, __FILE__, __LINE__, __PRETTY_FUNCTION__, ## __VA_ARGS__]

#if DEBUG
#define AKSessionManagerLog(INFO, ...) !AKSessionManagerLogState ? : NSLog((@"\n[Date:%s]\n[Time:%s]\n[File:%s]\n[Line:%d]\n[Function:%s]\n" INFO @"\n"), __DATE__, __TIME__, __FILE__, __LINE__, __PRETTY_FUNCTION__, ## __VA_ARGS__);
#else
#define AKSessionManagerLog(INFO, ...)
#endif

#endif /* AKSessionManagerMacro_h */

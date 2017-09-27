//
//  AKSessionManagerMacros.h
//  Pods
//
//  Created by 李翔宇 on 2016/12/11.
//
//

#ifndef AKSessionManagerMacros_h
#define AKSessionManagerMacros_h

#if DEBUG
    #define AKSessionManagerLog(_Format, ...)\
    do {\
        NSString *file = [NSString stringWithUTF8String:__FILE__].lastPathComponent;\
        NSLog((@"\n[%@][%d][%s]\n" _Format), file, __LINE__, __PRETTY_FUNCTION__, ## __VA_ARGS__);\
        printf("\n");\
    } while(0)
#else
    #define AKSessionManagerLog(_Format, ...)
#endif

#endif /* AKSessionManagerMacros_h */

//
//  AKSessionManagerMacro.h
//  Pods
//
//  Created by 李翔宇 on 2016/12/11.
//
//

#ifndef AKSessionManagerMacro_h
#define AKSessionManagerMacro_h

#if DEBUG
    #define AKSessionManagerLog(_Format, ...) NSLog((@"\n[File:%s]\n[Line:%d]\n[Function:%s]\n" _Format), __FILE__, __LINE__, __PRETTY_FUNCTION__, ## __VA_ARGS__);printf("\n");
#else
    #define AKSessionManagerLog(_Format, ...)
#endif

#endif /* AKSessionManagerMacro_h */

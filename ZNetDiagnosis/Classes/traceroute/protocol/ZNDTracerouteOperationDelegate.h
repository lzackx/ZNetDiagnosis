//
//  ZNDTracerouteOperationDelegate.h
//  Pods
//
//  Created by lZackx on 2022/8/8.
//

#ifndef ZNDTracerouteOperationDelegate_h
#define ZNDTracerouteOperationDelegate_h

#import <Foundation/Foundation.h>


@class ZNDTracerouteOperation;
@protocol ZNDTracerouteOperationDelegate <NSObject>

- (void)traceroute:(ZNDTracerouteOperation *)traceroute didSucceedWithInfo:(NSDictionary *)info;

- (void)traceroute:(ZNDTracerouteOperation *)traceroute didFailWithInfo:(NSDictionary *)info;

- (void)traceroute:(ZNDTracerouteOperation *)traceroute didCompleteWithInfo:(NSDictionary *)info;

@end

#endif /* ZNDTracerouteOperationDelegate_h */

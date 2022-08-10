//
//  ZNDPingOperationDelegate.h
//  Pods
//
//  Created by lZackx on 2022/8/8.
//

#ifndef ZNDPingOperationDelegate_h
#define ZNDPingOperationDelegate_h

#import <Foundation/Foundation.h>


@class ZNDPingOperation;
@protocol ZNDPingOperationDelegate <NSObject>

- (void)ping:(ZNDPingOperation *)ping didSucceedWithInfo:(NSDictionary *)info;

- (void)ping:(ZNDPingOperation *)ping didFailWithInfo:(NSDictionary *)info;

- (void)ping:(ZNDPingOperation *)ping didCompleteWithInfo:(NSDictionary *)info;

@end

#endif /* ZNDPingOperationDelegate_h */

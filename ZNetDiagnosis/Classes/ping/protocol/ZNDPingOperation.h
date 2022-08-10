//
//  ZNDPingOperation.h
//  ZNetDiagnosis
//
//  Created by lZackx on 2022/8/8.
//

#ifndef ZNDPingOperation_h
#define ZNDPingOperation_h

#import <Foundation/Foundation.h>
#import "ZNDPingConfiguration.h"
#import "ZNDPingOperationDelegate.h"

@interface ZNDPingOperation: NSOperation

@property (nonatomic, readwrite, strong) ZNDPingConfiguration *configuration;
@property (nonatomic, readwrite, weak) id<ZNDPingOperationDelegate> delegate;

- (instancetype)initWithConfiguration:(ZNDPingConfiguration *)configuration;

@end


#endif /* ZNDPingOperation_h */

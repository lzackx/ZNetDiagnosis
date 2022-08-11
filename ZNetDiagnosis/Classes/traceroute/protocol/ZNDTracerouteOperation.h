//
//  ZNDTracerouteOperation.h
//  ZNetDiagnosis
//
//  Created by lZackx on 2022/8/8.
//

#ifndef ZNDTracerouteOperation_h
#define ZNDTracerouteOperation_h

#import <Foundation/Foundation.h>
#import "ZNDTracerouteConfiguration.h"
#import "ZNDTracerouteOperationDelegate.h"

@interface ZNDTracerouteOperation: NSOperation

@property (nonatomic, readwrite, strong) ZNDTracerouteConfiguration *configuration;
@property (nonatomic, readwrite, weak) id<ZNDTracerouteOperationDelegate> delegate;

- (instancetype)initWithConfiguration:(ZNDTracerouteConfiguration *)configuration;

@end


#endif /* ZNDTracerouteOperation_h */

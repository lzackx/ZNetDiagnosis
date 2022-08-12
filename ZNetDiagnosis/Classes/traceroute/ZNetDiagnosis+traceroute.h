//
//  ZNetDiagnosis+traceroute.h
//  Pods-ZNetDiagnosis_Example
//
//  Created by lZackx on 2022/8/8.
//

#import <ZNetDiagnosis/ZNetDiagnosis.h>
#import "ZNDTracerouteConfiguration.h"
#import "ZNDTracerouteOperation.h"
#import "ZNDTracerouteOperationDelegate.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^ZNDTracerouteSuccess)(NSDictionary *info);
typedef void (^ZNDTracerouteFailure)(NSDictionary *info);
typedef void (^ZNDTracerouteCompletion)(NSDictionary *info);

@interface ZNetDiagnosis (traceroute) <ZNDTracerouteOperationDelegate>

@property (nonatomic, readwrite, copy) ZNDTracerouteSuccess tracerouteSuccess;
@property (nonatomic, readwrite, copy) ZNDTracerouteFailure tracerouteFailure;
@property (nonatomic, readwrite, copy) ZNDTracerouteCompletion tracerouteCompletion;

- (void)tracerouteWithConfiguration:(ZNDTracerouteConfiguration *)configuration;

- (void)tracerouteWithConfiguration:(ZNDTracerouteConfiguration *)configuration
                            success:(ZNDTracerouteSuccess _Nullable)success
                            failure:(ZNDTracerouteFailure _Nullable)failure
                         completion:(ZNDTracerouteCompletion _Nullable)completion;

@end

NS_ASSUME_NONNULL_END

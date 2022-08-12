//
//  ZNetDiagnosis+ping.h
//  Pods-ZNetDiagnosis_Example
//
//  Created by lZackx on 2022/8/8.
//

#import <ZNetDiagnosis/ZNetDiagnosis.h>
#import "ZNDPingConfiguration.h"
#import "ZNDPingOperation.h"
#import "ZNDPingOperationDelegate.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^ZNDPingSuccess)(NSDictionary *info);
typedef void (^ZNDPingFailure)(NSDictionary *info);
typedef void (^ZNDPingCompletion)(NSDictionary *info);

@interface ZNetDiagnosis (ping) <ZNDPingOperationDelegate>

@property (nonatomic, readwrite, copy) ZNDPingSuccess pingSuccess;
@property (nonatomic, readwrite, copy) ZNDPingFailure pingFailure;
@property (nonatomic, readwrite, copy) ZNDPingCompletion pingCompletion;

- (void)pingWithConfiguration:(ZNDPingConfiguration *)configuration;

- (void)pingWithConfiguration:(ZNDPingConfiguration *)configuration
                      success:(ZNDPingSuccess _Nullable)success
                      failure:(ZNDPingFailure _Nullable)failure
                   completion:(ZNDPingCompletion _Nullable)completion;

@end

NS_ASSUME_NONNULL_END

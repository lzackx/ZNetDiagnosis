//
//  ZNetDiagnosis+ping.m
//  Pods-ZNetDiagnosis_Example
//
//  Created by lZackx on 2022/8/8.
//

#import "ZNetDiagnosis+ping.h"
#import <objc/runtime.h>
#import <objc/message.h>

#import "ZNDPingICMPOperation.h"


@implementation ZNetDiagnosis (ping)

// MARK: - Getter / Setter
- (ZNDPingSuccess)success {
    ZNDPingSuccess block = objc_getAssociatedObject(self, @selector(success));
    return block;
}

- (void)setSuccess:(ZNDPingSuccess)success {
    objc_setAssociatedObject(self, @selector(success), success, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (ZNDPingFailure)failure {
    ZNDPingFailure block = objc_getAssociatedObject(self, @selector(failure));
    return block;
}

- (void)setFailure:(ZNDPingFailure)failure {
    objc_setAssociatedObject(self, @selector(failure), failure, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (ZNDPingCompletion)completion {
    ZNDPingCompletion block = objc_getAssociatedObject(self, @selector(completion));
    return block;
}

- (void)setCompletion:(ZNDPingCompletion)completion {
    objc_setAssociatedObject(self, @selector(completion), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

// MARK: - ping
- (void)pingWithConfiguration:(ZNDPingConfiguration *)configuration {
    [self pingWithConfiguration:configuration success:nil failure:nil completion:nil];
}

- (void)pingWithConfiguration:(ZNDPingConfiguration *)configuration
                      success:(ZNDPingSuccess _Nullable)success
                      failure:(ZNDPingFailure _Nullable)failure
                   completion:(ZNDPingCompletion _Nullable)completion {
    
    if (success) {
        [self setSuccess:success];
    }
    if (failure) {
        [self setFailure:failure];
    }
    if (completion) {
        [self setCompletion:completion];
    }
    
    ZNDPingOperation *pingOperation;
    switch (configuration.pingProtocol) {
        case ZNDPingProtocolICMP:
            pingOperation = [[ZNDPingICMPOperation alloc] initWithConfiguration:configuration];
            break;
        default:
            break;
    }
    pingOperation.delegate = self;
    [self addOperation:pingOperation];
}

// MARK: - ZNDPingOperationDelegate
- (void)ping:(ZNDPingOperation *)ping didSucceedWithInfo:(NSDictionary *)info {
    ZLog(@"%s => info: %@", __FUNCTION__, info);
    if ([self success]) {
        ZNDPingSuccess success = [self success];
        success(info);
    }
}

- (void)ping:(ZNDPingOperation *)ping didFailWithInfo:(NSDictionary *)info {
    ZLog(@"%s => info: %@", __FUNCTION__, info);
    if ([self failure]) {
        ZNDPingFailure failure = [self failure];
        failure(info);
    }
}

- (void)ping:(ZNDPingOperation *)ping didCompleteWithInfo:(NSDictionary *)info {
    ZLog(@"%s => info: %@", __FUNCTION__, info);
    if ([self completion]) {
        ZNDPingCompletion completion = [self completion];
        completion(info);
    }
}

@end

//
//  ZNetDiagnosis+traceroute.m
//  Pods-ZNetDiagnosis_Example
//
//  Created by lZackx on 2022/8/8.
//

#import "ZNetDiagnosis+traceroute.h"
#import <objc/runtime.h>
#import <objc/message.h>

#import "ZNDTracerouteICMPOperation.h"


@implementation ZNetDiagnosis (traceroute)

// MARK: - Getter / Setter
- (ZNDTracerouteSuccess)success {
    ZNDTracerouteSuccess block = objc_getAssociatedObject(self, @selector(success));
    return block;
}

- (void)setSuccess:(ZNDTracerouteSuccess)success {
    objc_setAssociatedObject(self, @selector(success), success, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (ZNDTracerouteFailure)failure {
    ZNDTracerouteFailure block = objc_getAssociatedObject(self, @selector(failure));
    return block;
}

- (void)setFailure:(ZNDTracerouteFailure)failure {
    objc_setAssociatedObject(self, @selector(failure), failure, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (ZNDTracerouteCompletion)completion {
    ZNDTracerouteCompletion block = objc_getAssociatedObject(self, @selector(completion));
    return block;
}

- (void)setCompletion:(ZNDTracerouteCompletion)completion {
    objc_setAssociatedObject(self, @selector(completion), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

// MARK: - traceroute
- (void)tracerouteWithConfiguration:(ZNDTracerouteConfiguration *)configuration {
    [self tracerouteWithConfiguration:configuration success:nil failure:nil completion:nil];
}

- (void)tracerouteWithConfiguration:(ZNDTracerouteConfiguration *)configuration
                      success:(ZNDTracerouteSuccess _Nullable)success
                      failure:(ZNDTracerouteFailure _Nullable)failure
                   completion:(ZNDTracerouteCompletion _Nullable)completion {
    
    if (success) {
        [self setSuccess:success];
    }
    if (failure) {
        [self setFailure:failure];
    }
    if (completion) {
        [self setCompletion:completion];
    }
    
    ZNDTracerouteOperation *tracerouteOperation;
    switch (configuration.tracerouteProtocol) {
        case ZNDTracerouteProtocolICMP:
            tracerouteOperation = [[ZNDTracerouteICMPOperation alloc] initWithConfiguration:configuration];
            break;
        default:
            break;
    }
    tracerouteOperation.delegate = self;
    [self addOperation:tracerouteOperation];
}

// MARK: - ZNDTracerouteOperationDelegate
- (void)traceroute:(ZNDTracerouteOperation *)traceroute didSucceedWithInfo:(NSDictionary *)info {
    ZLog(@"%s => info: %@", __FUNCTION__, info);
    if ([self success]) {
        ZNDTracerouteSuccess success = [self success];
        success(info);
    }
}

- (void)traceroute:(ZNDTracerouteOperation *)traceroute didFailWithInfo:(NSDictionary *)info {
    ZLog(@"%s => info: %@", __FUNCTION__, info);
    if ([self failure]) {
        ZNDTracerouteFailure failure = [self failure];
        failure(info);
    }
}

- (void)traceroute:(ZNDTracerouteOperation *)traceroute didCompleteWithInfo:(NSDictionary *)info {
    ZLog(@"%s => info: %@", __FUNCTION__, info);
    if ([self completion]) {
        ZNDTracerouteCompletion completion = [self completion];
        completion(info);
    }
}

@end

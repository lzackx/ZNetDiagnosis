//
//  ZNetDiagnosis+traceroute.m
//  Pods-ZNetDiagnosis_Example
//
//  Created by lZackx on 2022/8/8.
//

#import "ZNetDiagnosis+traceroute.h"
#import <objc/runtime.h>
#import <objc/message.h>

#import "ZNDTracerouteMixOperation.h"
#import "ZNDTracerouteICMPOperation.h"


@implementation ZNetDiagnosis (traceroute)

// MARK: - Getter / Setter
- (ZNDTracerouteSuccess)tracerouteSuccess {
    ZNDTracerouteSuccess block = objc_getAssociatedObject(self, @selector(tracerouteSuccess));
    return block;
}

- (void)setTracerouteSuccess:(ZNDTracerouteSuccess)success {
    objc_setAssociatedObject(self, @selector(tracerouteSuccess), success, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (ZNDTracerouteFailure)tracerouteFailure {
    ZNDTracerouteFailure block = objc_getAssociatedObject(self, @selector(tracerouteFailure));
    return block;
}

- (void)setTracerouteFailure:(ZNDTracerouteFailure)failure {
    objc_setAssociatedObject(self, @selector(tracerouteFailure), failure, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (ZNDTracerouteCompletion)tracerouteCompletion {
    ZNDTracerouteCompletion block = objc_getAssociatedObject(self, @selector(tracerouteCompletion));
    return block;
}

- (void)setTracerouteCompletion:(ZNDTracerouteCompletion)completion {
    objc_setAssociatedObject(self, @selector(tracerouteCompletion), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
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
        [self setTracerouteSuccess:success];
    }
    if (failure) {
        [self setTracerouteFailure:failure];
    }
    if (completion) {
        [self setTracerouteCompletion:completion];
    }
    
    ZNDTracerouteOperation *tracerouteOperation;
    switch (configuration.tracerouteProtocol) {
        case ZNDTracerouteProtocolMix:
            tracerouteOperation = [[ZNDTracerouteMixOperation alloc] initWithConfiguration:configuration];
            break;
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
    if ([self tracerouteSuccess]) {
        ZNDTracerouteSuccess success = [self tracerouteSuccess];
        success(info);
    }
}

- (void)traceroute:(ZNDTracerouteOperation *)traceroute didFailWithInfo:(NSDictionary *)info {
    ZLog(@"%s => info: %@", __FUNCTION__, info);
    if ([self tracerouteFailure]) {
        ZNDTracerouteFailure failure = [self tracerouteFailure];
        failure(info);
    }
}

- (void)traceroute:(ZNDTracerouteOperation *)traceroute didCompleteWithInfo:(NSDictionary *)info {
    ZLog(@"%s => info: %@", __FUNCTION__, info);
    if ([self tracerouteCompletion]) {
        ZNDTracerouteCompletion completion = [self tracerouteCompletion];
        completion(info);
    }
}

@end

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
- (ZNDPingSuccess)pingSuccess {
    ZNDPingSuccess block = objc_getAssociatedObject(self, @selector(pingSuccess));
    return block;
}

- (void)setPingSuccess:(ZNDPingSuccess)success {
    objc_setAssociatedObject(self, @selector(pingSuccess), success, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (ZNDPingFailure)pingFailure {
    ZNDPingFailure block = objc_getAssociatedObject(self, @selector(pingFailure));
    return block;
}

- (void)setPingFailure:(ZNDPingFailure)failure {
    objc_setAssociatedObject(self, @selector(pingFailure), failure, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (ZNDPingCompletion)pingCompletion {
    ZNDPingCompletion block = objc_getAssociatedObject(self, @selector(pingCompletion));
    return block;
}

- (void)setPingCompletion:(ZNDPingCompletion)completion {
    objc_setAssociatedObject(self, @selector(pingCompletion), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
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
        [self setPingSuccess:success];
    }
    if (failure) {
        [self setPingFailure:failure];
    }
    if (completion) {
        [self setPingCompletion:completion];
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
    if ([self pingSuccess]) {
        ZNDPingSuccess success = [self pingSuccess];
        success(info);
    }
}

- (void)ping:(ZNDPingOperation *)ping didFailWithInfo:(NSDictionary *)info {
    ZLog(@"%s => info: %@", __FUNCTION__, info);
    if ([self pingFailure]) {
        ZNDPingFailure failure = [self pingFailure];
        failure(info);
    }
}

- (void)ping:(ZNDPingOperation *)ping didCompleteWithInfo:(NSDictionary *)info {
    ZLog(@"%s => info: %@", __FUNCTION__, info);
    if ([self pingCompletion]) {
        ZNDPingCompletion completion = [self pingCompletion];
        completion(info);
    }
}

@end

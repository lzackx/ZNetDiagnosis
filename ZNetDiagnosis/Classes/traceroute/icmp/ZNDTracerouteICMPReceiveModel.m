//
//  ZNDTracerouteICMPReceiveModel.m
//  ZNetDiagnosis
//
//  Created by lZackx on 2022/8/12.
//

#import "ZNDTracerouteICMPReceiveModel.h"

@implementation ZNDTracerouteICMPReceiveModel

- (instancetype)initWithTTL:(NSInteger)ttl {
    if (self = [super init]) {
        _targetIP = [NSString string];
        _replyIP = [NSString string];
        _ttl = ttl;
        _durations = [NSMutableArray array];
        _status = ZNDTracerouteICMPReceiveStatusReceiving;
    }
    return self;
}

@end

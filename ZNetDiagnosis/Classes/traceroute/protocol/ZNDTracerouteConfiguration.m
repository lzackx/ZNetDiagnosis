//
//  ZNDTracerouteConfiguration.m
//  ZNetDiagnosis
//
//  Created by lZackx on 2022/8/8.
//

#import <Foundation/Foundation.h>
#import "ZNDTracerouteConfiguration.h"


@implementation ZNDTracerouteConfiguration

- (instancetype)init {
    self = [super init];
    if (self) {
        _target = [NSString string];
        _port = 32100;
        _maxTTL = 64;
        _attempt = 3;
        _tracerouteProtocol = ZNDTracerouteProtocolICMP;
    }
    return self;
}

@end

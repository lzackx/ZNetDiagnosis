//
//  ZNDPingConfiguration.m
//  ZNetDiagnosis
//
//  Created by lZackx on 2022/8/8.
//

#import <Foundation/Foundation.h>
#import "ZNDPingConfiguration.h"


@implementation ZNDPingConfiguration

- (instancetype)init {
    self = [super init];
    if (self) {
        _target = [NSString string];
        _maxTTL = 64;
        _attempt = 4;
        _timeout = 1;
        _pingProtocol = ZNDPingProtocolICMP;
    }
    return self;
}

@end

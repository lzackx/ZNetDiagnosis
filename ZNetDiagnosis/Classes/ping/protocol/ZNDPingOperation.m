//
//  ZNDPingOperation.m
//  ZNetDiagnosis
//
//  Created by lZackx on 2022/8/9.
//

#import "ZNDPingOperation.h"

@implementation ZNDPingOperation

- (instancetype)initWithConfiguration:(ZNDPingConfiguration *)configuration {
    self = [super init];
    if (self) {
        _configuration = configuration;
    }
    return self;
}

@end

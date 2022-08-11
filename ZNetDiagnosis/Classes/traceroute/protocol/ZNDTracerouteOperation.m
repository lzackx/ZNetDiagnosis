//
//  ZNDTracerouteOperation.m
//  ZNetDiagnosis
//
//  Created by lZackx on 2022/8/9.
//

#import "ZNDTracerouteOperation.h"

@implementation ZNDTracerouteOperation

- (instancetype)initWithConfiguration:(ZNDTracerouteConfiguration *)configuration {
    self = [super init];
    if (self) {
        _configuration = configuration;
    }
    return self;
}

@end

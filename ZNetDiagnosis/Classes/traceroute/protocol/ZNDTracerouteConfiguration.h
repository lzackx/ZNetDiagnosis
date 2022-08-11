//
//  ZNDTracerouteConfiguration.h
//  ZNetDiagnosis
//
//  Created by lZackx on 2022/8/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ZNDTracerouteProtocol) {
    ZNDTracerouteProtocolICMP
};

@interface ZNDTracerouteConfiguration : NSObject

// target: Host or IP
@property (nonatomic, readwrite, copy) NSString *target;

@property (nonatomic, readwrite, assign) NSUInteger port;
@property (nonatomic, readwrite, assign) NSInteger maxTTL;
@property (nonatomic, readwrite, assign) NSInteger attempt;

@property (nonatomic, readwrite, assign) ZNDTracerouteProtocol tracerouteProtocol;

@end

NS_ASSUME_NONNULL_END

//
//  ZNDPingConfiguration.h
//  ZNetDiagnosis
//
//  Created by lZackx on 2022/8/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ZNDPingProtocol) {
    ZNDPingProtocolICMP
};

@interface ZNDPingConfiguration : NSObject

// target: Host or IP
@property (nonatomic, readwrite, copy) NSString *target;

@property (nonatomic, readwrite, assign) NSInteger maxTTL;
@property (nonatomic, readwrite, assign) NSInteger attempt;
@property (nonatomic, readwrite, assign) NSInteger timeout; // unit: second

@property (nonatomic, readwrite, assign) ZNDPingProtocol pingProtocol;

@end

NS_ASSUME_NONNULL_END

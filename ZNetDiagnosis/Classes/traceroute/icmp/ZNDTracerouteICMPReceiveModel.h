//
//  ZNDTracerouteICMPReceiveModel.h
//  ZNetDiagnosis
//
//  Created by lZackx on 2022/8/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum ZNDTracerouteICMPReceiveStatus {
    ZNDTracerouteICMPReceiveStatusReceiving = 0,
    ZNDTracerouteICMPReceiveStatusDone
}ZNDTracerouteICMPReceiveStatus;


@interface ZNDTracerouteICMPReceiveModel : NSObject

@property (nonatomic, readwrite, copy) NSString *targetIP;
@property (nonatomic, readonly, assign) NSInteger ttl;
@property (nonatomic, readwrite, strong) NSMutableArray<NSString *> *replyIPs;
@property (nonatomic, readwrite, strong) NSMutableArray<NSString *> *durations; // unit: ms
@property (nonatomic, assign) ZNDTracerouteICMPReceiveStatus status;

- (instancetype)initWithTTL:(NSInteger)ttl;

@end


NS_ASSUME_NONNULL_END

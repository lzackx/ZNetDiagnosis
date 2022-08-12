//
//  ZNetDiagnosis+icmp.h
//  ZNetDiagnosis
//
//  Created by lZackx on 2022/8/12.
//

#import <ZNetDiagnosis/ZNetDiagnosis.h>
#import "ZNDICMPStructure.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZNetDiagnosis (icmp)

- (struct sockaddr *)makeSockaddrWithAddress:(NSString *)address
                                        port:(int)port
                                      isIPv6:(BOOL)isIPv6;

- (NSData *)makeICMPPacketHeaderWithIdentifier:(uint16_t)identifier
                                sequenceNumber:(uint16_t)sequenceNumber
                                      isICMPv6:(BOOL)isICMPv6;

- (BOOL)isEchoReplyPacket:(char *)packet length:(int)len isIPv6:(BOOL)isIPv6;

- (BOOL)isTimeoutPacket:(char *)packet length:(int)len isIPv6:(BOOL)isIPv6;


- (ICMPPacketHeader *)unpackICMPv4Packet:(char *)packet length:(int)length;

- (ICMPPacketHeader *)unpackICMPv6Packet:(char *)packet length:(int)length;

@end

NS_ASSUME_NONNULL_END

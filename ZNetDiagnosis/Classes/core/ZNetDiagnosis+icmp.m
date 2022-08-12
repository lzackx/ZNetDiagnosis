//
//  ZNetDiagnosis+icmp.m
//  ZNetDiagnosis
//
//  Created by lZackx on 2022/8/12.
//

#import "ZNetDiagnosis+icmp.h"
#import "ZNDIPStructure.h"

#include <arpa/inet.h>


@implementation ZNetDiagnosis (icmp)

- (struct sockaddr *)makeSockaddrWithAddress:(NSString *)address port:(int)port isIPv6:(BOOL)isIPv6 {
    NSData *addrData = nil;
    if (isIPv6) {
        struct sockaddr_in6 addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin6_family = AF_INET6;
        addr.sin6_len = sizeof(addr);
        addr.sin6_port = htons(port);
        if (inet_pton(AF_INET6, address.UTF8String, &addr.sin6_addr) < 0) {
            return NULL;
        }
        addrData = [NSData dataWithBytes:&addr length:sizeof(addr)];
    } else {
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_len = sizeof(addr);
        addr.sin_family = AF_INET;
        addr.sin_port = htons(port);
        if (inet_pton(AF_INET, address.UTF8String, &addr.sin_addr.s_addr) < 0) {
            return NULL;
        }
        addrData = [NSData dataWithBytes:&addr length:sizeof(addr)];
    }
    return (struct sockaddr *)[addrData bytes];
}

- (NSData *)makeICMPPacketHeaderWithIdentifier:(uint16_t)identifier
                                sequenceNumber:(uint16_t)sequenceNumber
                                      isICMPv6:(BOOL)isICMPv6 {
    NSMutableData *packet;
    ICMPPacketHeader *icmpPtr;
    
    packet = [NSMutableData dataWithLength:sizeof(*icmpPtr)];
    
    icmpPtr = packet.mutableBytes;
    icmpPtr->type = isICMPv6 ? ICMPv6TypeEchoRequest : ICMPv4TypeEchoRequest;
    icmpPtr->code = 0;
    
    if (isICMPv6) {
        icmpPtr->identifier     = 0;
        icmpPtr->sequenceNumber = 0;
    } else {
        icmpPtr->identifier     = OSSwapHostToBigInt16(identifier);
        icmpPtr->sequenceNumber = OSSwapHostToBigInt16(sequenceNumber);
    }
    
    // ICMPv6的校验和由内核计算
    if (!isICMPv6) {
        icmpPtr->checksum = 0;
        icmpPtr->checksum = in_checksum(packet.bytes, packet.length);//[self makeChecksumFor:packet.bytes len:packet.length];
    }
    
    return packet;
}

- (BOOL)isEchoReplyPacket:(char *)packet length:(int)length isIPv6:(BOOL)isIPv6 {
    ICMPPacketHeader *icmpPacket = NULL;
    
    if (isIPv6) {
        icmpPacket = [self unpackICMPv6Packet:packet length:length];
        if (icmpPacket != NULL && icmpPacket->type == ICMPv6TypeEchoReply) {
            return YES;
        }
    } else {
        icmpPacket = [self unpackICMPv4Packet:packet length:length];
        if (icmpPacket != NULL && icmpPacket->type == ICMPv4TypeEchoReply) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)isTimeoutPacket:(char *)packet length:(int)length isIPv6:(BOOL)isIPv6 {
    ICMPPacketHeader *icmpPacket = NULL;
    
    if (isIPv6) {
        icmpPacket = [self unpackICMPv6Packet:packet length:length];
        if (icmpPacket != NULL && icmpPacket->type == ICMPv6TypeEchoReply) {
            return YES;
        }
    } else {
        icmpPacket = [self unpackICMPv4Packet:packet length:length];
        if (icmpPacket != NULL && icmpPacket->type == ICMPv4TypeEchoTimeout) {
            return YES;
        }
    }
    
    return NO;
}

// 从IPv4数据包中解析出ICMP
- (ICMPPacketHeader *)unpackICMPv4Packet:(char *)packet length:(int)length {
    if (length < (sizeof(IPv4PacketHeader) + sizeof(ICMPPacketHeader))) {
        return NULL;
    }
    const struct IPv4PacketHeader *ipPtr = (const IPv4PacketHeader *)packet;
    if ((ipPtr->versionAndHeaderLength & 0xF0) != 0x40 || // IPv4
        ipPtr->protocol != 1) { //ICMP
        return NULL;
    }
    
    size_t ipHeaderLength = (ipPtr->versionAndHeaderLength & 0x0F) * sizeof(uint32_t); // IPv4头部长度
    if (length < ipHeaderLength + sizeof(ICMPPacketHeader)) {
        return NULL;
    }
    
    return (ICMPPacketHeader *)((char *)packet + ipHeaderLength);
}

// 从IPv6数据包中解析出ICMP
// https://tools.ietf.org/html/rfc2463
- (ICMPPacketHeader *)unpackICMPv6Packet:(char *)packet length:(int)length {
//    if (len < (sizeof(IPv6Header) + sizeof(ICMPPacketHeader))) {
//        return NULL;
//    }
//    const struct IPv6Header *ipPtr = (const IPv6Header *)packet;
//    if (ipPtr->nextHeader != 58) { // ICMPv6
//        return NULL;
//    }
//
//    size_t ipHeaderLength = sizeof(uint8_t) * 40; // IPv6头部长度为固定的40字节
//    if (len < ipHeaderLength + sizeof(ICMPPacketHeader)) {
//        return NULL;
//    }
//
//    return (ICMPPacketHeader *)((char *)packet + ipHeaderLength);
    return (ICMPPacketHeader *)packet;
}

@end

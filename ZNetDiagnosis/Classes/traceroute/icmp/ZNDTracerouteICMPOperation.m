//
//  ZNDTracerouteICMPOperation.m
//  ZNetDiagnosis
//
//  Created by lZackx on 2022/8/8.
//

#import "ZNDTracerouteICMPOperation.h"
#import "ZNetDiagnosisDefined.h"
#import "ZNDIPStructure.h"
#import "ZNDICMPStructure.h"
#import "ZNDTracerouteICMPReceiveModel.h"

#import "ZNetDiagnosis+icmp.h"
#import "ZNetDiagnosis+dns.h"

#include <netdb.h>
#include <arpa/inet.h>
#include <sys/time.h>


typedef enum ZNDTracerouteReceivedType{
    ZNDTracerouteReceivedTypeNone = 0,
    ZNDTracerouteReceivedTypeNoReply,
    ZNDTracerouteReceivedTypeRouteReceive,
    ZNDTracerouteReceivedTypeDestination
}ZNDTracerouteReceivedType;

@interface ZNDTracerouteICMPOperation ()

@property (nonatomic, readwrite, strong) NSMutableDictionary *defaultInfo;
@property (nonatomic, readwrite, assign) NSUInteger ipVersion;
@property (nonatomic, readwrite, assign) struct sockaddr *socketAddress;

@end

@implementation ZNDTracerouteICMPOperation

// MARK: - Life Cycle
- (instancetype)initWithConfiguration:(ZNDTracerouteConfiguration *)configuration {
    self = [super initWithConfiguration:configuration];
    if (self) {
        _defaultInfo = [NSMutableDictionary dictionary];
        [_defaultInfo setValue:configuration.target forKey:@"target"];
        _ipVersion = 4;
    }
    return self;
}

- (void)main {
    ZLog(@"%s", __FUNCTION__);
    
    [self traceroute:self.configuration.target];
    
    if ([self.delegate respondsToSelector:@selector(traceroute:didCompleteWithInfo:)]) {
        [self.delegate traceroute:self didCompleteWithInfo:self.defaultInfo];
    }
    ZLog(@"%s Done", __FUNCTION__);
}

- (void)dealloc {
    ZLog(@"%s", __FUNCTION__);
}

// MARK: - Traceroute
- (void)traceroute:(NSString *)target {
    NSString *ip = [[[ZNetDiagnosis shared] ipsForDomainName:target] firstObject];
    if (ip.length == 0) {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(traceroute:didFailWithInfo:)]) {
            NSError *error = [NSError errorWithDomain:@"ZNDDNSFailure" code:-1 userInfo:@{}];
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            [info setValue:error forKey:@"error"];
            [info addEntriesFromDictionary:self.defaultInfo];
            [self.delegate traceroute:self didFailWithInfo:info];
        }
        return;
    } else {
        [self.defaultInfo setValue:ip forKey:@"ip"];
    }
    
    BOOL isIPv6 = [ip rangeOfString:@":"].location != NSNotFound;
    // 目标主机地址
    struct sockaddr *sockaddr = [[ZNetDiagnosis shared] makeSockaddrWithAddress:ip
                                                                           port:(int)self.configuration.port
                                                                         isIPv6:isIPv6];
    
    
    if (sockaddr == NULL) {
        return;
    }
    
    // Socket
    int sock;
    if ((sock = socket(sockaddr->sa_family,
                       SOCK_DGRAM,
                       isIPv6 ? IPPROTO_ICMPV6 : IPPROTO_ICMP)) < 0) {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(traceroute:didFailWithInfo:)]) {
            NSError *error = [NSError errorWithDomain:@"ZNDReceiveSocketInitFailure" code:-1 userInfo:@{}];
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            [info setValue:error forKey:@"error"];
            [info addEntriesFromDictionary:self.defaultInfo];
            [self.delegate traceroute:self didFailWithInfo:info];
        }
        return;
    }
    
    // timeout
    struct timeval timeout;
    if (self.configuration.timeout > 0) {
        timeout.tv_sec = self.configuration.timeout;
        timeout.tv_usec = 0;
    } else {
        timeout.tv_sec = 1;
        timeout.tv_usec = 0;
    }
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout, sizeof(timeout));
    
    int ttl = 1;
    BOOL succeed = NO;
    do {
        // TTL
        if (setsockopt(sock,
                       isIPv6 ? IPPROTO_IPV6 : IPPROTO_IP,
                       isIPv6 ? IPV6_UNICAST_HOPS : IP_TTL,
                       &ttl,
                       sizeof(ttl)) < 0) {
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(traceroute:didFailWithInfo:)]) {
                NSError *error = [NSError errorWithDomain:@"ZNDSetSocketOptionFailure" code:-1 userInfo:@{}];
                NSMutableDictionary *info = [NSMutableDictionary dictionary];
                [info setValue:error forKey:@"error"];
                [info addEntriesFromDictionary:self.defaultInfo];
                [self.delegate traceroute:self didFailWithInfo:info];
            }
        }
        succeed = [self sendAndRecv:sock addr:sockaddr ttl:ttl];
    } while (++ttl <= self.configuration.maxTTL && !succeed);
    
    close(sock);
}

- (BOOL)sendAndRecv:(int)sendSock
               addr:(struct sockaddr *)addr
                ttl:(int)ttl {
    char buff[200];
    BOOL finished = NO;
    BOOL isIPv6 = [[self.defaultInfo objectForKey:@"ip"] rangeOfString:@":"].location != NSNotFound;
    socklen_t addrLen = isIPv6 ? sizeof(struct sockaddr_in6) : sizeof(struct sockaddr_in);
    
    // Packet
    uint16_t identifier = (uint16_t)ttl;
    NSData *packetData = [[ZNetDiagnosis shared] makeICMPPacketHeaderWithIdentifier:identifier
                                                                     sequenceNumber:ttl
                                                                           isICMPv6:isIPv6];
    
    // Recived Model
    ZNDTracerouteICMPReceiveModel *receivedModel = [[ZNDTracerouteICMPReceiveModel alloc] initWithTTL:ttl];
        
    BOOL receiveReply = NO;
    NSMutableArray *durations = [[NSMutableArray alloc] init];
    
    for (int try = 0; try < self.configuration.attempt; try ++) {
        
        // Send
        NSDate* startTime = [NSDate date];
        ssize_t sent = sendto(sendSock,
                              packetData.bytes,
                              packetData.length,
                              0,
                              addr,
                              addrLen);
        if (sent < 0) {
            [receivedModel.replyIPs addObject:@"*\t"];
            [durations addObject:@"0"];
            continue;
        }
        
        // Receive
        struct sockaddr remoteAddr;
        ssize_t resultLen = recvfrom(sendSock,
                                     buff,
                                     sizeof(buff),
                                     0,
                                     (struct sockaddr*)&remoteAddr,
                                     &addrLen);
        if (resultLen < 0) {
            [receivedModel.replyIPs addObject:@"*\t"];
            [durations addObject:@"0"];
            continue;
        } else {
            receiveReply = YES;
            NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:startTime];
            
            // Parse IP
            NSString* replyIP = [NSString string];
            if (!isIPv6) {
                char ip[INET_ADDRSTRLEN] = {0};
                inet_ntop(AF_INET, &((struct sockaddr_in *)&remoteAddr)->sin_addr.s_addr, ip, sizeof(ip));
                replyIP = [NSString stringWithUTF8String:ip];
            } else {
                char ip[INET6_ADDRSTRLEN] = {0};
                inet_ntop(AF_INET6, &((struct sockaddr_in6 *)&remoteAddr)->sin6_addr, ip, INET6_ADDRSTRLEN);
                replyIP = [NSString stringWithUTF8String:ip];
            }
            
            if (replyIP.length > 0) {
                [receivedModel.replyIPs addObject:replyIP];
            } else {
                [receivedModel.replyIPs addObject:@"*\t"];
            }
            
            // Parse Packet
            if ([[ZNetDiagnosis shared] isTimeoutPacket:buff length:(int)resultLen isIPv6:isIPv6]) {
                // On the road
                [durations addObject:[NSString stringWithFormat:@"%@", @(duration)]];
            } else if ([[ZNetDiagnosis shared] isEchoReplyPacket:buff length:(int)resultLen isIPv6:isIPv6] &&
                       [replyIP isEqualToString:[self.defaultInfo objectForKey:@"ip"]]) {
                // Reach Target
                [durations addObject:@(duration)];
                finished = YES;
            } else {
                // Failed
                [durations addObject:@"0"];
            }
        }
    }
    receivedModel.durations = [durations copy];
    ZLog(@"TTL: %ld, Reply IP: %@, durations: %@", (long)receivedModel.ttl, receivedModel.replyIP, receivedModel.durations);
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(traceroute:didFailWithInfo:)]) {
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        [info setValue:receivedModel forKey:@"log"];
        [info addEntriesFromDictionary:self.defaultInfo];
        [self.delegate traceroute:self didSucceedWithInfo:info];
    }
    return finished;
}

@end


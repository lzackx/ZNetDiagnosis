//
//  ZNDTracerouteUDP.m
//  ZNetDiagnosis
//
//  Created by lZackx on 2022/8/8.
//

#import "ZNDTracerouteICMPOperation.h"
#import "ZNetDiagnosisDefined.h"
#import "ZNDICMPStructure.h"

#import "ZNetDiagnosis+dns.h"

#include <netdb.h>
#include <arpa/inet.h>
#include <sys/time.h>


@interface ZNDTracerouteICMPOperation ()

@property (nonatomic, readwrite, strong) NSMutableDictionary *defaultInfo;

@end

@implementation ZNDTracerouteICMPOperation

// MARK: - Life Cycle
- (instancetype)initWithConfiguration:(ZNDTracerouteConfiguration *)configuration {
    self = [super initWithConfiguration:configuration];
    if (self) {
        _defaultInfo = [NSMutableDictionary dictionary];
        [_defaultInfo setValue:configuration.target forKey:@"target"];
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
- (Boolean)traceroute:(NSString *)target {
    NSArray *serverDNSs = [[ZNetDiagnosis shared] ipsForDomainName:target];
    if (!serverDNSs || serverDNSs.count <= 0) {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(traceroute:didFailWithInfo:)]) {
            NSError *error = [NSError errorWithDomain:@"ZNDDNSFailure" code:-1 userInfo:@{}];
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            [info setValue:error forKey:@"error"];
            [info addEntriesFromDictionary:self.defaultInfo];
            [self.delegate traceroute:self didFailWithInfo:info];
        }
        return false;
    } else {
        [self.defaultInfo setValue:[serverDNSs firstObject] forKey:@"ip"];
    }
    
    NSString *ipAddr0 = [serverDNSs firstObject];
    // 设置server主机的套接口地址
    NSData *addrData = nil;
    BOOL isIPv6 = NO;
    if ([ipAddr0 rangeOfString:@":"].location == NSNotFound) {
        isIPv6 = NO;
        struct sockaddr_in nativeAddr4;
        memset(&nativeAddr4, 0, sizeof(nativeAddr4));
        nativeAddr4.sin_len = sizeof(nativeAddr4);
        nativeAddr4.sin_family = AF_INET;
        nativeAddr4.sin_port = htons(self.configuration.port);
        inet_pton(AF_INET, ipAddr0.UTF8String, &nativeAddr4.sin_addr.s_addr);
        addrData = [NSData dataWithBytes:&nativeAddr4 length:sizeof(nativeAddr4)];
    } else {
        isIPv6 = YES;
        struct sockaddr_in6 nativeAddr6;
        memset(&nativeAddr6, 0, sizeof(nativeAddr6));
        nativeAddr6.sin6_len = sizeof(nativeAddr6);
        nativeAddr6.sin6_family = AF_INET6;
        nativeAddr6.sin6_port = htons(self.configuration.port);
        inet_pton(AF_INET6, ipAddr0.UTF8String, &nativeAddr6.sin6_addr);
        addrData = [NSData dataWithBytes:&nativeAddr6 length:sizeof(nativeAddr6)];
    }
    
    struct sockaddr *destination;
    destination = (struct sockaddr *)[addrData bytes];
    
    //初始化套接口
    struct sockaddr fromAddr;
    int recv_sock;
    int send_sock;
    Boolean error = false;
    
    // recevice socket
    if ((recv_sock = socket(destination->sa_family, SOCK_DGRAM, isIPv6 ? IPPROTO_ICMPV6 : IPPROTO_ICMP)) < 0) {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(traceroute:didFailWithInfo:)]) {
            NSError *error = [NSError errorWithDomain:@"ZNDReceiveSocketInitFailure" code:-1 userInfo:@{}];
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            [info setValue:error forKey:@"error"];
            [info addEntriesFromDictionary:self.defaultInfo];
            [self.delegate traceroute:self didFailWithInfo:info];
        }
        return false;
    }
    
    // send socket
    if ((send_sock = socket(destination->sa_family, SOCK_DGRAM, 0)) < 0) {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(traceroute:didFailWithInfo:)]) {
            NSError *error = [NSError errorWithDomain:@"ZNDSendSocketInitFailure" code:-1 userInfo:@{}];
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            [info setValue:error forKey:@"error"];
            [info addEntriesFromDictionary:self.defaultInfo];
            [self.delegate traceroute:self didFailWithInfo:info];
        }
        return false;
    }

    char *cmsg = "GET / HTTP/1.1\r\n\r\n";
    socklen_t n = sizeof(fromAddr);
    char buf[100];
    
    int ttl = 1;  // index sur le TTL en cours de traitement.
    int timeoutTTL = 0;
    bool icmpReceived = false;  // Positionné à true lorsqu'on reçoit la trame ICMP en retour.
    NSDate *startTime;     // Timestamp lors de l'émission du GET HTTP
    NSTimeInterval delta;         // Durée de l'aller-retour jusqu'au hop.
    
    // On progresse jusqu'à un nombre de TTLs max.
    while (ttl <= self.configuration.maxTTL) {
        memset(&fromAddr, 0, sizeof(fromAddr));
        // set send socket TTL
        if ((isIPv6 ? setsockopt(send_sock,IPPROTO_IPV6, IPV6_UNICAST_HOPS, &ttl, sizeof(ttl)) : setsockopt(send_sock, IPPROTO_IP, IP_TTL, &ttl, sizeof(ttl))) < 0) {
            error = true;
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(traceroute:didFailWithInfo:)]) {
                NSError *error = [NSError errorWithDomain:@"ZNDSetSendSocketOptionFailure" code:-1 userInfo:@{}];
                NSMutableDictionary *info = [NSMutableDictionary dictionary];
                [info setValue:error forKey:@"error"];
                [info addEntriesFromDictionary:self.defaultInfo];
                [self.delegate traceroute:self didFailWithInfo:info];
            }
        }
        
        // attempt
        icmpReceived = false;
        NSMutableString *traceTTLLog = [[NSMutableString alloc] initWithCapacity:20];
        [traceTTLLog appendFormat:@"%d\t", ttl];
        NSString *ip = @"***";
        for (int try = 0; try < self.configuration.attempt; try ++) {
            startTime = [NSDate date];
            // 发送成功返回值等于发送消息的长度
            ssize_t sentLen = sendto(send_sock, cmsg, sizeof(cmsg), 0, (struct sockaddr *)destination, isIPv6?sizeof(struct sockaddr_in6):sizeof(struct sockaddr_in));
            if (sentLen != sizeof(cmsg)) {
                ZLog(@"Error sending to server: %d %d", errno, (int)sentLen);
                error = true;
                [traceTTLLog appendFormat:@"*\t"];
            }
            
            long res = 0;
            // 从（已连接）套接口上接收数据，并捕获数据发送源的地址。
            if (-1 == fcntl(recv_sock, F_SETFL, O_NONBLOCK)) {
                ZLog(@"fcntl socket error!\n");
                return -1;
            }
            /* set recvfrom from server timeout */
            struct timeval tv;
            fd_set readfds;
            tv.tv_sec = 1;
            tv.tv_usec = 0;  //设置了1s的延迟
            FD_ZERO(&readfds);
            FD_SET(recv_sock, &readfds);
            select(recv_sock + 1, &readfds, NULL, NULL, &tv);
            if (FD_ISSET(recv_sock, &readfds) > 0) {
                timeoutTTL = 0;
                if ((res = recvfrom(recv_sock, buf, 100, 0, (struct sockaddr *)&fromAddr, &n)) <
                    0) {
                    error = true;
                    [traceTTLLog appendFormat:@"%s\t", strerror(errno)];
                } else {
                    icmpReceived = true;
                    delta = [[NSDate date] timeIntervalSinceDate:startTime];
                    
                    // 将“二进制整数” －> “点分十进制，获取hostAddress和hostName
                    if (fromAddr.sa_family == AF_INET) {
                        char display[INET_ADDRSTRLEN] = {0};
                        inet_ntop(AF_INET, &((struct sockaddr_in *)&fromAddr)->sin_addr.s_addr, display, sizeof(display));
                        ip = [NSString stringWithFormat:@"%s", display];
                    }
                    
                    else if (fromAddr.sa_family == AF_INET6) {
                        char ipv6[INET6_ADDRSTRLEN];
                        inet_ntop(AF_INET6, &((struct sockaddr_in6 *)&fromAddr)->sin6_addr, ipv6, INET6_ADDRSTRLEN);
                        ip = [NSString stringWithUTF8String:ipv6];
                    }
                    
                    if (try == 0) {
                        [traceTTLLog appendFormat:@"%@\t\t", ip];
                    }
                    [traceTTLLog appendFormat:@"%0.2fms\t", (float)delta * 1000];
                }
            } else {
                timeoutTTL++;
                traceTTLLog = [NSMutableString stringWithFormat:@"%d\t* * *\t", ttl];
                break;
            }
        }
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(traceroute:didFailWithInfo:)]) {
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            [info setValue:traceTTLLog forKey:@"log"];
            [info addEntriesFromDictionary:self.defaultInfo];
            [self.delegate traceroute:self didSucceedWithInfo:info];
        }
        if ([ip isEqualToString:ipAddr0]) {
            break;
        }
        ttl++;
    }
    return error;
}

@end


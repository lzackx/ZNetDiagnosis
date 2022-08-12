//
//  ZNetDiagnosis+dns.m
//  Pods-ZNetDiagnosis_Example
//
//  Created by lZackx on 2022/8/11.
//

#import "ZNetDiagnosis+dns.h"


#import <ifaddrs.h>
#import <arpa/inet.h>
#import <netdb.h>
#import <sys/socket.h>
#import <resolv.h>
#import <dns.h>
#import <sys/sysctl.h>
#import <netinet/in.h>

#if TARGET_IPHONE_SIMULATOR
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 110000
#import <net/route.h>
#else
#import "ZNDRoute.h"
#endif
#else
#import "ZNDRoute.h"
#endif /*the very same from google-code*/

#define ROUNDUP(a) ((a) > 0 ? (1 + (((a)-1) | (sizeof(long) - 1))) : sizeof(long))

@implementation ZNetDiagnosis (dns)


- (NSString *)deviceIP {
    NSString *address = @"";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0) {  // 0 表示获取成功
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            ZLog(@"ifa_name===%@",[NSString stringWithUTF8String:temp_addr->ifa_name]);
            // Check if interface is en0 which is the wifi connection on the iPhone
            if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"] || [[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"pdp_ip0"]) {
                // ipv4
                if (temp_addr->ifa_addr->sa_family == AF_INET){
                    // Get NSString from C String
                    address = [self formatedIPv4:((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr];
                }
                // ipv6
                else if (temp_addr->ifa_addr->sa_family == AF_INET6){
                    address = [self formatedIPv6:((struct sockaddr_in6 *)temp_addr->ifa_addr)->sin6_addr];
                    if (address && ![address isEqualToString:@""] && ![address.uppercaseString hasPrefix:@"FE80"]) break;
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    // 以FE80开始的地址是单播地址
    if (address && ![address isEqualToString:@""] && ![address.uppercaseString hasPrefix:@"FE80"]) {
        return address;
    } else {
        return @"127.0.0.1";
    }
}

- (NSString *)gatewayIP {
    NSString *address = nil;
    /* net.route.0.inet.flags.gateway */
    int mib[] = {CTL_NET, PF_ROUTE, 0, AF_INET6, NET_RT_FLAGS, RTF_GATEWAY};
    size_t l;
    char *buf, *p;
    struct rt_msghdr *rt;
    struct sockaddr_in6 *sa;
    struct sockaddr_in6 *sa_tab[RTAX_MAX];
    int i;
    if (sysctl(mib, sizeof(mib) / sizeof(int), 0, &l, 0, 0) < 0) {
        address = @"192.168.0.1";
    }
    if (l > 0) {
        buf = malloc(l);
        if (sysctl(mib, sizeof(mib) / sizeof(int), buf, &l, 0, 0) < 0) {
            address = @"192.168.0.1";
        }
        for (p = buf; p < buf + l; p += rt->rtm_msglen) {
            rt = (struct rt_msghdr *)p;
            sa = (struct sockaddr_in6 *)(rt + 1);
            for (i = 0; i < RTAX_MAX; i++) {
                if (rt->rtm_addrs & (1 << i)) {
                    sa_tab[i] = sa;
                    sa = (struct sockaddr_in6 *)((char *)sa + sa->sin6_len);
                } else {
                    sa_tab[i] = NULL;
                }
            }
            if( ((rt->rtm_addrs & (RTA_DST|RTA_GATEWAY)) == (RTA_DST|RTA_GATEWAY))
               && sa_tab[RTAX_DST]->sin6_family == AF_INET6
               && sa_tab[RTAX_GATEWAY]->sin6_family == AF_INET6) {
                address = [self formatedIPv6:((struct sockaddr_in6 *)(sa_tab[RTAX_GATEWAY]))->sin6_addr];
                NSLog(@"IPV6address%@", address);
                break;
            }
        }
        free(buf);
    }
    return address;
}

- (NSArray *)ipv4sForDomainName:(NSString *)hostName {
    const char *hostN = [hostName UTF8String];
    struct hostent *phot;
    @try {
        phot = gethostbyname(hostN);
    } @catch (NSException *exception) {
        return nil;
    }
    NSMutableArray *result = [[NSMutableArray alloc] init];
    int j = 0;
    while (phot && phot->h_addr_list && phot->h_addr_list[j]) {
        struct in_addr ip_addr;
        memcpy(&ip_addr, phot->h_addr_list[j], 4);
        char ip[20] = {0};
        inet_ntop(AF_INET, &ip_addr, ip, sizeof(ip));
        
        NSString *strIPAddress = [NSString stringWithUTF8String:ip];
        [result addObject:strIPAddress];
        j++;
    }
    return [NSArray arrayWithArray:result];
}

- (NSArray *)ipv6ForDomainName:(NSString *)hostName {
    const char *hostN = [hostName UTF8String];
    struct hostent *phot;
    @try {
        phot = gethostbyname2(hostN, AF_INET6);
    } @catch (NSException *exception) {
        return nil;
    }
    NSMutableArray *result = [[NSMutableArray alloc] init];
    int j = 0;
    while (phot && phot->h_addr_list && phot->h_addr_list[j]) {
        struct in6_addr ip6_addr;
        memcpy(&ip6_addr, phot->h_addr_list[j], sizeof(struct in6_addr));
        NSString *strIPAddress = [self formatedIPv6: ip6_addr];
        [result addObject:strIPAddress];
        j++;
    }
    return [NSArray arrayWithArray:result];
}

- (NSArray *)ipsForDomainName:(NSString *)domainName {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSArray *IPV4DNSs = [self ipv4sForDomainName:domainName];
    if (IPV4DNSs && IPV4DNSs.count > 0) {
        [result addObjectsFromArray:IPV4DNSs];
    }
    NSArray *IPV6DNSs = [self ipv6ForDomainName:domainName];
    if (IPV6DNSs && IPV6DNSs.count > 0) {
        [result removeAllObjects];
        [result addObjectsFromArray:IPV6DNSs];
    }
    return [NSArray arrayWithArray:result];
}

//- (NSArray<NSString *> *)resolveHost:(NSString *)hostname {
//    NSMutableArray<NSString *> *resolve = [NSMutableArray array];
//    CFHostRef hostRef = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef)hostname);
//    if (hostRef != NULL) {
//        Boolean result = CFHostStartInfoResolution(hostRef, kCFHostAddresses, NULL); // 开始DNS解析
//        if (result == true) {
//            CFArrayRef addresses = CFHostGetAddressing(hostRef, &result);
//            for(int i = 0; i < CFArrayGetCount(addresses); i++){
//                CFDataRef saData = (CFDataRef)CFArrayGetValueAtIndex(addresses, i);
//                struct sockaddr *addressGeneric = (struct sockaddr *)CFDataGetBytePtr(saData);
//
//                if (addressGeneric != NULL) {
//                    if (addressGeneric->sa_family == AF_INET) {
//                        struct sockaddr_in *remoteAddr = (struct sockaddr_in *)CFDataGetBytePtr(saData);
//                        [resolve addObject:[self formatIPv4Address:remoteAddr->sin_addr]];
//                    } else if (addressGeneric->sa_family == AF_INET6) {
//                        struct sockaddr_in6 *remoteAddr = (struct sockaddr_in6 *)CFDataGetBytePtr(saData);
//                        [resolve addObject:[self formatIPv6Address:remoteAddr->sin6_addr]];
//                    }
//                }
//            }
//        }
//    }
//
//    return [resolve copy];
//}

- (NSArray *)dnsServers {
    res_state res = malloc(sizeof(struct __res_state));
    int result = res_ninit(res);
    NSMutableArray *servers = [[NSMutableArray alloc] init];
    if (result == 0) {
        union res_9_sockaddr_union *addr_union = malloc(res->nscount * sizeof(union res_9_sockaddr_union));
        res_getservers(res, addr_union, res->nscount);
        for (int i = 0; i < res->nscount; i++) {
            if (addr_union[i].sin.sin_family == AF_INET) {
                char ip[INET_ADDRSTRLEN];
                inet_ntop(AF_INET, &(addr_union[i].sin.sin_addr), ip, INET_ADDRSTRLEN);
                NSString *dnsIP = [NSString stringWithUTF8String:ip];
                [servers addObject:dnsIP];
                ZLog(@"IPv4 DNS IP: %@", dnsIP);
            } else if (addr_union[i].sin6.sin6_family == AF_INET6) {
                char ip[INET6_ADDRSTRLEN];
                inet_ntop(AF_INET6, &(addr_union[i].sin6.sin6_addr), ip, INET6_ADDRSTRLEN);
                NSString *dnsIP = [NSString stringWithUTF8String:ip];
                [servers addObject:dnsIP];
                ZLog(@"IPv6 DNS IP: %@", dnsIP);
            } else {
                ZLog(@"Undefined family.");
            }
        }
    }
    res_nclose(res);
    free(res);
    return [NSArray arrayWithArray:servers];
}

- (NSString *)formatedIPv4:(struct in_addr)ipv4 {
    NSString *address = nil;
    char dstStr[INET_ADDRSTRLEN];
    char srcStr[INET_ADDRSTRLEN];
    memcpy(srcStr, &ipv4, sizeof(struct in_addr));
    if(inet_ntop(AF_INET, srcStr, dstStr, INET_ADDRSTRLEN) != NULL){
        address = [NSString stringWithUTF8String:dstStr];
    }
    return address;
}

- (NSString *)formatedIPv6:(struct in6_addr)ipv6 {
    NSString *address = nil;
    char dstStr[INET6_ADDRSTRLEN];
    char srcStr[INET6_ADDRSTRLEN];
    memcpy(srcStr, &ipv6, sizeof(struct in6_addr));
    if(inet_ntop(AF_INET6, srcStr, dstStr, INET6_ADDRSTRLEN) != NULL){
        address = [NSString stringWithUTF8String:dstStr];
    }
    return address;
}

@end

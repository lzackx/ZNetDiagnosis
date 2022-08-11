//
//  ZNetDiagnosis+dns.h
//  Pods-ZNetDiagnosis_Example
//
//  Created by lZackx on 2022/8/11.
//

#import <ZNetDiagnosis/ZNetDiagnosis.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZNetDiagnosis (dns)

- (NSString *)deviceIP;

- (NSString *)gatewayIP;

- (NSArray *)ipsForDomainName:(NSString *)domainName;

- (NSArray *)dnsServers;

- (NSString *)formatedIPv4:(struct in_addr)ipv4;

- (NSString *)formatedIPv6:(struct in6_addr)ipv6;

@end

NS_ASSUME_NONNULL_END

//
//  ZNDPingUDP.m
//  ZNetDiagnosis
//
//  Created by lZackx on 2022/8/8.
//

#import "ZNDPingICMPOperation.h"
#import "ZNetDiagnosisDefined.h"
#import "ZNDSimplePing.h"
#import "ZNDICMPStructure.h"

#include <netdb.h>


@interface ZNDPingICMPOperation () <ZNDSimplePingDelegate>

@property (nonatomic, readwrite, assign) NSUInteger sent;
@property (nonatomic, readwrite, assign) NSUInteger received;
@property (nonatomic, readwrite, assign) BOOL shouldStop;
@property (nonatomic, readwrite, strong) ZNDSimplePing *ping;
@property (nonatomic, readwrite, strong) NSMutableDictionary *defaultInfo;
@property (nonatomic, readwrite, assign) NSDate *sendDate;
@property (nonatomic, readwrite, strong) NSTimer *timer;

@end

@implementation ZNDPingICMPOperation

// MARK: - Life Cycle
- (instancetype)initWithConfiguration:(ZNDPingConfiguration *)configuration {
    self = [super initWithConfiguration:configuration];
    if (self) {
        _sent = 0;
        _received = 0;
        _shouldStop = NO;
        _ping = [[ZNDSimplePing alloc] initWithHostName:self.configuration.target];
        _ping.delegate = self;
        _defaultInfo = [NSMutableDictionary dictionary];
        [_defaultInfo setValue:configuration.target forKey:@"target"];
        _sendDate = [NSDate date];
        _timer = nil;
    }
    return self;
}

- (void)main {
    ZLog(@"%s", __FUNCTION__);
    [self.ping start];
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:self.configuration.timeout]];
    } while (self.shouldStop == NO);
    
    if ([self.delegate respondsToSelector:@selector(ping:didCompleteWithInfo:)]) {
        [self.delegate ping:self didCompleteWithInfo:self.defaultInfo];
    }
    ZLog(@"%s Done info: %@", __FUNCTION__, self.defaultInfo);
}

- (void)cancel {
    [self.ping stop];
    self.sent = 0;
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    ZLog(@"%s", __FUNCTION__);
}

- (void)dealloc {
    [_ping stop];
    _sent = 0;
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    ZLog(@"%s", __FUNCTION__);
}

// MARK: - ZNDSimplePingDelegate

/*! A SimplePing delegate callback, called once the object has started up.
 *  \details This is called shortly after you start the object to tell you that the
 *      object has successfully started.  On receiving this callback, you can call
 *      `-sendPingWithData:` to send pings.
 *
 *      If the object didn't start, `-simplePing:didFailWithError:` is called instead.
 *  \param ping The object issuing the callback.
 *  \param address The address that's being pinged; at the time this delegate callback
 *      is made, this will have the same value as the `hostAddress` property.
 */

- (void)simplePing:(ZNDSimplePing *)ping didStartWithAddress:(NSData *)address {
    ZLog(@"%s", __FUNCTION__);
    NSString *ip = [self convertedAddress:address];
    [self.defaultInfo setValue:ip forKey:@"ip"];
    [self sendWithPing:ping];
}


/*! A SimplePing delegate callback, called if the object fails to start up.
 *  \details This is called shortly after you start the object to tell you that the
 *      object has failed to start.  The most likely cause of failure is a problem
 *      resolving `hostName`.
 *
 *      By the time this callback is called, the object has stopped (that is, you don't
 *      need to call `-stop` yourself).
 *  \param ping The object issuing the callback.
 *  \param error Describes the failure.
 */
- (void)simplePing:(ZNDSimplePing *)ping didFailWithError:(NSError *)error {
    ZLog(@"%s", __FUNCTION__);
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    [info setValue:error forKey:@"error"];
    [info addEntriesFromDictionary:self.defaultInfo];
    if ([self.delegate respondsToSelector:@selector(ping:didFailWithInfo:)]) {
        [self.delegate ping:self didFailWithInfo:info];
    }
    self.shouldStop = YES;
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}


/*! A SimplePing delegate callback, called when the object has successfully sent a ping packet.
 *  \details Each call to `-sendPingWithData:` will result in either a
 *      `-simplePing:didSendPacket:sequenceNumber:` delegate callback or a
 *      `-simplePing:didFailToSendPacket:sequenceNumber:error:` delegate callback (unless you
 *      stop the object before you get the callback).  These callbacks are currently delivered
 *      synchronously from within `-sendPingWithData:`, but this synchronous behaviour is not
 *      considered API.
 *  \param ping The object issuing the callback.
 *  \param packet The packet that was sent; this includes the ICMP header (`ICMPPacketHeader`) and the
 *      data you passed to `-sendPingWithData:` but does not include any IP-level headers.
 *  \param sequenceNumber The ICMP sequence number of that packet.
 */

- (void)simplePing:(ZNDSimplePing *)ping
     didSendPacket:(NSData *)packet
    sequenceNumber:(uint16_t)sequenceNumber {
    ZLog(@"%s", __FUNCTION__);
}

/*! A SimplePing delegate callback, called when the object fails to send a ping packet.
 *  \details Each call to `-sendPingWithData:` will result in either a
 *      `-simplePing:didSendPacket:sequenceNumber:` delegate callback or a
 *      `-simplePing:didFailToSendPacket:sequenceNumber:error:` delegate callback (unless you
 *      stop the object before you get the callback).  These callbacks are currently delivered
 *      synchronously from within `-sendPingWithData:`, but this synchronous behaviour is not
 *      considered API.
 *  \param ping The object issuing the callback.
 *  \param packet The packet that was not sent; see `-simplePing:didSendPacket:sequenceNumber:`
 *      for details.
 *  \param sequenceNumber The ICMP sequence number of that packet.
 *  \param error Describes the failure.
 */
- (void)simplePing:(ZNDSimplePing *)ping
didFailToSendPacket:(NSData *)packet
    sequenceNumber:(uint16_t)sequenceNumber
             error:(NSError *)error {
    ZLog(@"%s", __FUNCTION__);
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    [info setValue:error forKey:@"error"];
    [info addEntriesFromDictionary:self.defaultInfo];
    if ([self.delegate respondsToSelector:@selector(ping:didFailWithInfo:)]) {
        [self.delegate ping:self didFailWithInfo:info];
    }
    [self sendWithPing:ping];
}


/*! A SimplePing delegate callback, called when the object receives a ping response.
 *  \details If the object receives an ping response that matches a ping request that it
 *      sent, it informs the delegate via this callback.  Matching is primarily done based on
 *      the ICMP identifier, although other criteria are used as well.
 *  \param ping The object issuing the callback.
 *  \param packet The packet received; this includes the ICMP header (`ICMPPacketHeader`) and any data that
 *      follows that in the ICMP message but does not include any IP-level headers.
 *  \param sequenceNumber The ICMP sequence number of that packet.
 */
- (void)simplePing:(ZNDSimplePing *)ping
didReceivePingResponsePacket:(NSData *)packet
    sequenceNumber:(uint16_t)sequenceNumber {
    ZLog(@"%s", __FUNCTION__);
    
    // ==== Data
    //由于IPV6在IPheader中不返回TTL数据，所以这里不返回TTL，改为返回Type
    //http://blog.sina.com.cn/s/blog_6a1837e901012ds8.html
    const struct ICMPPacketHeader *icmp = [ZNDSimplePing icmpInPacket:packet];
    NSString *type = (icmp->type == 129) ? @"ICMPv6TypeEchoReply" : @"ICMPv4TypeEchoReply";
    NSNumber *duration = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceDate:self.sendDate]];
    NSDictionary *response = @{
        @"type": type,
        @"duration": duration
    };
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    [info addEntriesFromDictionary:response];
    [info addEntriesFromDictionary:self.defaultInfo];
    // ====
    
    if ([self.delegate respondsToSelector:@selector(ping:didSucceedWithInfo:)]) {
        [self.delegate ping:self didSucceedWithInfo:info];
    }
    [self receiveWithPing:ping];
    [self sendWithPing:ping];
    ZLog(@"%s response info: %@", __FUNCTION__, info);
}

/*! A SimplePing delegate callback, called when the object receives an unmatched ICMP message.
 *  \details If the object receives an ICMP message that does not match a ping request that it
 *      sent, it informs the delegate via this callback.  The nature of ICMP handling in a
 *      BSD kernel makes this a common event because, when an ICMP message arrives, it is
 *      delivered to all ICMP sockets.
 *
 *      IMPORTANT: This callback is especially common when using IPv6 because IPv6 uses ICMP
 *      for important network management functions.  For example, IPv6 routers periodically
 *      send out Router Advertisement (RA) packets via Neighbor Discovery Protocol (NDP), which
 *      is implemented on top of ICMP.
 *
 *      For more on matching, see the discussion associated with
 *      `-simplePing:didReceivePingResponsePacket:sequenceNumber:`.
 *  \param ping The object issuing the callback.
 *  \param packet The packet received; this includes the ICMP header (`ICMPPacketHeader`) and any data that
 *      follows that in the ICMP message but does not include any IP-level headers.
 */
- (void)simplePing:(ZNDSimplePing *)ping
didReceiveUnexpectedPacket:(NSData *)packet {
    ZLog(@"%s", __FUNCTION__);
    
    // ==== Data
    //由于IPV6在IPheader中不返回TTL数据，所以这里不返回TTL，改为返回Type
    //http://blog.sina.com.cn/s/blog_6a1837e901012ds8.html
    const struct ICMPPacketHeader *icmp = [ZNDSimplePing icmpInPacket:packet];
    NSString *type = (icmp->type == 129) ? @"ICMPv6TypeEchoReply" : @"ICMPv4TypeEchoReply";
    NSNumber *duration = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSinceDate:self.sendDate]];
    uint8_t code = icmp->code;
    NSDictionary *response = @{
        @"type": type,
        @"duration": duration
    };
    NSError *error = [NSError errorWithDomain:@"ZNDPingUnexpectedPacket" code:code userInfo:response];
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    [info setValue:error forKey:@"error"];
    [info addEntriesFromDictionary:self.defaultInfo];
    // ====
    
    if ([self.delegate respondsToSelector:@selector(ping:didFailWithInfo:)]) {
        [self.delegate ping:self didFailWithInfo:info];
    }
    
    [self receiveWithPing:ping];
    [self sendWithPing:ping];
    ZLog(@"%s response info: %@", __FUNCTION__, info);
}

// MARK: - Private
- (void)sendWithPing:(ZNDSimplePing *)ping {
    if (self.sent >= self.configuration.attempt) {
        return;
    }
    self.sent++;
    self.sendDate = [NSDate date];
    [ping sendPingWithData:nil];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.configuration.timeout
                                                  target:self
                                                selector:@selector(timeoutWithTimer:)
                                                userInfo:self.defaultInfo
                                                 repeats:NO];
}

- (void)receiveWithPing:(ZNDSimplePing *)ping {
    self.received++;
    self.sendDate = [NSDate date];
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    if (self.received >= self.configuration.attempt) {
        self.shouldStop = YES;
    }
}

- (void)timeoutWithTimer:(NSTimer *)timer {
    ZLog(@"%s", __FUNCTION__);
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    NSError *error = [NSError errorWithDomain:@"ZNDPingTimeout" code:-1 userInfo:nil];
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    [info setValue:error forKey:@"error"];
    [info addEntriesFromDictionary:self.defaultInfo];
    if ([self.delegate respondsToSelector:@selector(ping:didFailWithInfo:)]) {
        [self.delegate ping:self didFailWithInfo:info];
    }
    [self.ping stop];
    self.shouldStop = YES;
}

// MARK: - Parse
- (NSString *)convertedAddress:(NSData *)address {
    int err;
    NSString *result;
    char host[NI_MAXHOST];
    result = nil;
    if (address != nil) {
        err = getnameinfo([address bytes],
                          (socklen_t)[address length],
                          host,
                          sizeof(host),
                          NULL,
                          0,
                          NI_NUMERICHOST);
        if (err == 0) {
            result = [NSString stringWithCString:host encoding:NSASCIIStringEncoding];
            assert(result != nil);
        }
    }
    return result;
}

@end


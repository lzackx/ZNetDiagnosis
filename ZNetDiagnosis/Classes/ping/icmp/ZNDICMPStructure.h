//
//  ZNDICMPStructure.h
//  Pods
//
//  Created by lZackx on 2022/8/9.
//

#ifndef ZNDICMPStructure_h
#define ZNDICMPStructure_h

#import <netinet/in.h>
#import <AssertMacros.h>

/*! Describes the on-the-wire header format for an ICMP ping.
 *  \details This defines the header structure of ping packets on the wire.  Both IPv4 and
 *      IPv6 use the same basic structure.
 *
 *      This is declared in the header because clients of SimplePing might want to use
 *      it parse received ping packets.
 */
struct ICMPPacketHeader {
    uint8_t     type;
    uint8_t     code;
    uint16_t    checksum;
    uint16_t    identifier;
    uint16_t    sequenceNumber;
    // data...
};
typedef struct ICMPPacketHeader ICMPPacketHeader;

__Check_Compile_Time((sizeof(ICMPPacketHeader)) == (8));
__Check_Compile_Time(offsetof(ICMPPacketHeader, type) == 0);
__Check_Compile_Time(offsetof(ICMPPacketHeader, code) == 1);
__Check_Compile_Time(offsetof(ICMPPacketHeader, checksum) == 2);
__Check_Compile_Time(offsetof(ICMPPacketHeader, identifier) == 4);
__Check_Compile_Time(offsetof(ICMPPacketHeader, sequenceNumber) == 6);

enum {
    ICMPv4TypeEchoRequest = 8,          ///< The ICMP `type` for a ping request; in this case `code` is always 0.
    ICMPv4TypeEchoReply   = 0           ///< The ICMP `type` for a ping response; in this case `code` is always 0.
};

enum {
    ICMPv6TypeEchoRequest = 128,        ///< The ICMP `type` for a ping request; in this case `code` is always 0.
    ICMPv6TypeEchoReply   = 129         ///< The ICMP `type` for a ping response; in this case `code` is always 0.
};



#endif /* ZNDICMPStructure_h */

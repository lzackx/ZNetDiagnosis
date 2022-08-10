//
//  ZNDIPStructure.h
//  Pods
//
//  Created by lZackx on 2022/8/9.
//

#ifndef ZNDIPStructure_h
#define ZNDIPStructure_h

#import <netinet/in.h>
#import <AssertMacros.h>

/*! Describes the on-the-wire header format for an IPv4 packet.
 *  \details This defines the header structure of IPv4 packets on the wire.  We need
 *      this in order to skip this header in the IPv4 case, where the kernel passes
 *      it to us for no obvious reason.
 */

struct IPv4PacketHeader {
    uint8_t     versionAndHeaderLength;
    uint8_t     differentiatedServices;
    uint16_t    totalLength;
    uint16_t    identification;
    uint16_t    flagsAndFragmentOffset;
    uint8_t     timeToLive;
    uint8_t     protocol;
    uint16_t    headerChecksum;
    uint8_t     sourceAddress[4];
    uint8_t     destinationAddress[4];
    // options...
    // data...
};
typedef struct IPv4PacketHeader IPv4PacketHeader;

__Check_Compile_Time(sizeof(IPv4PacketHeader) == 20);
__Check_Compile_Time(offsetof(IPv4PacketHeader, versionAndHeaderLength) == 0);
__Check_Compile_Time(offsetof(IPv4PacketHeader, differentiatedServices) == 1);
__Check_Compile_Time(offsetof(IPv4PacketHeader, totalLength) == 2);
__Check_Compile_Time(offsetof(IPv4PacketHeader, identification) == 4);
__Check_Compile_Time(offsetof(IPv4PacketHeader, flagsAndFragmentOffset) == 6);
__Check_Compile_Time(offsetof(IPv4PacketHeader, timeToLive) == 8);
__Check_Compile_Time(offsetof(IPv4PacketHeader, protocol) == 9);
__Check_Compile_Time(offsetof(IPv4PacketHeader, headerChecksum) == 10);
__Check_Compile_Time(offsetof(IPv4PacketHeader, sourceAddress) == 12);
__Check_Compile_Time(offsetof(IPv4PacketHeader, destinationAddress) == 16);


/*! Calculates an IP checksum.
 *  \details This is the standard BSD checksum code, modified to use modern types.
 *  \param buffer A pointer to the data to checksum.
 *  \param bufferLen The length of that data.
 *  \returns The checksum value, in network byte order.
 */

static uint16_t in_checksum(const void *buffer, size_t bufferLen) {
    //
    size_t              bytesLeft;
    int32_t             sum;
    const uint16_t *    cursor;
    union {
        uint16_t        us;
        uint8_t         uc[2];
    } last;
    uint16_t            answer;
    
    bytesLeft = bufferLen;
    sum = 0;
    cursor = buffer;
    
    /*
     * Our algorithm is simple, using a 32 bit accumulator (sum), we add
     * sequential 16 bit words to it, and at the end, fold back all the
     * carry bits from the top 16 bits into the lower 16 bits.
     */
    while (bytesLeft > 1) {
        sum += *cursor;
        cursor += 1;
        bytesLeft -= 2;
    }
    
    /* mop up an odd byte, if necessary */
    if (bytesLeft == 1) {
        last.uc[0] = * (const uint8_t *) cursor;
        last.uc[1] = 0;
        sum += last.us;
    }
    
    /* add back carry outs from top 16 bits to low 16 bits */
    sum = (sum >> 16) + (sum & 0xffff);    /* add hi 16 to low 16 */
    sum += (sum >> 16);            /* add carry */
    answer = (uint16_t) ~sum;   /* truncate to 16 bits */
    
    return answer;
}

#endif /* ZNDIPStructure_h */

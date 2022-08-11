//
//  ZNetDiagnosis.m
//  ZNetDiagnosis
//
//  Created by lZackx on 2022/8/3.
//

#import "ZNetDiagnosis.h"


@interface ZNetDiagnosis ()

@property (nonatomic, readwrite, strong) NSOperationQueue *queue;

@end

@implementation ZNetDiagnosis

// MARK: - Life Cycle
static ZNetDiagnosis *_shared;

+ (instancetype)shared {
    static dispatch_once_t zndOneToken;
    dispatch_once(&zndOneToken, ^{
        _shared = [[super allocWithZone:NULL] init];
    });
    return _shared;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [ZNetDiagnosis shared];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _queue = [[NSOperationQueue alloc] init];
        _queue.name = @"com.znd.operation";
        _queue.maxConcurrentOperationCount = 1;
    }
    return self;
}

// MARK: - Queue
- (void)addOperation:(NSOperation *)operation {
    [self.queue addOperation:operation ];
}

@end
